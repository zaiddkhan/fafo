import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/blogs/domain/blog.dart';

final blogsRepositoryProvider = Provider<BlogsRepository>((ref) {
  return BlogsRepository(ref.watch(dioProvider));
});

class BlogsRepository {
  BlogsRepository(this._dio);

  final Dio _dio;

  Future<List<BlogResponse>> getBlogs({required String city, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/blogs',
        queryParameters: {'city': city, 'limit': limit},
      );
      final data = response.data as List;
      return data
          .map((e) => BlogResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
