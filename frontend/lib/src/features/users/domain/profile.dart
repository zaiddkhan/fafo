import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Area with _$Area {
  const factory Area({
    required double lat,
    required double lng,
    @JsonKey(name: 'radius_km') @Default(15.0) double radiusKm,
  }) = _Area;

  factory Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);
}

@freezed
abstract class ProfileSetupRequest with _$ProfileSetupRequest {
  const factory ProfileSetupRequest({
    @JsonKey(name: 'display_name') required String displayName,
    required String username,
    Area? area,
  }) = _ProfileSetupRequest;

  factory ProfileSetupRequest.fromJson(Map<String, dynamic> json) =>
      _$ProfileSetupRequestFromJson(json);
}

@freezed
abstract class ProfileResponse with _$ProfileResponse {
  const factory ProfileResponse({
    required String uid,
    required String phone,
    @JsonKey(name: 'display_name') required String displayName,
    required String username,
    @JsonKey(name: 'photo_url') String? photoUrl,
    Area? area,
    @JsonKey(name: 'onboarding_complete') required bool onboardingComplete,
    @JsonKey(name: 'first_launch_tooltip_complete')
    @Default(false)
    bool firstLaunchTooltipComplete,
    @JsonKey(name: 'is_creator') @Default(false) bool isCreator,
  }) = _ProfileResponse;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}

@freezed
abstract class UsernameCheckResponse with _$UsernameCheckResponse {
  const factory UsernameCheckResponse({
    required String username,
    required bool available,
  }) = _UsernameCheckResponse;

  factory UsernameCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$UsernameCheckResponseFromJson(json);
}

@freezed
abstract class PhotoUploadResponse with _$PhotoUploadResponse {
  const factory PhotoUploadResponse({
    @JsonKey(name: 'upload_path') required String uploadPath,
    @JsonKey(name: 'photo_url') required String photoUrl,
  }) = _PhotoUploadResponse;

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$PhotoUploadResponseFromJson(json);
}
