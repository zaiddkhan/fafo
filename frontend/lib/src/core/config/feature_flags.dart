/// Build-time switches for features the V3 brief (Nudge, Side Quests, Profile)
/// takes out of the app. Nothing behind a flag is deleted: flipping a flag back
/// to `true` restores the surface without rework. Everything defaults to off.
class FeatureFlags {
  const FeatureFlags._();

  /// Map screen, Mapbox, area re-centring, location prompt (brief 1.2).
  static const bool map = false;

  /// Events: create, join, detail, Events Index, Blogs, Spotlight (brief 1.3).
  static const bool events = false;

  /// Streak counter and activity stats on the profile (brief 1.6, 6.3).
  static const bool streaksAndStats = false;

  /// "Send reminder n/N" on live nudges (brief 4.6).
  static const bool nudgeReminders = false;

  /// Location field on nudges (brief 4.1).
  static const bool nudgeLocation = false;

  /// Chat thread after a nudge is answered (brief 4.6).
  static const bool chat = false;

  /// Weekly rotating colour palettes (brief 2.1).
  static const bool weeklyPalettes = false;

  /// Viewing other people's profiles (brief 6.3).
  static const bool publicProfiles = false;

  /// Exit surveys before unfriending, blocking, leaving or deleting a group.
  /// The prototype's flows have none.
  static const bool exitSurveys = false;

  /// In-app V3 sounds (brief 7.4): nudge sent, Yes / No tap and "I'm free".
  /// The files are in assets/sounds/.
  static const bool inAppSounds = true;

  /// Custom push sounds (brief 7.4): notification (N) and timer (EXP). Off
  /// until those two files are delivered and installed
  /// (assets/sounds/README.md); pushes use the system sound meanwhile.
  /// Flipping this also moves Android to the custom-sound channels.
  static const bool customSounds = false;

  /// iOS Live Activities for running nudge / side-quest timers: Lock Screen
  /// and Dynamic Island (lib/src/features/notifications/data/live_timers.dart).
  /// Needs the FafoTimer widget extension in the iOS build; iOS 16.2+.
  static const bool liveActivities = true;

  /// "Preview both sides" (brief 3.9): a demo-only two-phone sheet from the
  /// prototype. Not part of the real app; kept for client demos.
  static const bool previewBothSides = false;

  /// "Also free" avatars under the free pill on Home. The 1 Nov design moves
  /// free friends to the Friends tab's "Free now" filter.
  static const bool homeAlsoFree = false;

  /// Group mute (8 hours, 1 week, always). Needs a backend endpoint; until
  /// then the Mute button stays hidden.
  static const bool groupMute = false;

  /// Settings rows the 1 Nov HTML doesn't have (SB-136): Default countdown,
  /// Side quest invites, and the per-phone "Plans on this phone" switch in the
  /// Notifications sheet. Profiles keep their saved values (10 min, invites on
  /// by default); flip this to bring the controls back.
  static const bool extraSettings = false;

  /// In-app System / Light / Dark choice in Settings. Light is the default
  /// (product call; brief 2.4 had System).
  static const bool inAppThemeSwitch = true;
}
