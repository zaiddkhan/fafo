import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';

/// How often home re-reads nudges and friends. Timers themselves tick locally
/// from server timestamps; polling only picks up answers and new nudges.
const _nudgePoll = Duration(seconds: 5);
const _friendPoll = Duration(seconds: 15);

/// Every nudge the user sent or received, newest first. Polls while home is
/// on screen and keeps the last good data across refreshes (no spinner flash).
final myNudgesProvider =
    AsyncNotifierProvider.autoDispose<MyNudgesNotifier, List<NudgeResponse>>(
      MyNudgesNotifier.new,
    );

class MyNudgesNotifier extends AsyncNotifier<List<NudgeResponse>> {
  Timer? _timer;

  /// Bumped by [upsert]. A poll that started before a local change and lands
  /// after it would put the old card back, so its result is dropped.
  int _generation = 0;

  @override
  Future<List<NudgeResponse>> build() {
    _timer?.cancel();
    _timer = Timer.periodic(_nudgePoll, (_) => refresh());
    ref.onDispose(() => _timer?.cancel());
    return ref.read(nudgesRepositoryProvider).listMine();
  }

  Future<void> refresh() async {
    final startedAt = _generation;
    try {
      final next = await ref.read(nudgesRepositoryProvider).listMine();
      if (startedAt != _generation) return;
      state = AsyncData(next);
    } catch (_) {
      // Keep showing the last good list; the next poll retries.
    }
  }

  /// Swap in a nudge the server just returned (send / answer) so the card
  /// updates without waiting for the next poll.
  void upsert(NudgeResponse nudge) {
    _generation++;
    final current = state.value ?? const <NudgeResponse>[];
    final others = current.where((n) => n.id != nudge.id);
    state = AsyncData([nudge, ...others]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }
}

/// Friends list, refreshed periodically so "also free" stays current.
final liveFriendsProvider =
    AsyncNotifierProvider.autoDispose<LiveFriendsNotifier, List<FriendResponse>>(
      LiveFriendsNotifier.new,
    );

class LiveFriendsNotifier extends AsyncNotifier<List<FriendResponse>> {
  Timer? _timer;

  @override
  Future<List<FriendResponse>> build() {
    _timer?.cancel();
    _timer = Timer.periodic(_friendPoll, (_) => refresh());
    ref.onDispose(() => _timer?.cancel());
    return ref.read(friendsRepositoryProvider).getFriends();
  }

  Future<void> refresh() async {
    try {
      state = AsyncData(await ref.read(friendsRepositoryProvider).getFriends());
    } catch (_) {}
  }
}

/// Friends for the composer's invite chips: most recently nudged first.
List<FriendResponse> friendsByRecentNudge(List<FriendResponse> friends) {
  final sorted = [...friends];
  sorted.sort((a, b) {
    final at = a.lastNudge?.createdAt;
    final bt = b.lastNudge?.createdAt;
    if (at == null && bt == null) return a.user.displayName.compareTo(b.user.displayName);
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
  return sorted;
}
