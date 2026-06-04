import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static ThemeMode _themeMode = ThemeMode.light;

  static void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
  }

  static bool get _isDark => _themeMode == ThemeMode.dark;

  static const Color lightBgPrimary = Color(0xFFF8FBFD);
  static const Color lightBgSecondary = Color(0xFFFCFDFE);
  static const Color lightBgTertiary = Color(0xFFD6EAFB);
  static const Color lightSurface = Color(0xFFFCFDFE);
  static const Color lightBorder = Color(0xFF171717);
  static const Color lightTextPrimary = Color(0xFF0A2540);
  static const Color lightTextSecondary = Color(0xFF3D6B8E);
  static const Color lightTextTertiary = Color(0xFF7BA3C2);

  static const Color darkBgPrimary = Color(0xFF1A1A1E);
  static const Color darkBgSecondary = Color(0xFF2A2A2F);
  static const Color darkBgTertiary = Color(0xFF3A3A40);
  static const Color darkSurface = darkBgSecondary;
  static const Color darkBorder = Color(0xFF34353D);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA0A0A8);
  static const Color darkTextTertiary = Color(0xFF6B6B73);

  static const Color accentPrimary = Color(0xFF1A87DA);
  static const Color accentSecondary = Color(0xFF1472B8);
  static const Color accentWarm = Color(0xFF0E5C96);
  static const Color accentLight1 = Color(0xFF5EAEE8);
  static const Color accentLight2 = Color(0xFFA3D4F4);
  static const Color accentLightest = Color(0xFFEBF5FC);

  static Color get bgPrimary => _isDark ? darkBgPrimary : lightBgPrimary;
  static Color get bgSecondary => _isDark ? darkBgSecondary : lightBgSecondary;
  static Color get bgTertiary => _isDark ? darkBgTertiary : lightBgTertiary;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get border => _isDark ? darkBorder : lightBorder;
  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textTertiary =>
      _isDark ? darkTextTertiary : lightTextTertiary;

  static LinearGradient get primaryGradient =>
      const LinearGradient(colors: [accentPrimary, accentSecondary]);
}
