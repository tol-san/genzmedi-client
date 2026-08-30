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
        title: const Text(
          'Create',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space20,
          vertical: AppSpacing.space16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What are you posting?',
              style: AppTypography.title.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Post directly to your profile or contribute to a community.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space20),

            // 1. 🎬 Video
            _buildCreateOption(
              context,
              icon: Icons.videocam_rounded,
              title: '🎬 Video',
              subtitle: 'Post a short video',
              onTap: () {
                context.pushNamed(
                  RouteNames.createPost,
                  queryParameters: {'type': 'video'},
                );
              },
            ),
            const SizedBox(height: AppSpacing.space12),

            // 2. 🖼️ Photo
            _buildCreateOption(
              context,
              icon: Icons.photo_library_rounded,
              title: '🖼️ Photo',
              subtitle: 'Share one or multiple photos',
              onTap: () {
                context.pushNamed(
                  RouteNames.createPost,
                  queryParameters: {'type': 'image'},
                );
              },
            ),
            const SizedBox(height: AppSpacing.space12),

            // 3. 💬 Post
            _buildCreateOption(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: '💬 Post',
              subtitle: 'Share a thought, story, or discussion',
              onTap: () {
                context.pushNamed(
                  RouteNames.createPost,
                  queryParameters: {'type': 'text'},
                );
              },
            ),
            const SizedBox(height: AppSpacing.space12),

            // 4. 📊 Poll
            _buildCreateOption(
              context,
              icon: Icons.poll_rounded,
              title: '📊 Poll',
              subtitle: 'Ask the community',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Polls are coming soon to GenZ Media!'),
                    backgroundColor: AppColors.primaryElectricBlue,
                  ),
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
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryCrimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: AppColors.primaryCrimson, size: 24),
                ),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor ?? AppColors.primaryCrimson,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
