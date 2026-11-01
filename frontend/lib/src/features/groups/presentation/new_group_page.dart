import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/home/presentation/app_header.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// New group (a full screen): pick two or more friends, then "Name group"
/// opens a sheet to name it and save. Pops with the new group.
class NewGroupPage extends ConsumerStatefulWidget {
  const NewGroupPage({super.key});

  @override
  ConsumerState<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends ConsumerState<NewGroupPage> {
  final Set<String> _picked = {};

  Future<void> _name(List<FriendResponse> friends) async {
    final members = [for (final f in friends) if (_picked.contains(f.user.uid)) f.user];
    final group = await showFafoSheet<GroupResponse>(
      context,
      title: 'Name group',
      builder: (_) => _NameGroupSheet(
        members: members,
        onToggle: (uid) => setState(() {
          if (!_picked.remove(uid)) _picked.add(uid);
        }),
      ),
    );
    if (group != null && mounted) Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final friends = [...friendsAsync.value ?? const <FriendResponse>[]]
      ..sort((a, b) => a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase()));
    final atCap = _picked.length + 1 >= maxGroupSize;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBody: true,
      bottomNavigationBar: const FafoPageMenu(index: 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(bottom: false, child: FafoAppHeader(onBack: () => Navigator.of(context).maybePop())),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, FafoBottomNav.clearance(context) + 70),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const FafoDisplay('New group'),
                        const SizedBox(width: 10),
                        Text(
                          '${_picked.length} selected',
                          style: AppTypography.label(fontSize: 12, color: AppColors.textSecondary).copyWith(letterSpacing: 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (friendsAsync.isLoading && friends.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (friends.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Add a few friends first. Groups are made from your friends.',
                          style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                        ),
                      ),
                    for (final f in friends)
                      FafoCheckRow(
                        title: f.user.displayName,
                        subtitle: '@${f.user.username}',
                        leading: FafoAvatar(
                          name: f.user.displayName,
                          photoUrl: f.user.photoUrl,
                          size: FafoAvatarSize.md,
                          free: f.user.freeNow,
                        ),
                        checked: _picked.contains(f.user.uid),
                        onTap: atCap && !_picked.contains(f.user.uid)
                            ? null
                            : () => setState(() {
                                if (!_picked.remove(f.user.uid)) _picked.add(f.user.uid);
                              }),
                      ),
                  ],
                ),
                // Floats 14px above the menu once two people are picked.
                if (_picked.length >= 2)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottom + 12 + FafoBottomNav.height + 14,
                    child: Center(
                      child: FafoPill(label: 'Name group', onPressed: () => _name(friends)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameGroupSheet extends ConsumerStatefulWidget {
  const _NameGroupSheet({required this.members, required this.onToggle});

  final List<PublicUserResponse> members;

  /// Keeps the picker behind in step when someone is deselected here.
  final ValueChanged<String> onToggle;

  @override
  ConsumerState<_NameGroupSheet> createState() => _NameGroupSheetState();
}

class _NameGroupSheetState extends ConsumerState<_NameGroupSheet> {
  final _name = TextEditingController();
  bool _saving = false;
  late final Set<String> _in = {for (final m in widget.members) m.uid};

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final group = await ref
          .read(groupsRepositoryProvider)
          .createGroup(name, memberUids: _in.toList());
      ref.invalidate(groupsListProvider);
      FafoToasts.show('$name is ready.');
      if (mounted) Navigator.of(context).pop(group);
    } catch (e) {
      FafoToasts.error(e);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FafoSheetBody(
      footer: FafoPill(
        label: 'Save group',
        block: true,
        busy: _saving,
        // A name and at least two people.
        onPressed: _name.text.trim().isEmpty || _in.length < 2 ? null : _save,
      ),
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _save(),
          style: AppTypography.ui(22, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: 'Name it',
            hintStyle: AppTypography.ui(22, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rule, width: 2)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentPrimary, width: 2)),
          ),
        ),
        FafoSectionLabel('Members · ${_in.length}', bottom: 4),
        for (final m in widget.members)
          FafoCheckRow(
            title: m.displayName,
            subtitle: '@${m.username}',
            leading: FafoAvatar(name: m.displayName, photoUrl: m.photoUrl, size: FafoAvatarSize.md),
            checked: _in.contains(m.uid),
            onTap: () {
              setState(() {
                if (!_in.remove(m.uid)) _in.add(m.uid);
              });
              widget.onToggle(m.uid);
            },
          ),
      ],
    );
  }
}
