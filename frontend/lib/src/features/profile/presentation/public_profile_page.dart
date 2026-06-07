import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_feed_sheet.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({required this.user, super.key});

  static const routeName = 'public-profile';
  static const routePath = '/profile/public';

  final PublicUserResponse user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = user.displayName.isEmpty ? '@${user.username}' : user.displayName;
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      backgroundColor: AppColors.bgPrimary,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
                  child: user.photoUrl == null ? Text(displayName.characters.first.toUpperCase()) : null,
                ),
                if (user.online)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: const Color(0xFF4ED164), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: Text(displayName, style: Theme.of(context).textTheme.displayLarge)),
          const SizedBox(height: AppSpacing.xs),
          Center(child: Text('@${user.username}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary))),
          const SizedBox(height: AppSpacing.xl),
          switch (user.friendshipStatus) {
            FriendshipStatus.friends => FilledButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.85,
                    child: NudgeFeedSheet(
                      feedType: NudgeFeedType.friend,
                      targetId: user.uid,
                      title: displayName,
                      photoUrl: user.photoUrl,
                      online: user.online,
                    ),
                  ),
                ),
                child: const Text('Message'),
              ),
            FriendshipStatus.requestSent => const Center(child: Text('Friend request pending')),
            FriendshipStatus.requestReceived => const Center(child: Text('Requested you')),
            FriendshipStatus.blocked || FriendshipStatus.blockedBy => const Center(child: Text('Unavailable')),
            FriendshipStatus.none => FilledButton(
                onPressed: () async {
                  await ref.read(friendsRepositoryProvider).sendFriendRequest(uid: user.uid);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent')));
                },
                child: const Text('Friend Request'),
              ),
          },
        ],
      ),
    );
  }
}
