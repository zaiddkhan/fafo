import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

/// Landing screen for a `/invite/<token>` deep link.
///
/// Placeholder for now: it acknowledges the invite and drops the user into the
/// app. The [token] is wired through so the real flow (resolve the inviter via
/// the backend and offer an Add Friend action) can be built on top without
/// touching routing or deep-link plumbing.
class InviteLandingPage extends StatelessWidget {
  const InviteLandingPage({required this.token, super.key});

  static const routeName = 'invite-landing';
  static const routePath = '/invite/:token';

  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPrimary,
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'You\'ve been invited to Fafo',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Jump in to discover what\'s popping near you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Continue',
                variant: AppButtonVariant.featured,
                onPressed: () => context.go(MainShell.routePath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
