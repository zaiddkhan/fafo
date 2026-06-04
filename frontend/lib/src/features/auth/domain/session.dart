import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
abstract class SessionRequest with _$SessionRequest {
  const factory SessionRequest({
    @JsonKey(name: 'id_token') required String idToken,
  }) = _SessionRequest;

  factory SessionRequest.fromJson(Map<String, dynamic> json) =>
      _$SessionRequestFromJson(json);
}

@freezed
abstract class SessionResponse with _$SessionResponse {
  const factory SessionResponse({
    required String uid,
    required String phone,
    @JsonKey(name: 'is_new') required bool isNew,
    @JsonKey(name: 'onboarding_complete') required bool onboardingComplete,
    @JsonKey(name: 'is_creator') @Default(false) bool isCreator,
  }) = _SessionResponse;

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);
}
