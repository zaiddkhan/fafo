import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/categories/domain/category.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(dioProvider));
});

class CategoriesRepository {
  CategoriesRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryResponse>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final data = response.data as List;
      return data
          .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
