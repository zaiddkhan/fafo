import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/services/shared_preferences_provider.dart';

const appThemeModePreferenceKey = 'app_theme_mode';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // V3 follows the phone's setting; the saved choice only applies while the
    // in-app switch is un-parked.
    if (!FeatureFlags.inAppThemeSwitch) return ThemeMode.system;
    final savedMode = ref
        .watch(sharedPreferencesProvider)
        .maybeWhen(
          data: (prefs) => prefs.getString(appThemeModePreferenceKey),
          orElse: () => null,
        );
    return _themeModeFromName(savedMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    state = mode;

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(appThemeModePreferenceKey, mode.name);
  }

  ThemeMode _themeModeFromName(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
