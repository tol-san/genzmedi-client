import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/features/communities/data/models/community_models.dart';

class CommunityCardWidget extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback? onTap;

  const CommunityCardWidget({
    super.key,
    required this.community,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              // Avatar or Default Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppSpacing.roundedSm,
                ),
                clipBehavior: Clip.antiAlias,
                child: community.avatarUrl != null &&
                        community.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: community.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primaryCrimson,
                          size: 26,
                        ),
                      )
                    : const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primaryCrimson,
                        size: 26,
                      ),
              ),
              const SizedBox(width: AppSpacing.space16),

              // Title, Metadata, Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            community.name,
                            style: AppTypography.label.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: community.isPrivate
                                ? AppColors.warning
                                    .withValues(alpha: 0.15)
                                : AppColors.signalMint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                community.isPrivate
                                    ? Icons.lock_outline_rounded
                                    : Icons.public_rounded,
                                size: 10,
                                color: community.isPrivate
                                    ? AppColors.warning
                                    : AppColors.signalMint,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                community.isPrivate ? 'Private' : 'Public',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: community.isPrivate
                                      ? AppColors.warning
                                      : AppColors.signalMint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${community.memberCount} ${community.memberCount == 1 ? 'member' : 'members'} · ${community.postCount} posts',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryCrimson,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (community.description != null &&
                        community.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
