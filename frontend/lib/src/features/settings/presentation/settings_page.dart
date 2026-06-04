import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';
import 'package:fafu/src/features/creators/presentation/creator_application_page.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';
  static const routePath = '/settings';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _locationSharing = true;

  Future<void> _showMapDataLicenses() async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MapConfig.attributionTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                MapConfig.attributionSummary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SettingsTile(
                icon: Icons.public_outlined,
                title: 'OpenFreeMap',
                onTap: () => launchUrl(
                  Uri.parse(MapConfig.openFreeMapUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsTile(
                icon: Icons.map_outlined,
                title: 'OpenStreetMap copyright',
                onTap: () => launchUrl(
                  Uri.parse(MapConfig.openStreetMapCopyrightUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('Settings', style: theme.textTheme.displayMedium),
                ],
              ),
            ),
            Divider(color: AppColors.border, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsToggle(
                    icon: isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Dark Mode',
                    value: isDarkMode,
                    onChanged: (value) => ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Account section
                  Text(
                    'Account',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.interests_outlined,
                    title: 'Update Interests',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.verified_outlined,
                    title: 'Become a Creator',
                    onTap: () =>
                        context.pushNamed(CreatorApplicationPage.routeName),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Notifications section
                  Text(
                    'Notifications',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsToggle(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  _SettingsToggle(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    value: _emailNotifications,
                    onChanged: (v) => setState(() => _emailNotifications = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Privacy section
                  Text(
                    'Privacy',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsToggle(
                    icon: Icons.location_on_outlined,
                    title: 'Location Sharing',
                    value: _locationSharing,
                    onChanged: (v) => setState(() => _locationSharing = v),
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // About section
                  Text(
                    'About',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    trailing: Text('1.0.0', style: theme.textTheme.labelMedium),
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.map_outlined,
                    title: MapConfig.attributionTitle,
                    onTap: _showMapDataLicenses,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Logout
                  AppButton(
                    label: 'Log Out',
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(onboardingCompleteKey);
                      if (context.mounted) context.go('/');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accentPrimary,
          ),
        ],
      ),
    );
  }
}
