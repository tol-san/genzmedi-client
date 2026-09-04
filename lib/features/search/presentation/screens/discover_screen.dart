import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/presentation/notifiers/discover_notifier.dart';
import 'package:client/features/search/presentation/notifiers/discover_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 420) {
      ref.read(discoverNotifierProvider.notifier).loadMorePosts();
    }
  }

  void _openSearch() => context.pushNamed(RouteNames.discoverSearch);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverNotifierProvider);
    final notifier = ref.read(discoverNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<DiscoverState>(discoverNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          (next.posts.isNotEmpty ||
              next.users.isNotEmpty ||
              next.communities.isNotEmpty)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: state.isLoading
          ? const _DiscoverSkeleton()
          : state.errorMessage != null &&
                state.posts.isEmpty &&
                state.users.isEmpty &&
                state.communities.isEmpty
          ? EmptyStateWidget(
              icon: Icons.cloud_off_outlined,
              title: 'Discover is taking a break',
              subtitle: state.errorMessage,
              actionText: 'Try again',
              onAction: notifier.loadInitial,
            )
          : RefreshIndicator(
              color: AppColors.primaryElectricBlue,
              onRefresh: notifier.refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.space24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space8,
                      AppSpacing.space16,
                      AppSpacing.space20,
                    ),
                    child: TextField(
                      readOnly: true,
                      onTap: _openSearch,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search_rounded, size: 21),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightBorderSubtle,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedMd,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedMd,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (state.communities.isNotEmpty) ...[
                    _SimpleSectionTitle(
                      'Communities for you',
                      actionLabel: 'See all',
                      onAction: () =>
                          context.pushNamed(RouteNames.communityList),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    ...state.communities
                        .take(3)
                        .map(
                          (item) => _CommunityRow(
                            item: item,
                            isPending: state.pendingCommunityIds.contains(
                              item.community.id,
                            ),
                            onTap: () => context.pushNamed(
                              RouteNames.communityDetail,
                              pathParameters: {
                                'communityId': item.community.id,
                              },
                            ),
                            onMembershipToggle: () =>
                                notifier.toggleCommunity(item.community.id),
                          ),
                        ),
                    const SizedBox(height: AppSpacing.space12),
                    _SectionDivider(isDark: isDark),
                    const SizedBox(height: AppSpacing.space16),
                  ],
                  if (state.users.isNotEmpty) ...[
                    const _SimpleSectionTitle('People with your interests'),
                    const SizedBox(height: AppSpacing.space4),
                    ...state.users
                        .take(3)
                        .map(
                          (item) => _CreatorRow(
                            item: item,
                            isPending: state.pendingUserIds.contains(
                              item.user.id,
                            ),
                            onTap: () => context.pushNamed(
                              RouteNames.publicProfile,
                              pathParameters: {'username': item.user.username},
                            ),
                            onFollow: () => notifier.toggleFollow(item.user.id),
                          ),
                        ),
                    const SizedBox(height: AppSpacing.space12),
                    _SectionDivider(isDark: isDark),
                    const SizedBox(height: AppSpacing.space16),
                  ],
                  const _SimpleSectionTitle('Trending for you'),
                  const SizedBox(height: AppSpacing.space8),
                  if (state.posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: AppSpacing.space32,
                      ),
                      child: Text(
                        'Nothing to show yet.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  else
                    ...state.posts.map(
                      (post) => Column(
                        children: [
                          PostCardWidget(
                            key: ValueKey(post.id),
                            post: post,
                            onLike: () => notifier.toggleLike(post.id),
                            onSave: () => notifier.toggleSave(post.id),
                            onShare: () => notifier.sharePost(post.id),
                            onComment: () => PostCommentsSheet.show(
                              context,
                              postId: post.id,
                              post: post,
                            ),
                          ),
                          Container(
                            height: 8,
                            color: isDark
                                ? const Color(0xFF030D1A)
                                : const Color(0xFFF0F2F5),
                          ),
                        ],
                      ),
                    ),
                  if (state.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.space20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SimpleSectionTitle extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SimpleSectionTitle(this.text, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTypography.label.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryElectricBlue,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  final DiscoverCommunityModel item;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onMembershipToggle;

  const _CommunityRow({
    required this.item,
    required this.isPending,
    required this.onTap,
    required this.onMembershipToggle,
  });

  @override
  Widget build(BuildContext context) {
    final community = item.community;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interest = item.interestName?.trim();
    final contextText = interest != null && interest.isNotEmpty
        ? '$interest · ${community.memberCount} members'
        : '${community.memberCount} members';
    final actionText = item.isJoinPending
        ? 'Requested'
        : item.isJoined
        ? 'Joined'
        : community.isPrivate
        ? 'Request'
        : 'Join';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: community.name,
              imageUrl: community.avatarUrl,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contextText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            SizedBox(
              width: 88,
              height: 34,
              child: item.isJoined || item.isJoinPending
                  ? OutlinedButton(
                      onPressed: isPending || item.isJoinPending
                          ? null
                          : onMembershipToggle,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: isPending
                          ? const _ButtonLoader()
                          : Text(actionText),
                    )
                  : FilledButton(
                      onPressed: isPending ? null : onMembershipToggle,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primaryElectricBlue,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                      child: isPending
                          ? const _ButtonLoader()
                          : Text(actionText),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final bool isDark;

  const _SectionDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 8,
      thickness: 8,
      color: isDark ? const Color(0xFF030D1A) : const Color(0xFFF0F2F5),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  final DiscoverUserModel item;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  const _CreatorRow({
    required this.item,
    required this.isPending,
    required this.onTap,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final user = item.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sharedInterests = item.sharedInterests.take(2).join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: user.displayName ?? user.username,
              imageUrl: user.avatarUrl,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sharedInterests.isNotEmpty
                        ? sharedInterests
                        : '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            SizedBox(
              width: 88,
              height: 34,
              child: item.isFollowing
                  ? OutlinedButton(
                      onPressed: isPending ? null : onFollow,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: isPending
                          ? const _ButtonLoader()
                          : const Text('Following'),
                    )
                  : FilledButton(
                      onPressed: isPending ? null : onFollow,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primaryElectricBlue,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                      child: isPending
                          ? const _ButtonLoader()
                          : const Text('Follow'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 15,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: const [
        AppSkeleton.rectangular(height: 48, borderRadius: AppSpacing.roundedMd),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.text(width: 140, height: 18),
        SizedBox(height: AppSpacing.space16),
        AppSkeleton.rectangular(height: 64),
        SizedBox(height: AppSpacing.space8),
        AppSkeleton.rectangular(height: 64),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.text(width: 110, height: 18),
        SizedBox(height: AppSpacing.space16),
        AppSkeleton.rectangular(height: 280),
      ],
    );
  }
}
