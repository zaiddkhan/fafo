import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = AppTypography.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.darkSurface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBgPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        titleTextStyle: textTheme.displayMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkBgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppChrome.cardRadius),
          side: AppChrome.outlineSide,
        ),
      ),
      dividerColor: AppColors.darkBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          borderSide: AppChrome.outlineSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          borderSide: AppChrome.outlineSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          borderSide: AppChrome.outlineSide,
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = AppTypography.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBgPrimary,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        titleTextStyle: textTheme.displayMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightBgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppChrome.cardRadius),
          side: AppChrome.outlineSide,
        ),
      ),
      dividerColor: AppColors.lightBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          borderSide: AppChrome.outlineSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          borderSide: AppChrome.outlineSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          borderSide: AppChrome.outlineSide,
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentPrimary;
          }
          return AppColors.lightBgSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentLight1;
          }
          return AppColors.lightBorder;
        }),
      ),
    );
  }
}
