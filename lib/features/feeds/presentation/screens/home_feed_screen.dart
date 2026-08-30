import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/widgets/app_logo.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/feeds/presentation/notifiers/home_feed_notifier.dart';
import 'package:client/features/feeds/presentation/notifiers/home_feed_state.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(homeFeedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(homeFeedNotifierProvider);
    final notifier = ref.read(homeFeedNotifierProvider.notifier);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_isAppBarVisible ? kToolbarHeight : 0.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          height: _isAppBarVisible ? (kToolbarHeight + statusBarHeight) : 0.0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: AppBar(
              title: const AppLogo.wordmark(width: 140, height: 22),
              actions: [
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryCrimson,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications (Coming soon)')),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.space8),
              ],
            ),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isAppBarVisible) {
              setState(() => _isAppBarVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isAppBarVisible) {
              setState(() => _isAppBarVisible = true);
            }
          }
          return false;
        },
        child: _buildBody(state, notifier, isDark),
      ),
    );
  }

  Widget _buildBody(HomeFeedState state, HomeFeedNotifier notifier, bool isDark) {
    if (state.isLoading && state.posts.isEmpty) {
      return _buildFeedSkeleton(isDark);
    }

    if (state.posts.isEmpty && !state.isLoading) {
      return RefreshIndicator(
        color: AppColors.primaryCrimson,
        onRefresh: notifier.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space48),
          child: EmptyStateWidget(
            icon: Icons.dynamic_feed_rounded,
            title: 'Your feed is just getting started',
            subtitle:
                'Follow creators and join interest communities to populate your personal timeline.',
            actionText: 'Explore Discover',
            onAction: () {
              context.goNamed(RouteNames.discover);
            },
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: state.posts.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => Container(
          height: 8,
          color: isDark ? const Color(0xFF030D1A) : const Color(0xFFF0F2F5),
        ),
        itemBuilder: (context, index) {
          if (index == state.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space24),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryCrimson,
                ),
              ),
            );
          }

          final post = state.posts[index];
          return PostCardWidget(
            key: ValueKey(post.id),
            post: post,
            onLike: () => notifier.toggleLike(post.id),
            onSave: () => notifier.toggleSave(post.id),
            onShare: () => notifier.sharePost(post.id),
            onComment: () {
              context.pushNamed(
                RouteNames.postDetail,
                pathParameters: {'postId': post.id},
              );
            },
            onTap: () {
              context.pushNamed(
                RouteNames.postDetail,
                pathParameters: {'postId': post.id},
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedSkeleton(bool isDark) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 3,
      separatorBuilder: (context, index) => Container(
        height: 8,
        color: isDark ? const Color(0xFF030D1A) : const Color(0xFFF0F2F5),
      ),
      itemBuilder: (context, index) => Container(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space12),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
              child: Row(
                children: [
                  AppSkeleton.circle(size: 40),
                  SizedBox(width: AppSpacing.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton.text(width: 120, height: 14),
                      SizedBox(height: 6),
                      AppSkeleton.text(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.space12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
              child: AppSkeleton.text(width: 200, height: 16),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
              child: AppSkeleton.text(width: double.infinity, height: 14),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
              child: AppSkeleton.text(width: 240, height: 14),
            ),
            SizedBox(height: AppSpacing.space12),
            AppSkeleton.rectangular(height: 220),
            SizedBox(height: AppSpacing.space12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSkeleton.rectangular(width: 60, height: 20),
                  AppSkeleton.rectangular(width: 60, height: 20),
                  AppSkeleton.rectangular(width: 60, height: 20),
                  AppSkeleton.rectangular(width: 60, height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
