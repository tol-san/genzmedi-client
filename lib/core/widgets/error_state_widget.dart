import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';

/// Standard visual error state placeholder with a retry action button.
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String retryText;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.retryText = 'Try Again',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.space24),
              AppButton(
                text: retryText,
                onPressed: onRetry,
                isFullWidth: false,
                size: AppButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
