import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';

class NearbyEventsParams {
  const NearbyEventsParams({
    required this.lat,
    required this.lng,
    this.radiusKm = 15.0,
    this.categoryId,
    this.eventType,
    this.limit = 50,
    this.cursor,
  });

  final double lat;
  final double lng;
  final double radiusKm;
  final String? categoryId;
  final EventType? eventType;
  final int limit;
  final String? cursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyEventsParams &&
          lat == other.lat &&
          lng == other.lng &&
          radiusKm == other.radiusKm &&
          categoryId == other.categoryId &&
          eventType == other.eventType &&
          limit == other.limit &&
          cursor == other.cursor;

  @override
  int get hashCode => Object.hash(
        lat,
        lng,
        radiusKm,
        categoryId,
        eventType,
        limit,
        cursor,
      );
}

final nearbyEventsProvider =
    FutureProvider.family<List<EventResponse>, NearbyEventsParams>(
  (ref, params) {
    final repo = ref.watch(eventsRepositoryProvider);
    return repo.getEvents(
      lat: params.lat,
      lng: params.lng,
      radiusKm: params.radiusKm,
      categoryId: params.categoryId,
      eventType: params.eventType,
      limit: params.limit,
      cursor: params.cursor,
    );
  },
);

final eventDetailProvider =
    FutureProvider.family<EventResponse, String>((ref, eventId) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getEvent(eventId);
});
