import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fafu/src/core/theme/app_colors.dart';

/// The four type roles from the V3 brief:
/// - Display: Anton, ultra-condensed, always uppercase (uppercase the string at
///   the call site; keep it sentence case in code so screen readers read it).
/// - Timer: Archivo extra-bold with tabular figures, so digits don't jitter.
/// - UI text: Archivo, semibold to bold for buttons and row titles.
/// - Label: IBM Plex Mono, uppercase, tracked. Eyebrows and card header strips.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final tertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;

    return TextTheme(
      displayLarge: display(36, color: primary),
      displayMedium: display(22, color: primary),
      titleLarge: _ui(16, 22, FontWeight.w700, primary),
      bodyLarge: _ui(15, 22, FontWeight.w500, primary),
      bodyMedium: _ui(14, 20, FontWeight.w400, secondary),
      labelLarge: _ui(13, 16, FontWeight.w600, primary),
      labelMedium: _ui(12.5, 16, FontWeight.w500, secondary),
      labelSmall: _ui(12, 16, FontWeight.w500, tertiary),
    );
  }

  /// Display role. Headlines, plan titles, profile name, section titles.
  static TextStyle display(double fontSize, {Color? color}) {
    return GoogleFonts.anton(
      fontSize: fontSize,
      height: 0.92,
      letterSpacing: fontSize * 0.003,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textPrimary,
    );
  }

  /// Timer role. Always mm:ss with a short label under it.
  static TextStyle timer(double fontSize, {Color? color}) {
    return GoogleFonts.archivo(
      fontSize: fontSize,
      height: 1,
      letterSpacing: -fontSize * 0.01,
      fontWeight: FontWeight.w800,
      color: color ?? AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Label role. Uppercase the string at the call site.
  static TextStyle label({double fontSize = 11, Color? color}) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      height: 1.2,
      letterSpacing: fontSize * 0.12,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
    );
  }

  /// UI text role.
  static TextStyle ui(
    double fontSize, {
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return _ui(fontSize, fontSize * 1.45, fontWeight, color);
  }

  static TextStyle _ui(
    double fontSize,
    double height,
    FontWeight fontWeight,
    Color? color,
  ) {
    return GoogleFonts.archivo(
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
    );
  }
}
