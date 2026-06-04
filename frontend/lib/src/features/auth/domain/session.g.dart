// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionRequest _$SessionRequestFromJson(Map<String, dynamic> json) =>
    _SessionRequest(idToken: json['id_token'] as String);

Map<String, dynamic> _$SessionRequestToJson(_SessionRequest instance) =>
    <String, dynamic>{'id_token': instance.idToken};

_SessionResponse _$SessionResponseFromJson(Map<String, dynamic> json) =>
    _SessionResponse(
      uid: json['uid'] as String,
      phone: json['phone'] as String,
      isNew: json['is_new'] as bool,
      onboardingComplete: json['onboarding_complete'] as bool,
      isCreator: json['is_creator'] as bool? ?? false,
    );

Map<String, dynamic> _$SessionResponseToJson(_SessionResponse instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'phone': instance.phone,
      'is_new': instance.isNew,
      'onboarding_complete': instance.onboardingComplete,
      'is_creator': instance.isCreator,
    };
