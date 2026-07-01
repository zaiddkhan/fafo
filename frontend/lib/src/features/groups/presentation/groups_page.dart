import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_feed_sheet.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  static const routeName = 'groups';
  static const routePath = '/groups';

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(groupsListProvider);
    ref.invalidate(incomingGroupInvitesProvider);
    ref.invalidate(friendsListProvider);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      // The action may take a while; bail out if the page was disposed in the
      // meantime so we never touch a torn-down ref/provider.
      if (!mounted) return;
      _refresh();
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<String>?> _negativeAnswers(String title) {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => _NegativeAnswersDialog(title: title),
    );
  }

  Future<String?> _textDialog(String title, String label, {String initial = ''}) {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(title: title, label: label, initial: initial),
    );
  }

  Future<void> _createGroup() async {
    final name = await _textDialog('Create group', 'Group name');
    if (name == null) return;
    await _run(() => ref.read(groupsRepositoryProvider).createGroup(name).then((_) {}));
  }

  Future<void> _inviteFriend(GroupResponse group) async {
    final friends = await ref.read(friendsListProvider.future);
    if (!mounted) return;
    final selectedUid = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Invite a friend'),
        children: friends.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text('No friends available to invite.'))]
            : friends
                .where((friend) => !group.members.any((member) => member.user.uid == friend.user.uid))
                .map(
                  (friend) => SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(friend.user.uid),
                    child: Text('${friend.user.displayName} (@${friend.user.username})'),
                  ),
                )
                .toList(),
      ),
    );
    if (selectedUid == null) return;
    await _run(() => ref.read(groupsRepositoryProvider).inviteMember(group.id, selectedUid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ref.watch(groupsListProvider);
    final invites = ref.watch(incomingGroupInvitesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Groups'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
          children: [
            Text('Private groups', style: theme.textTheme.displayLarge?.copyWith(color: AppColors.accentPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text('Create friend-only groups, handle invites, and manage membership.', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: _busy ? 'Working…' : 'Create group', variant: AppButtonVariant.featured, onPressed: _busy ? null : _createGroup),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Group invites'),
            invites.when(
              loading: () => const _LoadingBlock(),
              error: (e, _) => _ErrorBlock(error: e.toString()),
              data: (items) => items.isEmpty
                  ? const _EmptyBlock(text: 'No pending group invites.')
                  : Column(children: items.map((invite) => _InviteCard(invite: invite, busy: _busy, onAccept: () => _run(() => ref.read(groupsRepositoryProvider).acceptInvite(invite.id)), onDecline: () => _run(() => ref.read(groupsRepositoryProvider).declineInvite(invite.id)))).toList()),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Your groups'),
            groups.when(
              loading: () => const _LoadingBlock(),
              error: (e, _) => _ErrorBlock(error: e.toString()),
              data: (items) => items.isEmpty
                  ? const _EmptyBlock(text: 'No groups yet.')
                  : Column(children: items.map((group) => _GroupCard(group: group, busy: _busy, onInvite: () => _inviteFriend(group), onRename: () async { final name = await _textDialog('Rename group', 'Group name', initial: group.name); if (name != null) await _run(() => ref.read(groupsRepositoryProvider).updateGroup(group.id, name).then((_) {})); }, onLeave: () async { final answers = await _negativeAnswers('Leave ${group.name}?'); if (answers != null) await _run(() => ref.read(groupsRepositoryProvider).leaveGroup(group.id, answers: answers)); }, onDissolve: () async { final answers = await _negativeAnswers('Dissolve ${group.name}?'); if (answers != null) await _run(() => ref.read(groupsRepositoryProvider).dissolveGroup(group.id, answers: answers)); }, onRemove: (uid) async { final answers = await _negativeAnswers('Remove member?'); if (answers != null) await _run(() => ref.read(groupsRepositoryProvider).removeMember(group.id, uid, answers: answers)); }, onTransfer: (uid) => _run(() => ref.read(groupsRepositoryProvider).transferOwnership(group.id, uid)))).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.busy, required this.onAccept, required this.onDecline});

  final GroupInviteResponse invite;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(invite.groupName),
        subtitle: Text('Invited by @${invite.inviter.username}'),
        trailing: Wrap(spacing: 8, children: [
          OutlinedButton(onPressed: busy ? null : onDecline, child: const Text('Decline')),
          FilledButton(onPressed: busy ? null : onAccept, child: const Text('Accept')),
        ]),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.busy, required this.onInvite, required this.onRename, required this.onLeave, required this.onDissolve, required this.onRemove, required this.onTransfer});

  final GroupResponse group;
  final bool busy;
  final VoidCallback onInvite;
  final VoidCallback onRename;
  final VoidCallback onLeave;
  final VoidCallback onDissolve;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onTransfer;

  bool get _isAdmin => FirebaseAuth.instance.currentUser?.uid == group.adminUid;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    return Card(
      elevation: 0,
      color: AppColors.bgSecondary,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(20, 10, 14, 10),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        collapsedShape: RoundedRectangleBorder(borderRadius: borderRadius),
        backgroundColor: AppColors.bgSecondary,
        collapsedBackgroundColor: AppColors.bgSecondary,
        title: Text(group.name),
        subtitle: Text('${group.members.length} member${group.members.length == 1 ? '' : 's'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'nudge') {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => NudgeFeedSheet(feedType: NudgeFeedType.group, targetId: group.id, title: group.name),
                ),
              );
            }
            if (value == 'invite') onInvite();
            if (value == 'rename') onRename();
            if (value == 'leave') onLeave();
            if (value == 'dissolve') onDissolve();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'nudge', child: Text('Nudge feed')),
            if (_isAdmin) const PopupMenuItem(value: 'invite', child: Text('Invite friend')),
            if (_isAdmin) const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'leave', child: Text('Leave')),
            if (_isAdmin) const PopupMenuItem(value: 'dissolve', child: Text('Dissolve')),
          ],
        ),
        children: group.members.map((member) {
          final canManage = _isAdmin && member.user.uid != group.adminUid;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minLeadingWidth: 52,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(child: Text((member.user.displayName.isEmpty ? member.user.username : member.user.displayName).characters.first.toUpperCase())),
                if (member.user.online)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ED164),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgSecondary, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(member.user.displayName.isEmpty ? '@${member.user.username}' : member.user.displayName),
            subtitle: Text(member.isAdmin ? '@${member.user.username} • Admin' : '@${member.user.username}'),
            trailing: canManage
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') onRemove(member.user.uid);
                      if (value == 'transfer') onTransfer(member.user.uid);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'transfer', child: Text('Make admin')),
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}

