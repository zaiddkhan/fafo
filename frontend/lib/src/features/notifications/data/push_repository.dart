import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepository(ref.watch(dioProvider));
});

/// Talks to the backend push endpoints: device-token registry + timezone.
class PushRepository {
  PushRepository(this._dio);

  final Dio _dio;

  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    try {
      // live_nudges: this build draws V3 nudge pushes itself (live countdown
      // bars), so the backend may send them data-only on Android.
      await _dio.post('/devices', data: {
        'token': token,
        'platform': platform,
        'capabilities': ['live_nudges'],
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unregisterDevice(String token) async {
    try {
      // Token contains ':' so encode it for the path segment.
      await _dio.delete('/devices/${Uri.encodeComponent(token)}');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateTimezone(String timezone) async {
    try {
      await _dio.put('/users/me/timezone', data: {'timezone': timezone});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
