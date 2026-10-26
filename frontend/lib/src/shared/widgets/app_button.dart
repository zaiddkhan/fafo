import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';

enum AppButtonVariant { primary, secondary, featured }

/// Pill button from the V3 brief. Primary: solid ink (inverts in dark mode).
/// Secondary: 2px ink outline, transparent. Buttons never get an offset shadow.
/// `featured` is kept for existing callers and renders as primary.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  bool get _isDisabled => onPressed == null;
  bool get _isPrimary => variant != AppButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: _isDisabled ? 0.35 : 1,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: _isPrimary ? AppColors.primaryFill : Colors.transparent,
          borderRadius: BorderRadius.circular(AppChrome.pillRadius),
          border: Border.all(
            color: AppColors.primaryFill,
            width: AppChrome.outlineWidth,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.ui(
            15,
            fontWeight: FontWeight.w700,
            color: _isPrimary ? AppColors.onPrimaryFill : AppColors.textPrimary,
          ).copyWith(height: 1),
        ),
      ),
    );

    return AppPressable(onTap: onPressed, child: button);
  }
}
