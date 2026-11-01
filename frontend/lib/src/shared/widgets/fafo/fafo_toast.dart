import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';

enum FafoToastKind { success, error, info }

/// The app's one toast for confirmations, errors and heads-ups. Drawn by
/// [FafoToastHost] above the navigator, so it shows over sheets and dialogs
/// too, and drops in from the top, clear of the keyboard and the bottom nav.
///
///   ScaffoldMessenger.of(context).toast('Defaults saved.');
///   messenger.toastError(e);
///   FafoToasts.show('Profile still loading…', kind: FafoToastKind.info);
class FafoToasts {
  const FafoToasts._();

  static final ValueNotifier<_Toast?> _current = ValueNotifier(null);
  static int _seq = 0;

  static void show(String message, {FafoToastKind kind = FafoToastKind.success}) {
    switch (kind) {
      case FafoToastKind.success:
        HapticFeedback.lightImpact();
      case FafoToastKind.error:
        HapticFeedback.heavyImpact();
      case FafoToastKind.info:
        HapticFeedback.selectionClick();
    }
    // One at a time: a new toast replaces the old one instead of queueing.
    _current.value = _Toast(++_seq, message, kind);
  }

  static void error(Object error) => show(friendlyErrorMessage(error), kind: FafoToastKind.error);

  static void hide() => _current.value = null;
}

/// Kept so call sites read like the snackbars they replaced.
extension FafoToastMessenger on ScaffoldMessengerState {
  void toast(String message, {FafoToastKind kind = FafoToastKind.success}) =>
      FafoToasts.show(message, kind: kind);

  /// Error toast with the friendly copy for [error].
  void toastError(Object error) => FafoToasts.error(error);
}

void showFafoToast(BuildContext context, String message, {FafoToastKind kind = FafoToastKind.success}) =>
    FafoToasts.show(message, kind: kind);

class _Toast {
  const _Toast(this.id, this.message, this.kind);

  final int id;
  final String message;
  final FafoToastKind kind;
}

/// Hosts toasts above [child] (the app's navigator). Mounted once, from
/// MaterialApp's builder.
class FafoToastHost extends StatefulWidget {
  const FafoToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<FafoToastHost> createState() => _FafoToastHostState();
}

class _FafoToastHostState extends State<FafoToastHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FafoToasts._current.addListener(_changed);
  }

  @override
  void dispose() {
    FafoToasts._current.removeListener(_changed);
    _timer?.cancel();
    super.dispose();
  }

  void _changed() {
    _timer?.cancel();
    final toast = FafoToasts._current.value;
    if (toast != null) {
      _timer = Timer(
        // About two seconds; errors get a beat longer to be read.
        Duration(milliseconds: toast.kind == FafoToastKind.error ? 3200 : 2200),
        () {
          if (FafoToasts._current.value?.id == toast.id) FafoToasts.hide();
        },
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final toast = FafoToasts._current.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: toast == null
                ? const SizedBox.shrink()
                : _FafoToast(key: ValueKey(toast.id), message: toast.message, kind: toast.kind),
          ),
        ),
      ],
    );
  }
}

class _FafoToast extends StatelessWidget {
  const _FafoToast({super.key, required this.message, required this.kind});

  final String message;
  final FafoToastKind kind;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    // One short sentence in an ink pill with a soft shadow (inverts in dark).
    final card = Semantics(
      liveRegion: true,
      label: message,
      child: GestureDetector(
        onTap: FafoToasts.hide,
        // Flick it away upwards.
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < 0) FafoToasts.hide();
        },
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryFill,
                borderRadius: BorderRadius.circular(AppChrome.pillRadius),
                boxShadow: dark
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -6)]
                    : [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.38), blurRadius: 28, offset: const Offset(0, 10), spreadRadius: -8),
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
              ),
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: AppColors.onPrimaryFill),
              ),
            ),
          ),
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return card;

    // Success and info pop in with a small tilt; errors shake no.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: kind == FafoToastKind.error ? 520 : 420),
      curve: kind == FafoToastKind.error ? Curves.linear : Curves.easeOutBack,
      child: card,
      builder: (context, t, child) {
        if (kind == FafoToastKind.error) {
          final dx = math.sin(t * math.pi * 6) * (1 - t) * 10;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        }
        return Transform.rotate(
          angle: (1 - t) * -0.06,
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
        );
      },
    );
  }
}
