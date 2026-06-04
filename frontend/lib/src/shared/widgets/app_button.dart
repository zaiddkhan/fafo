import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';

enum AppButtonVariant { primary, secondary, featured }

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

  @override
  Widget build(BuildContext context) {
    final isRaised = !_isDisabled && variant != AppButtonVariant.secondary;
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF111111);
    final button = Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppChrome.controlRadius),
        border: _border,
        boxShadow: isRaised ? null : _shadow,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.displayMedium?.copyWith(color: _textColor),
      ),
    );

    if (!isRaised) {
      return AppPressable(onTap: onPressed, child: button);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(6, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(AppChrome.controlRadius),
                ),
              ),
            ),
          ),
          AppPressable(onTap: onPressed, child: button),
        ],
      ),
    );
  }

  Color get _backgroundColor {
    if (_isDisabled) return AppColors.bgTertiary;

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.accentPrimary;
      case AppButtonVariant.featured:
        return AppColors.accentPrimary;
      case AppButtonVariant.secondary:
        return AppColors.bgTertiary;
    }
  }

  Color get _textColor {
    if (_isDisabled) return AppColors.textTertiary;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.featured:
        return Colors.white;
      case AppButtonVariant.secondary:
        return AppColors.textPrimary;
    }
  }

  Border? get _border {
    return AppChrome.outlineBorder;
  }

  List<BoxShadow>? get _shadow {
    if (_isDisabled || variant == AppButtonVariant.secondary) return null;

    return AppChrome.cardShadowSoft;
  }
}
