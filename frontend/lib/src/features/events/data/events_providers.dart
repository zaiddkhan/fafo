import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';

final eventDetailProvider =
    FutureProvider.family<EventResponse, String>((ref, eventId) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getEvent(eventId);
});
