import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';

class NudgeFeedKey {
  const NudgeFeedKey(this.feedType, this.targetId);
  final NudgeFeedType feedType;
  final String targetId;

  @override
  bool operator ==(Object other) => other is NudgeFeedKey && other.feedType == feedType && other.targetId == targetId;
  @override
  int get hashCode => Object.hash(feedType, targetId);
}

final nudgeFeedProvider = FutureProvider.autoDispose.family<List<NudgeResponse>, NudgeFeedKey>((ref, key) {
  return ref.watch(nudgesRepositoryProvider).listFeed(key.feedType, key.targetId);
});
