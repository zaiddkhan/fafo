import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/services/logger_provider.dart';
import 'package:fafu/src/features/notifications/data/notification_navigation.dart';
import 'package:fafu/src/features/notifications/data/push_repository.dart';

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// Android channel for foreground notifications surfaced via the local-notifs
/// plugin. Must match the channel FCM uses so importance is consistent.
const _androidChannel = AndroidNotificationChannel(
  'fafu_default',
  'Notifications',
  description: 'Nudges, friend requests, and event updates',
  importance: Importance.high,
);

/// Background/terminated data-message handler. Must be a top-level function and
/// kept alive across tree-shaking. Notification-type messages are rendered by
/// the OS automatically; this exists so data still arrives. Registered from
/// bootstrap before runApp.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No work needed yet — taps are handled by onMessageOpenedApp /
  // getInitialMessage once the app is in the foreground.
}

/// Owns the device's push lifecycle: permission, FCM token registration, token
/// refresh, timezone sync (for quiet hours), foreground display, tap routing,
/// and logout cleanup.
///
/// Every step is best-effort — a failure here must never block the user. Web is
/// skipped (the app uses native push only).
class PushService {
  PushService(this._ref);

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
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

      await _initLocalNotifications();

      // Timezone needs no permission, so sync it regardless of the push grant.
      await _syncTimezone();

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      // Tokens rotate; keep the backend registry current.
      messaging.onTokenRefresh.listen(_registerToken);

      // Foreground messages: Android won't display these automatically, so we
      // render them ourselves; iOS is covered by the presentation options above.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Tap that brought the app back from the background.
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _routeFromMessage(message.data),
      );

      // Tap that cold-started the app from terminated.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _routeFromMessage(initial.data);
      }
    } catch (e, st) {
      logger.e('Push init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // FCM already requested iOS permissions; don't ask twice here.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = (jsonDecode(payload) as Map).cast<String, dynamic>();
          _routeFromMessage(data);
        } catch (_) {
          // Malformed payload — nothing to route to.
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _routeFromMessage(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    try {
      routeFromNotificationData(_ref.read(appRouterProvider), data);
    } catch (e) {
      _ref.read(loggerProvider).w('Notification routing failed: $e');
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
