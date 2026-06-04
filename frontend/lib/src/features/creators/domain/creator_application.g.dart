// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreatorApplicationRequest _$CreatorApplicationRequestFromJson(
  Map<String, dynamic> json,
) => _CreatorApplicationRequest(
  purpose: json['purpose'] as String,
  socialLinks:
      (json['social_links'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  phone: json['phone'] as String,
  relevantLinks:
      (json['relevant_links'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$CreatorApplicationRequestToJson(
  _CreatorApplicationRequest instance,
) => <String, dynamic>{
  'purpose': instance.purpose,
  'social_links': instance.socialLinks,
  'phone': instance.phone,
  'relevant_links': instance.relevantLinks,
};

_CreatorApplicationResponse _$CreatorApplicationResponseFromJson(
  Map<String, dynamic> json,
) => _CreatorApplicationResponse(
  uid: json['uid'] as String,
  purpose: json['purpose'] as String,
  socialLinks: (json['social_links'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  phone: json['phone'] as String,
  relevantLinks: (json['relevant_links'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  status: json['status'] as String,
  submittedAt: DateTime.parse(json['submitted_at'] as String),
);

Map<String, dynamic> _$CreatorApplicationResponseToJson(
  _CreatorApplicationResponse instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'purpose': instance.purpose,
  'social_links': instance.socialLinks,
  'phone': instance.phone,
  'relevant_links': instance.relevantLinks,
  'status': instance.status,
  'submitted_at': instance.submittedAt.toIso8601String(),
};
