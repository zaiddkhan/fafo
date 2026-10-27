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

  /// The five V3 sounds (brief 7.4). Off until the audio files are installed
  /// (assets/sounds/README.md): pushes use the system sound and in-app sounds
  /// stay silent. Flipping this also moves Android to the custom-sound channels.
  static const bool customSounds = false;

  /// "Preview both sides" (brief 3.9): a demo-only two-phone sheet from the
  /// prototype. Not part of the real app; kept for client demos.
  static const bool previewBothSides = false;

  /// In-app System / Light / Dark choice in Settings. System is the default,
  /// as brief 2.4 asks.
  static const bool inAppThemeSwitch = true;
}
