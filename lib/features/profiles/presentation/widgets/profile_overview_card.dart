import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/profiles/presentation/widgets/profile_stat_widget.dart';

/// Shared profile hero used by both personal and public profiles.
///
/// It keeps identity, social proof, interests, and primary actions in one
/// visually connected surface while allowing each screen to own its behavior.
class ProfileOverviewCard extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final String postCount;
  final String followersCount;
  final String followingCount;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final List<String> interests;
  final Widget primaryAction;
  final VoidCallback onShare;

  const ProfileOverviewCard({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.isVerified = false,
    required this.postCount,
    required this.followersCount,
    required this.followingCount,
    this.onFollowersTap,
    this.onFollowingTap,
    this.interests = const [],
    required this.primaryAction,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.navyBorder : AppColors.lightBorder;
    final primaryText = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: AppSpacing.space8,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryCrimson, Color(0xFFFF6B77)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProfileAvatar(
                      name: displayName,
                      avatarUrl: avatarUrl,
                      isVerified: isVerified,
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(
                            color: isDark
                                ? AppColors.navyBorder
                                : AppColors.lightBorderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ProfileStatWidget(
                                count: postCount,
                                label: 'Posts',
                                compact: true,
                              ),
                            ),
                            _StatDivider(color: border),
                            Expanded(
                              child: ProfileStatWidget(
                                count: followersCount,
                                label: 'Followers',
                                onTap: onFollowersTap,
                                compact: true,
                              ),
                            ),
                            _StatDivider(color: border),
                            Expanded(
                              child: ProfileStatWidget(
                                count: followingCount,
                                label: 'Following',
                                onTap: onFollowingTap,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: AppSpacing.space4),
                      const Tooltip(
                        message: 'Verified creator',
                        child: Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: AppColors.signalMint,
                        ),
                      ),
                    ],
                  ],
                ),
                if (bio != null && bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    bio!.trim(),
                    style: AppTypography.bodySmall.copyWith(
                      color: secondaryText,
                      height: 1.45,
                    ),
                  ),
                ],
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space16),
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space8,
                    children: interests
                        .map(
                          (interest) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.primarySoft,
                              borderRadius: AppSpacing.roundedFull,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.navyBorder
                                    : AppColors.primaryCrimson.withValues(
                                        alpha: 0.12,
                                      ),
                              ),
                            ),
                            child: Text(
                              '#$interest',
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.primaryCrimson,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
                Row(
                  children: [
                    Expanded(child: primaryAction),
                    const SizedBox(width: AppSpacing.space8),
                    Tooltip(
                      message: 'Copy profile link',
                      child: Material(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        borderRadius: AppSpacing.roundedMd,
                        child: InkWell(
                          onTap: onShare,
                          borderRadius: AppSpacing.roundedMd,
                          child: Container(
                            width: AppSpacing.minTouchTarget,
                            height: AppSpacing.minTouchTarget,
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(color: border),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.ios_share_rounded,
                              size: 19,
                              color: primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isVerified;

  const _ProfileAvatar({
    required this.name,
    required this.avatarUrl,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(
              color: AppColors.primaryCrimson.withValues(alpha: 0.28),
              width: 2,
            ),
          ),
          child: AppAvatar(name: name, size: 72, imageUrl: avatarUrl),
        ),
        if (isVerified)
          Positioned(
            right: -2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 20,
                color: AppColors.signalMint,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  final Color color;

  const _StatDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: color);
  }
}
