import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_colors.dart';

/// Shape rules from the V3 brief: hard outlines and offset shadows. The offset
/// block means "raised or selected" and goes on cards and selected chips,
/// never on buttons. Offset shadows drop to none in dark mode.
class AppChrome {
  const AppChrome._();

  static const double controlRadius = 11;
  static const double cardRadius = 22;
  static const double cardRadiusLg = 22;
  static const double rowRadius = 16;
  static const double chipRadius = 11;
  static const double pillRadius = 99;
  static const double outlineWidth = 2;
  static const double softOutlineWidth = 1.5;

  static BorderSide get outlineSide =>
      BorderSide(color: AppColors.border, width: outlineWidth);

  static Border get outlineBorder =>
      Border.all(color: AppColors.border, width: outlineWidth);

  /// Unselected chips: soft line, no shadow.
  static Border get softBorder =>
      Border.all(color: AppColors.softLine, width: softOutlineWidth);

  /// Cards: 6px hard offset.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: AppColors.shadow, blurRadius: 0, offset: const Offset(6, 6)),
  ];

  /// Selected chips and the "I'm free rn" pill: 3px hard offset.
  static List<BoxShadow> get cardShadowSoft => [
    BoxShadow(color: AppColors.shadow, blurRadius: 0, offset: const Offset(3, 3)),
  ];
}
