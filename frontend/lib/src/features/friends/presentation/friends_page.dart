import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  static const routeName = 'friends';
  static const routePath = '/friends';

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(friendsRepositoryProvider).updatePresence());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _refresh() {
    ref.invalidate(friendsListProvider);
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(outgoingFriendRequestsProvider);
    ref.invalidate(friendStatsProvider);
    if (_query.length >= 2) ref.invalidate(friendSearchProvider(_query));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<List<String>?> _negativeAnswers(String title) async {
    final controllers = List.generate(3, (_) => TextEditingController());
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Answer these quick questions to confirm.'),
            const SizedBox(height: 12),
            TextField(
              controller: controllers[0],
              decoration: const InputDecoration(labelText: 'What happened?'),
            ),
            TextField(
              controller: controllers[1],
              decoration: const InputDecoration(labelText: 'Was this accidental?'),
            ),
            TextField(
              controller: controllers[2],
              decoration: const InputDecoration(labelText: 'Anything we should know?'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final answers = controllers
                  .map((c) => c.text.trim())
                  .where((text) => text.isNotEmpty)
                  .toList();
              if (answers.length < 3) return;
              Navigator.of(context).pop(answers);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    for (final controller in controllers) {
      controller.dispose();
    }
    return result;
  }

  Future<void> _createInvite() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final invite = await ref.read(friendsRepositoryProvider).createInvite();
      await Clipboard.setData(ClipboardData(text: invite.inviteUrl));
      if (mounted) _showSnack('Invite link copied');
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(friendStatsProvider);
    final incoming = ref.watch(incomingFriendRequestsProvider);
    final outgoing = ref.watch(outgoingFriendRequestsProvider);
    final friends = ref.watch(friendsListProvider);
    final search = _query.length >= 2
        ? ref.watch(friendSearchProvider(_query))
        : const AsyncValue<List<PublicUserResponse>>.data([]);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Friends'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
          children: [
            Text(
              'Find your people',
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Search by name or username, accept requests, and invite friends who are not on WhatsPopn yet.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            stats.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => Row(
                children: [
                  Expanded(child: _StatCard(label: 'Friends', value: '${s.friendsCount}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Incoming', value: '${s.incomingRequestCount}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Sent', value: '${s.outgoingRequestCount}')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _busy ? 'Working…' : 'Copy invite link',
              variant: AppButtonVariant.featured,
              onPressed: _busy ? null : _createInvite,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or username',
              ),
            ),
            if (_query.length >= 2) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('Search results'),
              search.when(
                loading: () => const _LoadingBlock(),
                error: (e, _) => _ErrorBlock(error: e.toString()),
                data: (users) => users.isEmpty
                    ? const _EmptyBlock(text: 'No users found.')
                    : Column(
                        children: users
                            .map(
                              (user) => _UserTile(
                                user: user,
                                trailing: _SearchAction(
                                  status: user.friendshipStatus,
                                  busy: _busy,
                                  onAdd: () => _runAction(
                                    () => ref.read(friendsRepositoryProvider).sendFriendRequest(uid: user.uid),
                                  ),
                                ),
                                onBlock: () async {
                                  final answers = await _negativeAnswers('Block ${user.displayName}?');
                                  if (answers == null) return;
                                  await _runAction(
                                    () => ref.read(friendsRepositoryProvider).blockUser(user.uid, answers: answers),
                                  );
                                },
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle('Incoming requests'),
            incoming.when(
              loading: () => const _LoadingBlock(),
              error: (e, _) => _ErrorBlock(error: e.toString()),
              data: (requests) => requests.isEmpty
                  ? const _EmptyBlock(text: 'No pending requests.')
                  : Column(
                      children: requests
                          .map(
                            (request) => _UserTile(
                              user: request.requester,
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _runAction(
                                              () => ref.read(friendsRepositoryProvider).declineRequest(request.id),
                                            ),
                                    child: const Text('Decline'),
                                  ),
                                  FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _runAction(
                                              () => ref.read(friendsRepositoryProvider).acceptRequest(request.id),
                                            ),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle('Sent requests'),
            outgoing.when(
              loading: () => const _LoadingBlock(),
              error: (e, _) => _ErrorBlock(error: e.toString()),
              data: (requests) => requests.isEmpty
                  ? const _EmptyBlock(text: 'No sent requests.')
                  : Column(
                      children: requests
                          .map((request) => _UserTile(user: request.recipient, trailing: const Text('Pending')))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle('Your friends'),
            friends.when(
              loading: () => const _LoadingBlock(),
              error: (e, _) => _ErrorBlock(error: e.toString()),
              data: (items) => items.isEmpty
                  ? const _EmptyBlock(text: 'No friends yet. Search or invite someone.')
                  : Column(
                      children: items
                          .map(
                            (friend) => _UserTile(
                              user: friend.user,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'unfriend') {
                                    final answers = await _negativeAnswers('Unfriend ${friend.user.displayName}?');
                                    if (answers == null) return;
                                    await _runAction(
                                      () => ref.read(friendsRepositoryProvider).unfriend(friend.user.uid, answers: answers),
                                    );
                                  } else if (value == 'block') {
                                    final answers = await _negativeAnswers('Block ${friend.user.displayName}?');
                                    if (answers == null) return;
                                    await _runAction(
                                      () => ref.read(friendsRepositoryProvider).blockUser(friend.user.uid, answers: answers),
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
                                  PopupMenuItem(value: 'block', child: Text('Block')),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppChrome.cardRadius),
        border: AppChrome.outlineBorder,
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.displayMedium),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.trailing, this.onBlock});

  final PublicUserResponse user;
  final Widget trailing;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isEmpty ? '@${user.username}' : user.displayName;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
              child: user.photoUrl == null ? Text(displayName.characters.first.toUpperCase()) : null,
            ),
            if (user.online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ED164),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(displayName),
        subtitle: Text('@${user.username}'),
        trailing: trailing,
        onLongPress: onBlock,
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  const _SearchAction({required this.status, required this.busy, required this.onAdd});

  final FriendshipStatus status;
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      FriendshipStatus.friends => const Text('Friends'),
      FriendshipStatus.requestSent => const Text('Pending'),
      FriendshipStatus.requestReceived => const Text('Requested you'),
      FriendshipStatus.blocked => const Text('Blocked'),
      FriendshipStatus.blockedBy => const Text('Unavailable'),
      FriendshipStatus.none => FilledButton(
          onPressed: busy ? null : onAdd,
          child: const Text('Add'),
        ),
    };
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(error, style: const TextStyle(color: Color(0xFFE5484D))),
    );
  }
}
