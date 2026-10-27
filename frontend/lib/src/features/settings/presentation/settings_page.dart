import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/auth_token_provider.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';
import 'package:fafu/src/core/utils/legal_links.dart';
import 'package:fafu/src/features/creators/data/creators_providers.dart';
import 'package:fafu/src/features/creators/presentation/creator_application_page.dart';
import 'package:fafu/src/features/events/data/saved_events_controller.dart';
import 'package:fafu/src/features/location/selected_area_controller.dart';
import 'package:fafu/src/features/notifications/data/push_service.dart';
import 'package:fafu/src/features/profile/presentation/edit_profile_page.dart';
import 'package:fafu/src/features/settings/presentation/quick_defaults.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/location_search_sheet.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/features/notifications/data/notification_nag.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';
  static const routePath = '/settings';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

/// SharedPreferences key for the per-device push opt-out.
const _pushEnabledKey = 'push_notifications_enabled';

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _busy = false;

  /// Tracks the in-flight push registration so we can show a brief spinner
  /// without fully locking the toggle (see [_setPushNotifications]).
  bool _pushBusy = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() => _pushNotifications = prefs.getBool(_pushEnabledKey) ?? true);
    });
  }

  /// Push is a per-device setting: turning it off unregisters this device's FCM
  /// token (the backend stops sending here); turning it on re-registers. The
  /// choice is persisted so it survives restarts.
  Future<void> _setPushNotifications(bool enabled) async {
    // Optimistic: reflect the choice immediately and persist it. The toggle
    // stays interactive (we only show a small spinner) so it can never feel
    // "locked" while the slower permission/registration work runs.
    setState(() {
      _pushNotifications = enabled;
      _pushBusy = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pushEnabledKey, enabled);
      final push = ref.read(pushServiceProvider);
      final work = enabled ? push.initialize() : push.unregister();
      // A pending OS permission dialog or a slow network call must never keep
      // the spinner up forever — bound it so the UI always settles.
      await work.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // The preference is saved and the work continues in the background; just
      // stop the spinner and keep the user's optimistic choice.
    } catch (e) {
      if (mounted) {
        // Only roll back if the user hasn't flipped it again in the meantime.
        if (_pushNotifications == enabled) {
          setState(() => _pushNotifications = !enabled);
        }
        ScaffoldMessenger.of(context).toast('Couldn’t update notifications: ${friendlyErrorMessage(e)}', kind: FafoToastKind.error);
      }
    } finally {
      // Switching push off here is a choice: the "notifications are off" bar
      // shouldn't nag about it (and should come back if switched on again).
      if (mounted) {
        ref.read(notificationNagProvider.notifier).recheck();
        setState(() => _pushBusy = false);
      }
    }
  }

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
    // Drop device-local, account-scoped caches so they don't bleed into the
    // next account signed in on this device.
    await prefs.remove(savedEventIdsPreferenceKey);
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
      ScaffoldMessenger.of(context).toast('Area set to ${result.label}. The map will re-centre.');
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
      if (mounted) ScaffoldMessenger.of(context).toast(e.message, kind: FafoToastKind.error);
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
    final profile = ref.watch(currentProfileProvider).value;
    final selectedArea = ref.watch(selectedAreaProvider);
    final isCreator = ref.watch(currentProfileProvider).value?.isCreator ?? false;
    // A submitted-but-unreviewed application means the user already filled the
    // form — offer a "pending" tile instead of inviting them to apply again.
    final creatorApplicationPending = FeatureFlags.events && ref
        .watch(creatorApplicationProvider)
        .maybeWhen(
          data: (a) {
            final status = a.status.toLowerCase();
            return status == 'pending' || status == 'reapplied';
          },
          orElse: () => false,
        );
    final areaLabel = selectedArea == null
        ? 'Auto (GPS)'
        : selectedArea.label.split(',').first;

    return FafoFormPage(
      eyebrow: 'Profile',
      title: 'Settings',
      onBack: () => context.pop(),
                children: [
                  // V3 brief 2.4 follows the system; System stays the default.
                  if (FeatureFlags.inAppThemeSwitch) ...[
                    const _SectionLabel('Appearance'),
                    const SizedBox(height: 12),
                    FafoChipGrid(
                      children: [
                        for (final (mode, label) in const [
                          (ThemeMode.system, 'System'),
                          (ThemeMode.light, 'Light'),
                          (ThemeMode.dark, 'Dark'),
                        ])
                          FafoChip(
                            selected: themeMode == mode,
                            onTap: () => ref.read(themeModeControllerProvider.notifier).setThemeMode(mode),
                            child: Text(label),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (profile != null) ...[
                    const _SectionLabel('Quick defaults'),
                    QuickDefaults(profile: profile),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Account section
                  const _SectionLabel('Account'),
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit profile',
                    onTap: () {
                      final profile = ref.read(currentProfileProvider).value;
                      if (profile == null) {
                        ScaffoldMessenger.of(context).toast('Profile still loading…', kind: FafoToastKind.info);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
                      );
                    },
                  ),
                  // Parked with the map (V3 brief 1.2): area re-centring.
                  if (FeatureFlags.map)
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
                  // Creators publish events; parked with events (V3 brief 1.3).
                  if (FeatureFlags.events && !isCreator)
                    creatorApplicationPending
                        ? _SettingsTile(
                            icon: Icons.hourglass_top_outlined,
                            title: 'Creator application pending',
                            onTap: () =>
                                ScaffoldMessenger.of(context).toast('Your creator application is under review. We\'ll reach out over email.', kind: FafoToastKind.info),
                          )
                        : _SettingsTile(
                            icon: Icons.verified_outlined,
                            title: 'Become a Creator',
                            onTap: () => context
                                .pushNamed(CreatorApplicationPage.routeName),
                          ),
                  const SizedBox(height: AppSpacing.xl),

                  // Notifications section
                  const _SectionLabel('Notifications'),
                  _SettingsToggle(
                    icon: Icons.notifications_outlined,
                    title: 'Push notifications',
                    value: _pushNotifications,
                    loading: _pushBusy,
                    onChanged: _setPushNotifications,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Privacy section
                  const _SectionLabel('Privacy'),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy policy',
                    onTap: () => openExternalUrl(context, privacyUrl),
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of service',
                    onTap: () => openExternalUrl(context, termsUrl),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // About section
                  const _SectionLabel('About'),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'App version',
                    trailing: Text('1.0.0', style: theme.textTheme.labelMedium),
                    onTap: () {},
                  ),
                  if (FeatureFlags.map)
                  _SettingsTile(
                    icon: Icons.map_outlined,
                    title: MapConfig.attributionTitle,
                    onTap: _showMapDataLicenses,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  FafoPill(
                    label: 'Log out',
                    primary: false,
                    block: true,
                    onPressed: () async {
                      await _signOutLocally();
                      if (context.mounted) context.go('/');
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FafoInlineLink(
                      label: _busy ? 'Deleting…' : 'Delete account',
                      color: AppColors.signalRed,
                      onTap: _busy ? null : _deleteAccount,
                    ),
                  ),
                ],
    );
  }
}

/// Mono section label with a 2px rule above, as between profile sections.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.rule, width: 2)),
      ),
      child: FafoEyebrow(text, color: AppColors.textSecondary),
    );
  }
}

/// A list row in the V3 style: title, optional value, arrow, hairline.
/// [icon] is kept for the parked layout but not drawn (the prototype's rows
/// carry no icons).
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
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTypography.ui(15, fontWeight: FontWeight.w600)),
            ),
            trailing ?? Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: 16),
          ],
        ),
      ),
    );
  }
}

/// On/off setting as the Quick defaults checkbox row.
class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FafoCheckRow(
      title: title,
      subtitle: loading ? 'Updating…' : null,
      checked: value,
      onTap: loading || onChanged == null ? null : () => onChanged!(!value),
    );
  }
}
