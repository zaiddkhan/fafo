import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/features/home/presentation/main_shell.dart';

/// Bridges platform deep links (https universal/app links) into the app's
/// [GoRouter]. Handles both the cold-start link and the warm/background link
/// stream — the piece the app was missing, so links only resolved on cold start
/// via go_router's platform initial route.
///
/// Recognised destinations (host `getfafo.app`):
///   `/`                 → home (map)
///   `/event/<id>`       → event detail
///   `/invite/<token>`   → friend invite landing
///   `/groups/<id>`      → a specific group
/// Anything else is ignored so unrelated marketing URLs never disrupt the app.
class DeepLinkHandler {
  DeepLinkHandler(this._router);

  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Warm / backgrounded taps arrive here for the life of the process.
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, isInitial: false),
      onError: (Object e) => debugPrint('DeepLinkHandler stream error: $e'),
    );

    // Cold start: the link that launched the app (null if launched normally).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial, isInitial: true);
    } catch (e) {
      debugPrint('DeepLinkHandler initial link error: $e');
    }
  }

  void _handle(Uri uri, {required bool isInitial}) {
    final location = _mapToLocation(uri);
    if (location == null) return;

    final currentPath =
        _router.routerDelegate.currentConfiguration.uri.path;

    // On cold start go_router may have already routed to this same link via the
    // platform's initial route — don't stack a duplicate on top of it.
    if (isInitial && currentPath == uri.path) return;

    // Warm taps push (so back returns to where the user was); a cold link that
    // go_router didn't already handle replaces the current location.
    if (isInitial) {
      _router.go(location);
    } else {
      _router.push(location);
    }
  }

  /// Translates an incoming deep-link [uri] to an in-app location, or null when
  /// the path isn't something the app should intercept.
  String? _mapToLocation(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;

    if (path == '/') return MainShell.routePath;

    if (path.startsWith('/event/') ||
        path.startsWith('/invite/') ||
        path.startsWith('/groups/')) {
      // Preserve any query string (harmless for these routes today, future-proof).
      return uri.hasQuery ? '$path?${uri.query}' : path;
    }

    return null;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
