import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Standard typography tokens for GenZ Media based on Inter font family.
abstract class AppTypography {
  static TextStyle _inter({
    required double fontSize,
    required double height,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        height: height / fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle get display => _inter(
        fontSize: 32,
        height: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get headingLarge => _inter(
        fontSize: 28,
        height: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      );

  static TextStyle get heading => _inter(
        fontSize: 24,
        height: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get title => _inter(
        fontSize: 20,
        height: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get bodyLarge => _inter(
        fontSize: 17,
        height: 25,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get body => _inter(
        fontSize: 16,
        height: 24,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => _inter(
        fontSize: 14,
        height: 20,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get label => _inter(
        fontSize: 14,
        height: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get caption => _inter(
        fontSize: 12,
        height: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get buttonText => _inter(
        fontSize: 15,
        height: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );
}
