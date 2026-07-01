import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/friends/presentation/contacts_sync_page.dart';
import 'package:fafu/src/features/groups/presentation/groups_page.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_feed_sheet.dart';
import 'package:fafu/src/features/profile/presentation/public_profile_page.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({this.showBackButton = true, super.key});

  final bool showBackButton;

  static const routeName = 'friends';
  static const routePath = '/friends';

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

enum _FriendsTab { all, incoming, pending }

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _busy = false;
  _FriendsTab _tab = _FriendsTab.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(friendsRepositoryProvider).updatePresence(),
    );
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
    ref.invalidate(blockedUsersProvider);
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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openNudgeFeed(PublicUserResponse user) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => NudgeFeedSheet(
          feedType: NudgeFeedType.friend,
          targetId: user.uid,
          title: user.displayName.isEmpty
              ? '@${user.username}'
              : user.displayName,
          photoUrl: user.photoUrl,
          online: user.online,
        ),
      ),
    );
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
              decoration: const InputDecoration(
                labelText: 'Was this accidental?',
              ),
            ),
            TextField(
              controller: controllers[2],
              decoration: const InputDecoration(
                labelText: 'Anything we should know?',
              ),
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
      final message = Uri.encodeComponent(
        'Join me on FaFo: ${invite.inviteUrl}',
      );
      final whatsappUri = Uri.parse('whatsapp://send?text=$message');
      final canOpen = await canLaunchUrl(whatsappUri);
      if (canOpen) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        _showSnack(
          'Invite link copied${canOpen ? ' and WhatsApp opened' : ''}',
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingFriendRequestsProvider);
    final outgoing = ref.watch(outgoingFriendRequestsProvider);
    final friends = ref.watch(friendsListProvider);
    final blocked = ref.watch(blockedUsersProvider);
    final search = _query.length >= 2
        ? ref.watch(friendSearchProvider(_query))
        : const AsyncValue<List<PublicUserResponse>>.data([]);

    // Counts drive the segmented-tab badges; read straight from the lists we
    // already watch so they stay in sync with what each tab shows.
    final friendsCount = friends.asData?.value.length ?? 0;
    final incomingCount = incoming.asData?.value.length ?? 0;
    final outgoingCount = outgoing.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: widget.showBackButton
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Friends',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.accentPrimary,
                        fontSize: 28,
                        height: 1,
                      ),
                    ),
                  ),
                  _SmallActionButton(
                    label: 'Groups',
                    onTap: () => context.push(GroupsPage.routePath),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SearchBox(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 18),
              _SegmentedTabs(
                current: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
                segments: [
                  _TabSpec(_FriendsTab.all, 'Friends', friendsCount),
                  _TabSpec(_FriendsTab.incoming, 'Requests', incomingCount),
                  _TabSpec(_FriendsTab.pending, 'Sent', outgoingCount),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StickerAction(
                      icon: Icons.contacts_outlined,
                      label: 'Sync Contacts',
                      onTap: _busy
                          ? null
                          : () => context.push(ContactsSyncPage.routePath),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StickerAction(
                      icon: Icons.ios_share,
                      label: 'Invite Link',
                      onTap: _busy ? null : _createInvite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_query.length >= 2) ...[
                _ListHeader('Search Results'),
                search.when(
                  loading: () => const _LoadingBlock(),
                  error: (e, _) => _ErrorBlock(error: e.toString()),
                  data: (users) => users.isEmpty
                      ? const _EmptyBlock(text: 'No users found.')
                      : Column(
                          children: users
                              .map(
                                (user) => _SearchResultRow(
                                  user: user,
                                  busy: _busy,
                                  onAdd: () => _runAction(
                                    () => ref
                                        .read(friendsRepositoryProvider)
                                        .sendFriendRequest(uid: user.uid),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 18),
              ],
              if (_tab == _FriendsTab.all)
                friends.when(
                  loading: () => const _LoadingBlock(),
                  error: (e, _) => _ErrorBlock(error: e.toString()),
                  data: (items) => items.isEmpty
                      ? const _AllFriendsEmpty()
                      : Column(
                          children: items
                              .map(
                                (friend) => _FriendListCard(
                                  user: friend.user,
                                  statusText: _statusForFriend(friend.user),
                                  onTap: () => _openNudgeFeed(friend.user),
                                  onProfile: () => context.push(
                                    PublicProfilePage.routePath,
                                    extra: friend.user,
                                  ),
                                  onUnfriend: () async {
                                    final answers = await _negativeAnswers(
                                      'Unfriend ${friend.user.displayName}?',
                                    );
                                    if (answers == null) return;
                                    await _runAction(
                                      () => ref
                                          .read(friendsRepositoryProvider)
                                          .unfriend(
                                            friend.user.uid,
                                            answers: answers,
                                          ),
                                    );
                                  },
                                  onBlock: () async {
                                    final answers = await _negativeAnswers(
                                      'Block ${friend.user.displayName}?',
                                    );
                                    if (answers == null) return;
                                    await _runAction(
                                      () => ref
                                          .read(friendsRepositoryProvider)
                                          .blockUser(
                                            friend.user.uid,
                                            answers: answers,
                                          ),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                ),
              if (_tab == _FriendsTab.incoming)
                incoming.when(
                  loading: () => const _LoadingBlock(),
                  error: (e, _) => _ErrorBlock(error: e.toString()),
                  data: (requests) => requests.isEmpty
                      ? const _EmptyBlock(text: 'No new friend requests.')
                      : Column(
                          children: requests
                              .map(
                                (request) => _RequestCard(
                                  user: request.requester,
                                  primaryLabel: 'Accept',
                                  secondaryLabel: 'Decline',
                                  onPrimary: () => _runAction(
                                    () => ref
                                        .read(friendsRepositoryProvider)
                                        .acceptRequest(request.id),
                                  ),
                                  onSecondary: () => _runAction(
                                    () => ref
                                        .read(friendsRepositoryProvider)
                                        .declineRequest(request.id),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              if (_tab == _FriendsTab.pending)
                outgoing.when(
                  loading: () => const _LoadingBlock(),
                  error: (e, _) => _ErrorBlock(error: e.toString()),
                  data: (requests) => requests.isEmpty
                      ? const _EmptyBlock(text: 'No pending sent requests.')
                      : Column(
                          children: requests
                              .map(
                                (request) => _RequestCard(
                                  user: request.recipient,
                                  primaryLabel: 'Pending',
                                  onPrimary: null,
                                ),
                              )
                              .toList(),
                        ),
                ),
              const SizedBox(height: 24),
              blocked.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ListHeader('Blocked Users'),
                          ...items.map(
                            (blockedUser) => _RequestCard(
                              user: blockedUser.user,
                              primaryLabel: 'Unblock',
                              onPrimary: _busy
                                  ? null
                                  : () async {
                                      final answers = await _negativeAnswers(
                                        'Unblock ${blockedUser.user.displayName}?',
                                      );
                                      if (answers == null) return;
                                      await _runAction(
                                        () => ref
                                            .read(friendsRepositoryProvider)
                                            .unblockUser(
                                              blockedUser.user.uid,
                                              answers: answers,
                                            ),
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusForFriend(PublicUserResponse user) {
    if (user.online) return 'New Nudge Received';
    return 'Last Nudge Accepted';
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.7),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 24,
          ),
          hintText: 'Search Friends...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Label + live count for one segment of [_SegmentedTabs].
class _TabSpec {
  const _TabSpec(this.tab, this.label, this.count);
  final _FriendsTab tab;
  final String label;
  final int count;
}

/// A single connected segmented control: equal-width segments inside one
/// ink-outlined, offset-shadowed "sticker" bar. The selected segment fills with
/// the accent; each segment carries a count badge when its count is non-zero.
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.current,
    required this.onChanged,
    required this.segments,
  });

  final _FriendsTab current;
  final ValueChanged<_FriendsTab> onChanged;
  final List<_TabSpec> segments;

  @override
  Widget build(BuildContext context) {
    const offset = 3.0;
    return Padding(
      padding: const EdgeInsets.only(right: offset, bottom: offset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(offset, offset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.3),
              child: Row(
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0) Container(width: 1.7, color: AppColors.border),
                    Expanded(
                      child: _Segment(
                        spec: segments[i],
                        selected: current == segments[i].tab,
                        onTap: () => onChanged(segments[i].tab),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.spec,
    required this.selected,
    required this.onTap,
  });
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: selected ? AppColors.accentPrimary : AppColors.surface,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (spec.count > 0) ...[
              const SizedBox(width: 6),
              _CountBadge(count: spec.count, selected: selected),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : AppColors.accentPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? AppColors.accentPrimary : AppColors.surface,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Pressable "sticker" action (icon + label) matching the app's ink-outline,
/// offset-shadow chrome. Used for Sync Contacts / Invite Link.
class _StickerAction extends StatelessWidget {
  const _StickerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const offset = 3.0;
    final enabled = onTap != null;
    final contentColor = enabled
        ? AppColors.textPrimary
        : AppColors.textTertiary;
    return Padding(
      padding: const EdgeInsets.only(right: offset, bottom: offset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(offset, offset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 1.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: enabled ? AppColors.accentPrimary : contentColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guiding empty state for the Friends tab — points to the two ways to grow a
/// circle, which sit right above this block.
class _AllFriendsEmpty extends StatelessWidget {
  const _AllFriendsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : AppColors.accentLightest,
        border: Border.all(color: AppColors.border, width: 1.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.group_add_outlined,
              color: AppColors.accentPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No friends yet',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sync your contacts or share an invite link to start nudging friends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FriendListCard extends StatelessWidget {
  const _FriendListCard({
    required this.user,
    required this.statusText,
    required this.onTap,
    required this.onProfile,
    required this.onUnfriend,
    required this.onBlock,
  });
  final PublicUserResponse user;
  final String statusText;
  final VoidCallback onTap;
  final VoidCallback onProfile;
  final VoidCallback onUnfriend;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isEmpty
        ? '@${user.username}'
        : user.displayName;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _Avatar(user: user, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.accentPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '• $statusText',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: AppColors.textPrimary,
                size: 28,
              ),
              onSelected: (value) {
                if (value == 'message') onTap();
                if (value == 'profile') onProfile();
                if (value == 'unfriend') onUnfriend();
                if (value == 'block') onBlock();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'message', child: Text('Message')),
                PopupMenuItem(value: 'profile', child: Text('View Profile')),
                PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
                PopupMenuItem(value: 'block', child: Text('Block')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.user,
    required this.primaryLabel,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });
  final PublicUserResponse user;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isEmpty
        ? '@${user.username}'
        : user.displayName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Avatar(user: user, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.accentPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                if (user.displayName.isNotEmpty)
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (secondaryLabel != null)
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.user,
    required this.busy,
    required this.onAdd,
  });
  final PublicUserResponse user;
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _RequestCard(
      user: user,
      primaryLabel: switch (user.friendshipStatus) {
        FriendshipStatus.friends => 'Friends',
        FriendshipStatus.requestSent => 'Pending',
        FriendshipStatus.requestReceived => 'Requested',
        FriendshipStatus.blocked || FriendshipStatus.blockedBy => 'Unavailable',
        FriendshipStatus.none => 'Add',
      },
      onPrimary: user.friendshipStatus == FriendshipStatus.none && !busy
          ? onAdd
          : null,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});
  final PublicUserResponse user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isEmpty
        ? user.username
        : user.displayName;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(8),
            image: user.photoUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(user.photoUrl!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: user.photoUrl == null
              ? Center(
                  child: Text(
                    displayName.isEmpty
                        ? '🙂'
                        : displayName.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        ),
        if (user.online)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF59E85D),
                border: Border.all(color: AppColors.border, width: 1.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 20,
      ),
    ),
  );
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Center(
      child: CircularProgressIndicator(color: AppColors.accentPrimary),
    ),
  );
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
    ),
  );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(error, style: const TextStyle(color: Color(0xFFE5484D))),
  );
}
