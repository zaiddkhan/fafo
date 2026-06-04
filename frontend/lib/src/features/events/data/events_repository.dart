import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/events/domain/event.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(dioProvider));
});

class EventsRepository {
  EventsRepository(this._dio);

  final Dio _dio;

  Future<List<EventResponse>> getEvents({
    required double lat,
    required double lng,
    double radiusKm = 15.0,
    String? categoryId,
    EventType? eventType,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'radius_km': radiusKm,
        'limit': limit,
      };
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (eventType != null) queryParams['event_type'] = eventType.name;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _dio.get('/events', queryParameters: queryParams);
      final data = response.data as List;
      return data
          .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<EventResponse>> getMyEvents({bool includeArchived = false}) async {
    try {
      final response = await _dio.get(
        '/events/mine',
        queryParameters: {'include_archived': includeArchived},
      );
      final data = response.data as List;
      return data
          .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<EventResponse>> getJoinedEvents({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/events/joined',
        queryParameters: {'limit': limit},
      );
      final data = response.data as List;
      return data
          .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<EventResponse> getEvent(String eventId) async {
    try {
      final response = await _dio.get('/events/$eventId');
      return EventResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<EventResponse> createEvent(EventCreateRequest request) async {
    try {
      final response = await _dio.post('/events', data: request.toJson());
      return EventResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<EventBannerUploadResponse> uploadBanner(
    String eventId,
    File banner,
  ) async {
    try {
      final path = banner.path.toLowerCase();
      final DioMediaType mediaType;
      if (path.endsWith('.png')) {
        mediaType = DioMediaType('image', 'png');
      } else if (path.endsWith('.webp')) {
        mediaType = DioMediaType('image', 'webp');
      } else {
        mediaType = DioMediaType('image', 'jpeg');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          banner.path,
          filename: banner.path.split('/').last,
          contentType: mediaType,
        ),
      });

      final response = await _dio.post(
        '/events/$eventId/banner',
        data: formData,
      );
      return EventBannerUploadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<EventResponse> updateEvent(
    String eventId,
    EventUpdateRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/events/$eventId',
        data: request.toJson(),
      );
      return EventResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelEvent(String eventId, {required String reason}) async {
    try {
      await _dio.post(
        '/events/$eventId/cancel',
        data: EventCancelRequest(reason: reason).toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<EventJoinResponse> joinEvent(String eventId) async {
    try {
      final response = await _dio.post('/events/$eventId/join');
      return EventJoinResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unjoinEvent(String eventId, {required UnjoinReason reason}) async {
    try {
      await _dio.delete(
        '/events/$eventId/join',
        data: EventUnjoinRequest(reason: reason).toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<JoineeResponse>> getJoinees(
    String eventId, {
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _dio.get(
        '/events/$eventId/joinees',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data
          .map((e) => JoineeResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
