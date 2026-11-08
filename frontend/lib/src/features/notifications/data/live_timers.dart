import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';

/// Running nudge / side-quest timers as iOS Live Activities: Lock Screen and
/// Dynamic Island (native side: ios/Runner/FafoLiveActivityPlugin.swift and
/// the FafoTimer widget extension). Android has the equivalent already, the
/// live countdown notification in live_nudge_notifications.dart.
///
/// Home calls [sync] every tick with the nudges it shows. Each running timer
/// becomes one activity; anything that stopped running is ended. The countdown
/// ticks natively, so nothing needs the app while it's closed. When a timer
/// hits zero in the background the activity flips to its done state ("Go
/// time" / "Time's up") on its own, via the stale date.
///
/// Not covered until APNs is set up: changes made while the app is closed (an
/// answer arriving, a new nudge) reach the activity the next time the app
/// opens.
class LiveTimers {
  LiveTimers._();

  static const _channel = MethodChannel('fafo/live_activity');

  /// iOS shows up to two in the Dynamic Island; a few more on the Lock Screen
  /// is plenty.
  static const _max = 3;

  static String? _lastSent;

  static bool get _enabled =>
      FeatureFlags.liveActivities &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Bring the activities in line with [views]. Cheap to call every second:
  /// iOS only hears about it when the set of timers actually changes.
  static void sync(List<NudgeView> views, DateTime now) {
    if (!_enabled) return;
    final entries = [
      for (final v in views) ?_entry(v, now),
    ]..sort((a, b) => (a.$1).compareTo(b.$1));
    final payload = [for (final e in entries.take(_max)) e.$2];
    final signature = jsonEncode(payload);
    if (signature == _lastSent) return;
    _lastSent = signature;
    _channel.invokeMethod<void>('sync', payload).catchError((Object e) {
      // Let the next tick retry.
      _lastSent = null;
      debugPrint('Live Activity sync failed: $e');
    });
  }

  /// Sign-out: nothing from this account should stay on the Lock Screen.
  static Future<void> endAll() async {
    if (!_enabled) return;
    _lastSent = null;
    try {
      await _channel.invokeMethod<void>('endAll');
    } catch (e) {
      debugPrint('Live Activity endAll failed: $e');
    }
  }

  /// One timer, with a sort key: an answer you owe first, then whatever ends
  /// soonest. Null when this nudge has no timer worth showing.
  static (int, Map<String, Object?>)? _entry(NudgeView v, DateTime now) {
    final n = v.nudge;
    final state = v.state(now);
    final name = v.targetName;
    final answerStart = n.createdAt;
    final goStart = n.goTime.subtract(Duration(minutes: n.countdownMinutes));

    String head;
    String label;
    DateTime start;
    DateTime end;
    var red = false;
    var done = false;
    var priority = 1;

    switch (state) {
      case NudgeCardState.pending when v.isSender:
        head = n.isGroup ? 'Waiting on $name' : 'Waiting for $name';
        label = 'left to answer';
        (start, end) = (answerStart, n.answerDeadline);
      case NudgeCardState.pending:
        head = 'From ${v.senderName}';
        label = 'left to answer';
        (start, end) = (answerStart, n.answerDeadline);
        priority = 0;
      case NudgeCardState.accepted:
        head = v.isSender
            ? (n.isGroup ? '$name is on' : '$name’s in')
            : (n.isGroup ? 'You’re in' : 'You said yes');
        label = 'to get there';
        (start, end) = (goStart, n.goTime);
        red = true;
      case NudgeCardState.goTime when v.isInLiveArea(now):
        // Lingers as "Go time" while home still shows it, then ends.
        head = 'Go time';
        label = 'to get there';
        (start, end) = (goStart, n.goTime);
        red = true;
        done = true;
      default:
        return null;
    }

    final key = priority * 1000000000000 + end.millisecondsSinceEpoch;
    return (
      key,
      {
        'id': n.id,
        'title': n.title,
        'quest': n.isQuest,
        'head': head,
        'label': label,
        'doneLabel': red ? 'Go time' : 'Time’s up',
        'start': _deviceMillis(start),
        'end': _deviceMillis(end),
        'red': red,
        'done': done,
      },
    );
  }

  /// Timers come from server timestamps; iOS counts on the device clock.
  static int _deviceMillis(DateTime serverTime) =>
      serverTime.subtract(ServerClock.offset).millisecondsSinceEpoch;
}
