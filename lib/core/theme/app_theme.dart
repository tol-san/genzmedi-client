import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

/// Central theme definitions for GenZ Media.
abstract class AppTheme {
  /// Clean, Minimalist Light Theme (Default)
  static ThemeData get lightTheme {
    final baseTextTheme = Typography.material2021().black;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      primaryColor: AppColors.primaryCrimson,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryCrimson,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryPressed,
        secondary: AppColors.signalMint,
        onSecondary: AppColors.textInverse,
        surface: AppColors.lightSurface,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.lightSurfaceElevated,
        error: AppColors.error,
        onError: AppColors.textInverse,
        outline: AppColors.lightBorder,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.display.copyWith(color: AppColors.textPrimaryLight),
        headlineLarge: AppTypography.headingLarge.copyWith(color: AppColors.textPrimaryLight),
        headlineMedium: AppTypography.heading.copyWith(color: AppColors.textPrimaryLight),
        titleLarge: AppTypography.title.copyWith(color: AppColors.textPrimaryLight),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.textPrimaryLight),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
        labelLarge: AppTypography.buttonText.copyWith(color: AppColors.textPrimaryLight),
        labelMedium: AppTypography.label.copyWith(color: AppColors.textPrimaryLight),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading.copyWith(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.transparent,
          systemNavigationBarColor: AppColors.lightSurface,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.textPrimaryLight,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.lightSurfaceElevated,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.caption.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.textPrimaryLight, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonDark,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
          textStyle: AppTypography.buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
          textStyle: AppTypography.buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.textPrimaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        errorMaxLines: 2,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondaryLight),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.lightBorder,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    final baseTextTheme = Typography.material2021().white;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.midnightNavy,
      primaryColor: AppColors.primaryCrimson,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCrimson,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primaryPressed,
        onPrimaryContainer: AppColors.textInverse,
        secondary: AppColors.signalMint,
        onSecondary: AppColors.midnightNavy,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        error: AppColors.error,
        onError: AppColors.textInverse,
        outline: AppColors.navyBorder,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.display.copyWith(color: AppColors.textPrimaryDark),
        headlineLarge: AppTypography.headingLarge.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: AppTypography.heading.copyWith(color: AppColors.textPrimaryDark),
        titleLarge: AppTypography.title.copyWith(color: AppColors.textPrimaryDark),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
        labelLarge: AppTypography.buttonText.copyWith(color: AppColors.textPrimaryDark),
        labelMedium: AppTypography.label.copyWith(color: AppColors.textPrimaryDark),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.midnightNavy,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading.copyWith(color: AppColors.textPrimaryDark),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.transparent,
          systemNavigationBarColor: AppColors.midnightNavy,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.midnightNavy,
        selectedItemColor: AppColors.primaryCrimson,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.midnightNavy,
        indicatorColor: AppColors.primaryCrimson.withValues(alpha: 0.15),
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              color: AppColors.primaryCrimson,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.caption.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryCrimson, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.navyBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.navyBorder,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryCrimson,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
          textStyle: AppTypography.buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
          side: const BorderSide(color: AppColors.navyBorder, width: 1.5),
          textStyle: AppTypography.buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.navyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.navyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.primaryCrimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        errorMaxLines: 2,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondaryDark),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        elevation: 16,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.navyBorder,
      ),
    );
  }
}
