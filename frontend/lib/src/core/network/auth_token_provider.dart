import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/services/shared_preferences_provider.dart';

const _tokenKey = 'auth_token';

final authTokenProvider =
    NotifierProvider<AuthTokenNotifier, String?>(AuthTokenNotifier.new);

class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
          data: (prefs) => prefs,
          orElse: () => null,
        );
    return prefs?.getString(_tokenKey);
  }

  void setToken(String token) {
    state = token;
    ref
        .read(sharedPreferencesProvider)
        .whenData((prefs) => prefs.setString(_tokenKey, token));
  }

  void clearToken() {
    state = null;
    ref
        .read(sharedPreferencesProvider)
        .whenData((prefs) => prefs.remove(_tokenKey));
  }
}
