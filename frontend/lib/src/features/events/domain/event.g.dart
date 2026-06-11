// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventResponse _$EventResponseFromJson(Map<String, dynamic> json) =>
    _EventResponse(
      id: json['id'] as String,
      creatorUid: json['creator_uid'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String,
      eventType: $enumDecode(_$EventTypeEnumMap, json['event_type']),
      customEmoji: json['custom_emoji'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      locationName: json['location_name'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      capacity: (json['capacity'] as num?)?.toInt(),
      joineeCount: (json['joinee_count'] as num).toInt(),
      registrationOpen: json['registration_open'] as bool,
      cancelled: json['cancelled'] as bool,
      bannerUrl: json['banner_url'] as String?,
      organizerName: json['organizer_name'] as String?,
      organizerContact: json['organizer_contact'] as String?,
      organizerInstagram: json['organizer_instagram'] as String?,
      isJoined: json['is_joined'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EventResponseToJson(_EventResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'creator_uid': instance.creatorUid,
      'title': instance.title,
      'description': instance.description,
      'category_id': instance.categoryId,
      'event_type': _$EventTypeEnumMap[instance.eventType]!,
      'custom_emoji': instance.customEmoji,
      'lat': instance.lat,
      'lng': instance.lng,
      'location_name': instance.locationName,
      'date_time': instance.dateTime.toIso8601String(),
      'capacity': instance.capacity,
      'joinee_count': instance.joineeCount,
      'registration_open': instance.registrationOpen,
      'cancelled': instance.cancelled,
      'banner_url': instance.bannerUrl,
      'organizer_name': instance.organizerName,
      'organizer_contact': instance.organizerContact,
      'organizer_instagram': instance.organizerInstagram,
      'is_joined': instance.isJoined,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$EventTypeEnumMap = {
  EventType.normal: 'normal',
  EventType.spotlight: 'spotlight',
  EventType.volunteering: 'volunteering',
};

_EventCreateRequest _$EventCreateRequestFromJson(Map<String, dynamic> json) =>
    _EventCreateRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String,
      eventType:
          $enumDecodeNullable(_$EventTypeEnumMap, json['event_type']) ??
          EventType.normal,
      customEmoji: json['custom_emoji'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      locationName: json['location_name'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      capacity: (json['capacity'] as num?)?.toInt(),
      organizerName: json['organizer_name'] as String?,
      organizerContact: json['organizer_contact'] as String?,
      organizerInstagram: json['organizer_instagram'] as String?,
    );

Map<String, dynamic> _$EventCreateRequestToJson(_EventCreateRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category_id': instance.categoryId,
      'event_type': _$EventTypeEnumMap[instance.eventType]!,
      'custom_emoji': instance.customEmoji,
      'lat': instance.lat,
      'lng': instance.lng,
      'location_name': instance.locationName,
      'date_time': instance.dateTime.toIso8601String(),
      'capacity': instance.capacity,
      'organizer_name': instance.organizerName,
      'organizer_contact': instance.organizerContact,
      'organizer_instagram': instance.organizerInstagram,
    };

_EventUpdateRequest _$EventUpdateRequestFromJson(Map<String, dynamic> json) =>
    _EventUpdateRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      eventType: $enumDecodeNullable(_$EventTypeEnumMap, json['event_type']),
      customEmoji: json['custom_emoji'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      dateTime: json['date_time'] == null
          ? null
          : DateTime.parse(json['date_time'] as String),
      capacity: (json['capacity'] as num?)?.toInt(),
      registrationOpen: json['registration_open'] as bool?,
      organizerName: json['organizer_name'] as String?,
      organizerContact: json['organizer_contact'] as String?,
      organizerInstagram: json['organizer_instagram'] as String?,
    );

Map<String, dynamic> _$EventUpdateRequestToJson(_EventUpdateRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category_id': instance.categoryId,
      'event_type': _$EventTypeEnumMap[instance.eventType],
      'custom_emoji': instance.customEmoji,
      'lat': instance.lat,
      'lng': instance.lng,
      'location_name': instance.locationName,
      'date_time': instance.dateTime?.toIso8601String(),
      'capacity': instance.capacity,
      'registration_open': instance.registrationOpen,
      'organizer_name': instance.organizerName,
      'organizer_contact': instance.organizerContact,
      'organizer_instagram': instance.organizerInstagram,
    };

_EventCancelRequest _$EventCancelRequestFromJson(Map<String, dynamic> json) =>
    _EventCancelRequest(reason: json['reason'] as String);

Map<String, dynamic> _$EventCancelRequestToJson(_EventCancelRequest instance) =>
    <String, dynamic>{'reason': instance.reason};

_EventJoinResponse _$EventJoinResponseFromJson(Map<String, dynamic> json) =>
    _EventJoinResponse(
      eventId: json['event_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$EventJoinResponseToJson(_EventJoinResponse instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'joined_at': instance.joinedAt.toIso8601String(),
    };

_EventUnjoinRequest _$EventUnjoinRequestFromJson(Map<String, dynamic> json) =>
    _EventUnjoinRequest(
      reason: $enumDecode(_$UnjoinReasonEnumMap, json['reason']),
    );

Map<String, dynamic> _$EventUnjoinRequestToJson(_EventUnjoinRequest instance) =>
    <String, dynamic>{'reason': _$UnjoinReasonEnumMap[instance.reason]!};

const _$UnjoinReasonEnumMap = {
  UnjoinReason.changeOfPlans: 'change_of_plans',
  UnjoinReason.schedulingConflict: 'scheduling_conflict',
  UnjoinReason.noLongerInterested: 'no_longer_interested',
  UnjoinReason.other: 'other',
};

_EventBannerUploadResponse _$EventBannerUploadResponseFromJson(
  Map<String, dynamic> json,
) => _EventBannerUploadResponse(
  eventId: json['event_id'] as String,
  bannerUrl: json['banner_url'] as String,
);

Map<String, dynamic> _$EventBannerUploadResponseToJson(
  _EventBannerUploadResponse instance,
) => <String, dynamic>{
  'event_id': instance.eventId,
  'banner_url': instance.bannerUrl,
};

_JoineeResponse _$JoineeResponseFromJson(Map<String, dynamic> json) =>
    _JoineeResponse(
      uid: json['uid'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
      online: json['online'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$JoineeResponseToJson(_JoineeResponse instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'username': instance.username,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'online': instance.online,
      'joined_at': instance.joinedAt.toIso8601String(),
    };
