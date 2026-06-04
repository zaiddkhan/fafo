import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class CategoryResponse with _$CategoryResponse {
  const factory CategoryResponse({
    required String id,
    required String name,
    required String emoji,
    @JsonKey(name: 'sort_order') required int sortOrder,
  }) = _CategoryResponse;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseFromJson(json);
}
