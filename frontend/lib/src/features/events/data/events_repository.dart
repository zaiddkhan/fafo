import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/events/domain/event.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(dioProvider));
});

/// Bumped whenever the user creates / edits / cancels an event. The Explore
/// (events list) and Creator Dashboard tabs live inside a persistent
/// IndexedStack, so they watch this to re-fetch instead of relying on
/// initState (which only runs once). Call [bumpEventsRevision] after a mutation.
class EventsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final eventsRevisionProvider = NotifierProvider<EventsRevision, int>(EventsRevision.new);

void bumpEventsRevision(WidgetRef ref) {
  ref.read(eventsRevisionProvider.notifier).bump();
}

class EventsRepository {
  EventsRepository(this._dio);

  final Dio _dio;

  /// Live stream of all non-cancelled events straight from Firestore, so the
  /// map updates in real time as creators post or edit events. Radius,
  /// category, visibility-window and event-type filtering are applied by the
  /// caller (the map screen) on top of this stream.
  Stream<List<EventResponse>> streamEvents({int limit = 300}) {
    return FirebaseFirestore.instance
        .collection('events')
        .where('cancelled', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _eventFromFirestore(doc.id, doc.data()))
              .whereType<EventResponse>()
              .toList(),
        );
  }

  static EventResponse? _eventFromFirestore(String id, Map<String, dynamic> data) {
    final location = data['location'];
    if (location is! GeoPoint) return null;
    final dateTime = _toDate(data['date_time']);
    if (dateTime == null) return null;
    return EventResponse(
      id: id,
      creatorUid: data['creator_uid'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      categoryId: data['category_id'] as String? ?? '',
      eventType: _eventTypeFromString(data['event_type'] as String?),
      customEmoji: data['custom_emoji'] as String?,
      lat: location.latitude,
      lng: location.longitude,
      locationName: data['location_name'] as String? ?? '',
      dateTime: dateTime,
      capacity: (data['capacity'] as num?)?.toInt(),
      joineeCount: (data['joinee_count'] as num?)?.toInt() ?? 0,
      registrationOpen: data['registration_open'] as bool? ?? true,
      cancelled: data['cancelled'] as bool? ?? false,
      bannerUrl: data['banner_url'] as String?,
      organizerName: data['organizer_name'] as String?,
      organizerContact: data['organizer_contact'] as String?,
      organizerInstagram: data['organizer_instagram'] as String?,
      isJoined: false,
      createdAt: _toDate(data['created_at']) ?? dateTime,
      updatedAt: _toDate(data['updated_at']) ?? dateTime,
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static EventType _eventTypeFromString(String? value) {
    return switch (value) {
      'volunteering' => EventType.volunteering,
      'spotlight' => EventType.spotlight,
      _ => EventType.normal,
    };
  }

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
    XFile banner,
  ) async {
    try {
      final path = banner.name.toLowerCase();
      final DioMediaType mediaType;
      if (path.endsWith('.png')) {
        mediaType = DioMediaType('image', 'png');
      } else if (path.endsWith('.webp')) {
        mediaType = DioMediaType('image', 'webp');
      } else {
        mediaType = DioMediaType('image', 'jpeg');
      }

      // Read bytes so this works on Flutter web too (MultipartFile.fromFile
      // needs dart:io, which isn't available on web).
      final bytes = await banner.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: banner.name.isNotEmpty ? banner.name : 'banner.jpg',
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

  Future<void> cancelEvent(String eventId, {required String reason, List<String> answers = const []}) async {
    try {
      await _dio.post(
        '/events/$eventId/cancel',
        data: {'reason': reason, 'answers': answers},
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

  Future<void> unjoinEvent(String eventId, {required UnjoinReason reason, List<String> answers = const []}) async {
    try {
      await _dio.delete(
        '/events/$eventId/join',
        data: {'reason': _unjoinReasonValue(reason), 'answers': answers},
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

String _unjoinReasonValue(UnjoinReason reason) {
  return switch (reason) {
    UnjoinReason.changeOfPlans => 'change_of_plans',
    UnjoinReason.schedulingConflict => 'scheduling_conflict',
    UnjoinReason.noLongerInterested => 'no_longer_interested',
    UnjoinReason.other => 'other',
  };
}
