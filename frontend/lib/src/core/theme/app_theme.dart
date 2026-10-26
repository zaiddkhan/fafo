import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textTheme = AppTypography.textTheme(brightness);

    final paper = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final card = isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
    final edge = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hair = isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary;
    final soft = isDark ? AppColors.darkSoftLine : AppColors.lightSoftLine;
    // Primary pills invert in dark mode: light fill, ink text.
    final primaryFill = isDark ? AppColors.darkTextPrimary : AppColors.ink;
    final onPrimaryFill = isDark ? AppColors.ink : AppColors.lightBgSecondary;

    final outline = BorderSide(color: edge, width: AppChrome.outlineWidth);
    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppChrome.pillRadius),
    );
    final buttonText = AppTypography.ui(15, fontWeight: FontWeight.w700);
    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: text, width: AppChrome.outlineWidth),
    );

    return base.copyWith(
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      textTheme: textTheme,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
            primary: AppColors.accentPrimary,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.accentSecondary,
            onSecondary: AppColors.onAccent,
            error: AppColors.signalRed,
            surface: card,
            onSurface: text,
            outline: edge,
            outlineVariant: hair,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.displayMedium,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppChrome.cardRadius),
          side: outline,
        ),
      ),
      dividerColor: hair,
      dividerTheme: DividerThemeData(color: hair, thickness: 1, space: 1),
      // Text fields are a single underline, as in the composer.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.accentPrimary,
            width: AppChrome.outlineWidth,
          ),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelLarge,
      ),
      // Buttons: full-radius pills, no shadows.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: onPrimaryFill,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: pillShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: onPrimaryFill,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: pillShape,
          textStyle: buttonText,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: BorderSide(color: primaryFill, width: AppChrome.outlineWidth),
          shape: pillShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          textStyle: AppTypography.ui(14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: AppColors.accentPrimary,
        labelStyle: AppTypography.ui(15, color: text),
        secondaryLabelStyle: AppTypography.ui(15, color: AppColors.onAccent),
        checkmarkColor: AppColors.onAccent,
        side: BorderSide(color: soft, width: AppChrome.softOutlineWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppChrome.chipRadius),
        ),
      ),
      // Sheets, not pages: paper background, rounded top.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: paper,
        modalBackgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : AppColors.ink.withValues(alpha: 0.42),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppChrome.cardRadius),
          side: outline,
        ),
        titleTextStyle: textTheme.displayMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accentPrimary,
        linearTrackColor: hair,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryFill;
          return card;
        }),
        checkColor: WidgetStatePropertyAll(onPrimaryFill),
        side: BorderSide(color: text, width: AppChrome.outlineWidth),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onAccent;
          }
          return card;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentPrimary;
          }
          return text;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return text;
        }),
      ),
    );
  }
}
