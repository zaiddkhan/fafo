import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/new_group_page.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';
import 'package:fafu/src/features/nudges/presentation/plan_detail_sheet.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Max people in a group, creator included (matches backend).
const maxGroupSize = 15;

/// What a group sheet hands back to whoever opened it.
sealed class GroupSheetResult {
  const GroupSheetResult();
}

/// "Send nudge" on the group.
class GroupSendNudge extends GroupSheetResult {
  const GroupSendNudge(this.group);
  final GroupResponse group;
}

/// "Send again" on one of the group's plans.
class GroupSendAgain extends GroupSheetResult {
  const GroupSendAgain(this.nudge);
  final NudgeResponse nudge;
}

/// A member row: open that friend's sheet.
class GroupOpenFriend extends GroupSheetResult {
  const GroupOpenFriend(this.user);
  final PublicUserResponse user;
}

/// Opens a group's detail sheet, or New group when [group] is null.
Future<GroupSheetResult?> showGroupSheet(BuildContext context, {GroupResponse? group}) async {
  if (group == null) {
    await Navigator.of(context).push(MaterialPageRoute<GroupResponse>(builder: (_) => const NewGroupPage()));
    return null;
  }
  return showFafoSheet<GroupSheetResult>(context, builder: (_) => GroupSheet(group: group));
}

/// Group detail: overlapping member avatars, the name (the admin can rename it
/// in place), Send nudge, Members, Plans, then Leave and, for the admin,
/// Delete. Only the admin renames, removes or deletes; an admin who leaves
/// hands the group to someone or deletes it.
class GroupSheet extends ConsumerStatefulWidget {
  const GroupSheet({super.key, required this.group});

  final GroupResponse group;

