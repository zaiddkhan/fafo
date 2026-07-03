import 'package:fafu/src/features/events/domain/event.dart';

/// One cursor-paginated page of events from GET /events/search.
class EventPage {
  const EventPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<EventResponse> items;
  final String? nextCursor;
  final bool hasMore;

  factory EventPage.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List? ?? const [])
        .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
        .toList();
    return EventPage(
      items: rawItems,
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
