import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/profiles/presentation/notifiers/public_profile_notifier.dart';
import 'package:client/features/profiles/presentation/widgets/profile_overview_card.dart';
import 'package:client/features/profiles/presentation/widgets/profile_post_card.dart';
import 'package:client/features/profiles/presentation/widgets/report_user_sheet.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showBlockConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    bool isBlocking,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBlocking ? 'Unblock @$username?' : 'Block @$username?'),
        content: Text(
          isBlocking
              ? 'They will be able to follow you and view your posts again.'
              : 'They will not be able to follow you, view your posts, or send you messages. Any existing follow relationship will be severed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(publicProfileNotifierProvider(username).notifier)
                  .toggleBlock();
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBlocking
                          ? 'Unblocked @$username'
                          : 'Blocked @$username',
                    ),
                    backgroundColor: isBlocking
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              isBlocking ? 'Unblock' : 'Block',
              style: TextStyle(
                color: isBlocking ? AppColors.signalMint : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publicProfileNotifierProvider(username));
    final authState = ref.watch(authNotifierProvider);

    final currentUser = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthNeedsOnboarding ? authState.user : null);

    final user = state.user;
    final isOwnProfile =
        currentUser != null &&
        currentUser.username.toLowerCase() == username.toLowerCase();

    if (state.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null && !state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('@$username')),
        body: EmptyStateWidget(
          icon: Icons.person_off_outlined,
          title: 'User not found',
          subtitle: 'The profile you are looking for does not exist or has been deactivated.',
          actionText: 'Go Back',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final relationship = state.relationship;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '@${user!.username}',
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (user.isVerified) ...[
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
          if (!isOwnProfile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'block') {
                  _showBlockConfirmationDialog(
                    context,
                    ref,
                    relationship.isBlocking,
                  );
                } else if (value == 'report') {
                  ReportUserSheet.show(
                    context,
                    username: username,
                    onReport: (reason, desc) => ref
                        .read(publicProfileNotifierProvider(username).notifier)
                        .reportUser(reason: reason, description: desc),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      Text('Report User'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relationship.isBlocking ? 'Unblock User' : 'Block User',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: AppSpacing.space8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryCrimson,
        onRefresh: () => ref
            .read(publicProfileNotifierProvider(username).notifier)
            .refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space16),

              ProfileOverviewCard(
                displayName: user.displayName ?? user.username,
                avatarUrl: user.avatarUrl,
                bio: user.bio,
                isVerified: user.isVerified,
                postCount: _formatCount(user.postCount),
                followersCount: _formatCount(user.followersCount),
                followingCount: _formatCount(user.followingCount),
                onFollowersTap: () => context.pushNamed(
                  RouteNames.followList,
                  pathParameters: {'userId': user.id},
                  queryParameters: {'username': user.username, 'tab': '0'},
                ),
                onFollowingTap: () => context.pushNamed(
                  RouteNames.followList,
                  pathParameters: {'userId': user.id},
                  queryParameters: {'username': user.username, 'tab': '1'},
                ),
                interests: user.interests,
                primaryAction: isOwnProfile
                    ? AppButton.secondary(
                        text: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        borderRadius: AppSpacing.roundedMd,
                        onPressed: () =>
                            context.pushNamed(RouteNames.editProfile),
                      )
                    : relationship.isFollowing
                    ? AppButton.secondary(
                        text: 'Following',
                        icon: Icons.check_rounded,
                        borderRadius: AppSpacing.roundedMd,
                        onPressed: () => ref
                            .read(
                              publicProfileNotifierProvider(username).notifier,
                            )
                            .toggleFollow(),
                      )
                    : AppButton(
                        text: 'Follow',
                        icon: Icons.person_add_alt_1_rounded,
                        borderRadius: AppSpacing.roundedMd,
                        onPressed: () => ref
                            .read(
                              publicProfileNotifierProvider(username).notifier,
                            )
                            .toggleFollow(),
                      ),
                onShare: () {
                  final link =
                      'https://genzmedia.app/profile/@${user.username}';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile link copied: $link'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // Posts Section Header
              Row(
                children: [
                  const Icon(Icons.grid_on_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Posts', style: AppTypography.label),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),

              // Posts Grid / Empty State
              if (state.posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space24,
                  ),
                  child: EmptyStateWidget(
                    icon: Icons.grid_view_rounded,
                    title: 'No posts yet',
                    subtitle: '@${user.username} hasn\'t published any posts.',
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                          SnackBar(
                            content: Text('Post: ${post.title ?? post.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.space32),
            ],
          ),
        ),
      ),
    );
  }
}
