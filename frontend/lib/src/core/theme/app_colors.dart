import 'package:flutter/material.dart';

/// Colour tokens from the V3 brief (SB-125) and the client prototype.
/// Components read tokens only, never raw hex, so the parked weekly palettes
/// can come back later by swapping values here.
class AppColors {
  const AppColors._();

  static Brightness _brightness = Brightness.light;

  /// Set once per frame from the app root with the effective brightness
  /// (the app follows the system setting, see [FeatureFlags.inAppThemeSwitch]).
  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  /// Kept for the parked in-app theme switch.
  static void setThemeMode(ThemeMode mode) {
    if (mode == ThemeMode.system) return;
    _brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  static bool get _isDark => _brightness == Brightness.dark;

  /// Whether the app is currently in dark mode. Exposed so non-widget code
  /// (e.g. building a themed WebView URL) can match the active theme.
  static bool get isDark => _isDark;

  // Light set: paper, card, ink, soft line, muted.
  static const Color lightBgPrimary = Color(0xFFEDEBE3); // Paper
  static const Color lightBgSecondary = Color(0xFFFDFDFD); // Card
  static const Color lightBgTertiary = Color(0xFFD5D3CB); // Hairline
  static const Color lightSurface = lightBgSecondary;
  static const Color lightBorder = Color(0xFF171714); // Ink
  static const Color lightSoftLine = Color(0xFFC9C7BF);
  static const Color lightTextPrimary = Color(0xFF171714);
  static const Color lightTextSecondary = Color(0xFF5F5E58); // Muted
  static const Color lightTextTertiary = Color(0xFF8C8A82);

  // Dark set: cards sit close to the background with a visible edge and no
  // offset shadow.
  static const Color darkBgPrimary = Color(0xFF151513); // Paper
  static const Color darkBgSecondary = Color(0xFF1F1F1C); // Card
  static const Color darkBgTertiary = Color(0xFF33332F); // Hairline
  static const Color darkSurface = darkBgSecondary;
  static const Color darkBorder = Color(0xFF45464E); // Edge
  static const Color darkSoftLine = darkBorder;
  static const Color darkTextPrimary = Color(0xFFEDEBE3);
  static const Color darkTextSecondary = Color(0xFFA3A198); // Muted
  static const Color darkTextTertiary = Color(0xFF6F6E67);

  /// FaFo blue. The only "live" colour: selected, free, "this is for you".
  /// Deep enough that white text on it passes AA at every size. Same in both
  /// themes, always with [onAccent] text.
  static const Color accentPrimary = Color(0xFF1A6FD0);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentSecondary = Color(0xFF1559A8);
  static const Color accentWarm = Color(0xFF0F4785);
  static const Color accentLight1 = Color(0xFF5E9BE0);
  static const Color accentLight2 = Color(0xFFA9C9EE);
  static const Color accentLightest = Color(0xFFE8F0FA);

  /// Avatars and the Hard badge only.
  static const Color signalRed = Color(0xFFEB5147);

  /// Medium badge only.
  static const Color amber = Color(0xFFF2C350);

  /// The live notification's post-yes bar. The only green in the app.
  static const Color stateGreen = Color(0xFF4ED164);

  /// Fixed ink: borders and shadows that stay ink in both themes (blue cards,
  /// badges, avatars).
  static const Color ink = Color(0xFF171714);

  static Color get bgPrimary => _isDark ? darkBgPrimary : lightBgPrimary;
  static Color get bgSecondary => _isDark ? darkBgSecondary : lightBgSecondary;
  static Color get bgTertiary => _isDark ? darkBgTertiary : lightBgTertiary;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get border => _isDark ? darkBorder : lightBorder;
  static Color get softLine => _isDark ? darkSoftLine : lightSoftLine;
  static Color get hairline => bgTertiary;
  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textTertiary =>
      _isDark ? darkTextTertiary : lightTextTertiary;

  /// 2px section rules: ink in light, light text colour in dark.
  static Color get rule => textPrimary;

  /// Offset shadows drop to none in dark mode.
  static Color get shadow => _isDark ? Colors.transparent : ink;

  /// Primary pill fill and its text. Inverts in dark mode.
  static Color get primaryFill => _isDark ? darkTextPrimary : ink;
  static Color get onPrimaryFill => _isDark ? ink : lightBgSecondary;

  /// No gradients in V3; kept as a flat fill so existing callers still build.
  static LinearGradient get primaryGradient =>
      const LinearGradient(colors: [accentPrimary, accentPrimary]);
}
