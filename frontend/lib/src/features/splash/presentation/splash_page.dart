import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The FaFo mark: blue rounded square, ink outline, offset.
                    Container(
                      width: 70,
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.ink, width: 2),
                        boxShadow: AppChrome.cardShadowSoft,
                      ),
                      child: ExcludeSemantics(
                        child: Text('F', style: AppTypography.display(40, color: AppColors.onAccent).copyWith(height: 1)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FafoDisplay('Plans in\nten minutes.', fontSize: 62),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Send one clear plan. Get one clear answer. No group chat.',
                        style: AppTypography.ui(16, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FafoPill(
                label: 'Get started',
                block: true,
                onPressed: () => context.push(SignupPage.routePath),
              ),
              const SizedBox(height: 6),
              FafoTextButton(
                label: 'I already have an account',
                onTap: () => context.push(LoginPage.routePath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
