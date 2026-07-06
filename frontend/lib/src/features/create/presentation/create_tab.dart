import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/create/presentation/creator_dashboard_page.dart';
import 'package:fafu/src/features/creators/data/creators_providers.dart';
import 'package:fafu/src/features/creators/presentation/creator_application_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

/// Gates the Create tab: verified creators see the create-event form, everyone
/// else sees a prompt to apply for creator verification.
class CreateTab extends ConsumerWidget {
  const CreateTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return profile.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
      ),
      // On error (e.g. not signed in / offline) fall back to the gate so the
      // user can still reach the apply flow rather than hitting a dead screen.
      error: (_, _) => const _CreatorGate(),
      data: (p) => p.isCreator
          ? const CreatorDashboardPage()
          : const _CreatorGateOrPending(),
    );
  }
}

/// For non-creators, decides between the apply prompt and a "review in progress"
/// state. If the user has already submitted an application that is still
/// pending, we must NOT show the form again — we show the pending state instead.
class _CreatorGateOrPending extends ConsumerWidget {
  const _CreatorGateOrPending();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(creatorApplicationProvider);

    return application.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
      ),
      // A 404 (no application yet) — and any transient error — falls through to
      // the apply gate. Re-submitting a still-pending application is harmless:
      // the backend rejects it with a 409 the form surfaces.
      error: (_, _) => const _CreatorGate(),
      data: (application) {
        final status = application.status.toLowerCase();
        // "pending"/"reapplied" mean the application is awaiting review, so the
        // user has already filled the form — show the pending state, not the form.
        if (status == 'pending' || status == 'reapplied') {
          return const _CreatorPending();
        }
        // "rejected"/"revoked" (or anything else) can re-apply.
        return const _CreatorGate();
      },
    );
  }
}

/// Shown when the user's creator application is submitted and awaiting review.
/// Replaces the apply gate so they aren't asked to fill the form again.
class _CreatorPending extends StatelessWidget {
  const _CreatorPending();

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
                  Icons.hourglass_top_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Application under review',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your creator application is in. We review every applicant personally and will reach out over email — no need to apply again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorGate extends StatelessWidget {
  const _CreatorGate();

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
                  Icons.verified_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Hosting needs verification',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Only verified creators can publish events. Apply once and we\'ll reach out over email.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Become a creator',
                variant: AppButtonVariant.featured,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreatorApplicationPage(),
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
