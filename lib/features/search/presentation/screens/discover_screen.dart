import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Bar
            AppTextField(
              hintText: 'Search creators, communities, posts...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              onSubmitted: (query) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for "$query"... (Phase 2)')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.space24),

            // Trending Categories & Hashtags
            Text(
              'Trending Topics',
              style: AppTypography.title.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              children: [
                _buildTagChip('#Gaming', isDark),
                _buildTagChip('#MusicDrop', isDark),
                _buildTagChip('#Streetwear', isDark),
                _buildTagChip('#TechAI', isDark),
                _buildTagChip('#DesignDaily', isDark),
                _buildTagChip('#AnimeCommunity', isDark),
              ],
            ),
            const SizedBox(height: AppSpacing.space32),

            // Suggested Communities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Communities',
                  style: AppTypography.title.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See all',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            _buildCommunityCard(
              context,
              name: 'Anime & Manga Global',
              members: '48.2k members',
              description: 'The ultimate space for anime discussions, seasonal reviews, and art.',
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.space12),
            _buildCommunityCard(
              context,
              name: 'Indie Game Creators',
              members: '19.4k members',
              description: 'Showcase devlogs, get playtesting feedback, and network.',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildCommunityCard(
    BuildContext context, {
    required String name,
    required String members,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.primaryCrimson, size: 26),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.label.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  members,
                  style: AppTypography.caption.copyWith(color: AppColors.primaryCrimson),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
