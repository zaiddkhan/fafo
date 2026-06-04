import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/auth_token_provider.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/auth/domain/session.dart';

final sessionProvider =
    NotifierProvider<SessionNotifier, AsyncValue<SessionResponse?>>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<AsyncValue<SessionResponse?>> {
  @override
  AsyncValue<SessionResponse?> build() => const AsyncValue.data(null);

  Future<SessionResponse> createSession(String idToken) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.createSession(idToken: idToken);
      ref.read(authTokenProvider.notifier).setToken(idToken);
      state = AsyncValue.data(session);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void logout() {
    ref.read(authTokenProvider.notifier).clearToken();
    state = const AsyncValue.data(null);
  }
}
