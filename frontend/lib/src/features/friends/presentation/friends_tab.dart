import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/friends/presentation/add_friends_sheet.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';
import 'package:fafu/src/features/nudges/presentation/plan_detail_sheet.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

export 'package:fafu/src/features/friends/presentation/add_friends_sheet.dart' show showAddFriendsSheet;

enum _Filter { free, everyone, groups }

/// Friends: search with the add icon next to it, then Free now / Everyone /
/// Groups. Rows open a friend's or group's sheet; free friends carry a blue
/// dot on their avatar.
class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key, required this.onNudge, this.onNudgeGroup, this.onSendAgain});

  /// Opens the composer for [friend]; the shell handles what happens after.
  final ValueChanged<PublicUserResponse> onNudge;
  final ValueChanged<GroupResponse>? onNudgeGroup;
  final ValueChanged<NudgeResponse>? onSendAgain;

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.everyone;
  String? _highlight;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addFriends() async {
    final group = await showAddFriendsSheet(context);
    if (group != null && mounted) _showNewGroup(group);
  }

  /// Land on Groups with the new group washed blue for a moment.
  void _showNewGroup(GroupResponse group) {
    ref.invalidate(groupsListProvider);
    setState(() {
      _filter = _Filter.groups;
      _highlight = group.id;
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _highlight == group.id) setState(() => _highlight = null);
    });
  }

  Future<void> _openFriend(PublicUserResponse user, {FriendResponse? friend}) async {
    final result = await showFriendSheet(context, user: user, friend: friend);
    if (!mounted || result == null) return;
    switch (result) {
      case FriendSendNudge():
        widget.onNudge(user);
      case FriendSendAgain(:final nudge):
        widget.onSendAgain?.call(nudge);
    }
  }

  Future<void> _openGroup(GroupResponse group) async {
    final result = await showGroupSheet(context, group: group);
    if (!mounted || result == null) return;
    switch (result) {
      case GroupSendNudge(:final group):
        widget.onNudgeGroup?.call(group);
      case GroupSendAgain(:final nudge):
        widget.onSendAgain?.call(nudge);
      case GroupOpenFriend(:final user):
        final friends = ref.read(liveFriendsProvider).value ?? const <FriendResponse>[];
        await _openFriend(user, friend: friends.where((f) => f.user.uid == user.uid).firstOrNull);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(liveFriendsProvider);
    final groupsAsync = ref.watch(groupsListProvider);
    final requests = ref.watch(incomingFriendRequestsProvider).value ?? const <FriendRequestResponse>[];
    final all = friends.value ?? const <FriendResponse>[];
    final groups = groupsAsync.value ?? const <GroupResponse>[];
    final myUid = ref.watch(currentProfileProvider).value?.uid;
    final q = _search.text.trim().toLowerCase();

    bool friendHit(FriendResponse f) =>
        q.isEmpty || f.user.displayName.toLowerCase().contains(q) || f.user.username.toLowerCase().contains(q);
    final sorted = [...all]..sort((a, b) {
      if (a.user.freeNow != b.user.freeNow) return a.user.freeNow ? -1 : 1;
      return a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase());
    });
    final freeCount = all.where((f) => f.user.freeNow).length;
    final shownFriends = [
      for (final f in sorted)
        if (friendHit(f) && (_filter != _Filter.free || f.user.freeNow)) f,
    ];
    final shownGroups = [
      for (final g in groups)
        if (q.isEmpty || g.name.toLowerCase().contains(q)) g,
    ];
    final loading = friends.isLoading && !friends.hasValue;
    final empty = !loading && all.isEmpty && groups.isEmpty && requests.isEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomingFriendRequestsProvider);
        ref.invalidate(groupsListProvider);
        await ref.read(liveFriendsProvider.notifier).refresh();
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, FafoBottomNav.clearance(context)),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const FafoDisplay('Friends'),
              const SizedBox(width: 10),
              Text(
                '${all.length}',
                style: AppTypography.label(fontSize: 12, color: AppColors.textSecondary).copyWith(letterSpacing: 0),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (empty)
            _NoFriends(onAdd: _addFriends)
          else ...[
            Row(
              children: [
                Expanded(child: FafoSearchField(controller: _search)),
                const SizedBox(width: 10),
                FafoRoundButton(icon: Icons.person_add_alt_outlined, label: 'Add friends', size: 48, onTap: _addFriends),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (filter, label, count) in [
                  (_Filter.free, 'Free now', freeCount),
                  (_Filter.everyone, 'Everyone', all.length),
                  (_Filter.groups, 'Groups', groups.length),
                ]) ...[
                  if (filter != _Filter.free) const SizedBox(width: 8),
                  Expanded(
                    child: FafoFilterChip(
                      label: label,
                      count: count,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (requests.isNotEmpty && _filter != _Filter.groups && q.isEmpty) ...[
              const FafoSectionLabel('Wants to add you', top: 4, bottom: 4),
              for (final r in requests) _RequestRow(request: r),
              const FafoSectionLabel('Friends', top: 18, bottom: 4),
            ],
            if (loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (friends.hasError && all.isEmpty)
              _None(friendlyErrorMessage(friends.error))
            else if (_filter == _Filter.groups) ...[
              for (final g in shownGroups)
                _Highlight(
                  on: _highlight == g.id,
                  child: FafoListRow(
                    title: g.name,
                    subtitle: _memberLine(g, myUid),
                    leading: SizedBox(
                      width: 76,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FafoAvatarStack(
                          people: [
                            for (final m in g.members)
                              if (m.user.uid != myUid) (m.user.displayName, m.user.photoUrl),
                          ],
                          dimension: 32,
                        ),
                      ),
                    ),
                    onTap: () => _openGroup(g),
                  ),
                ),
              if (shownGroups.isEmpty)
                _None(q.isNotEmpty ? 'No group called “${_search.text.trim()}”.' : 'No groups yet.'),
            ] else ...[
              for (final f in shownFriends)
                FafoListRow(
                  title: f.user.displayName,
                  subtitle: '@${f.user.username}',
                  leading: FafoAvatar(
                    name: f.user.displayName,
                    photoUrl: f.user.photoUrl,
                    size: FafoAvatarSize.md,
                    free: f.user.freeNow,
                  ),
                  onTap: () => _openFriend(f.user, friend: f),
                ),
              if (shownFriends.isEmpty)
                _None(
                  q.isNotEmpty
                      ? 'No one called “${_search.text.trim()}”.'
                      : _filter == _Filter.free
                      ? 'Nobody’s free right now.'
                      : 'No friends yet. Your people show up here once they’re on FaFo.',
                ),
            ],
          ],
        ],
      ),
    );
  }
}

