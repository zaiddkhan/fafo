import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/notifications/data/notification_navigation.dart';
import 'package:fafu/src/features/notifications/data/notifications_repository.dart';
import 'package:fafu/src/features/notifications/domain/notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static const routeName = 'notifications';
  static const routePath = '/notifications';

  void _refresh(WidgetRef ref) {
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    _refresh(ref);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.read) {
      // Optimistic: fire-and-forget the read, then refresh the badge.
      ref.read(notificationsRepositoryProvider).markRead(n.id).then((_) {
        ref.invalidate(unreadNotificationsProvider);
        ref.invalidate(notificationsListProvider);
      }).catchError((_) {});
    }
    routeFromNotificationData(GoRouter.of(context), n.data);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = ref.watch(notificationsListProvider);
    final hasUnread = (list.asData?.value.unreadCount ?? 0) > 0;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () => _markAllRead(ref),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: list.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary),
          ),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load notifications.\nPull down to retry.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (data) => data.items.isEmpty
              ? _EmptyInbox(theme: theme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _NotificationCard(
                    notification: data.items[i],
                    onTap: () => _open(context, ref, data.items[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.read;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? AppColors.accentLightest : Colors.white,
          border: Border.all(color: AppColors.ink, width: 1.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.ink, width: 1.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(notification.type),
                color: AppColors.accentPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink, width: 1.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.accentPrimary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "You're all caught up",
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            color: AppColors.ink,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nudges, friend requests, and event updates will show up here.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'social_pull':
      return Icons.waving_hand_outlined;
    case 'groups':
      return Icons.group_outlined;
    case 'map_fomo':
      return Icons.place_outlined;
    case 'time_pressure':
      return Icons.schedule_outlined;
    case 'event_updates':
      return Icons.event_outlined;
    case 'inactivity':
      return Icons.bolt_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
