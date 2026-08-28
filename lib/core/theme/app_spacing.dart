import 'package:flutter/material.dart';

/// Spacing, radius, duration, and touch target tokens for GenZ Media.
abstract class AppSpacing {
  // Spacing Grid (8dp base with 4dp fine adjustment)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Corner Radius Tokens
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;  // compact controls & buttons
  static const double radiusMd = 16.0;  // cards, video player & media containers
  static const double radiusLg = 24.0;  // bottom sheets & dialogs
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // BorderRadius helpers
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Minimum Touch Target
  static const double minTouchTarget = 48.0;

  // Motion & Animation Durations
  static const Duration durationMicro = Duration(milliseconds: 120);
  static const Duration durationFast = Duration(milliseconds: 180);
  static const Duration durationMedium = Duration(milliseconds: 240);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // Animation Curves
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveEntrance = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
}
