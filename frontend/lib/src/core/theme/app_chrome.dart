import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_colors.dart';

class AppChrome {
  const AppChrome._();

  static const double controlRadius = 10;
  static const double cardRadius = 14;
  static const double cardRadiusLg = 16;
  static const double chipRadius = 8;
  static const double outlineWidth = 1.5;

  static BorderSide get outlineSide =>
      BorderSide(color: AppColors.border, width: outlineWidth);

  static Border get outlineBorder =>
      Border.all(color: AppColors.border, width: outlineWidth);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadowSoft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 0,
      offset: const Offset(0, 3),
    ),
  ];
}
