import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/features/users/domain/profile_stats.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(dioProvider));
});

/// Current user's profile (including creator status), fetched from `/users/me`.
/// Used to gate creator-only actions. Refresh with `ref.invalidate`.
final currentProfileProvider = FutureProvider<ProfileResponse>((ref) {
  return ref.watch(usersRepositoryProvider).getMe();
});

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
