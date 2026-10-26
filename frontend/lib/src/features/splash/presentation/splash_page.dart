import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/legal_links.dart';
import 'package:fafu/src/shared/widgets/fafo_wordmark.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/signup_page.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

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
    final legal = AppTypography.ui(12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
    final link = legal.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header, as on home: wordmark and a 2px rule.
              Container(
                padding: const EdgeInsets.only(top: 22, bottom: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FafoWordmark(style: AppTypography.display(28).copyWith(height: 1)),
                ),
              ),
              const Spacer(flex: 3),
              const FafoEyebrow('Right now'),
              const SizedBox(height: 12),
              const FafoDisplay('Skip the group chat.', fontSize: 62),
              const SizedBox(height: 12),
              Text(
                'Send one clear plan. Get one clear answer.',
                style: AppTypography.ui(15, fontWeight: FontWeight.w400),
              ),
              const Spacer(flex: 4),
              FafoPill(
                label: 'Get started',
                block: true,
                onPressed: () => context.push(SignupPage.routePath),
              ),
              const SizedBox(height: 10),
              FafoPill(
                label: 'I already have an account',
                primary: false,
                block: true,
                onPressed: () => context.push(LoginPage.routePath),
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: legal,
                  children: [
                    TextSpan(text: 'Terms', style: link, recognizer: _termsRecognizer),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacyRecognizer),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
