import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';

/// Geometry-matching shimmer loading skeleton.
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const AppSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  const AppSkeleton.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  }) : shape = BoxShape.rectangle;

  const AppSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14.0,
  })  : borderRadius = AppSpacing.roundedSm,
        shape = BoxShape.rectangle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? AppColors.darkSurface : AppColors.lightBorder;
    final highlightColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? (borderRadius ?? AppSpacing.roundedSm)
              : null,
        ),
      ),
    );
  }
}
