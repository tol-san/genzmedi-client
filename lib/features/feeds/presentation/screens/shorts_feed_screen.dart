import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/features/feeds/presentation/notifiers/shorts_feed_notifier.dart';
import 'package:client/features/feeds/presentation/widgets/short_video_item_widget.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

class ShortsFeedScreen extends ConsumerStatefulWidget {
  final PostModel? initialPost;
  final String? initialPostId;
  final bool isStandalone;

  const ShortsFeedScreen({
    super.key,
    this.initialPost,
    this.initialPostId,
    this.isStandalone = false,
  });

  @override
  ConsumerState<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}

class _ShortsFeedScreenState extends ConsumerState<ShortsFeedScreen> {
  late PageController _pageController;
  int _activeIndex = 0;

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

  List<PostModel> _computeShortsList(List<PostModel> fetchedShorts) {
    if (widget.initialPost != null) {
      final existingIndex = fetchedShorts.indexWhere(
        (p) => p.id == widget.initialPost!.id,
      );
      if (existingIndex >= 0) {
        final list = List<PostModel>.from(fetchedShorts);
        final item = list.removeAt(existingIndex);
        list.insert(0, item);
        return list;
      } else {
        return [widget.initialPost!, ...fetchedShorts];
      }
    } else if (widget.initialPostId != null) {
      final existingIndex = fetchedShorts.indexWhere(
        (p) => p.id == widget.initialPostId,
      );
      if (existingIndex > 0) {
        final list = List<PostModel>.from(fetchedShorts);
        final item = list.removeAt(existingIndex);
        list.insert(0, item);
        return list;
      }
    }
    return fetchedShorts;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shortsFeedNotifierProvider);
    final notifier = ref.read(shortsFeedNotifierProvider.notifier);

    final displayShorts = _computeShortsList(state.shorts);

    if (state.isLoading && displayShorts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCrimson),
        ),
      );
    }

    if (state.errorMessage != null &&
        displayShorts.isEmpty &&
        !state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.primaryCrimson,
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  'Unable to load shorts',
                  style: AppTypography.heading.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
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

    if (displayShorts.isEmpty && !state.isLoading) {
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
                  decoration: const BoxDecoration(
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
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
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
        itemCount: displayShorts.length,
        onPageChanged: (index) {
          setState(() => _activeIndex = index);
          notifier.setActiveIndex(index);
        },
        itemBuilder: (context, index) {
          final post = displayShorts[index];
          final isActive = _activeIndex == index;

          return ShortVideoItemWidget(
            key: ValueKey(post.id),
            post: post,
            isActive: isActive,
            onLike: () => notifier.toggleLike(post.id),
            onSave: () => notifier.toggleSave(post.id),
            onShare: () => notifier.sharePost(post.id),
            onComment: () {
              PostCommentsSheet.show(context, postId: post.id, post: post);
            },
            onVideoCompleted: () {
              if (index < displayShorts.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              }
            },
          );
        },
      ),
    );
  }
}
