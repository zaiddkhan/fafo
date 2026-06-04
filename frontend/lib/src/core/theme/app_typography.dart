import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fafu/src/core/theme/app_colors.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: _style(28, 36, FontWeight.w800),
      displayMedium: _style(18, 24, FontWeight.w700),
      titleLarge: _style(16, 22, FontWeight.w600),
      bodyLarge: _style(14, 20, FontWeight.w500),
      bodyMedium: _style(
        14,
        20,
        FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelLarge: _style(12, 16, FontWeight.w500),
      labelMedium: _style(
        12,
        16,
        FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: _style(
        12,
        16,
        FontWeight.w500,
        color: AppColors.textTertiary,
      ),
    );
  }

  static TextStyle _style(
    double fontSize,
    double height,
    FontWeight fontWeight, {
    Color? color,
  }) {
    return GoogleFonts.tomorrow(
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
    );
  }
}
