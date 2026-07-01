import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/services/shared_preferences_provider.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';

/// SharedPreferences key holding the list of event ids the user has saved
/// (bookmarked) from the event detail screen.
const savedEventIdsPreferenceKey = 'saved_event_ids';

/// Locally-persisted set of saved (bookmarked) event ids.
///
/// The backend has no "saved events" concept yet, so saves are persisted on
/// device via SharedPreferences. The event detail screen toggles membership
/// here and the profile screen reads it to render the "Saved events" section.
final savedEventIdsProvider =
    NotifierProvider<SavedEventsController, Set<String>>(
      SavedEventsController.new,
    );

class SavedEventsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final saved = ref
        .watch(sharedPreferencesProvider)
        .maybeWhen(
          data: (prefs) => prefs.getStringList(savedEventIdsPreferenceKey),
          orElse: () => null,
        );
    return {...?saved};
  }

  bool isSaved(String eventId) => state.contains(eventId);

  /// Flips the saved state for [eventId] and persists the result. Returns the
  /// new saved state so callers can surface feedback.
  Future<bool> toggle(String eventId) async {
    final next = {...state};
    final nowSaved = next.add(eventId);
    if (!nowSaved) next.remove(eventId);
    state = next;

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setStringList(savedEventIdsPreferenceKey, next.toList());
    return nowSaved;
  }
}

/// Resolves the saved event ids into full events for display on the profile.
/// Ids that can no longer be fetched (deleted / cancelled) are dropped.
final savedEventsProvider = FutureProvider.autoDispose<List<EventResponse>>((
  ref,
) async {
  final ids = ref.watch(savedEventIdsProvider);
  if (ids.isEmpty) return const [];

  final repo = ref.watch(eventsRepositoryProvider);
  final results = await Future.wait(
    ids.map((id) async {
      try {
        return await repo.getEvent(id);
      } catch (_) {
        return null;
      }
    }),
  );
  return results.whereType<EventResponse>().toList();
});
