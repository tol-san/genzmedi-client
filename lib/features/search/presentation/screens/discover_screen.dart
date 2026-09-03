import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';
import 'package:client/features/search/presentation/notifiers/discover_notifier.dart';
import 'package:client/features/search/presentation/notifiers/discover_state.dart';
import 'package:client/features/search/presentation/widgets/discover_result_cards.dart';

// ─── Hardcoded topic list ─────────────────────────────────────────────────────

class _Topic {
  final String label;
  final IconData icon;
  final Color color;
  const _Topic(this.label, this.icon, this.color);
}

const _kTopics = [
  _Topic('Gaming', Icons.sports_esports_rounded, Color(0xFF7C3AED)),
  _Topic('Music', Icons.headphones_rounded, Color(0xFF0EA5E9)),
  _Topic('Streetwear', Icons.checkroom_rounded, Color(0xFFEC4899)),
  _Topic('Technology AI', Icons.memory_rounded, Color(0xFF10B981)),
  _Topic('Design', Icons.palette_outlined, Color(0xFFF59E0B)),
  _Topic('Anime', Icons.auto_awesome_rounded, Color(0xFFF97316)),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _heroAnim;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut));

    // Start hero entrance after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _heroAnim.forward());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heroAnim.dispose();
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

  void _openSearch([String? rawQuery]) {
    final query = (rawQuery ?? _searchController.text).trim();
    context.pushNamed(
      RouteNames.discoverSearch,
      queryParameters: {if (query.isNotEmpty) 'q': query},
    );
  }

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
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: state.isLoading
          ? const _DiscoverSkeleton()
          : state.errorMessage != null &&
                state.posts.isEmpty &&
                state.users.isEmpty &&
                state.communities.isEmpty
          ? EmptyStateWidget(
              icon: Icons.explore_off_outlined,
              title: 'Discover is taking a break',
              subtitle: state.errorMessage,
              actionText: 'Try again',
              onAction: notifier.loadInitial,
            )
          : RefreshIndicator(
              color: AppColors.primaryCrimson,
              onRefresh: notifier.refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.space32),
                children: [
                  // ── Hero ──────────────────────────────────────
                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: _buildHero(isDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // ── Topics ────────────────────────────────────
                  _SectionHeader(
                    title: 'Explore topics',
                    subtitle: 'Curated starting points',
                    icon: Icons.interests_rounded,
                    iconColor: AppColors.primaryCrimson,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _buildTopicChips(isDark),

                  // ── Creators ──────────────────────────────────
                  if (state.users.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space24),
                    const _SectionHeader(
                      title: 'Creators for you',
                      subtitle: 'People who share your interests',
                      icon: Icons.person_search_rounded,
                      iconColor: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    SizedBox(
                      height: 232,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space16,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: state.users.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.space12),
                        itemBuilder: (context, index) {
                          final item = state.users[index];
                          return DiscoverCreatorCard(
                            width: 272,
                            item: item,
                            isPending: state.pendingUserIds.contains(
                              item.user.id,
                            ),
                            onTap: () => context.pushNamed(
                              RouteNames.publicProfile,
                              pathParameters: {'username': item.user.username},
                            ),
                            onFollowToggle: () =>
                                notifier.toggleFollow(item.user.id),
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Communities ───────────────────────────────
                  if (state.communities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space24),
                    _SectionHeader(
                      title: 'Communities for you',
                      subtitle: 'Recommended from your interests',
                      icon: Icons.groups_rounded,
                      iconColor: AppColors.signalMint,
                      actionLabel: 'See all',
                      onAction: () =>
                          context.pushNamed(RouteNames.communityList),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    SizedBox(
                      height: 292,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space16,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: state.communities.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.space12),
                        itemBuilder: (context, index) {
                          final item = state.communities[index];
                          return DiscoverCommunityCard(
                            width: 296,
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
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Recommended posts ─────────────────────────
                  const SizedBox(height: AppSpacing.space24),
                  const _SectionHeader(
                    title: 'Recommended posts',
                    subtitle: 'Personalized for your interests',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  if (state.posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                      ),
                      child: EmptyStateWidget(
                        icon: Icons.dynamic_feed_outlined,
                        title: 'No recommendations yet',
                        subtitle: 'Choose interests or follow creators to personalise your Discover feed.',
                      ),
                    )
                  else
                    ...state.posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space12,
                          0,
                          AppSpacing.space12,
                          AppSpacing.space12,
                        ),
                        child: ClipRRect(
                          borderRadius: AppSpacing.roundedLg,
                          child: PostCardWidget(
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
                        ),
                      ),
                    ),

                  // ── Load-more indicator ───────────────────────
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

  // ─── Hero section ──────────────────────────────────────────────────────────

  Widget _buildHero(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurfaceElevated, AppColors.darkSurface]
                : [AppColors.primarySoft, const Color(0xFFFFFAFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(
            color: AppColors.primaryCrimson.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eyebrow label
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
                vertical: AppSpacing.space4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryCrimson.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    size: 13,
                    color: AppColors.primaryCrimson,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Discover',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space12),

            // Headline
            Text(
              'Find your next\nobsession',
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                height: 1.2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Search creators, communities, posts, and interests.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // Search bar tap-target
            GestureDetector(
              onTap: () => _openSearch(),
              child: AbsorbPointer(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search Discover…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: const Icon(Icons.arrow_forward_rounded),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedFull,
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.navyBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedFull,
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.navyBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: AppSpacing.space16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Topic chips ───────────────────────────────────────────────────────────

  Widget _buildTopicChips(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
        scrollDirection: Axis.horizontal,
        itemCount: _kTopics.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space8),
        itemBuilder: (context, index) {
          final topic = _kTopics[index];
          return _TopicChip(topic: topic, isDark: isDark, onTap: _openSearch);
        },
      ),
    );
  }
}

// ─── Topic chip ───────────────────────────────────────────────────────────────

class _TopicChip extends StatefulWidget {
  final _Topic topic;
  final bool isDark;
  final ValueChanged<String> onTap;

  const _TopicChip({
    required this.topic,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TopicChip> createState() => _TopicChipState();
}

class _TopicChipState extends State<_TopicChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppSpacing.durationFast,
      value: 1.0,
    );
    _scale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _press() async {
    _ctrl.reverse();
    await Future.delayed(AppSpacing.durationFast);
    _ctrl.forward();
    widget.onTap(widget.topic.label);
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final isDark = widget.isDark;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _press,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: topic.color.withValues(alpha: 0.08),
            borderRadius: AppSpacing.roundedFull,
            border: Border.all(color: topic.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(topic.icon, size: 16, color: topic.color),
              const SizedBox(width: AppSpacing.space8),
              Text(
                topic.label,
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primaryCrimson,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      child: Row(
        children: [
          // Colored left-border accent
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: AppSpacing.roundedFull,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.space12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryCrimson,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: const [
        AppSkeleton.rectangular(
          height: 168,
          borderRadius: AppSpacing.roundedLg,
        ),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.text(width: 180, height: 18),
        SizedBox(height: AppSpacing.space12),
        AppSkeleton.rectangular(height: 44, borderRadius: AppSpacing.roundedMd),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.text(width: 160, height: 18),
        SizedBox(height: AppSpacing.space12),
        AppSkeleton.rectangular(
          height: 220,
          borderRadius: AppSpacing.roundedLg,
        ),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.rectangular(
          height: 290,
          borderRadius: AppSpacing.roundedLg,
        ),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.rectangular(
          height: 280,
          borderRadius: AppSpacing.roundedLg,
        ),
      ],
    );
  }
}
