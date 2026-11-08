import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:fafu/firebase_options.dart';
import 'package:fafu/src/core/config/app_config.dart';
import 'package:fafu/src/features/notifications/data/live_nudge_notifications.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';

/// "I'm in" / "Can't" tapped on a nudge notification while the app is in the
/// background or closed. Android runs this in a fresh isolate, so it sets up
/// Firebase and config itself before answering.
@pragma('vm:entry-point')
Future<void> onNudgeNotificationActionBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await handleNudgeNotificationAction(response);
}

/// Answers the nudge from its notification. Yes swaps the blue answer bar for
/// the red "to get there" countdown; Can't leaves it cleared (Android already
/// removed it). On failure the notification asks them to open FaFo instead.
/// Returns true when the answer went through.
Future<bool> handleNudgeNotificationAction(
  NotificationResponse response, {
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final action = response.actionId;
  if (action != nudgeYesAction && action != nudgeNoAction) return false;
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return false;
  final Map<String, dynamic> data;
  try {
    data = (jsonDecode(payload) as Map).cast<String, dynamic>();
  } catch (_) {
    return false;
  }
  final nudgeId = data['nudge_id'] as String?;
  if (nudgeId == null) return false;
  final yes = action == nudgeYesAction;

  final notifications = plugin ?? await _backgroundPlugin();
  final live = LiveNudgeNotifications(notifications);
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    if (!dotenv.isInitialized) await dotenv.load(fileName: 'assets/env/.env');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final token = await user.getIdToken();
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final res = await dio.post(
      '/nudges/$nudgeId/respond',
      data: {'vote': nudgeVoteToJson(yes ? NudgeVote.yes : NudgeVote.no)},
    );
    final nudge = NudgeResponse.fromJson(res.data as Map<String, dynamic>);
    if (yes) {
      await live.showYouSaidYes(nudge);
    } else {
      await live.cancel(nudgeId);
    }
    return true;
  } catch (_) {
    // Put a tappable note where the bar was, so the answer isn't silently lost.
    await notifications.show(
      LiveNudgeNotifications.idFor(nudgeId),
      'Couldn’t send your answer',
      'Open FaFo to answer before the time runs out.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          nudgeAndroidChannel.id,
          nudgeAndroidChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_fafo',
        ),
      ),
      payload: payload,
    );
    return false;
  }
}

Future<FlutterLocalNotificationsPlugin> _backgroundPlugin() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('ic_stat_fafo')),
  );
  return plugin;
}
