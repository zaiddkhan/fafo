import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';

final usernameCheckProvider =
    FutureProvider.family<UsernameCheckResponse, String>((ref, username) {
  final repo = ref.watch(usersRepositoryProvider);
  return repo.checkUsername(username);
});

final profileProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<ProfileResponse?>>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<AsyncValue<ProfileResponse?>> {
  @override
  AsyncValue<ProfileResponse?> build() => const AsyncValue.data(null);

  Future<ProfileResponse> setupProfile(ProfileSetupRequest request) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(usersRepositoryProvider);
      final profile = await repo.setupProfile(request);
      state = AsyncValue.data(profile);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PhotoUploadResponse> getPhotoUploadUrl() async {
    final repo = ref.read(usersRepositoryProvider);
    return repo.getPhotoUploadUrl();
  }
}
