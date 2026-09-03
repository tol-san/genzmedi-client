import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

class SettingsTileWidget extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SettingsTileWidget({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDestructive
        ? AppColors.error
        : (iconColor ?? AppColors.primaryCrimson);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Icon(
                icon,
                size: 20,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppColors.error
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? AppColors.textMuted : AppColors.lightBorder,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  final String? heading;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    this.heading,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heading != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.space4,
              bottom: AppSpacing.space8,
            ),
            child: Text(
              heading!.toUpperCase(),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
        Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedLg,
            side: BorderSide(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 64,
                    color: isDark
                        ? AppColors.navyBorder.withValues(alpha: 0.6)
                        : AppColors.lightBorderSubtle,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
