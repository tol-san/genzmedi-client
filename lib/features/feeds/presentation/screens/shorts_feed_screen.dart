import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';

class ShortsFeedScreen extends StatelessWidget {
  const ShortsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Stack(
        children: [
          // Background / Video Stage Placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.midnightNavy,
                  AppColors.darkSurface,
                  AppColors.midnightNavy,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 48,
                      color: AppColors.primaryCrimson,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    'Shorts Video Feed',
                    style: AppTypography.heading.copyWith(color: AppColors.textInverse),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Swipe vertically to discover trending short-form video.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          ),

          // Right Side Action Buttons (Like, Comment, Bookmark, Share)
          Positioned(
            right: AppSpacing.space16,
            bottom: AppSpacing.space32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppAvatar(
                  name: 'Gen Z',
                  size: 48,
                  isOnline: true,
                ),
                const SizedBox(height: AppSpacing.space20),
                _buildShortsAction(
                  icon: Icons.favorite_rounded,
                  label: '24.5k',
                  color: AppColors.primaryCrimson,
                ),
                const SizedBox(height: AppSpacing.space16),
                _buildShortsAction(
                  icon: Icons.chat_bubble_rounded,
                  label: '1.2k',
                ),
                const SizedBox(height: AppSpacing.space16),
                _buildShortsAction(
                  icon: Icons.bookmark_rounded,
                  label: '840',
                ),
                const SizedBox(height: AppSpacing.space16),
                _buildShortsAction(
                  icon: Icons.share_rounded,
                  label: 'Share',
                ),
              ],
            ),
          ),

          // Bottom Left Author & Description
          Positioned(
            left: AppSpacing.space16,
            right: 80,
            bottom: AppSpacing.space32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@genz_official',
                  style: AppTypography.title.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Welcome to GenZ Media! Explore communities, connect with creators, and share your passions. #GenZ #Community',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textInverse),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortsAction({
    required IconData icon,
    required String label,
    Color color = AppColors.textInverse,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.midnightNavy.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
