import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';

class LegalSheetWidget extends StatelessWidget {
  final String title;
  final String content;

  const LegalSheetWidget({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LegalSheetWidget(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              borderRadius: AppSpacing.roundedFull,
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space20,
              vertical: AppSpacing.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
          ),

          // Content body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space20),
              child: Text(
                content,
                style: AppTypography.bodySmall.copyWith(
                  height: 1.6,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),

          // Bottom dismiss button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: AppButton(
              text: 'Got it',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
