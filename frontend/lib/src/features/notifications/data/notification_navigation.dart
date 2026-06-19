import 'package:go_router/go_router.dart';

import 'package:fafu/src/features/friends/presentation/friends_page.dart';
import 'package:fafu/src/features/groups/presentation/groups_page.dart';
import 'package:fafu/src/features/notifications/presentation/notifications_page.dart';

/// Routes a notification (push tap or inbox tap) to the most relevant screen
/// based on the backend `data` payload. Falls back to the in-app inbox when the
/// payload carries nothing actionable.
///
/// The backend attaches ids it knows about — `event_id` (event updates, map
/// FOMO, reminders), `group_id` (group lifecycle), `nudge_id` (friend/group
/// nudges) — plus `template_id`/`type`.
void routeFromNotificationData(GoRouter router, Map<String, dynamic> data) {
  final eventId = _str(data['event_id']);
  if (eventId != null) {
    router.push('/event/$eventId');
    return;
  }

  final groupId = _str(data['group_id']);
  if (groupId != null) {
    router.push(GroupsPage.routePath);
    return;
  }

  // Nudges surface inside the Friends tab's nudge feed; land the user there.
  if (_str(data['nudge_id']) != null) {
    router.push(FriendsPage.routePath);
    return;
  }

  router.push(NotificationsPage.routePath);
}

String? _str(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
