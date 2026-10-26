import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';

/// Android channel for V3 nudge notifications, drawn by the app from data-only
/// pushes so they can carry a live countdown bar (brief 7.3).
const nudgeAndroidChannel = AndroidNotificationChannel(
  'fafo_nudges',
  'Nudges',
  description: 'Plans from friends, answers, and go time',
  importance: Importance.high,
);

/// Custom-sound channels (brief 7.4). Android fixes a channel's sound when it
/// is first created, so N and EXP each get their own channel, and the ids carry
/// a version: bump it if the sound files ever change.
const nudgeSoundChannel = AndroidNotificationChannel(
  'fafo_nudge_n_v1',
  'Nudges',
  description: 'Plans from friends and their answers',
  importance: Importance.high,
  sound: RawResourceAndroidNotificationSound('n'),
);

const timerSoundChannel = AndroidNotificationChannel(
  'fafo_nudge_exp_v1',
  'Timers',
  description: 'Expired plans and go time',
  importance: Importance.high,
  sound: RawResourceAndroidNotificationSound('exp'),
);

/// Every channel the app should create, given whether custom sounds are in.
List<AndroidNotificationChannel> get nudgeChannels => FeatureFlags.customSounds
    ? const [nudgeAndroidChannel, nudgeSoundChannel, timerSoundChannel]
    : const [nudgeAndroidChannel];

/// Renders V3 nudge pushes as live notifications on Android:
/// - arrives: red bar filling over the 10-minute answer window
/// - after yes: green bar over the sender's 5, 10 or 15 minutes
/// - expired / go time: the same notification turns static and stays
///
/// Android runs the countdown natively (chronometer + timeout), so nothing has
/// to update it while the app is closed; the server's expiry and go-time pushes
/// replace it with the final state. iOS receives a normal alert from APNs (a
/// Live Activity is a separate native piece).
class LiveNudgeNotifications {
  LiveNudgeNotifications(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static bool isNudgePush(Map<String, dynamic> data) =>
      (data['template_id'] as String? ?? '').startsWith('nudge.') &&
      data['n_title'] != null;

  /// One notification per nudge, replaced as it moves through its states.
  static int idFor(String nudgeId) => nudgeId.hashCode & 0x7fffffff;

  Future<void> show(Map<String, dynamic> data) async {
    if (defaultTargetPlatform != TargetPlatform.android || !isNudgePush(data)) return;
    final nudgeId = data['nudge_id'] as String?;
    if (nudgeId == null) return;

    final template = data['template_id'] as String;
    final title = data['n_title'] as String? ?? '';
    final body = data['n_body'] as String? ?? '';
    final now = DateTime.now().toUtc();
    final answerBy = DateTime.tryParse(data['answer_by'] as String? ?? '');
    final goAt = DateTime.tryParse(data['go_at'] as String? ?? '');
    final countdown = int.tryParse(data['countdown_minutes']?.toString() ?? '') ?? 10;

    final channel = !FeatureFlags.customSounds
        ? nudgeAndroidChannel
        : template == 'nudge.expired' || template == 'nudge.go_time'
        ? timerSoundChannel
        : nudgeSoundChannel;

    AndroidNotificationDetails details;
    switch (template) {
      case 'nudge.received' || 'nudge.group_received' when answerBy != null:
        details = _bar(
          channel: channel,
          // The sender's own bar: NS already played in the app.
          silent: data['silent'] == '1',
          start: answerBy.subtract(const Duration(minutes: 10)),
          end: answerBy,
          now: now,
          color: AppColors.signalRed,
        );
      case 'nudge.said_yes' || 'nudge.group_first_yes' when goAt != null:
        details = _bar(
          channel: channel,
          start: goAt.subtract(Duration(minutes: countdown)),
          end: goAt,
          now: now,
          color: AppColors.stateGreen,
        );
      case 'nudge.expired':
        details = _done(channel: channel, color: AppColors.signalRed);
      case 'nudge.go_time':
        details = _done(channel: channel, color: AppColors.stateGreen);
      default:
        details = _plain(channel);
    }

    // A "2/5 in" tally lands beside the running green countdown. "No one's in"
    // replaces the sender's red bar, which would otherwise keep counting.
    final yesCount = int.tryParse(data['yes_count']?.toString() ?? '') ?? 0;
    final id = template == 'nudge.group_final' && yesCount > 0
        ? idFor('$nudgeId:final')
        : idFor(nudgeId);
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: details),
      payload: jsonEncode(data),
    );
  }

  /// The sender's own red bar while they wait (brief 7.3, suggested): drawn
  /// locally right after sending, so both sides watch one clock. The answer,
  /// expiry or go-time push later replaces it under the same id.
  Future<void> showSenderWaiting(NudgeResponse nudge) {
    final who = nudge.targetName ?? (nudge.isGroup ? 'your group' : 'your friend');
    return show({
      'template_id': 'nudge.received',
      'nudge_id': nudge.id,
      'feed_type': nudge.isGroup ? 'group' : 'friend',
      'target_id': nudge.targetId ?? '',
      'title': nudge.title,
      'answer_by': nudge.answerDeadline.toUtc().toIso8601String(),
      'countdown_minutes': '${nudge.countdownMinutes}',
      'n_title': '${nudge.isGroup ? 'Waiting on' : 'Waiting for'} $who: ${nudge.title}',
      'n_body': 'Left to answer.',
      'silent': '1',
    });
  }

  /// The user answered in the app: the red bar is no longer needed.
  Future<void> cancel(String nudgeId) => _plugin.cancel(idFor(nudgeId));

  AndroidNotificationDetails _bar({
    required AndroidNotificationChannel channel,
    bool silent = false,
    required DateTime start,
    required DateTime end,
    required DateTime now,
    required Color color,
  }) {
    final total = end.difference(start).inSeconds.clamp(1, 1 << 30);
    final elapsed = now.difference(start).inSeconds.clamp(0, total);
    final left = end.difference(now);
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: color,
      category: AndroidNotificationCategory.progress,
      silent: silent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: total,
      progress: elapsed,
      // The countdown ticks natively, even with the app closed.
      usesChronometer: true,
      chronometerCountDown: true,
      showWhen: true,
      when: end.millisecondsSinceEpoch,
      // Clears at zero; the server's expiry / go-time push takes over.
      timeoutAfter: left.isNegative ? 1 : left.inMilliseconds,
    );
  }

  AndroidNotificationDetails _done({
    required AndroidNotificationChannel channel,
    required Color color,
  }) {
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: color,
      showProgress: true,
      maxProgress: 1,
      progress: 1,
    );
  }

  AndroidNotificationDetails _plain(AndroidNotificationChannel channel) {
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
  }
}
