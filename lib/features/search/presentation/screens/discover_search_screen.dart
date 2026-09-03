import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/presentation/notifiers/discover_search_notifier.dart';
import 'package:client/features/search/presentation/notifiers/discover_search_state.dart';
import 'package:client/features/search/presentation/widgets/discover_result_cards.dart';

// ─── Recent-search persistence key ───────────────────────────────────────────
const _kRecentKey = 'discover_recent_searches';
const _kMaxRecent = 8;

class DiscoverSearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;

  const DiscoverSearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<DiscoverSearchScreen> createState() =>
      _DiscoverSearchScreenState();
}

class _DiscoverSearchScreenState extends ConsumerState<DiscoverSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  final _scrollController = ScrollController();
  late final AnimationController _searchBarAnimController;
  late final Animation<double> _searchBarGlow;
  Timer? _debounce;

  List<String> _recentSearches = [];
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _scrollController.addListener(_onScroll);

    _searchBarAnimController = AnimationController(
      vsync: this,
      duration: AppSpacing.durationMedium,
    );
    _searchBarGlow = CurvedAnimation(
      parent: _searchBarAnimController,
      curve: Curves.easeOut,
    );

    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchBarAnimController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // ─── Recent searches ───────────────────────────────────────────────────────

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList(_kRecentKey) ?? [];
      });
    }
  }

  Future<void> _saveRecent(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [
      query.trim(),
      ..._recentSearches.where((q) => q != query.trim()),
    ].take(_kMaxRecent).toList();
    await prefs.setStringList(_kRecentKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _removeRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = _recentSearches.where((q) => q != query).toList();
    await prefs.setStringList(_kRecentKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  // ─── Scroll pagination ─────────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.extentAfter < 320) {
      ref
          .read(discoverSearchNotifierProvider(widget.initialQuery).notifier)
          .loadMore();
    }
  }

  // ─── Query handling ────────────────────────────────────────────────────────

  void _onQueryChanged(String query) {
    setState(() {}); // rebuild to toggle clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref
            .read(discoverSearchNotifierProvider(widget.initialQuery).notifier)
            .updateQuery(query);
        _resetScroll();
      }
    });
  }

  void _submitQuery(String query) {
    _debounce?.cancel();
    ref
        .read(discoverSearchNotifierProvider(widget.initialQuery).notifier)
        .updateQuery(query);
    _saveRecent(query);
    _resetScroll();
    FocusScope.of(context).unfocus();
  }

  void _applyRecent(String query) {
    _controller.text = query;
    _submitQuery(query);
  }

  void _clearSearch() {
    _controller.clear();
    ref
        .read(discoverSearchNotifierProvider(widget.initialQuery).notifier)
        .updateQuery('');
    setState(() {});
  }

  void _resetScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels > 0) {
      _scrollController.animateTo(
        0,
        duration: AppSpacing.durationMedium,
        curve: AppSpacing.curveEntrance,
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = discoverSearchNotifierProvider(widget.initialQuery);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<DiscoverSearchState>(provider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          !next.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.space16),
          child: _SearchBar(
            controller: _controller,
            isFocused: _isFocused,
            glowAnimation: _searchBarGlow,
            onFocusChanged: (v) {
              setState(() => _isFocused = v);
              if (v) {
                _searchBarAnimController.forward();
              } else {
                _searchBarAnimController.reverse();
              }
            },
            onChanged: _onQueryChanged,
            onSubmitted: _submitQuery,
            onClear: _clearSearch,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _CategoryTabBar(
            state: state,
            isDark: isDark,
            onSelected: (cat) {
              notifier.setCategory(cat);
              _resetScroll();
            },
          ),
        ),
      ),
      body: _buildBody(state, notifier, isDark),
    );
  }

  Widget _buildBody(
    DiscoverSearchState state,
    DiscoverSearchNotifier notifier,
    bool isDark,
  ) {
    // Empty query: show recent searches
    if (state.query.isEmpty) {
      return _RecentSearches(
        searches: _recentSearches,
        isDark: isDark,
        onTap: _applyRecent,
        onRemove: _removeRecent,
        onClearAll: _clearAllRecent,
      );
    }

    if (state.isLoading) {
      return const _SearchSkeleton();
    }

    if (state.errorMessage != null && state.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'Search unavailable',
        subtitle: state.errorMessage,
        actionText: 'Retry',
        onAction: notifier.search,
      );
    }

    if (state.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No results for "${state.query}"',
        subtitle: 'Try different keywords or switch categories.',
        actionText: 'Clear search',
        onAction: _clearSearch,
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        AppSpacing.space32,
      ),
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.category == DiscoverSearchCategory.all
                      ? 'Results for "${state.query}"'
                      : state.category.label,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              if (state.totalResults > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space8,
                    vertical: AppSpacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCrimson.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Text(
                    '${state.totalResults}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Results body
        if (state.category == DiscoverSearchCategory.all)
          ..._buildAllResults(state, notifier)
        else
          ..._buildCategoryResults(state, notifier),

        // Load-more indicator
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.space20),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAllResults(
    DiscoverSearchState state,
    DiscoverSearchNotifier notifier,
  ) {
    return [
      if (state.users.isNotEmpty) ...[
        _ResultHeading(
          title: 'Creators',
          count: state.users.length,
          onSeeAll: () => notifier.setCategory(DiscoverSearchCategory.users),
        ),
        ...state.users.take(3).map((item) => _creatorTile(item, state, notifier)),
        const SizedBox(height: AppSpacing.space20),
      ],
      if (state.communities.isNotEmpty) ...[
        _ResultHeading(
          title: 'Communities',
          count: state.communities.length,
          onSeeAll: () =>
              notifier.setCategory(DiscoverSearchCategory.communities),
        ),
        ...state.communities
            .take(3)
            .map((item) => _communityTile(item, state, notifier)),
        const SizedBox(height: AppSpacing.space20),
      ],
      if (state.posts.isNotEmpty) ...[
        _ResultHeading(
          title: 'Posts',
          count: state.posts.length,
          onSeeAll: () => notifier.setCategory(DiscoverSearchCategory.posts),
        ),
        ...state.posts.take(3).map(_postTile),
        const SizedBox(height: AppSpacing.space20),
      ],
      if (state.interests.isNotEmpty) ...[
        _ResultHeading(
          title: 'Interests',
          count: state.interests.length,
          onSeeAll: () =>
              notifier.setCategory(DiscoverSearchCategory.interests),
        ),
        ...state.interests.take(3).map(
              (interest) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: DiscoverInterestTile(
                  interest: interest,
                  onTap: () => _searchInterest(interest, notifier),
                ),
              ),
            ),
      ],
    ];
  }

  List<Widget> _buildCategoryResults(
    DiscoverSearchState state,
    DiscoverSearchNotifier notifier,
  ) {
    switch (state.category) {
      case DiscoverSearchCategory.users:
        return state.users
            .map((item) => _creatorTile(item, state, notifier))
            .toList();
      case DiscoverSearchCategory.communities:
        return state.communities
            .map((item) => _communityTile(item, state, notifier))
            .toList();
      case DiscoverSearchCategory.posts:
        return state.posts.map(_postTile).toList();
      case DiscoverSearchCategory.interests:
        return state.interests
            .map(
              (interest) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: DiscoverInterestTile(
                  interest: interest,
                  onTap: () => _searchInterest(interest, notifier),
                ),
              ),
            )
            .toList();
      case DiscoverSearchCategory.all:
        return const [];
    }
  }

  Widget _creatorTile(
    DiscoverUserModel item,
    DiscoverSearchState state,
    DiscoverSearchNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: DiscoverCreatorCard(
        item: item,
        isPending: state.pendingUserIds.contains(item.user.id),
        onTap: () => context.pushNamed(
          RouteNames.publicProfile,
          pathParameters: {'username': item.user.username},
        ),
        onFollowToggle: () => notifier.toggleFollow(item.user.id),
      ),
    );
  }

  Widget _communityTile(
    DiscoverCommunityModel item,
    DiscoverSearchState state,
    DiscoverSearchNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: DiscoverCommunityCard(
        item: item,
        isPending: state.pendingCommunityIds.contains(item.community.id),
        onTap: () => context.pushNamed(
          RouteNames.communityDetail,
          pathParameters: {'communityId': item.community.id},
        ),
        onMembershipToggle: () => notifier.toggleCommunity(item.community.id),
      ),
    );
  }

  Widget _postTile(PostModel post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: DiscoverPostResultCard(
        post: post,
        onTap: () => context.pushNamed(
          RouteNames.postDetail,
          pathParameters: {'postId': post.id},
        ),
      ),
    );
  }

  Future<void> _searchInterest(
    DiscoverInterestModel interest,
    DiscoverSearchNotifier notifier,
  ) async {
    _controller.text = interest.name;
    await notifier.setCategory(DiscoverSearchCategory.all);
    await notifier.updateQuery(interest.name);
    _saveRecent(interest.name);
    if (mounted) setState(() {});
  }
}

