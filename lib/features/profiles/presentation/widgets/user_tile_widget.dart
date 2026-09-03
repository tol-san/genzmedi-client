import 'package:flutter/material.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_button.dart';

class UserTileWidget extends StatelessWidget {
  final UserModel user;
  final bool isFollowing;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onFollowToggle;

  const UserTileWidget({
    super.key,
    required this.user,
    this.isFollowing = false,
    this.isCurrentUser = false,
    this.onTap,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: user.displayName ?? user.username,
              size: 48,
              imageUrl: user.avatarUrl,
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName ?? user.username,
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.signalMint,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isCurrentUser) ...[
              const SizedBox(width: AppSpacing.space8),
              SizedBox(
                width: 104,
                child: isFollowing
                    ? AppButton.secondary(
                        text: 'Following',
                        size: AppButtonSize.small,
                        borderRadius: AppSpacing.roundedMd,
                        onPressed: onFollowToggle,
                      )
                    : AppButton(
                        text: 'Follow',
                        size: AppButtonSize.small,
                        borderRadius: AppSpacing.roundedMd,
                        onPressed: onFollowToggle,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