  @override
  ConsumerState<GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends ConsumerState<GroupSheet> {
  late GroupResponse _group = widget.group;
  late final TextEditingController _name = TextEditingController(text: widget.group.name);
  final _nameFocus = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _rename();
    });
  }

  /// Held so a rename fired while the sheet closes never looks up a
  /// deactivated context.
  late ProviderContainer _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// Saves a rename when the field loses focus (Done, a tap elsewhere, or
  /// closing the sheet). Safe after the sheet is gone: it holds the container,
  /// not this state.
  Future<void> _rename() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _name.text = _group.name;
      return;
    }
    if (name == _group.name) return;
    final container = _container;
    final repo = container.read(groupsRepositoryProvider);
    try {
      final updated = await repo.updateGroup(_group.id, name);
      container.invalidate(groupsListProvider);
      if (mounted) setState(() => _group = updated);
      FafoToasts.show('Renamed to $name.');
    } catch (e) {
      if (mounted) _name.text = _group.name;
      FafoToasts.error(e);
    }
  }

  Future<void> _run(Future<void> Function() action, {String? done, bool close = true}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(groupsListProvider);
      if (done != null) FafoToasts.show(done);
      if (close && mounted) Navigator.of(context).pop();
    } catch (e) {
      FafoToasts.error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(bool isAdmin) async {
    final repo = ref.read(groupsRepositoryProvider);
    final others = _group.members.where((m) => m.user.uid != ref.read(currentProfileProvider).value?.uid).toList();
    if (!isAdmin) {
      final admin = _group.members.where((m) => m.user.uid == _group.adminUid).firstOrNull?.user.displayName.split(' ').first;
      final sure = await showFafoConfirm(
        context,
        title: 'Leave ${_group.name}?',
        message: 'You’ll stop getting its plans.${admin == null ? '' : ' $admin can add you back anytime.'}',
        confirmLabel: 'Leave group',
      );
      if (sure && mounted) await _run(() => repo.leaveGroup(_group.id, answers: const []), done: 'You left ${_group.name}.');
      return;
    }
    final choice = await showFafoModal<String>(
      context,
      title: 'Leave ${_group.name}?',
      message: 'You’re the admin. Hand it to someone, or delete the group for everyone.',
      actions: [
        if (others.isNotEmpty) const FafoModalAction('Assign admin', 'assign', primary: true),
        const FafoModalAction('Delete group', 'delete', danger: true),
        const FafoModalAction('Cancel', 'cancel'),
      ],
    );
    if (!mounted) return;
    if (choice == 'delete') {
      await _run(() => repo.dissolveGroup(_group.id, answers: const []), done: '${_group.name} is deleted.');
    } else if (choice == 'assign') {
      final uid = await showFafoSheet<String>(
        context,
        title: 'Assign admin',
        builder: (_) => _PickMembers(members: others, single: true, actionLabel: 'Save and leave'),
      );
      if (uid == null || !mounted) return;
      final name = others.firstWhere((m) => m.user.uid == uid).user.displayName;
      await _run(() async {
        await repo.transferOwnership(_group.id, uid);
        await repo.leaveGroup(_group.id, answers: const []);
      }, done: '$name is the admin now. You left ${_group.name}.');
    }
  }

  Future<void> _delete() async {
    final sure = await showFafoConfirm(
      context,
      title: 'Delete ${_group.name}?',
      message: 'It’s gone for everyone, along with its plan history. This can’t be undone.',
      confirmLabel: 'Delete group',
    );
    if (sure && mounted) {
      await _run(
        () => ref.read(groupsRepositoryProvider).dissolveGroup(_group.id, answers: const []),
        done: '${_group.name} is deleted.',
      );
    }
  }

  Future<void> _removeMembers(String myUid) async {
    final others = _group.members.where((m) => m.user.uid != myUid).toList();
    final picked = await showFafoSheet<Set<String>>(
      context,
      title: 'Remove members',
      builder: (_) => _PickMembers(members: others, actionLabel: 'Remove'),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final repo = ref.read(groupsRepositoryProvider);
    await _run(() async {
      for (final uid in picked) {
        await repo.removeMember(_group.id, uid, answers: const []);
      }
      final fresh = (await repo.getGroups()).where((g) => g.id == _group.id).firstOrNull;
      if (fresh != null && mounted) setState(() => _group = fresh);
    }, done: picked.length == 1 ? 'Removed 1 member.' : 'Removed ${picked.length} members.', close: false);
  }

  Future<void> _addMembers(String myUid) async {
    final friends = ref.read(friendsListProvider).value ?? const <FriendResponse>[];
    final current = {for (final m in _group.members) m.user.uid};
    final candidates = [
      for (final f in friends)
        if (!current.contains(f.user.uid))
          GroupMemberResponse(user: f.user, joinedAt: DateTime.now(), isAdmin: false),
    ];
    if (candidates.isEmpty) {
      FafoToasts.show('All your friends are in it.', kind: FafoToastKind.info);
      return;
    }
    final room = maxGroupSize - _group.members.length;
    final picked = await showFafoSheet<Set<String>>(
      context,
      title: 'Add members',
      builder: (_) => _PickMembers(members: candidates, actionLabel: 'Add', limit: room),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    await _run(() async {
      final updated = await ref.read(groupsRepositoryProvider).addMembers(_group.id, picked.toList());
      if (mounted) setState(() => _group = updated);
    }, done: picked.length == 1 ? 'Added 1 member.' : 'Added ${picked.length} members.', close: false);
  }

  Future<void> _openPlan(NudgeView view) async {
    final again = await showPlanDetailSheet(context, view);
    if (again != null && mounted) Navigator.of(context).pop(GroupSendAgain(again));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentProfileProvider).value;
    final myUid = me?.uid ?? '';
    final isAdmin = _group.adminUid == myUid;
    final friends = ref.watch(friendsListProvider).value ?? const <FriendResponse>[];
    final members = [..._group.members]
      ..sort((a, b) {
        // Admin first, then you, then everyone else by name.
        int rank(GroupMemberResponse m) => m.user.uid == _group.adminUid ? 0 : (m.user.uid == myUid ? 1 : 2);
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase());
      });
    final nudges = ref.watch(myNudgesProvider).value ?? const <NudgeResponse>[];
    final plans = [
      for (final n in nudges)
        if (n.isGroup && n.targetId == _group.id) NudgeView(n, myUid: myUid),
    ]..sort((a, b) => b.nudge.createdAt.compareTo(a.nudge.createdAt));
    final now = ServerClock.now();
    final stackPeople = [
      for (final m in members.where((m) => m.user.uid != myUid)) (m.user.displayName, m.user.photoUrl),
    ];

    return FafoSheetBody(
      children: [
        Center(child: FafoAvatarStack(people: stackPeople.isEmpty ? [(me?.displayName ?? '?', me?.photoUrl)] : stackPeople, dimension: 62)),
        const SizedBox(height: 12),
        if (isAdmin)
          TextField(
            controller: _name,
            focusNode: _nameFocus,
            maxLength: 40,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _nameFocus.unfocus(),
            style: AppTypography.ui(24, fontWeight: FontWeight.w800).copyWith(height: 1.15),
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 2, bottom: 6),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.softLine, width: 2)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentPrimary, width: 2)),
              semanticCounterText: 'Group name',
            ),
          )
        else
          Text(
            _group.name,
            textAlign: TextAlign.center,
            style: AppTypography.ui(24, fontWeight: FontWeight.w800).copyWith(height: 1.15),
          ),
        const SizedBox(height: 6),
        Text(
          '${_group.members.length} ${_group.members.length == 1 ? 'member' : 'members'}',
          textAlign: TextAlign.center,
          style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
        if (FeatureFlags.groupMute) ...[
          const SizedBox(height: 10),
          Center(child: _MuteButton(onTap: () {})),
        ],
        // No second plan while one to this group is still running.
        if (!plans.any((v) => _running(v, now))) ...[
          const SizedBox(height: 20),
          FafoPill(
            label: 'Send nudge',
            block: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(GroupSendNudge(_group)),
          ),
        ],
        FafoSectionLabel(
          'Members',
          bottom: 4,
          action: isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_group.members.length < maxGroupSize)
                      _LabelLink(label: 'Add', onTap: _busy ? null : () => _addMembers(myUid)),
                    if (_group.members.length > 1) ...[
                      const SizedBox(width: 14),
                      _LabelLink(label: 'Remove', onTap: _busy ? null : () => _removeMembers(myUid)),
                    ],
                  ],
                )
              : null,
        ),
        for (final m in members)
          FafoListRow(
            title: m.user.uid == myUid ? 'You' : m.user.displayName,
            subtitle: '@${m.user.username}',
            titleBadge: m.user.uid == _group.adminUid ? const FafoBadge('Admin', kind: FafoBadgeKind.tag, small: true) : null,
            leading: FafoAvatar(
              name: m.user.displayName,
              photoUrl: m.user.photoUrl,
              size: FafoAvatarSize.md,
              free: m.user.uid != myUid && (friends.where((f) => f.user.uid == m.user.uid).firstOrNull?.user.freeNow ?? m.user.freeNow),
            ),
            showChevron: m.user.uid != myUid,
            onTap: m.user.uid == myUid ? null : () => Navigator.of(context).pop(GroupOpenFriend(m.user)),
          ),
        if (plans.isNotEmpty) ...[
          const FafoSectionLabel('Plans', bottom: 4),
          for (final v in plans) PlanRow(view: v, now: now, onTap: () => _openPlan(v)),
        ],
        FafoQuietLinks(
          links: [
            ('Leave group', _busy ? null : () => _leave(isAdmin), false),
            if (isAdmin) ('Delete group', _busy ? null : _delete, true),
          ],
        ),
      ],
    );
  }
}

