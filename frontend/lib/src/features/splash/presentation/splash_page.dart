import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/utils/legal_links.dart';
import 'package:fafu/src/shared/widgets/fafo_wordmark.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/signup_page.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = 'splash';
  static const routePath = '/';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => openExternalUrl(context, termsUrl);
  late final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => openExternalUrl(context, privacyUrl);

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Brand
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.accentPrimary, AppColors.accentWarm],
                ).createShader(bounds),
                child: FafoWordmark(
                  style: theme.textTheme.displayMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Hero
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.textPrimary, AppColors.accentLight1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  'Discover\nwhat\'s happening\naround you',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'Events, late-night plans, and curated picks, all built around your vibe.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // CTAs
              AppButton(
                label: 'Get Started',
                variant: AppButtonVariant.featured,
                onPressed: () => context.push(SignupPage.routePath),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'I already have an account',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(LoginPage.routePath),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: theme.textTheme.labelSmall,
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      recognizer: _termsRecognizer,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      recognizer: _privacyRecognizer,
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
