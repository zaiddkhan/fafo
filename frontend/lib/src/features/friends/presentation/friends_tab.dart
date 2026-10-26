import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/right_now/presentation/code_sheet.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Friends tab: who's free right now, everyone else, and incoming requests.
/// "Nudge" opens the composer with that friend picked. Adding friends goes
/// through the referral code (brief 3.8).
class FriendsTab extends ConsumerWidget {
  const FriendsTab({super.key, required this.onNudge});

  /// Opens the composer for [friend]; the shell handles what happens after.
  final ValueChanged<PublicUserResponse> onNudge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(liveFriendsProvider);
    final requests = ref.watch(incomingFriendRequestsProvider);
    final list = [...friends.value ?? const <FriendResponse>[]]
      // Free friends first, then by name.
      ..sort((a, b) {
        if (a.user.freeNow != b.user.freeNow) return a.user.freeNow ? -1 : 1;
        return a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase());
      });
    final pending = requests.value ?? const <FriendRequestResponse>[];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomingFriendRequestsProvider);
            await ref.read(liveFriendsProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              _Header(onCode: () => showCodeSheet(context)),
              const SizedBox(height: 26),
              FafoSectionHeader(
                eyebrow: list.isEmpty ? 'Your people' : '${list.where((f) => f.user.freeNow).length} free rn',
                title: 'Friends',
              ),
              const SizedBox(height: 14),
              if (pending.isNotEmpty) ...[
                const FafoEyebrow('Requests', fontSize: 10.5),
                const SizedBox(height: 4),
                for (final r in pending) _RequestRow(request: r),
                const SizedBox(height: 22),
              ],
              if (friends.isLoading && list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (friends.hasError && list.isEmpty)
                Text(friendlyErrorMessage(friends.error), style: AppTypography.ui(13.5, color: AppColors.signalRed))
              else if (list.isEmpty)
                _Empty(onCode: () => showCodeSheet(context))
              else
                for (final f in list) _FriendRow(friend: f, onNudge: () => onNudge(f.user)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCode});

  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 22, bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: FafoEyebrow('Friends')),
          InkWell(
            onTap: onCode,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text('Code', style: AppTypography.ui(14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.onNudge});

  final FriendResponse friend;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    final user = friend.user;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          FafoAvatar(name: user.displayName, size: FafoAvatarSize.md, photoUrl: user.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (user.freeNow)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.accentPrimary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Free rn',
                        style: AppTypography.ui(12.5, fontWeight: FontWeight.w700, color: AppColors.accentPrimary),
                      ),
                    ],
                  )
                else
                  Text(
                    '@${user.username}',
                    style: AppTypography.ui(12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FafoPill(label: 'Nudge', small: true, height: 38, onPressed: onNudge),
        ],
      ),
    );
  }
}

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
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.request.requester;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          FafoAvatar(name: user.displayName, size: FafoAvatarSize.md, photoUrl: user.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: AppTypography.ui(15, fontWeight: FontWeight.w600)),
                Text(
                  '@${user.username}',
                  style: AppTypography.ui(12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FafoPill(label: 'Add', small: true, height: 38, busy: _busy, onPressed: () => _answer(true)),
          const SizedBox(width: 8),
          FafoPill(
            label: 'No',
            small: true,
            primary: false,
            height: 38,
            onPressed: _busy ? null : () => _answer(false),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCode});

  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No friends here yet. Share your code: whoever signs up with it shows up here, and you show up for them.',
          style: AppTypography.ui(15, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 16),
        FafoPill(label: 'Share your code', small: true, height: 44, onPressed: onCode),
      ],
    );
  }
}
