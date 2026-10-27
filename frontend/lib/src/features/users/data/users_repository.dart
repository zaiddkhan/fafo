import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/core/services/network_status.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/features/users/domain/profile_stats.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(dioProvider));
});

/// Current user's profile (including creator status), fetched from `/users/me`.
/// Used to gate creator-only actions. Refresh with `ref.invalidate`.
///
/// Implemented as an [AsyncNotifier] (rather than a plain [FutureProvider]) so
/// that write flows which already receive the fresh, authoritative profile from
/// the backend (e.g. Edit Profile's `PUT /users/profile`) can seed the cache
/// directly via [CurrentProfileNotifier.setProfile]. This avoids a redundant
/// `GET /users/me` refetch that can momentarily return stale data
/// (read-after-write lag) and make a successful save look like it didn't persist.
final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileNotifier, ProfileResponse>(
  CurrentProfileNotifier.new,
);

class CurrentProfileNotifier extends AsyncNotifier<ProfileResponse> {
  @override
  Future<ProfileResponse> build() {
    // A load that failed while offline would otherwise stick for the whole
    // session: home then can't tell which answers are yours.
    ref.listen<bool>(networkStatusProvider, (was, online) {
      if (was == false && online) retryIfFailed();
    });
    return ref.watch(usersRepositoryProvider).getMe();
  }

  /// Re-fetch only if the last load failed (on reconnect and app resume).
  void retryIfFailed() {
    if (state.hasError && !state.isLoading) ref.invalidateSelf();
  }

  /// Seed the cache with an already-fetched profile (e.g. the response returned
  /// by a profile update), so readers reflect the new values immediately
  /// without waiting on a fresh network round-trip.
  void setProfile(ProfileResponse profile) {
    state = AsyncValue.data(profile);
  }
}

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<ProfileResponse> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// "I'm free rn". Stays on until turned off.
  Future<ProfileResponse> setFree(bool free) async {
    try {
      final response = await _dio.put('/users/me/free', data: {'free': free});
      return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Quick defaults: default countdown and side quest invites.
  Future<ProfileResponse> setQuickDefaults({
    required int defaultCountdownMinutes,
    required bool sideQuestInvites,
  }) async {
    try {
      final response = await _dio.put('/users/me/defaults', data: {
        'default_countdown_minutes': defaultCountdownMinutes,
        'side_quest_invites': sideQuestInvites,
      });
      return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProfileStatsResponse> getMyStats() async {
    try {
      final response = await _dio.get('/users/me/stats');
      return ProfileStatsResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAccount({required List<String> answers}) async {
    try {
      await _dio.delete('/users/me', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UsernameCheckResponse> checkUsername(String username) async {
    try {
      final response = await _dio.get(
        '/users/username/check',
        queryParameters: {'username': username},
      );
      return UsernameCheckResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProfileResponse> setupProfile(ProfileSetupRequest request) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: request.toJson(),
      );
      return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> completeFirstLaunchTooltip() async {
    try {
      await _dio.post('/users/onboarding/first-launch-tooltip/complete');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PhotoUploadResponse> getPhotoUploadUrl() async {
    try {
      final response = await _dio.post('/users/profile/photo');
      return PhotoUploadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PhotoUploadResponse> uploadProfilePhoto(XFile photo) async {
    final upload = await getPhotoUploadUrl();
    final ref = FirebaseStorage.instance.ref(upload.uploadPath);
    final bytes = await photo.readAsBytes();
    await ref.putData(
      bytes,
      SettableMetadata(contentType: photo.mimeType ?? 'image/jpeg'),
    );
    return upload;
  }
}
