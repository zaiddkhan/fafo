import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/auth_token_provider.dart';

/// Tracks whether the current session is no longer valid — i.e. the backend
/// rejected our credentials with a 401 and the Firebase ID token could not be
/// refreshed (signed out elsewhere, token revoked, account deleted/disabled).
///
/// Normal hourly ID-token expiry never reaches here: the Dio interceptor
/// transparently force-refreshes and retries. This flag is only for the
/// unrecoverable case, and the router watches it to bounce the user to sign-in.
final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, bool>(SessionExpiredNotifier.new);

class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Called by the network layer when credentials are rejected and cannot be
  /// refreshed. Tears down the local session so the interceptor stops retrying,
  /// then flips the flag the router reacts to. Idempotent across the burst of
  /// concurrent requests that typically all 401 at once.
  void markExpired() {
    if (state) return;
    state = true;
    // Sign out of Firebase so it stops vending a (revoked) token, and drop the
    // cached backend token. Fire-and-forget: the flag flip above is what drives
    // the redirect; the cleanup just settles state.
    FirebaseAuth.instance.signOut().catchError((_) {});
    ref.read(authTokenProvider.notifier).clearToken();
  }

  /// Called after a successful re-authentication so the router stops forcing
  /// the user back to sign-in.
  void reset() {
    if (state) state = false;
  }
}
