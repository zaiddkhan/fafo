import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/categories/data/categories_repository.dart';
import 'package:fafu/src/features/categories/domain/category.dart';

final categoriesProvider = FutureProvider<List<CategoryResponse>>((ref) {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.getCategories();
});
