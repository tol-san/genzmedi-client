import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Content'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What do you want to share today?',
              style: AppTypography.heading.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Post directly to your profile or contribute to a community.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space32),
            _buildCreateOption(
              context,
              icon: Icons.video_camera_back_rounded,
              title: 'Short Video',
              subtitle: 'Upload vertical short video for the Shorts feed',
              badge: 'Popular',
              onTap: () {
                context.pushNamed(
                  RouteNames.createPost,
                  queryParameters: {'type': 'video'},
                );
              },
            ),
            const SizedBox(height: AppSpacing.space16),
            _buildCreateOption(
              context,
              icon: Icons.photo_library_rounded,
              title: 'Photo Carousel',
              subtitle: 'Share up to 10 images with tags and description',
              onTap: () {
                context.pushNamed(
                  RouteNames.createPost,
                  queryParameters: {'type': 'image'},
                );
              },
            ),
            const SizedBox(height: AppSpacing.space16),
            _buildCreateOption(
              context,
              icon: Icons.edit_note_rounded,
              title: 'Discussion / Thought',
              subtitle: 'Start a conversation with a formatted text post',
              onTap: () {
                context.pushNamed(
                  RouteNames.createPost,
                  queryParameters: {'type': 'text'},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space20),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.primaryCrimson.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Icon(icon, color: AppColors.primaryCrimson, size: 28),
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.title.copyWith(
                            fontSize: 18,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCrimson,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textInverse,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
