import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/quests/data/quests_repository.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';

final questsListProvider = FutureProvider.autoDispose<List<QuestResponse>>((ref) {
  return ref.watch(questsRepositoryProvider).getQuests();
});

/// The current user's started/completed quests (their Quest History). Not
/// auto-disposed so the started state stays warm across the quests + profile
/// screens.
final questActivationsProvider = FutureProvider<List<QuestActivation>>((ref) {
  return ref.watch(questsRepositoryProvider).getMyActivations();
});

/// Maximum number of quests a user can have active at once (mirrors the backend
/// `MAX_ACTIVE_QUESTS`).
const int kMaxActiveQuests = 3;
