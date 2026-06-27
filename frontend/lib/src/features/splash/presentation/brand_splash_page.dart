import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/services/shared_preferences_provider.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';

/// Branded launch splash: full-bleed blue, the "FAFO" wordmark and tagline.
/// Shown for a brief beat on cold start (covering the native launch window and
/// session restore) then routes to the app shell (onboarded) or the welcome
/// screen (new user). Kept visually continuous with the native launch screen,
/// which uses the same blue background.
class BrandSplashPage extends ConsumerStatefulWidget {
  const BrandSplashPage({super.key});

  static const routeName = 'brandSplash';
  static const routePath = '/splash';

  @override
  ConsumerState<BrandSplashPage> createState() => _BrandSplashPageState();
}

class _BrandSplashPageState extends ConsumerState<BrandSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _advanceTimer = Timer(const Duration(milliseconds: 2800), _advance);
  }

  void _advance() {
    if (!mounted) return;
    final isOnboarded =
        ref.read(sharedPreferencesProvider).value?.getBool(
          onboardingCompleteKey,
        ) ??
        false;
    context.go(
      isOnboarded ? MainShell.routePath : SplashPage.routePath,
    );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fixed brand blue — this screen is intentionally identical in light/dark
    // and matches the native launch background for a seamless start.
    return Scaffold(
      backgroundColor: AppColors.accentPrimary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wordmark. The squared "tomorrow" face echoes the blocky logo;
              // the hard offset shadow gives the extruded 3D look of the
              // original artwork.
              Text(
                'FAFO',
                style: GoogleFonts.tomorrow(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  height: 1,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      offset: Offset(4, 5),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'F*ck Around & Find Out',
                style: GoogleFonts.tomorrow(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
