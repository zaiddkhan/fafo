import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/services/deep_link_handler.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_theme.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

class FafoApp extends ConsumerStatefulWidget {
  const FafoApp({super.key});

  @override
  ConsumerState<FafoApp> createState() => _FafoAppState();
}

class _FafoAppState extends ConsumerState<FafoApp> {
  DeepLinkHandler? _deepLinks;
  Brightness? _brightness;

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

    // Static tokens need the effective brightness before the themes are built.
    // System mode reads the platform setting (MediaQuery from the root View).
    final brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    AppColors.setBrightness(brightness);
    // Widgets read the static tokens at build time, and const subtrees skip
    // rebuilds, so a theme change must repaint everything or parts keep the
    // old colours (cream-on-cream headers in Light on a dark phone).
    if (_brightness != null && _brightness != brightness) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildAll(context as Element);
      });
    }
    _brightness = brightness;

    return MaterialApp.router(
      title: 'FaFo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // Toasts sit above every route, sheets and dialogs included.
      builder: (context, child) => FafoToastHost(child: child!),
    );
  }
}

void _rebuildAll(Element root) {
  void mark(Element e) {
    e.markNeedsBuild();
    e.visitChildren(mark);
  }

  root.visitChildren(mark);
}
