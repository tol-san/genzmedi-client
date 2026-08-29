import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/communities/presentation/notifiers/community_list_notifier.dart';
import 'package:client/features/communities/presentation/widgets/community_card_widget.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<CommunityListScreen> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityListNotifierProvider);
    final notifier = ref.read(communityListNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryCrimson,
          labelColor: AppColors.primaryCrimson,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Explore (${state.exploreCommunities.length})'),
            Tab(text: 'Joined (${state.joinedCommunities.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryCrimson,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Create',
          style: AppTypography.label.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          context.pushNamed(RouteNames.createCommunity);
        },
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space8,
            ),
            child: Column(
              children: [
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search communities by name or topic...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                          },
                        )
                      : null,
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    _buildFilterChip('All', null, state.privacyFilter, notifier),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Public', false, state.privacyFilter, notifier),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Private', true, state.privacyFilter, notifier),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Explore Communities
                RefreshIndicator(
                  color: AppColors.primaryCrimson,
                  onRefresh: notifier.refresh,
                  child: state.isLoadingExplore &&
                          state.exploreCommunities.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryCrimson,
                          ),
                        )
                      : state.exploreCommunities.isEmpty
                          ? Center(
                              child: Text(
                                state.searchQuery.isNotEmpty
                                    ? 'No communities found matching "${state.searchQuery}".'
                                    : 'No communities discovered yet.',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.space16),
                              itemCount: state.exploreCommunities.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.space12),
                              itemBuilder: (context, index) {
                                final community =
                                    state.exploreCommunities[index];
                                return CommunityCardWidget(
                                  community: community,
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.communityDetail,
                                      pathParameters: {
                                        'communityId': community.id
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                ),

                // 2. Joined Communities
                RefreshIndicator(
                  color: AppColors.primaryCrimson,
                  onRefresh: notifier.refresh,
                  child: state.isLoadingJoined && state.joinedCommunities.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryCrimson,
                          ),
                        )
                      : state.joinedCommunities.isEmpty
                          ? Center(
                              child: Text(
                                'You have not joined any communities yet.',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.space16),
                              itemCount: state.joinedCommunities.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.space12),
                              itemBuilder: (context, index) {
                                final community =
                                    state.joinedCommunities[index];
                                return CommunityCardWidget(
                                  community: community,
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.communityDetail,
                                      pathParameters: {
                                        'communityId': community.id
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool? filterValue,
    bool? currentFilter,
    CommunityListNotifier notifier,
  ) {
    final isSelected = filterValue == currentFilter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => notifier.setPrivacyFilter(filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCrimson.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated),
          borderRadius: AppSpacing.roundedFull,
          border: Border.all(
            color:
                isSelected ? AppColors.primaryCrimson : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryCrimson
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
