import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/profile/presentation/edit_profile_page.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// The fixed header on every screen: paper, no line, no shadow. Left is the
/// FaFo logo on Home and a round back button everywhere else; centre is your
/// photo with an "Edit" pill (opens Edit profile); right is the settings gear,
/// blue while you're on Settings.
class FafoAppHeader extends ConsumerWidget {
  const FafoAppHeader({super.key, this.onBack, this.onLogo, this.onSettings = true});

  /// Shows the back button. Null shows the logo.
  final VoidCallback? onBack;

  /// Logo tap (Home scrolls to the top).
  final VoidCallback? onLogo;

  /// False while on Settings: the gear turns blue and does nothing.
  final bool onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: SizedBox(
        height: 66,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 56,
              child: Align(
                alignment: Alignment.center,
                child: onBack != null
                    ? FafoBackButton(onTap: onBack)
                    : _Logo(onTap: onLogo),
              ),
            ),
            Expanded(
              child: Center(
                child: _Me(
                  photoUrl: profile?.photoUrl,
                  onTap: () => showEditProfileSheet(context),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 56,
              child: Align(
                alignment: Alignment.center,
                child: FafoRoundButton(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  active: !onSettings,
                  onTap: onSettings ? () => context.push(SettingsPage.routePath) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'FaFo home',
      child: AppPressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: ExcludeSemantics(
            child: Text('F', style: AppTypography.display(24, color: AppColors.onAccent).copyWith(height: 1)),
          ),
        ),
      ),
    );
  }
}

/// 56px circular photo with a light ring and soft shadow, and the white
/// "Edit" pill overlapping its bottom edge.
class _Me extends StatelessWidget {
  const _Me({required this.photoUrl, required this.onTap});

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final shadowColor = dark ? Colors.black.withValues(alpha: 0.6) : AppColors.ink.withValues(alpha: 0.18);
    return Semantics(
      button: true,
      label: 'Edit profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 90,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              FafoProfilePhoto(photoUrl: photoUrl, size: 56, shadow: shadowColor),
              Positioned(
                bottom: -3,
                child: ExcludeSemantics(
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: dark ? Border.all(color: AppColors.darkBorder) : null,
                      boxShadow: [
                        BoxShadow(
                          color: dark ? Colors.black.withValues(alpha: 0.6) : AppColors.ink.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 13, color: AppColors.textPrimary),
                        const SizedBox(width: 5),
                        Text('Edit', style: AppTypography.ui(12.5, fontWeight: FontWeight.w600).copyWith(height: 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
