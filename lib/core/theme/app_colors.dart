import 'package:flutter/material.dart';

/// Centralized color palette for GenZ Media.
/// Clean, minimal light aesthetic with selective brand accents (#F20518 Electric Crimson & #061A33 Midnight Navy).
abstract class AppColors {
  // Brand Accent (Used selectively for primary CTA, like heart, live badge)
  static const Color primaryCrimson = Color(0xFFF20518);
  static const Color primaryPressed = Color(0xFFD00415);
  static const Color primarySoft = Color(0xFFFFF0F1);
  static const Color primaryElectricBlue = Color(0xFF1877F2);

  // Minimal Clean Light Canvas & Surfaces
  static const Color lightCanvas = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFEAEAEA);
  static const Color lightBorderSubtle = Color(0xFFF3F4F6);

  // Dark Canvas (Reserved for Shorts & Dark Mode)
  static const Color midnightNavy = Color(0xFF061A33);
  static const Color darkSurface = Color(0xFF0B2545);
  static const Color darkSurfaceElevated = Color(0xFF0F3057);
  static const Color navyBorder = Color(0xFF133663);

  // Typography & Content Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Minimal Functional Accents
  static const Color signalMint = Color(0xFF10B981); // Clean emerald mint
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Neutral Button Fill
  static const Color buttonDark = Color(0xFF0F172A);
  static const Color buttonLight = Color(0xFFF1F5F9);

  // Overlay & Transparency
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x40FFFFFF);
  static const Color transparent = Colors.transparent;
}
