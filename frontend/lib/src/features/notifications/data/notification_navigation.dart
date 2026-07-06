import 'package:go_router/go_router.dart';

import 'package:fafu/src/features/friends/presentation/friends_page.dart';
import 'package:fafu/src/features/groups/presentation/groups_page.dart';
import 'package:fafu/src/features/notifications/presentation/notifications_page.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_feed_sheet.dart';

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

  // A nudge that carries its feed coordinates (feed_type + target_id) deep-links
  // straight to that friend/group's nudge feed. Checked before group_id so a
  // *group* nudge opens its nudge feed rather than the group page. Older nudge
  // notifications lack these fields and fall through to the friends-page
  // fallback below.
  final nudgeFeedType = _str(data['feed_type']);
  final nudgeTargetId = _str(data['target_id']);
  if (_str(data['nudge_id']) != null &&
      nudgeFeedType != null &&
      nudgeTargetId != null) {
    final params = <String, String>{
      'feed_type': nudgeFeedType,
      'target_id': nudgeTargetId,
    };
    final title = _str(data['title']);
    if (title != null) params['title'] = title;
    router.push(Uri(path: NudgeFeedSheet.routePath, queryParameters: params).toString());
    return;
  }

  final groupId = _str(data['group_id']);
  if (groupId != null) {
    // Open the specific group (expanded + scrolled into view), not the whole
    // groups list. Backend attaches the group's document id as `group_id`.
    router.push('${GroupsPage.routePath}/$groupId');
    return;
  }

  // Nudges surface inside the Friends tab's nudge feed; land the user there.
  if (_str(data['nudge_id']) != null) {
    router.push(FriendsPage.routePath);
    return;
  }

  // No actionable target. This runs both for a system push tap (where opening
  // the inbox is the sensible landing spot) and for an inbox tap (where the user
  // is already on the notifications page). Only surface the inbox if we're not
  // already there — otherwise every tap stacks a duplicate notifications route,
  // trapping the user behind a pile of identical screens.
  final currentPath = router.routeInformationProvider.value.uri.path;
  if (currentPath != NotificationsPage.routePath) {
    router.push(NotificationsPage.routePath);
  }
}

String? _str(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
