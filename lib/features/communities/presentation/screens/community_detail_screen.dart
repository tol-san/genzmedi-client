import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/utils/media_url_resolver.dart';
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

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadCover(CommunityDetailNotifier notifier) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final success = await notifier.updateCoverImage(File(picked.path));
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Community cover banner updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar(CommunityDetailNotifier notifier) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final success = await notifier.updateAvatarImage(File(picked.path));
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Community avatar updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (_) {}
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
    final isPrivate = community?.isPrivate ?? false;
    final showRequestsTab = isOwner && isPrivate;
    final tabCount = showRequestsTab ? 4 : 3;

    return DefaultTabController(
      key: ValueKey('tab_ctrl_${widget.communityId}_$tabCount'),
      length: tabCount,
      child: Scaffold(
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
                child:
                    CircularProgressIndicator(color: AppColors.primaryCrimson),
              )
            : detail == null || community == null
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
                                          imageUrl: resolveMediaUrl(
                                                  community.coverImageUrl) ??
                                              community.coverImageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Container(
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
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),

                                // Owner Edit Cover Button
                                if (isOwner)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _pickAndUploadCover(notifier),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.65),
                                          borderRadius: AppSpacing.roundedFull,
                                          border:
                                              Border.all(color: Colors.white24),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.camera_alt_outlined,
                                                size: 14,
                                                color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Edit Banner',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // Avatar
                                Positioned(
                                  left: AppSpacing.space16,
                                  bottom: -30,
                                  child: GestureDetector(
                                    onTap: isOwner
                                        ? () => _pickAndUploadAvatar(notifier)
                                        : null,
                                    child: Stack(
                                      children: [
                                        Container(
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
                                                  imageUrl: resolveMediaUrl(
                                                          community.avatarUrl) ??
                                                      community.avatarUrl!,
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const Icon(
                                                    Icons.groups_rounded,
                                                    color: AppColors.primaryCrimson,
                                                    size: 36,
                                                  ),
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.groups_rounded,
                                                    color: AppColors.primaryCrimson,
                                                    size: 36,
                                                  ),
                                                ),
                                        ),
                                        if (isOwner)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primaryCrimson,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
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
                                                      ? AppColors
                                                          .textPrimaryDark
                                                      : AppColors
                                                          .textPrimaryLight,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    community.isPrivate
                                                        ? Icons
                                                            .lock_outline_rounded
                                                        : Icons.public_rounded,
                                                    size: 11,
                                                    color: community.isPrivate
                                                        ? AppColors.warning
                                                        : AppColors.signalMint,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    community.isPrivate
                                                        ? 'Private'
                                                        : 'Public',
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: community.isPrivate
                                                          ? AppColors.warning
                                                          : AppColors
                                                              .signalMint,
                                                    ),
                                                  ),
                                                ],
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
                            indicatorColor: AppColors.primaryCrimson,
                            labelColor: AppColors.primaryCrimson,
                            unselectedLabelColor: AppColors.textMuted,
                            labelStyle: AppTypography.label
                                .copyWith(fontWeight: FontWeight.w600),
                            tabs: [
                              const Tab(text: 'Posts'),
                              const Tab(text: 'About'),
                              Tab(text: 'Members (${state.members.length})'),
                              if (showRequestsTab)
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
                      children: [
                        // Tab 1: Posts Feed
                        _buildPostsTab(state, notifier, detail, isDark),

                        // Tab 2: About
                        _buildAboutTab(community, detail, isDark),

                        // Tab 3: Members
                        _buildMembersTab(
                            state, notifier, detail, isOwner, isDark),

                        // Tab 4: Join Requests (Private Community Owner only)
                        if (showRequestsTab)
                          _buildRequestsTab(state, notifier, isDark),
                      ],
                    ),
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
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 13, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              'Requested',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    CommunityDetailModel detail,
    bool isDark,
  ) {
    final isPrivateAndLocked =
        detail.community.isPrivate && !detail.isMember && !detail.isOwner;

    // 1. Private Community Locked Scrim for Non-Members
    if (isPrivateAndLocked) {
      if (detail.joinRequestStatus == 'pending') {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              Text(
                'Join Request Pending',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your request has been submitted to the community owner. You will get access once approved.',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.lock_rounded,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            Text(
              'Private Community',
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Posts, discussions, and member activities in this community are private. Request access to see content.',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Request to Join',
              size: AppButtonSize.small,
              isFullWidth: false,
              onPressed: () => notifier.joinCommunity(),
            ),
          ],
        ),
      );
    }

    if (state.isLoadingPosts && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCrimson),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: notifier.loadPosts,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        children: [
          // If member or owner: Quick Post CTA bar
          if (detail.isMember || detail.isOwner) ...[
            GestureDetector(
              onTap: () {
                context.pushNamed(RouteNames.createPost);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: isDark
                        ? AppColors.navyBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        color: AppColors.primaryCrimson, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Share something with the community...',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
          ],

          if (state.posts.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.space48),
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
            )
          else
            ...state.posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space16),
                child: PostCardWidget(
                  post: post,
                  onTap: () {
                    context.pushNamed(
                      RouteNames.postDetail,
                      pathParameters: {'postId': post.id},
                    );
                  },
                ),
              ),
            ),
        ],
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
    CommunityDetailModel detail,
    bool isOwner,
    bool isDark,
  ) {
    final isPrivateAndLocked =
        detail.community.isPrivate && !detail.isMember && !detail.isOwner;
    if (isPrivateAndLocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Member list is private.',
                style: AppTypography.title.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Join this community to view the member directory.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
