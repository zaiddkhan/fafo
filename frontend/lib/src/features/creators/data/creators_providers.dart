import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/creators/data/creators_repository.dart';
import 'package:fafu/src/features/creators/domain/creator_application.dart';

final creatorApplicationProvider =
    FutureProvider<CreatorApplicationResponse>((ref) {
  final repo = ref.watch(creatorsRepositoryProvider);
  return repo.getApplication();
});

final creatorApplyProvider = NotifierProvider<CreatorApplyNotifier,
    AsyncValue<CreatorApplicationResponse?>>(
  CreatorApplyNotifier.new,
);

class CreatorApplyNotifier
    extends Notifier<AsyncValue<CreatorApplicationResponse?>> {
  @override
  AsyncValue<CreatorApplicationResponse?> build() =>
      const AsyncValue.data(null);

  Future<CreatorApplicationResponse> apply(
    CreatorApplicationRequest request,
  ) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(creatorsRepositoryProvider);
      final response = await repo.apply(request);
      state = AsyncValue.data(response);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
