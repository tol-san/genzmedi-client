import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';
import 'package:client/features/profiles/presentation/widgets/profile_overview_card.dart';
import 'package:client/features/profiles/presentation/widgets/profile_post_card.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(myProfileNotifierProvider);
    final user = profileState.user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user != null ? '@${user.username}' : 'My Profile',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (user?.isVerified == true) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.signalMint,
                ),
              ],
            ],
          ),
          actions: [
            if (user?.isSuperuser == true)
              IconButton(
                icon: const Icon(Icons.shield_outlined),
                tooltip: 'Moderation center',
                onPressed: () => context.pushNamed(RouteNames.reports),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.pushNamed(RouteNames.settings),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              tooltip: 'Sign Out',
              onPressed: () => _showSignOutDialog(context),
            ),
            const SizedBox(width: AppSpacing.space8),
          ],
        ),
        body: profileState.isLoadingProfile && user == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primaryCrimson,
                onRefresh: () => ref
                    .read(myProfileNotifierProvider.notifier)
                    .refreshProfile(),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.space16),

                            ProfileOverviewCard(
                              displayName:
                                  user?.displayName ??
                                  user?.username ??
                                  'Gen Z Creator',
                              avatarUrl: user?.avatarUrl,
                              bio: user?.bio,
                              isVerified: user?.isVerified ?? false,
                              postCount: _formatCount(
                                user?.postCount ?? profileState.posts.length,
                              ),
                              followersCount: _formatCount(
                                user?.followersCount ?? 0,
                              ),
                              followingCount: _formatCount(
                                user?.followingCount ?? 0,
                              ),
                              onFollowersTap: user == null
                                  ? null
                                  : () => context.pushNamed(
                                      RouteNames.followList,
                                      pathParameters: {'userId': user.id},
                                      queryParameters: {
                                        'username': user.username,
                                        'tab': '0',
                                      },
                                    ),
                              onFollowingTap: user == null
                                  ? null
                                  : () => context.pushNamed(
                                      RouteNames.followList,
                                      pathParameters: {'userId': user.id},
                                      queryParameters: {
                                        'username': user.username,
                                        'tab': '1',
                                      },
                                    ),
                              interests: user?.interests ?? const [],
                              primaryAction: AppButton.secondary(
                                text: 'Edit Profile',
                                icon: Icons.edit_outlined,
                                borderRadius: AppSpacing.roundedMd,
                                onPressed: () =>
                                    context.pushNamed(RouteNames.editProfile),
                              ),
                              onShare: () {
                                final uname = user?.username ?? '';
                                final link =
                                    'https://genzmedia.app/profile/@$uname';
                                Clipboard.setData(ClipboardData(text: link));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Profile link copied: $link'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.space20),
                          ],
                        ),
                      ),
                    ),

                    // Tab Bar Header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          indicatorColor: AppColors.primaryCrimson,
                          indicatorWeight: 2.5,
                          labelColor: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: AppTypography.label,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.grid_on_rounded, size: 20),
                              text: 'Posts',
                            ),
                            Tab(
                              icon: Icon(
                                Icons.bookmark_border_rounded,
                                size: 20,
                              ),
                              text: 'Saved',
                            ),
                          ],
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      // Tab 1: Personal Posts
                      _buildPostsTab(profileState, isDark),
                      // Tab 2: Saved Posts
                      _buildSavedTab(profileState, isDark),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPostsTab(dynamic state, bool isDark) {
    if (state.isLoadingPosts && state.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.posts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.grid_view_rounded,
        title: 'No posts yet',
        subtitle: 'Share your thoughts, photos, or short videos to build your profile.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.space12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];
        return ProfilePostCard(
          post: post,
          onTap: () => _navigateToPost(context, post, isFromSavedTab: false),
        );
      },
    );
  }

  Widget _buildSavedTab(dynamic state, bool isDark) {
    if (state.isLoadingSaved && state.savedPosts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCrimson),
      );
    }

    if (state.savedErrorMessage != null && state.savedPosts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                'Failed to load saved posts',
                style: AppTypography.title.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                state.savedErrorMessage.toString(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space16),
              AppButton(
                text: 'Retry',
                size: AppButtonSize.small,
                isFullWidth: false,
                onPressed: () {
                  ref.read(myProfileNotifierProvider.notifier).loadSavedPosts();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (state.savedPosts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved posts',
        subtitle: 'Save posts from your feed to easily find them later.',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          ref.read(myProfileNotifierProvider.notifier).loadMoreSavedPosts();
        }
        return false;
      },
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.space12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: state.savedPosts.length,
              itemBuilder: (context, index) {
                final post = state.savedPosts[index];
                return ProfilePostCard(
                  post: post,
                  onTap: () => _navigateToPost(context, post, isFromSavedTab: true),
                );
              },
            ),
          ),
          if (state.isLoadingMoreSaved == true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryCrimson,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToPost(
    BuildContext context,
    PostModel post, {
    required bool isFromSavedTab,
  }) async {
    if (post.postType == 'video') {
      await context.pushNamed(
        RouteNames.shortsViewer,
        extra: post,
        queryParameters: {'postId': post.id},
      );
    } else if (post.postType == 'image' && post.media.isNotEmpty) {
      await context.pushNamed(
        RouteNames.mediaViewer,
        pathParameters: {'postId': post.id},
        extra: post,
      );
    } else {
      await context.pushNamed(
        RouteNames.postDetail,
        pathParameters: {'postId': post.id},
      );
    }

    if (mounted) {
      if (isFromSavedTab) {
        ref.read(myProfileNotifierProvider.notifier).loadSavedPosts();
      } else {
        ref.read(myProfileNotifierProvider.notifier).loadPosts();
      }
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverAppBarDelegate(this._tabBar, {required this.isDark});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
