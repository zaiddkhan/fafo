import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:fafu/src/core/services/logger_provider.dart';
import 'package:fafu/src/features/notifications/data/push_repository.dart';

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// Owns the device's push lifecycle: permission, FCM token registration, token
/// refresh, timezone sync (for quiet hours), and logout cleanup.
///
/// Every step is best-effort — a failure here must never block the user. Web is
/// skipped (the app uses native push only).
class PushService {
  PushService(this._ref);

  final Ref _ref;
  bool _initialized = false;
  String? _token;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Call once the user is signed in and inside the app shell.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    final logger = _ref.read(loggerProvider);

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      logger.i('Push permission: ${settings.authorizationStatus}');

      // iOS: also surface notifications while the app is foregrounded.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Timezone needs no permission, so sync it regardless of the push grant.
      await _syncTimezone();

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      // Tokens rotate; keep the backend registry current.
      messaging.onTokenRefresh.listen(_registerToken);
    } catch (e, st) {
      logger.e('Push init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _registerToken(String token) async {
    final logger = _ref.read(loggerProvider);
    try {
      _token = token;
      await _ref
          .read(pushRepositoryProvider)
          .registerDevice(token: token, platform: _platform);
      logger.i('Device token registered ($_platform)');
    } catch (e) {
      logger.w('Device token registration failed: $e');
    }
  }

  Future<void> _syncTimezone() async {
    final logger = _ref.read(loggerProvider);
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      await _ref.read(pushRepositoryProvider).updateTimezone(tz);
    } catch (e) {
      logger.w('Timezone sync failed: $e');
    }
  }

  /// Call on logout so this device stops receiving pushes for the old account.
  Future<void> unregister() async {
    if (kIsWeb) return;
    final logger = _ref.read(loggerProvider);
    try {
      final messaging = FirebaseMessaging.instance;
      final token = _token ?? await messaging.getToken();
      if (token != null) {
        await _ref.read(pushRepositoryProvider).unregisterDevice(token);
      }
      await messaging.deleteToken();
    } catch (e) {
      logger.w('Device unregister failed: $e');
    } finally {
      _initialized = false;
      _token = null;
    }
  }
}