/// Owns its [TextEditingController] so it is disposed on unmount — i.e. after
/// the dialog route finishes its exit transition. Disposing the controller
/// synchronously after `showDialog` returns (while the route is still animating
/// out and the [TextField] still depends on inherited widgets) triggers the
/// `InheritedElement.debugDeactivated` `_dependents.isEmpty` assertion crash.
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({required this.title, required this.label, required this.initial});

  final String title;
  final String label;
  final String initial;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(controller: _controller, autofocus: true, decoration: InputDecoration(labelText: widget.label)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) return;
            Navigator.of(context).pop(value);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// See [_TextInputDialog] — controllers are owned by the dialog's State so they
/// outlive the route's exit transition and are torn down safely on unmount.
class _NegativeAnswersDialog extends StatefulWidget {
  const _NegativeAnswersDialog({required this.title});

  final String title;

  @override
  State<_NegativeAnswersDialog> createState() => _NegativeAnswersDialogState();
}

class _NegativeAnswersDialogState extends State<_NegativeAnswersDialog> {
  final List<TextEditingController> _controllers = List.generate(3, (_) => TextEditingController());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Answer these quick questions to confirm.'),
          const SizedBox(height: 16),
          TextField(controller: _controllers[0], decoration: const InputDecoration(labelText: 'Why are you doing this?')),
          const SizedBox(height: 16),
          TextField(controller: _controllers[1], decoration: const InputDecoration(labelText: 'Was this accidental?')),
          const SizedBox(height: 16),
          TextField(controller: _controllers[2], decoration: const InputDecoration(labelText: 'Anything we should know?')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final answers = _controllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();
            if (answers.length < 3) return;
            Navigator.of(context).pop(answers);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(text, style: Theme.of(context).textTheme.displayMedium));
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)));
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)));
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => Text(error, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accentPrimary));
}
