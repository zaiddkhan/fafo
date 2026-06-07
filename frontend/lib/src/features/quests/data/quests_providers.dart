import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/quests/data/quests_repository.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';

final questsListProvider = FutureProvider.autoDispose<List<QuestResponse>>((ref) {
  return ref.watch(questsRepositoryProvider).getQuests();
});
