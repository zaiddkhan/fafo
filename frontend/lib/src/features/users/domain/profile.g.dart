// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Area _$AreaFromJson(Map<String, dynamic> json) => _Area(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 15.0,
);

Map<String, dynamic> _$AreaToJson(_Area instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'radius_km': instance.radiusKm,
};

_ProfileSetupRequest _$ProfileSetupRequestFromJson(Map<String, dynamic> json) =>
    _ProfileSetupRequest(
      displayName: json['display_name'] as String,
      username: json['username'] as String,
      area: json['area'] == null
          ? null
          : Area.fromJson(json['area'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileSetupRequestToJson(
  _ProfileSetupRequest instance,
) => <String, dynamic>{
  'display_name': instance.displayName,
  'username': instance.username,
  'area': instance.area,
};

_ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    _ProfileResponse(
      uid: json['uid'] as String,
      phone: json['phone'] as String,
      displayName: json['display_name'] as String,
      username: json['username'] as String,
      photoUrl: json['photo_url'] as String?,
      area: json['area'] == null
          ? null
          : Area.fromJson(json['area'] as Map<String, dynamic>),
      onboardingComplete: json['onboarding_complete'] as bool,
      firstLaunchTooltipComplete:
          json['first_launch_tooltip_complete'] as bool? ?? false,
      isCreator: json['is_creator'] as bool? ?? false,
    );

Map<String, dynamic> _$ProfileResponseToJson(_ProfileResponse instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'phone': instance.phone,
      'display_name': instance.displayName,
      'username': instance.username,
      'photo_url': instance.photoUrl,
      'area': instance.area,
      'onboarding_complete': instance.onboardingComplete,
      'first_launch_tooltip_complete': instance.firstLaunchTooltipComplete,
      'is_creator': instance.isCreator,
    };

_UsernameCheckResponse _$UsernameCheckResponseFromJson(
  Map<String, dynamic> json,
) => _UsernameCheckResponse(
  username: json['username'] as String,
  available: json['available'] as bool,
);

Map<String, dynamic> _$UsernameCheckResponseToJson(
  _UsernameCheckResponse instance,
) => <String, dynamic>{
  'username': instance.username,
  'available': instance.available,
};

_PhotoUploadResponse _$PhotoUploadResponseFromJson(Map<String, dynamic> json) =>
    _PhotoUploadResponse(
      uploadPath: json['upload_path'] as String,
      photoUrl: json['photo_url'] as String,
    );

Map<String, dynamic> _$PhotoUploadResponseToJson(
  _PhotoUploadResponse instance,
) => <String, dynamic>{
  'upload_path': instance.uploadPath,
  'photo_url': instance.photoUrl,
};
