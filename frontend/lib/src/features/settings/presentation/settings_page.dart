import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/auth_token_provider.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';
import 'package:fafu/src/features/creators/presentation/creator_application_page.dart';
import 'package:fafu/src/features/location/selected_area_controller.dart';
import 'package:fafu/src/features/notifications/data/push_service.dart';
import 'package:fafu/src/features/profile/presentation/edit_profile_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';
import 'package:fafu/src/shared/widgets/location_search_sheet.dart';

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
  bool _busy = false;

  Future<List<String>?> _negativeAnswers(String title) async {
    final controllers = List.generate(3, (_) => TextEditingController());
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Answer these questions to confirm this destructive action.'),
            const SizedBox(height: 12),
            TextField(controller: controllers[0], decoration: const InputDecoration(labelText: 'Why are you doing this?')),
            TextField(controller: controllers[1], decoration: const InputDecoration(labelText: 'What could have prevented this?')),
            TextField(controller: controllers[2], decoration: const InputDecoration(labelText: 'Anything else we should know?')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final answers = controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
              if (answers.length < 3) return;
              Navigator.of(context).pop(answers);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    for (final c in controllers) {
      c.dispose();
    }
    return result;
  }

  /// Fully signs the user out: clears local onboarding state, signs out of
  /// Firebase (otherwise the Dio interceptor silently re-fetches a token), and
  /// drops the cached auth token.
  Future<void> _signOutLocally() async {
    // Unregister the push token first, while the auth token is still valid.
    await ref.read(pushServiceProvider).unregister();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(onboardingCompleteKey);
    await FirebaseAuth.instance.signOut();
    ref.read(authTokenProvider.notifier).clearToken();
  }

  Future<void> _changeArea() async {
    final result = await showLocationSearchSheet(context);
    if (result == null) return;
    await ref.read(selectedAreaProvider.notifier).setArea(
          lat: result.lat,
          lng: result.lng,
          label: result.label,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Area set to ${result.label}. The map will re-centre.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final answers = await _negativeAnswers('Delete account?');
    if (answers == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(usersRepositoryProvider).deleteAccount(answers: answers);
      await _signOutLocally();
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    final selectedArea = ref.watch(selectedAreaProvider);
    final areaLabel = selectedArea == null
        ? 'Auto (GPS)'
        : selectedArea.label.split(',').first;

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
                    onTap: () {
                      final profile = ref.read(currentProfileProvider).value;
                      if (profile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile still loading…')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.place_outlined,
                    title: 'Change Area',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            areaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                      ],
                    ),
                    onTap: _changeArea,
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

                  AppButton(
                    label: _busy ? 'Deleting…' : 'Delete Account',
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy ? null : _deleteAccount,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Logout
                  AppButton(
                    label: 'Log Out',
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      await _signOutLocally();
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
