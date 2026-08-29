import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/presentation/notifiers/community_detail_notifier.dart';
import 'package:client/features/communities/presentation/notifiers/community_detail_state.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLeaveConfirmation(CommunityDetailNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Community?'),
        content: const Text(
          'You will lose access to community discussions, feeds, and group chat privileges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await notifier.leaveCommunity();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have left the community.'),
                    backgroundColor: AppColors.signalMint,
                  ),
                );
              }
            },
            child: const Text(
              'Leave',
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
    final state =
        ref.watch(communityDetailNotifierProvider(widget.communityId));
    final notifier =
        ref.read(communityDetailNotifierProvider(widget.communityId).notifier);

    final detail = state.detail;
    final community = detail?.community;
    final isOwner = detail?.isOwner ?? false;
    final tabCount = isOwner ? 4 : 3;

    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(community?.name ?? 'Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Community link copied for ${community?.name ?? ''}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: state.isLoading && detail == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCrimson),
            )
          : detail == null
              ? Center(
                  child: Text(
                    state.errorMessage ?? 'Community not found',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Cover Banner Image
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryCrimson
                                          .withValues(alpha: 0.7),
                                      AppColors.midnightNavy,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: community.coverImageUrl != null &&
                                        community.coverImageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: community.coverImageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // Avatar
                              Positioned(
                                left: AppSpacing.space16,
                                bottom: -30,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.midnightNavy
                                          : AppColors.lightCanvas,
                                      width: 4,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: community.avatarUrl != null &&
                                          community.avatarUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: community.avatarUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.groups_rounded,
                                            color: AppColors.primaryCrimson,
                                            size: 36,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 38),

                          // 2. Info & Action Row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              community.name,
                                              style: AppTypography.heading
                                                  .copyWith(
                                                fontSize: 20,
                                                color: isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.textPrimaryLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: community.isPrivate
                                                  ? AppColors.warning
                                                      .withValues(alpha: 0.15)
                                                  : AppColors.signalMint
                                                      .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              community.isPrivate
                                                  ? 'Private'
                                                  : 'Public',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: community.isPrivate
                                                    ? AppColors.warning
                                                    : AppColors.signalMint,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${community.memberCount} members · ${community.postCount} posts',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Membership Action Button
                                _buildActionButton(detail, notifier),
                              ],
                            ),
                          ),

                          // 3. Description
                          if (community.description != null &&
                              community.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.space16,
                                AppSpacing.space12,
                                AppSpacing.space16,
                                0,
                              ),
                              child: Text(
                                community.description!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.space16),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primaryCrimson,
                          labelColor: AppColors.primaryCrimson,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: AppTypography.label
                              .copyWith(fontWeight: FontWeight.w600),
                          tabs: [
                            const Tab(text: 'Posts'),
                            const Tab(text: 'About'),
                            Tab(text: 'Members (${state.members.length})'),
                            if (isOwner)
                              Tab(
                                  text:
                                      'Requests (${state.joinRequests.length})'),
                          ],
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Posts Feed
                      _buildPostsTab(state, notifier),

                      // Tab 2: About
                      _buildAboutTab(community!, detail, isDark),

                      // Tab 3: Members
                      _buildMembersTab(state, notifier, isOwner, isDark),

                      // Tab 4: Join Requests (Owner only)
                      if (isOwner)
                        _buildRequestsTab(state, notifier, isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActionButton(
    CommunityDetailModel detail,
    CommunityDetailNotifier notifier,
  ) {
    if (detail.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryCrimson.withValues(alpha: 0.15),
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded,
                size: 14, color: AppColors.primaryCrimson),
            const SizedBox(width: 4),
            Text(
              'Owner',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryCrimson,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (detail.isMember) {
      return AppButton(
        text: 'Joined',
        size: AppButtonSize.small,
        variant: AppButtonVariant.secondary,
        isFullWidth: false,
        isLoading: false,
        onPressed: () => _showLeaveConfirmation(notifier),
      );
    }

    if (detail.joinRequestStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.15),
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Text(
          'Requested',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return AppButton(
      text: detail.community.isPrivate ? 'Request to Join' : 'Join',
      size: AppButtonSize.small,
      isFullWidth: false,
      onPressed: () => notifier.joinCommunity(),
    );
  }

  Widget _buildPostsTab(
    CommunityDetailState state,
    CommunityDetailNotifier notifier,
  ) {
    if (state.isLoadingPosts && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCrimson),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.article_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No community posts yet.',
                style: AppTypography.title.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to share content with this community!',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: notifier.loadPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.space16),
        itemCount: state.posts.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.space16),
        itemBuilder: (context, index) {
          final post = state.posts[index];
          return PostCardWidget(
            post: post,
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

  Widget _buildAboutTab(
    CommunityModel community,
    CommunityDetailModel detail,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: [
        _buildAboutCard(
          'About Community',
          community.description ?? 'No description provided.',
          Icons.info_outline_rounded,
          isDark,
        ),
        const SizedBox(height: AppSpacing.space12),
        _buildAboutCard(
          'Privacy & Access',
          community.isPrivate
              ? 'Private Community: New members must request access and be approved by the community owner.'
              : 'Public Community: Anyone on GenZ Media can view, join, and post immediately.',
          community.isPrivate
              ? Icons.lock_outline_rounded
              : Icons.public_rounded,
          isDark,
        ),
        const SizedBox(height: AppSpacing.space12),
        _buildAboutCard(
          'Community Metrics',
          '• ${community.memberCount} total members\n• ${community.postCount} published posts',
          Icons.analytics_outlined,
          isDark,
        ),
      ],
    );
  }

  Widget _buildAboutCard(
    String title,
    String content,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryCrimson),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(
    CommunityDetailState state,
    CommunityDetailNotifier notifier,
    bool isOwner,
    bool isDark,
  ) {
    if (state.isLoadingMembers && state.members.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCrimson),
      );
    }

    if (state.members.isEmpty) {
      return Center(
        child: Text(
          'No members found.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: notifier.loadMembers,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.space16),
        itemCount: state.members.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = state.members[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AppAvatar(
              name: member.displayName ?? member.username,
              size: 40,
              imageUrl: member.avatarUrl,
            ),
            title: Text(
              member.displayName ?? member.username,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              '@${member.username} · ${member.role.toUpperCase()}',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            trailing: isOwner && member.role != 'owner'
                ? IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: AppColors.error, size: 20),
                    onPressed: () => notifier.kickMember(member.userId),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab(
    CommunityDetailState state,
    CommunityDetailNotifier notifier,
    bool isDark,
  ) {
    if (state.isLoadingRequests && state.joinRequests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCrimson),
      );
    }

    if (state.joinRequests.isEmpty) {
      return Center(
        child: Text(
          'No pending join requests.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: notifier.loadJoinRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.space16),
        itemCount: state.joinRequests.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.space12),
        itemBuilder: (context, index) {
          final req = state.joinRequests[index];
          return Container(
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(
                color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: req.displayName ?? req.username,
                  size: 40,
                  imageUrl: req.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.displayName ?? req.username,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '@${req.username}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                  onPressed: () => notifier.approveJoinRequest(req.id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded,
                      color: AppColors.error),
                  onPressed: () => notifier.rejectJoinRequest(req.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this._tabBar, {required this.isDark});

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