/// "Maya, Leo, Nina +1".
String _memberLine(GroupResponse g, String? myUid) {
  final names = [
    for (final m in g.members)
      if (m.user.uid != myUid) m.user.displayName.split(' ').first,
  ];
  if (names.length <= 3) return names.join(', ');
  return '${names.take(3).join(', ')} +${names.length - 3}';
}

class _None extends StatelessWidget {
  const _None(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 2),
      child: Text(text, style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
    );
  }
}

/// Empty Friends: one line, one action.
class _NoFriends extends StatelessWidget {
  const _NoFriends({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No friends yet.', style: AppTypography.ui(22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Your people show up here once they’re on FaFo.',
              style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          FafoPill(label: 'Add friends', onPressed: onAdd),
        ],
      ),
    );
  }
}

/// A 2.4 second blue wash on a row you were sent to.
class _Highlight extends StatelessWidget {
  const _Highlight({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        color: on ? AppColors.accentPrimary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// An incoming friend request: Add or No.
class _RequestRow extends ConsumerStatefulWidget {
  const _RequestRow({required this.request});

  final FriendRequestResponse request;

  @override
  ConsumerState<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<_RequestRow> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      if (accept) {
        await repo.acceptRequest(widget.request.id);
      } else {
        await repo.declineRequest(widget.request.id);
      }
      ref.invalidate(incomingFriendRequestsProvider);
      if (accept) await ref.read(liveFriendsProvider.notifier).refresh();
    } catch (e) {
      FafoToasts.error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.request.requester;
    return FafoListRow(
      title: user.displayName,
      subtitle: '@${user.username}',
      leading: FafoAvatar(name: user.displayName, size: FafoAvatarSize.md, photoUrl: user.photoUrl),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FafoPill(label: 'Add', small: true, height: 36, busy: _busy, onPressed: () => _answer(true)),
          const SizedBox(width: 8),
          FafoPill(label: 'No', small: true, height: 36, primary: false, onPressed: _busy ? null : () => _answer(false)),
        ],
      ),
    );
  }
}

