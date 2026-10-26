import 'package:flutter/foundation.dart';

/// What a notification tap asked home to show.
sealed class HomeFocusRequest {
  const HomeFocusRequest();
}

class FocusNudge extends HomeFocusRequest {
  const FocusNudge(this.nudgeId);
  final String nudgeId;
}

class FocusGroup extends HomeFocusRequest {
  const FocusGroup(this.groupId);
  final String groupId;
}

/// Bridges push handling (outside the widget tree) to the home screen. Home
/// is the only screen in V3, so a notification tap lands there and home opens
/// the matching card or group sheet.
class HomeFocus {
  const HomeFocus._();

  /// Set by a notification tap; home consumes and clears it.
  static final request = ValueNotifier<HomeFocusRequest?>(null);

  /// Bumped when a nudge push arrives in the foreground, so home refreshes now
  /// instead of on its next poll.
  static final refreshTick = ValueNotifier<int>(0);

  static void ping() => refreshTick.value++;
}
