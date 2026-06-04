import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/creators/domain/creator_application.dart';

final creatorsRepositoryProvider = Provider<CreatorsRepository>((ref) {
  return CreatorsRepository(ref.watch(dioProvider));
});

class CreatorsRepository {
  CreatorsRepository(this._dio);

  final Dio _dio;

  Future<CreatorApplicationResponse> apply(
    CreatorApplicationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/creators/apply',
        data: request.toJson(),
      );
      return CreatorApplicationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CreatorApplicationResponse> getApplication() async {
    try {
      final response = await _dio.get('/creators/application');
      return CreatorApplicationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
