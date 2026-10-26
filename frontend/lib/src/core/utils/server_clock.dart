/// Server-corrected clock. [offset] is set from the server's Date header so a
/// changed device clock doesn't move nudge timers (V3 brief 4.2).
class ServerClock {
  const ServerClock._();

  static Duration offset = Duration.zero;

  static DateTime now() => DateTime.now().toUtc().add(offset);
}
