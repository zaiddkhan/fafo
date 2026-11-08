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
import 'package:fafu/src/features/notifications/data/live_timers.dart';
import 'package:fafu/src/features/notifications/data/push_service.dart';
import 'package:fafu/src/features/settings/presentation/quick_defaults.dart';
import 'package:fafu/src/features/settings/presentation/faq_sheet.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/friends/presentation/add_friends_sheet.dart';
import 'package:fafu/src/features/home/presentation/app_header.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/location_search_sheet.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/features/notifications/data/notification_nag.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.focus});

  static const routeName = 'settings';
  static const routePath = '/settings';

  /// Deep-linked setting to wash blue on arrival (Profile's Theme and
  /// Notifications tiles).
  final String? focus;
  static const focusTheme = 'theme';
  static const focusNotifications = 'notifications';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

/// SharedPreferences key for the per-device push opt-out.
const _pushEnabledKey = 'push_notifications_enabled';

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _busy = false;
  bool _syncing = false;
  int? _syncedAt;
  String? _highlight;

  /// Tracks the in-flight push registration so we can show a brief spinner
  /// without fully locking the toggle (see [_setPushNotifications]).
  bool _pushBusy = false;

  @override
  void initState() {
    super.initState();
    _highlight = widget.focus;
    if (_highlight != null) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _highlight = null);
      });
    }
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _pushNotifications = prefs.getBool(_pushEnabledKey) ?? true;
        _syncedAt = prefs.getInt(contactsSyncedAtKey);
      });
    });
  }

  Future<void> _resync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final ok = await resyncContacts(ref);
    if (mounted) {
      setState(() {
        _syncing = false;
        if (ok) _syncedAt = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _inviteFriend() async {
    String link = 'https://getfafo.app';
    try {
      link = (await ref.read(friendsRepositoryProvider).getReferralCode()).shareUrl;
    } catch (_) {}
    await SharePlus.instance.share(
      ShareParams(text: 'I’m on FaFo. Send me a plan and I’ll send you one. $link'),
    );
  }

  Future<void> _logOut() async {
    final sure = await showFafoModal<bool>(
      context,
      title: 'Log out of FaFo?',
      message: 'You’ll need your number and a code to get back in. Your friends and plans stay put.',
      actions: const [
        FafoModalAction('Log out', true, primary: true),
        FafoModalAction('Cancel', false),
      ],
    );
    if (sure != true) return;
    await _signOutLocally();
    if (mounted) context.go('/');
  }

  Future<void> _openNotifications() => showFafoSheet<void>(
    context,
    title: 'Notifications',
    builder: (_) => StatefulBuilder(
      builder: (context, setSheet) => FafoSheetBody(
        children: [
          FafoListRow(
            title: 'Allow notifications',
            subtitle: 'Change in your phone settings',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ref.read(notificationNagProvider) ? 'Off' : 'On',
                  style: AppTypography.ui(14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward, size: 17, color: AppColors.textPrimary),
              ],
            ),
            onTap: () => ref.read(notificationNagProvider.notifier).openSettings(),
          ),
          if (FeatureFlags.extraSettings)
          FafoListRow(
            title: 'Plans on this phone',
            subtitle: _pushBusy ? 'Updating…' : 'Nudges, answers and go time',
            trailing: FafoSwitch(
              value: _pushNotifications,
              label: 'Plans on this phone',
              onChanged: (v) async {
                // _setPushNotifications flips the value synchronously before
                // its first await, so redraw the sheet straight after.
                final work = _setPushNotifications(v);
                setSheet(() {});
                await work;
                if (context.mounted) setSheet(() {});
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openBlocked() => showFafoSheet<void>(
    context,
    title: 'Blocked users',
    builder: (_) => const _BlockedUsers(),
  );

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
    await LiveTimers.endAll();
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
    final List<String> answers;
    if (FeatureFlags.exitSurveys) {
      final a = await _negativeAnswers('Delete account?');
      if (a == null) return;
      answers = a;
    } else {
      final sure = await showFafoModal<bool>(
        context,
        title: 'Delete your account?',
        message: 'This can’t be undone. You lose:',
        body: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in const [
                'Your friends and groups',
                'Every plan and side quest history',
                'Your @username, which someone else can take',
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('•  $line', style: AppTypography.ui(14.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
        actions: const [
          FafoModalAction('Delete account', true, danger: true),
          FafoModalAction('Keep my account', false),
        ],
      );
      if (sure != true) return;
      answers = const [];
    }
    setState(() => _busy = true);
    try {
      await ref.read(usersRepositoryProvider).deleteAccount(answers: answers);
      await _signOutLocally();
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      FafoToasts.show(e.message, kind: FafoToastKind.error);
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
    final themeMode = ref.watch(themeModeControllerProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final selectedArea = ref.watch(selectedAreaProvider);
    final isCreator = profile?.isCreator ?? false;
    // A submitted-but-unreviewed application means the user already filled the
    // form: offer a "pending" tile instead of inviting them to apply again.
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

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBody: true,
      bottomNavigationBar: const FafoPageMenu(index: 2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: FafoAppHeader(onBack: () => context.pop(), onSettings: false),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, FafoBottomNav.clearance(context)),
              children: [
                const FafoDisplay('Settings'),
                const FafoSectionLabel('App', top: 26, bottom: 4),
                _Wash(
                  on: _highlight == SettingsPage.focusNotifications,
                  child: _SettingsTile(icon: Icons.notifications_none, title: 'Notifications', onTap: _openNotifications),
                ),
                // Light by default; System follows the phone.
                if (FeatureFlags.inAppThemeSwitch)
                  _Wash(
                    on: _highlight == SettingsPage.focusTheme,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 12, 2, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Theme', style: AppTypography.ui(16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final (mode, label) in const [
                                (ThemeMode.system, 'System'),
                                (ThemeMode.light, 'Light'),
                                (ThemeMode.dark, 'Dark'),
                              ]) ...[
                                if (mode != ThemeMode.system) const SizedBox(width: 8),
                                Expanded(
                                  child: FafoFilterChip(
                                    label: label,
                                    selected: themeMode == mode,
                                    onTap: () => ref.read(themeModeControllerProvider.notifier).setThemeMode(mode),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (FeatureFlags.extraSettings && profile != null) QuickDefaults(profile: profile),

                const FafoSectionLabel('People', top: 30, bottom: 4),
                _SettingsTile(
                  icon: Icons.ios_share_rounded,
                  title: 'Invite a friend',
                  subtitle: 'Share FaFo on WhatsApp or anywhere',
                  trailing: Icon(Icons.ios_share_rounded, size: 19, color: AppColors.textSecondary),
                  onTap: _inviteFriend,
                ),
                _SettingsTile(
                  icon: Icons.sync,
                  title: 'Re-sync contacts',
                  subtitle: _syncing ? 'Syncing…' : (_syncedAt == null ? 'Never synced' : 'Last synced ${_ago(_syncedAt!)}'),
                  trailing: _syncing
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                      : Icon(Icons.sync_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: _resync,
                ),
                _SettingsTile(icon: Icons.block, title: 'Blocked users', onTap: _openBlocked),
                // Parked with the map (V3 brief 1.2): area re-centring.
                if (FeatureFlags.map)
                  _SettingsTile(
                    icon: Icons.place_outlined,
                    title: 'Change Area',
                    subtitle: areaLabel,
                    onTap: _changeArea,
                  ),
                // Creators publish events; parked with events (V3 brief 1.3).
                if (FeatureFlags.events && !isCreator)
                  creatorApplicationPending
                      ? _SettingsTile(
                          icon: Icons.hourglass_top_outlined,
                          title: 'Creator application pending',
                          onTap: () => FafoToasts.show('Your creator application is under review. We\'ll reach out over email.', kind: FafoToastKind.info),
                        )
                      : _SettingsTile(
                          icon: Icons.verified_outlined,
                          title: 'Become a Creator',
                          onTap: () => context.pushNamed(CreatorApplicationPage.routeName),
                        ),

                const FafoSectionLabel('Help', top: 30, bottom: 4),
                _SettingsTile(icon: Icons.help_outline, title: 'Help and FAQ', onTap: () => showFaqSheet(context)),
                _SettingsTile(icon: Icons.flag_outlined, title: 'Report a problem', onTap: () => reportProblem(context)),
                _SettingsTile(icon: Icons.shield_outlined, title: 'Privacy policy', onTap: () => openExternalUrl(context, privacyUrl)),
                _SettingsTile(icon: Icons.description_outlined, title: 'Terms of service', onTap: () => openExternalUrl(context, termsUrl)),
                if (FeatureFlags.map)
                  _SettingsTile(icon: Icons.map_outlined, title: MapConfig.attributionTitle, onTap: _showMapDataLicenses),

                const SizedBox(height: 30),
                FafoQuietLinks(
                  links: [
                    ('Log out', _logOut, false),
                    (_busy ? 'Deleting…' : 'Delete account', _busy ? null : _deleteAccount, true),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'FaFo 1.0.0',
                  textAlign: TextAlign.center,
                  style: AppTypography.label(fontSize: 11, color: AppColors.textSecondary).copyWith(letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "2h ago", "just now".
String _ago(int millis) {
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(millis));
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// A 2.4 second blue wash on a setting you were sent to.
class _Wash extends StatelessWidget {
  const _Wash({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        color: on ? AppColors.accentPrimary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// Blocked users with Unblock. Unblocking doesn't make you friends again.
class _BlockedUsers extends ConsumerStatefulWidget {
  const _BlockedUsers();

  @override
  ConsumerState<_BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<_BlockedUsers> {
  final Set<String> _busy = {};

  Future<void> _unblock(PublicUserResponse user) async {
    setState(() => _busy.add(user.uid));
    try {
      await ref.read(friendsRepositoryProvider).unblockUser(user.uid, answers: const []);
      ref.invalidate(blockedUsersProvider);
      FafoToasts.show('${user.displayName.split(' ').first} is unblocked.');
    } catch (e) {
      FafoToasts.error(e);
    } finally {
      if (mounted) setState(() => _busy.remove(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedUsersProvider);
    return FafoSheetBody(
      children: [
        ...blocked.when(
          loading: () => const [Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))],
          error: (e, _) => [Text(friendlyErrorMessage(e), style: AppTypography.ui(14, color: AppColors.errorText))],
          data: (items) => [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 2),
                child: Text('No one’s blocked.', style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
              ),
            for (final b in items)
              FafoListRow(
                title: b.user.displayName,
                subtitle: '@${b.user.username}',
                leading: FafoAvatar(name: b.user.displayName, photoUrl: b.user.photoUrl, size: FafoAvatarSize.md),
                trailing: FafoPill(
                  label: 'Unblock',
                  small: true,
                  height: 36,
                  primary: false,
                  busy: _busy.contains(b.user.uid),
                  onPressed: () => _unblock(b.user),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A settings row: label (and a quiet line under it) plus an arrow. No
/// values on the index, no divider. [icon] is kept for the parked layout but
/// not drawn.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.ui(16, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.ui(12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ?? Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: 17),
          ],
        ),
      ),
    );
  }
}
