import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/widgets/app_logo.dart';
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

    return Scaffold(
      appBar: AppBar(
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
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(HomeFeedState state, HomeFeedNotifier notifier) {
    if (state.isLoading && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCrimson),
      );
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
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
        itemCount: state.posts.length + (state.hasMore ? 1 : 0),
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
}
