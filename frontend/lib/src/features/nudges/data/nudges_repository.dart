import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';

final nudgesRepositoryProvider = Provider<NudgesRepository>((ref) => NudgesRepository(ref.watch(dioProvider)));

class NudgesRepository {
  NudgesRepository(this._dio);
  final Dio _dio;

  Future<List<NudgeResponse>> listFeed(NudgeFeedType feedType, String targetId) async {
    try {
      final response = await _dio.get('/nudges', queryParameters: {'feed_type': nudgeFeedTypeToJson(feedType), 'target_id': targetId});
      return (response.data as List).map((e) => NudgeResponse.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NudgeResponse> create({required NudgeFeedType feedType, required String targetId, required String title, String? location, required int windowMinutes}) async {
    try {
      final response = await _dio.post('/nudges', data: {
        'feed_type': nudgeFeedTypeToJson(feedType),
        'target_id': targetId,
        'title': title,
        'location': location,
        'response_window_minutes': windowMinutes,
      });
      return NudgeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> respond(String nudgeId, NudgeVote vote) async {
    try {
      await _dio.post('/nudges/$nudgeId/respond', data: {'vote': nudgeVoteToJson(vote)});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> remind(String nudgeId) async {
    try {
      await _dio.post('/nudges/$nudgeId/remind');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
