import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Max people in a group, creator included (V3 brief 6.5; matches backend).
const maxGroupSize = 15;

/// Opens the group sheet: create when [group] is null, else view/edit.
/// Resolves with the created or saved group, or null.
Future<GroupResponse?> showGroupSheet(BuildContext context, {GroupResponse? group}) {
  return showFafoSheet<GroupResponse>(
    context,
    builder: (_) => GroupSheet(group: group),
  );
}

/// One sheet to create, edit or leave a group (V3 brief 6.5). Members are the
/// creator's friends and are added directly, no accept step. The creator can
/// rename, add, remove and delete; anyone can leave.
class GroupSheet extends ConsumerStatefulWidget {
  const GroupSheet({super.key, this.group});

  final GroupResponse? group;

  @override
  ConsumerState<GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends ConsumerState<GroupSheet> {
  late final TextEditingController _name;
  late final Set<String> _selected;
  bool _busy = false;
  String? _error;

  GroupResponse? get _group => widget.group;
  bool get _isNew => _group == null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _group?.name ?? '');
    _name.addListener(() => setState(() {}));
    final myUid = ref.read(currentProfileProvider).value?.uid;
    _selected = {
      for (final m in _group?.members ?? const <GroupMemberResponse>[])
        if (m.user.uid != myUid) m.user.uid,
    };
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<GroupResponse?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      ref.invalidate(groupsListProvider);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<GroupResponse?> _save() async {
    final repo = ref.read(groupsRepositoryProvider);
    final name = _name.text.trim();
    final group = _group;
    if (group == null) {
      return repo.createGroup(name, memberUids: _selected.toList());
    }
    final current = {for (final m in group.members) m.user.uid};
    final myUid = ref.read(currentProfileProvider).value?.uid;
    final toAdd = _selected.difference(current).toList();
    final toRemove = current.difference(_selected)..remove(myUid);
    if (name != group.name) await repo.updateGroup(group.id, name);
    for (final uid in toRemove) {
      await repo.removeMember(group.id, uid, answers: const []);
    }
    if (toAdd.isNotEmpty) return repo.addMembers(group.id, toAdd);
    return group;
  }

  Future<GroupResponse?> _leave() async {
    await ref.read(groupsRepositoryProvider).leaveGroup(_group!.id, answers: const []);
    return null;
  }

  Future<GroupResponse?> _delete() async {
    await ref.read(groupsRepositoryProvider).dissolveGroup(_group!.id, answers: const []);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentProfileProvider).value?.uid;
    final isAdmin = _isNew || _group!.adminUid == myUid;
    final friends = ref.watch(friendsListProvider);
    final friendList = friends.value ?? const <FriendResponse>[];

    // Everyone pickable: my friends, plus current members who aren't (so a
    // member's row never vanishes from the list).
    final rows = <({String uid, String name, String? photo})>[
      for (final f in friendList) (uid: f.user.uid, name: f.user.displayName, photo: f.user.photoUrl),
      for (final m in _group?.members ?? const <GroupMemberResponse>[])
        if (m.user.uid != myUid && !friendList.any((f) => f.user.uid == m.user.uid))
          (uid: m.user.uid, name: m.user.displayName, photo: m.user.photoUrl),
    ];
    final atCap = _selected.length + 1 >= maxGroupSize;
    final canSave = _name.text.trim().isNotEmpty && _selected.isNotEmpty && !_busy;

    return FafoSheetBody(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 44),
          child: FafoEyebrow(_isNew ? 'New group' : 'Group'),
        ),
        TextField(
          controller: _name,
          enabled: isAdmin,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.display(40).copyWith(height: 1),
          decoration: InputDecoration(
            hintText: 'NAME IT',
            hintStyle: AppTypography.display(40, color: AppColors.softLine).copyWith(height: 1),
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FafoEyebrow('Members · your friends, up to $maxGroupSize', fontSize: 10.5),
            const SizedBox(height: 4),
            if (friends.isLoading && rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No friends yet. Share your code from home first.',
                  style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ),
            for (final r in rows)
              FafoCheckRow(
                title: r.name,
                leading: FafoAvatar(name: r.name, size: FafoAvatarSize.md, photoUrl: r.photo),
                checked: _selected.contains(r.uid),
                onTap: !isAdmin || _busy || (atCap && !_selected.contains(r.uid))
                    ? null
                    : () => setState(() {
                        if (!_selected.remove(r.uid)) _selected.add(r.uid);
                      }),
              ),
          ],
        ),
        if (isAdmin)
          FafoPill(
            label: _isNew ? 'Create group' : 'Save changes',
            block: true,
            busy: _busy,
            onPressed: canSave ? () => _run(_save) : null,
          ),
        if (!_isNew)
          Row(
            children: [
              Expanded(
                child: FafoPill(
                  label: 'Leave group',
                  primary: false,
                  onPressed: _busy ? null : () => _run(_leave),
                ),
              ),
            ],
          ),
        if (!_isNew && isAdmin)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busy ? null : () => _run(_delete),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
              child: Text(
                'Delete group',
                style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: AppColors.signalRed).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.signalRed,
                ),
              ),
            ),
          ),
        if (_error != null)
          Text(_error!, style: AppTypography.ui(13, color: AppColors.signalRed)),
        Text(
          'Friends are added straight away, no accept step. You can rename, add, remove and delete; anyone can leave.',
          style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