/// What a friend's sheet hands back.
sealed class FriendSheetResult {
  const FriendSheetResult();
}

class FriendSendNudge extends FriendSheetResult {
  const FriendSendNudge();
}

class FriendSendAgain extends FriendSheetResult {
  const FriendSendAgain(this.nudge);
  final NudgeResponse nudge;
}

/// A friend's sheet: who they are, Send nudge, the plans between you, then
/// the quieter Unfriend and Block.
Future<FriendSheetResult?> showFriendSheet(BuildContext context, {required PublicUserResponse user, FriendResponse? friend}) {
  return showFafoSheet<FriendSheetResult>(context, builder: (_) => FriendSheet(user: user, friend: friend));
}

class FriendSheet extends ConsumerStatefulWidget {
  const FriendSheet({super.key, required this.user, this.friend});

  final PublicUserResponse user;
  final FriendResponse? friend;

  @override
  ConsumerState<FriendSheet> createState() => FriendSheetState();
}

class FriendSheetState extends ConsumerState<FriendSheet> {
  bool _busy = false;

  Future<void> _remove({required bool block}) async {
    final user = widget.user;
    final first = user.displayName.split(' ').first;
    final sure = await showFafoConfirm(
      context,
      title: '${block ? 'Block' : 'Unfriend'} $first?',
      message: block
          ? '$first can’t send you plans or add you again, and won’t be told. You can unblock from Settings.'
          : 'You won’t see each other in Friends anymore. Any groups you share stay as they are.',
      confirmLabel: block ? 'Block' : 'Unfriend',
    );
    if (!sure || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      if (block) {
        await repo.blockUser(user.uid, answers: const []);
      } else {
        await repo.unfriend(user.uid, answers: const []);
      }
      await ref.read(liveFriendsProvider.notifier).refresh();
      ref.invalidate(blockedUsersProvider);
      if (mounted) Navigator.of(context).pop();
      FafoToasts.show(block ? '$first is blocked.' : 'You and $first aren’t friends anymore.');
    } catch (e) {
      FafoToasts.error(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPlan(NudgeView view) async {
    final again = await showPlanDetailSheet(context, view);
    if (again != null && mounted) Navigator.of(context).pop(FriendSendAgain(again));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final myUid = ref.watch(currentProfileProvider).value?.uid ?? '';
    final live = (ref.watch(liveFriendsProvider).value ?? const <FriendResponse>[])
        .where((f) => f.user.uid == user.uid)
        .firstOrNull;
    final isFriend = live != null || widget.friend != null;
    final free = live?.user.freeNow ?? user.freeNow;
    final nudges = ref.watch(myNudgesProvider).value ?? const <NudgeResponse>[];
    final plans = [
      for (final n in nudges)
        if (!n.isGroup && (n.senderUid == user.uid || n.targetId == user.uid)) NudgeView(n, myUid: myUid),
    ]..sort((a, b) => b.nudge.createdAt.compareTo(a.nudge.createdAt));
    final now = ServerClock.now();

    return FafoSheetBody(
      children: [
        Center(
          child: FafoAvatar(name: user.displayName, photoUrl: user.photoUrl, size: FafoAvatarSize.lg, free: free),
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: AppTypography.ui(24, fontWeight: FontWeight.w800).copyWith(height: 1.15),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          textAlign: TextAlign.center,
          style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
        // No second plan while one with them is still running.
        if (isFriend && !plans.any((v) {
          final st = v.state(now);
          return st == NudgeCardState.pending || st == NudgeCardState.accepted;
        })) ...[
          const SizedBox(height: 20),
          FafoPill(
            label: 'Send nudge',
            block: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(const FriendSendNudge()),
          ),
        ],
        if (plans.isNotEmpty) ...[
          const FafoSectionLabel('Plans', bottom: 4),
          for (final v in plans) PlanRow(view: v, now: now, onTap: () => _openPlan(v)),
        ],
        FafoQuietLinks(
          links: [
            if (isFriend) ('Unfriend', _busy ? null : () => _remove(block: false), false),
            ('Block', _busy ? null : () => _remove(block: true), true),
          ],
        ),
      ],
    );
  }
}
