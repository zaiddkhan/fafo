import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';

final questsRepositoryProvider = Provider<QuestsRepository>((ref) {
  return QuestsRepository(ref.watch(dioProvider));
});

class QuestsRepository {
  QuestsRepository(this._dio);

  final Dio _dio;

  Future<List<QuestResponse>> getQuests() async {
    try {
      final response = await _dio.get('/quests');
      return (response.data as List)
          .map((e) => QuestResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Marks a quest as activated. Feeds the activity streak + "Side Quests
  /// activated" profile stat. Idempotent on the backend.
  Future<void> activateQuest(String questId) async {
    try {
      await _dio.post('/quests/$questId/activate');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
