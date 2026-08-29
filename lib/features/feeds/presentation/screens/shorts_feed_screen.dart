import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/features/feeds/presentation/notifiers/shorts_feed_notifier.dart';
import 'package:client/features/feeds/presentation/widgets/short_video_item_widget.dart';

class ShortsFeedScreen extends ConsumerStatefulWidget {
  const ShortsFeedScreen({super.key});

  @override
  ConsumerState<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}

class _ShortsFeedScreenState extends ConsumerState<ShortsFeedScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shortsFeedNotifierProvider);
    final notifier = ref.read(shortsFeedNotifierProvider.notifier);

    if (state.isLoading && state.shorts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCrimson),
        ),
      );
    }

    if (state.shorts.isEmpty && !state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
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
                    Icons.video_library_outlined,
                    size: 48,
                    color: AppColors.primaryCrimson,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  'No shorts available',
                  style: AppTypography.heading.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Check back later or follow creators who share short videos.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.space24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh Feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCrimson,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: notifier.refresh,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: state.shorts.length,
        onPageChanged: (index) {
          notifier.setActiveIndex(index);
        },
        itemBuilder: (context, index) {
          final post = state.shorts[index];
          final isActive = state.activeIndex == index;

          return ShortVideoItemWidget(
            key: ValueKey(post.id),
            post: post,
            isActive: isActive,
            onLike: () => notifier.toggleLike(post.id),
            onSave: () => notifier.toggleSave(post.id),
            onShare: () => notifier.sharePost(post.id),
            onComment: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Comments for @${post.author.username}\'s video')),
              );
            },
          );
        },
      ),
    );
  }
}