/// Blue text action inside a section label ("Remove").
class _LabelLink extends StatelessWidget {
  const _LabelLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(label, style: AppTypography.ui(13.5, fontWeight: FontWeight.w700, color: AppColors.accentPrimary)),
        ),
      ),
    );
  }
}

/// Parked (FeatureFlags.groupMute) until the backend can mute a group.
class _MuteButton extends StatelessWidget {
  const _MuteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppChrome.pillRadius),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppChrome.pillRadius),
          border: Border.all(color: AppColors.softLine, width: AppChrome.softOutlineWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 15, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text('Mute', style: AppTypography.ui(13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// A stacked sheet to pick members: many (Remove, Add) or one (Assign admin).
/// Resolves with the picked uids (a Set) or the one uid (a String).
class _PickMembers extends StatefulWidget {
  const _PickMembers({required this.members, required this.actionLabel, this.single = false, this.limit});

  final List<GroupMemberResponse> members;
  final String actionLabel;
  final bool single;
  final int? limit;

  @override
  State<_PickMembers> createState() => _PickMembersState();
}

class _PickMembersState extends State<_PickMembers> {
  final Set<String> _picked = {};

  @override
  Widget build(BuildContext context) {
    final full = widget.limit != null && _picked.length >= widget.limit!;
    return FafoSheetBody(
      footer: FafoPill(
        label: widget.single || _picked.isEmpty ? widget.actionLabel : '${widget.actionLabel} ${_picked.length}',
        block: true,
        onPressed: _picked.isEmpty
            ? null
            : () => Navigator.of(context).pop(widget.single ? _picked.first : _picked),
      ),
      children: [
        for (final m in widget.members)
          FafoCheckRow(
            title: m.user.displayName,
            subtitle: '@${m.user.username}',
            radio: widget.single,
            leading: FafoAvatar(name: m.user.displayName, photoUrl: m.user.photoUrl, size: FafoAvatarSize.md),
            checked: _picked.contains(m.user.uid),
            onTap: full && !_picked.contains(m.user.uid)
                ? null
                : () => setState(() {
                    if (widget.single) {
                      _picked
                        ..clear()
                        ..add(m.user.uid);
                    } else if (!_picked.remove(m.user.uid)) {
                      _picked.add(m.user.uid);
                    }
                  }),
          ),
      ],
    );
  }
}

bool _running(NudgeView v, DateTime now) {
  final s = v.state(now);
  return s == NudgeCardState.pending || s == NudgeCardState.accepted;
}
