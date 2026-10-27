import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

enum FafoToastKind { success, error, info }

/// The app's one snackbar. Use these instead of a raw SnackBar so every
/// confirmation and error looks and moves the same:
///
///   ScaffoldMessenger.of(context).toast('Defaults saved.');
///   messenger.toastError(e);
///   showFafoToast(context, 'Profile still loading…', kind: FafoToastKind.info);
extension FafoToastMessenger on ScaffoldMessengerState {
  void toast(String message, {FafoToastKind kind = FafoToastKind.success}) {
    switch (kind) {
      case FafoToastKind.success:
        HapticFeedback.lightImpact();
      case FafoToastKind.error:
        HapticFeedback.heavyImpact();
      case FafoToastKind.info:
        HapticFeedback.selectionClick();
    }
    // One at a time: a new toast replaces the old one instead of queueing.
    removeCurrentSnackBar();
    showSnackBar(
      SnackBar(
        content: _FafoToast(message: message, kind: kind, onTap: hideCurrentSnackBar),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        // Room for the offset shadow and the tilt on entry.
        clipBehavior: Clip.none,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        duration: Duration(milliseconds: kind == FafoToastKind.error ? 4000 : 2600),
      ),
    );
  }

  /// Error toast with the friendly copy for [error].
  void toastError(Object error) => toast(friendlyErrorMessage(error), kind: FafoToastKind.error);
}

void showFafoToast(BuildContext context, String message, {FafoToastKind kind = FafoToastKind.success}) =>
    ScaffoldMessenger.of(context).toast(message, kind: kind);

class _FafoToast extends StatelessWidget {
  const _FafoToast({required this.message, required this.kind, required this.onTap});

  final String message;
  final FafoToastKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (String label, Color badge, IconData icon) = switch (kind) {
      FafoToastKind.success => ('Done', AppColors.accentPrimary, Icons.check_rounded),
      FafoToastKind.error => ('Nope', AppColors.signalRed, Icons.priority_high_rounded),
      FafoToastKind.info => ('Heads up', AppColors.textPrimary, Icons.info_outline_rounded),
    };
    final card = Semantics(
      liveRegion: true,
      label: '$label. $message',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppChrome.rowRadius),
            border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
            boxShadow: AppChrome.cardShadowSoft,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badge,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: AppChrome.outlineWidth),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  // Info's badge flips with the theme; the others sit on blue or red.
                  color: kind == FafoToastKind.info ? AppColors.bgPrimary : AppColors.onAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FafoEyebrow(
                      label,
                      fontSize: 10,
                      color: kind == FafoToastKind.error ? AppColors.signalRed : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(14.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
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
