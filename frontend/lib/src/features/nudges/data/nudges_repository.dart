import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
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

  /// Everything the user sent or received, newest first (home + Recent).
  Future<List<NudgeResponse>> listMine({int limit = 30}) async {
    try {
      final response = await _dio.get('/nudges/mine', queryParameters: {'limit': limit});
      // Correct timers for a skewed or changed device clock.
      final date = response.headers.value('date');
      if (date != null) {
        try {
          ServerClock.offset = HttpDate.parse(date).difference(DateTime.now().toUtc());
        } catch (_) {}
      }
      return (response.data as List).map((e) => NudgeResponse.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NudgeResponse> get(String nudgeId) async {
    try {
      final response = await _dio.get('/nudges/$nudgeId');
      return NudgeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// [windowMinutes] is the sender's countdown after yes; the answer window is
  /// a fixed 10 minutes server-side. [questId] shares a side quest.
  Future<NudgeResponse> create({required NudgeFeedType feedType, required String targetId, required String title, String? location, required int windowMinutes, String? questId}) async {
    try {
      final response = await _dio.post('/nudges', data: {
        'feed_type': nudgeFeedTypeToJson(feedType),
        'target_id': targetId,
        'title': title,
        'location': location,
        'response_window_minutes': windowMinutes,
        'quest_id': ?questId,
      });
      return NudgeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NudgeResponse> respond(String nudgeId, NudgeVote vote) async {
    try {
      final response = await _dio.post('/nudges/$nudgeId/respond', data: {'vote': nudgeVoteToJson(vote)});
      return NudgeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Sender only, while waiting or counting down.
  Future<NudgeResponse> cancel(String nudgeId) async {
    try {
      final response = await _dio.post('/nudges/$nudgeId/cancel');
      return NudgeResponse.fromJson(response.data as Map<String, dynamic>);
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
