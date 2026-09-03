import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/profiles/presentation/notifiers/follow_list_notifier.dart';
import 'package:client/features/profiles/presentation/widgets/user_tile_widget.dart';

class FollowListScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final int initialTabIndex;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(followListNotifierProvider(widget.userId));
    final notifier = ref.read(
      followListNotifierProvider(widget.userId).notifier,
    );
    final authState = ref.watch(authNotifierProvider);

    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : (authState is AuthNeedsOnboarding ? authState.user.id : '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '@${widget.username}',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space12,
                      vertical: AppSpacing.space8,
                    ),
                  ),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryCrimson,
                indicatorWeight: 2.5,
                labelColor: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppTypography.label,
                tabs: [
                  Tab(text: 'Followers (${state.followers.length})'),
                  Tab(text: 'Following (${state.following.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Followers
          _buildUserList(
            users: state.filteredFollowers,
            isLoading: state.isLoadingFollowers,
            hasMore: state.hasMoreFollowers,
            onRefresh: notifier.refresh,
            onLoadMore: notifier.loadFollowers,
            emptyTitle: 'No followers yet',
            emptySubtitle: state.searchQuery.isNotEmpty
                ? 'No followers matching "${state.searchQuery}".'
                : 'When people follow @${widget.username}, they\'ll show up here.',
            currentUserId: currentUserId,
            followingStatusMap: state.followingStatusMap,
            onFollowToggle: (userId, isFollowing) {
              notifier.toggleFollowUser(
                userId,
                isCurrentlyFollowing: isFollowing,
              );
            },
          ),
          // Tab 1: Following
          _buildUserList(
            users: state.filteredFollowing,
            isLoading: state.isLoadingFollowing,
            hasMore: state.hasMoreFollowing,
            onRefresh: notifier.refresh,
            onLoadMore: notifier.loadFollowing,
            emptyTitle: 'Not following anyone',
            emptySubtitle: state.searchQuery.isNotEmpty
                ? 'No users matching "${state.searchQuery}".'
                : '@${widget.username} isn\'t following anyone yet.',
            currentUserId: currentUserId,
            followingStatusMap: state.followingStatusMap,
            onFollowToggle: (userId, isFollowing) {
              notifier.toggleFollowUser(
                userId,
                isCurrentlyFollowing: isFollowing,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({
    required List<dynamic> users,
    required bool isLoading,
    required bool hasMore,
    required Future<void> Function() onRefresh,
    required Future<void> Function() onLoadMore,
    required String emptyTitle,
    required String emptySubtitle,
    required String currentUserId,
    required Map<String, bool> followingStatusMap,
    required void Function(String userId, bool isFollowing) onFollowToggle,
  }) {
    if (isLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryCrimson,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space48),
          child: EmptyStateWidget(
            icon: Icons.people_outline_rounded,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              hasMore &&
              !isLoading) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
          itemCount: users.length + (hasMore ? 1 : 0),
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            if (index == users.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.space16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final user = users[index];
            final isFollowing = followingStatusMap[user.id] ?? false;
            final isSelf = user.id == currentUserId;

            return UserTileWidget(
              user: user,
              isFollowing: isFollowing,
              isCurrentUser: isSelf,
              onTap: () {
                context.pushNamed(
                  RouteNames.publicProfile,
                  pathParameters: {'username': user.username},
                );
              },
              onFollowToggle: () => onFollowToggle(user.id, isFollowing),
            );
          },
        ),
      ),
    );
  }
}
