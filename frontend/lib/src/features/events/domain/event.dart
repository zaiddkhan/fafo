import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

enum EventType {
  @JsonValue('normal')
  normal,
  @JsonValue('spotlight')
  spotlight,
  @JsonValue('volunteering')
  volunteering,
}

enum UnjoinReason {
  @JsonValue('change_of_plans')
  changeOfPlans,
  @JsonValue('scheduling_conflict')
  schedulingConflict,
  @JsonValue('no_longer_interested')
  noLongerInterested,
  @JsonValue('other')
  other,
}

@freezed
abstract class EventResponse with _$EventResponse {
  const factory EventResponse({
    required String id,
    @JsonKey(name: 'creator_uid') required String creatorUid,
    required String title,
    String? description,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'event_type') required EventType eventType,
    @JsonKey(name: 'custom_emoji') String? customEmoji,
    required double lat,
    required double lng,
    @JsonKey(name: 'location_name') required String locationName,
    @JsonKey(name: 'date_time') required DateTime dateTime,
    int? capacity,
    @JsonKey(name: 'joinee_count') required int joineeCount,
    @JsonKey(name: 'registration_open') required bool registrationOpen,
    required bool cancelled,
    @JsonKey(name: 'banner_url') String? bannerUrl,
    @JsonKey(name: 'organizer_name') String? organizerName,
    @JsonKey(name: 'organizer_contact') String? organizerContact,
    @JsonKey(name: 'organizer_instagram') String? organizerInstagram,
    @JsonKey(name: 'is_joined') @Default(false) bool isJoined,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _EventResponse;

  factory EventResponse.fromJson(Map<String, dynamic> json) =>
      _$EventResponseFromJson(json);
}

@freezed
abstract class EventCreateRequest with _$EventCreateRequest {
  const factory EventCreateRequest({
    required String title,
    String? description,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'event_type') @Default(EventType.normal) EventType eventType,
    @JsonKey(name: 'custom_emoji') String? customEmoji,
    required double lat,
    required double lng,
    @JsonKey(name: 'location_name') required String locationName,
    @JsonKey(name: 'date_time') required DateTime dateTime,
    int? capacity,
    @JsonKey(name: 'organizer_name') String? organizerName,
    @JsonKey(name: 'organizer_contact') String? organizerContact,
    @JsonKey(name: 'organizer_instagram') String? organizerInstagram,
  }) = _EventCreateRequest;

  factory EventCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$EventCreateRequestFromJson(json);
}

@freezed
abstract class EventUpdateRequest with _$EventUpdateRequest {
  const factory EventUpdateRequest({
    String? title,
    String? description,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'event_type') EventType? eventType,
    @JsonKey(name: 'custom_emoji') String? customEmoji,
    double? lat,
    double? lng,
    @JsonKey(name: 'location_name') String? locationName,
    @JsonKey(name: 'date_time') DateTime? dateTime,
    int? capacity,
    @JsonKey(name: 'registration_open') bool? registrationOpen,
    @JsonKey(name: 'organizer_name') String? organizerName,
    @JsonKey(name: 'organizer_contact') String? organizerContact,
    @JsonKey(name: 'organizer_instagram') String? organizerInstagram,
  }) = _EventUpdateRequest;

  factory EventUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$EventUpdateRequestFromJson(json);
}

@freezed
abstract class EventCancelRequest with _$EventCancelRequest {
  const factory EventCancelRequest({
    required String reason,
  }) = _EventCancelRequest;

  factory EventCancelRequest.fromJson(Map<String, dynamic> json) =>
      _$EventCancelRequestFromJson(json);
}

@freezed
abstract class EventJoinResponse with _$EventJoinResponse {
  const factory EventJoinResponse({
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
  }) = _EventJoinResponse;

  factory EventJoinResponse.fromJson(Map<String, dynamic> json) =>
      _$EventJoinResponseFromJson(json);
}

@freezed
abstract class EventUnjoinRequest with _$EventUnjoinRequest {
  const factory EventUnjoinRequest({
    required UnjoinReason reason,
  }) = _EventUnjoinRequest;

  factory EventUnjoinRequest.fromJson(Map<String, dynamic> json) =>
      _$EventUnjoinRequestFromJson(json);
}

@freezed
abstract class EventBannerUploadResponse with _$EventBannerUploadResponse {
  const factory EventBannerUploadResponse({
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'banner_url') required String bannerUrl,
  }) = _EventBannerUploadResponse;

  factory EventBannerUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$EventBannerUploadResponseFromJson(json);
}

@freezed
abstract class JoineeResponse with _$JoineeResponse {
  const factory JoineeResponse({
    required String uid,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @Default(false) bool online,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
  }) = _JoineeResponse;

  factory JoineeResponse.fromJson(Map<String, dynamic> json) =>
      _$JoineeResponseFromJson(json);
}
