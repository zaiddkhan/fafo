import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/services/deep_link_handler.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_theme.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';

class FafoApp extends ConsumerStatefulWidget {
  const FafoApp({super.key});

  @override
  ConsumerState<FafoApp> createState() => _FafoAppState();
}

class _FafoAppState extends ConsumerState<FafoApp> {
  DeepLinkHandler? _deepLinks;

  @override
  void initState() {
    super.initState();
    // Start listening for platform deep links once the router is built. Deferred
    // to the first frame so navigating from a cold-start link has a router ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deepLinks = DeepLinkHandler(ref.read(appRouterProvider))..start();
    });
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    AppColors.setThemeMode(themeMode);

    return MaterialApp.router(
      title: 'FaFo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