// ─── Search bar widget ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isFocused;
  final Animation<double> glowAnimation;
  final ValueChanged<bool> onFocusChanged;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.isFocused,
    required this.glowAnimation,
    required this.onFocusChanged,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedFull,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCrimson
                    .withValues(alpha: 0.18 * glowAnimation.value),
                blurRadius: 12 * glowAnimation.value,
                spreadRadius: 1 * glowAnimation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Focus(
        onFocusChange: onFocusChanged,
        child: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AppTypography.body.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Search creators, communities…',
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClear,
                  ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: AppSpacing.space16,
            ),
            border: OutlineInputBorder(
              borderRadius: AppSpacing.roundedFull,
              borderSide: BorderSide(
                color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.roundedFull,
              borderSide: BorderSide(
                color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.roundedFull,
              borderSide: const BorderSide(
                color: AppColors.primaryCrimson,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category tab bar ─────────────────────────────────────────────────────────

class _CategoryTabBar extends StatelessWidget {
  final DiscoverSearchState state;
  final bool isDark;
  final ValueChanged<DiscoverSearchCategory> onSelected;

  const _CategoryTabBar({
    required this.state,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: DiscoverSearchCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space8),
        itemBuilder: (context, index) {
          final category = DiscoverSearchCategory.values[index];
          final selected = state.category == category;
          final count = _countForCategory(category, state);

          return GestureDetector(
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: AppSpacing.durationFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space8,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryCrimson
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: AppSpacing.roundedFull,
                border: Border.all(
                  color: selected
                      ? AppColors.primaryCrimson
                      : (isDark
                          ? AppColors.navyBorder
                          : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.label,
                    style: AppTypography.caption.copyWith(
                      color: selected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (count > 0 && state.query.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.primaryCrimson.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: AppTypography.caption.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.primaryCrimson,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _countForCategory(DiscoverSearchCategory cat, DiscoverSearchState s) {
    switch (cat) {
      case DiscoverSearchCategory.all:
        return s.totalResults;
      case DiscoverSearchCategory.users:
        return s.users.length;
      case DiscoverSearchCategory.communities:
        return s.communities.length;
      case DiscoverSearchCategory.posts:
        return s.posts.length;
      case DiscoverSearchCategory.interests:
        return s.interests.length;
    }
  }
}

// ─── Recent searches panel ────────────────────────────────────────────────────

class _RecentSearches extends StatelessWidget {
  final List<String> searches;
  final bool isDark;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _RecentSearches({
    required this.searches,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.manage_search_rounded,
        title: 'Search GenZ Media',
        subtitle:
            'Find creators, communities, posts, and interests all in one place.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent searches',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        ...searches.map(
          (query) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(
              Icons.history_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            title: Text(
              query,
              style: AppTypography.body.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => onRemove(query),
              tooltip: 'Remove',
            ),
            onTap: () => onTap(query),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Result section heading ───────────────────────────────────────────────────

class _ResultHeading extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onSeeAll;

  const _ResultHeading({
    required this.title,
    required this.count,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primaryCrimson,
              borderRadius: AppSpacing.roundedFull,
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              title,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (count > 3)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryCrimson,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.space16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
      itemBuilder: (_, i) => AppSkeleton.rectangular(
        height: i.isEven ? 96 : 80,
        borderRadius: AppSpacing.roundedLg,
      ),
    );
  }
}
