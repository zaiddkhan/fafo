import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether to show the "notifications are off" bar above the nav. Shown once
/// the permission has been refused [showAfter] times (Android stops asking
/// after two), until it's granted. Not shown if the user switched push off
/// in FaFo's own Settings: that's a choice, not a missed prompt.
final notificationNagProvider = NotifierProvider<NotificationNag, bool>(NotificationNag.new);

class NotificationNag extends Notifier<bool> {
  static const showAfter = 2;
  static const _denialsKey = 'push_permission_denials';
  // Same key as Settings' push toggle.
  static const _pushEnabledKey = 'push_notifications_enabled';
  static const _channel = MethodChannel('fafo/settings');

  bool _granted = true;

  @override
  bool build() {
    recheck();
    return false;
  }

  /// The answer to a permission request (PushService asks on each launch).
  Future<void> record(AuthorizationStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    _granted = _isGranted(status);
    final denials = prefs.getInt(_denialsKey) ?? 0;
    await prefs.setInt(_denialsKey, _granted ? 0 : denials + 1);
    _evaluate(prefs);
  }

  /// Re-reads the current permission without prompting: on launch, on resume
  /// (back from system settings) and after the in-app push toggle changes.
  Future<void> recheck() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      _granted = _isGranted(settings.authorizationStatus);
      if (_granted) await prefs.setInt(_denialsKey, 0);
    } catch (_) {
      // Firebase not ready (tests, very early start): keep the last answer.
    }
    _evaluate(prefs);
  }

  Future<void> openSettings() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      await _channel.invokeMethod<bool>('openNotificationSettings');
    }
  }

  void _evaluate(SharedPreferences prefs) {
    final optedOut = prefs.getBool(_pushEnabledKey) == false;
    state = !_granted && !optedOut && (prefs.getInt(_denialsKey) ?? 0) >= showAfter;
  }

  static bool _isGranted(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized || s == AuthorizationStatus.provisional;
}
