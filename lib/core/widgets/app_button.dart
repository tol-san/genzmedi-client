import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

/// Standard minimal customizable button for GenZ Media.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final IconData? icon;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.icon,
    this.borderRadius,
  });

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.icon,
    this.borderRadius,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.prefixIcon,
    this.suffixIcon,
    this.icon,
    this.borderRadius,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.icon,
    this.borderRadius,
  }) : variant = AppButtonVariant.destructive;

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 40.0;
      case AppButtonSize.medium:
        return 48.0;
      case AppButtonSize.large:
        return 54.0;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.space12);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.space20);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.space24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDark ? AppColors.textPrimaryDark : AppColors.buttonDark;
        foregroundColor = isDark ? AppColors.midnightNavy : AppColors.textInverse;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        foregroundColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        borderSide = BorderSide(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
          width: 1.0,
        );
        break;
      case AppButtonVariant.ghost:
        backgroundColor = AppColors.transparent;
        foregroundColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.textInverse;
        break;
    }

    final effectivePrefixIcon = prefixIcon ??
        (icon != null
            ? Icon(
                icon,
                size: size == AppButtonSize.small ? 18.0 : 20.0,
                color: foregroundColor,
              )
            : null);

    final effectiveRadius = borderRadius ?? AppSpacing.roundedSm;

    final buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
        ] else ...[
          if (effectivePrefixIcon != null) ...[
            effectivePrefixIcon,
            const SizedBox(width: AppSpacing.space8),
          ],
          Text(
            text,
            style: AppTypography.buttonText.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: AppSpacing.space8),
            suffixIcon!,
          ],
        ],
      ],
    );

    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: onPressed == null ? backgroundColor.withValues(alpha: 0.4) : backgroundColor,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: effectiveRadius,
          splashColor: foregroundColor.withValues(alpha: 0.1),
          child: Container(
            padding: _padding,
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
            ),
            alignment: Alignment.center,
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}
