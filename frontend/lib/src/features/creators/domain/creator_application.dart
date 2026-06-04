import 'package:freezed_annotation/freezed_annotation.dart';

part 'creator_application.freezed.dart';
part 'creator_application.g.dart';

@freezed
abstract class CreatorApplicationRequest with _$CreatorApplicationRequest {
  const factory CreatorApplicationRequest({
    required String purpose,
    @JsonKey(name: 'social_links') @Default([]) List<String> socialLinks,
    required String phone,
    @JsonKey(name: 'relevant_links') @Default([]) List<String> relevantLinks,
  }) = _CreatorApplicationRequest;

  factory CreatorApplicationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatorApplicationRequestFromJson(json);
}

@freezed
abstract class CreatorApplicationResponse with _$CreatorApplicationResponse {
  const factory CreatorApplicationResponse({
    required String uid,
    required String purpose,
    @JsonKey(name: 'social_links') required List<String> socialLinks,
    required String phone,
    @JsonKey(name: 'relevant_links') required List<String> relevantLinks,
    required String status,
    @JsonKey(name: 'submitted_at') required DateTime submittedAt,
  }) = _CreatorApplicationResponse;

  factory CreatorApplicationResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatorApplicationResponseFromJson(json);
}
