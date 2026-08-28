import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';
import 'package:client/features/profiles/presentation/widgets/profile_post_card.dart';
import 'package:client/features/profiles/presentation/widgets/profile_stat_widget.dart';

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
        content: const Text('Are you sure you want to sign out of your account?'),
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
                const Icon(Icons.verified_rounded, size: 16, color: AppColors.signalMint),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account Settings (Coming soon)')),
                );
              },
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
                onRefresh: () => ref.read(myProfileNotifierProvider.notifier).refreshProfile(),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.space16),

                            // Avatar & Stats Row
                            Row(
                              children: [
                                AppAvatar(
                                  name: user?.displayName ?? user?.username ?? 'User',
                                  size: 76,
                                  imageUrl: user?.avatarUrl,
                                ),
                                const SizedBox(width: AppSpacing.space16),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      ProfileStatWidget(
                                        count: _formatCount(user?.postCount ?? profileState.posts.length),
                                        label: 'Posts',
                                      ),
                                      ProfileStatWidget(
                                        count: _formatCount(user?.followersCount ?? 0),
                                        label: 'Followers',
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Followers list (Next phase)')),
                                          );
                                        },
                                      ),
                                      ProfileStatWidget(
                                        count: _formatCount(user?.followingCount ?? 0),
                                        label: 'Following',
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Following list (Next phase)')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space16),

                            // Display Name & Bio
                            Text(
                              user?.displayName ?? user?.username ?? 'Gen Z Creator',
                              style: AppTypography.title.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.bio!,
                                style: AppTypography.body.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.space16),

                            // Edit Profile & Share Row
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton.secondary(
                                    text: 'Edit Profile',
                                    size: AppButtonSize.small,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Edit Profile coming next!')),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.space8),
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: AppSpacing.roundedMd,
                                    border: Border.all(
                                      color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                                    ),
                                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.share_outlined, size: 18),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Profile link copied!')),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space16),

                            // Interests Cloud
                            if (user?.interests != null && user!.interests.isNotEmpty) ...[
                              Text(
                                'Interests',
                                style: AppTypography.label.copyWith(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space8),
                              Wrap(
                                spacing: AppSpacing.space8,
                                runSpacing: AppSpacing.space8,
                                children: user.interests
                                    .map(
                                      (interest) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.space12,
                                          vertical: AppSpacing.space4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                                          borderRadius: AppSpacing.roundedFull,
                                          border: Border.all(
                                            color: isDark ? AppColors.navyBorder : AppColors.primarySoft,
                                          ),
                                        ),
                                        child: Text(
                                          '#$interest',
                                          style: AppTypography.caption.copyWith(
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.primaryCrimson,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: AppSpacing.space16),
                            ],
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
                          labelColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: AppTypography.label,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.grid_on_rounded, size: 20),
                              text: 'Posts',
                            ),
                            Tab(
                              icon: Icon(Icons.bookmark_border_rounded, size: 20),
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Post: ${post.title ?? post.id}')),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedTab(dynamic state, bool isDark) {
    if (state.isLoadingSaved && state.savedPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.savedPosts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved posts',
        subtitle: 'Save posts from your feed to easily find them later.',
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
      itemCount: state.savedPosts.length,
      itemBuilder: (context, index) {
        final post = state.savedPosts[index];
        return ProfilePostCard(
          post: post,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved: ${post.title ?? post.id}')),
            );
          },
        );
      },
    );
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
