import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
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
  final _featuredController = PageController(viewportFraction: 0.88);
  String? _selectedInterestId;
  int _featuredIndex = 0;

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
  }

  void _openSearch() => context.pushNamed(RouteNames.discoverSearch);

  void _openCommunity(String id) {
    context.pushNamed(
      RouteNames.communityDetail,
      pathParameters: {'communityId': id},
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
          next.communities.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final visibleCommunities = _selectedInterestId == null
        ? state.communities
        : state.communities
              .where((item) => item.community.interestId == _selectedInterestId)
              .toList();
    final featuredCount = math.min(3, visibleCommunities.length);
    final featured = visibleCommunities.take(featuredCount).toList();
    final moreCommunities = visibleCommunities.skip(featuredCount).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.midnightNavy
          : const Color(0xFFF7FAFE),
      body: SafeArea(
        bottom: false,
        child: state.isLoading
            ? const _DiscoverSkeleton()
            : state.errorMessage != null && state.communities.isEmpty
            ? EmptyStateWidget(
                icon: Icons.groups_outlined,
                title: 'Communities are taking a break',
                subtitle: state.errorMessage,
                actionText: 'Try again',
                onAction: notifier.loadInitial,
              )
            : RefreshIndicator(
                color: AppColors.primaryElectricBlue,
                onRefresh: notifier.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _SearchField(onTap: _openSearch),
                    const SizedBox(height: AppSpacing.space16),
                    _InterestFilters(
                      interests: state.interests,
                      selectedId: _selectedInterestId,
                      onSelected: (id) {
                        setState(() {
                          _selectedInterestId = id;
                          _featuredIndex = 0;
                        });
                        if (_featuredController.hasClients) {
                          _featuredController.jumpToPage(0);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    const _SectionTitle('Featured for you'),
                    const SizedBox(height: AppSpacing.space8),
                    if (featured.isEmpty)
                      _NoCommunitiesCard(
                        onTap: () =>
                            context.pushNamed(RouteNames.communityList),
                      )
                    else ...[
                      SizedBox(
                        height: 132,
                        child: PageView.builder(
                          controller: _featuredController,
                          padEnds: false,
                          itemCount: featured.length,
                          onPageChanged: (index) {
                            setState(() => _featuredIndex = index);
                          },
                          itemBuilder: (context, index) {
                            final item = featured[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == featured.length - 1 ? 0 : 12,
                              ),
                              child: _FeaturedCommunityCard(
                                item: item,
                                isPending: state.pendingCommunityIds.contains(
                                  item.community.id,
                                ),
                                onTap: () => _openCommunity(item.community.id),
                                onMembershipToggle: () =>
                                    notifier.toggleCommunity(item.community.id),
                              ),
                            );
                          },
                        ),
                      ),
                      if (featured.length > 1) ...[
                        const SizedBox(height: AppSpacing.space8),
                        _PageIndicator(
                          count: featured.length,
                          activeIndex: _featuredIndex.clamp(
                            0,
                            featured.length - 1,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.space24),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle('More communities'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.pushNamed(RouteNames.communityList),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    if (moreCommunities.isEmpty)
                      _BrowseAllRow(
                        onTap: () =>
                            context.pushNamed(RouteNames.communityList),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.72,
                            ),
                        itemCount: moreCommunities.length,
                        itemBuilder: (context, index) {
                          final item = moreCommunities[index];
                          return _CommunityGridCard(
                            item: item,
                            isPending: state.pendingCommunityIds.contains(
                              item.community.id,
                            ),
                            onTap: () => _openCommunity(item.community.id),
                            onMembershipToggle: () =>
                                notifier.toggleCommunity(item.community.id),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: 'Search communities',
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: isDark ? AppColors.navyBorder : const Color(0xFFD5E0EE),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: isDark ? AppColors.navyBorder : const Color(0xFFD5E0EE),
          ),
        ),
      ),
    );
  }
}

class _InterestFilters extends StatelessWidget {
  final List<DiscoverInterestModel> interests;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _InterestFilters({
    required this.interests,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final visible = interests.take(3).toList();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'All',
              icon: Icons.auto_awesome_rounded,
              selected: selectedId == null,
              onTap: () => onSelected(null),
            );
          }
          final interest = visible[index - 1];
          return _FilterChip(
            label: interest.name,
            icon: _iconForInterest(interest.slug),
            selected: selectedId == interest.id,
            onTap: () => onSelected(interest.id),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? const Color(0xFF079BE5)
          : isDark
          ? AppColors.darkSurface
          : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? const Color(0xFF079BE5)
              : isDark
              ? AppColors.navyBorder
              : const Color(0xFFD5E0EE),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : null),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  color: selected ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.title.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FeaturedCommunityCard extends StatelessWidget {
  final DiscoverCommunityModel item;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onMembershipToggle;

  const _FeaturedCommunityCard({
    required this.item,
    required this.isPending,
    required this.onTap,
    required this.onMembershipToggle,
  });

  @override
  Widget build(BuildContext context) {
    final community = item.community;
    return Material(
      color: AppColors.midnightNavy,
      borderRadius: AppSpacing.roundedMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CommunityCover(url: community.coverImageUrl),
            ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.interestName?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.46),
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Text(
                            item.interestName!,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      _MembershipButton(
                        item: item,
                        isPending: isPending,
                        onPressed: onMembershipToggle,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    community.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_compactCount(community.memberCount)} members${community.description?.isNotEmpty == true ? ' · ${community.description}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipButton extends StatelessWidget {
  final DiscoverCommunityModel item;
  final bool isPending;
  final VoidCallback onPressed;

  const _MembershipButton({
    required this.item,
    required this.isPending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = item.isJoinPending
        ? 'Requested'
        : item.isJoined
        ? 'Joined'
        : item.community.isPrivate
        ? 'Request'
        : 'Join';
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: isPending || item.isJoinPending ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF058BCF),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.8),
          disabledForegroundColor: const Color(0xFF058BCF),
          padding: const EdgeInsets.symmetric(horizontal: 17),
          visualDensity: VisualDensity.compact,
        ),
        child: isPending
            ? const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _PageIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2768E8),
          borderRadius: AppSpacing.roundedFull,
          boxShadow: const [
            BoxShadow(
              color: Color(0x332768E8),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            count,
            (index) => AnimatedContainer(
              duration: AppSpacing.durationFast,
              width: index == activeIndex ? 8 : 6,
              height: index == activeIndex ? 8 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == activeIndex
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityGridCard extends StatelessWidget {
  final DiscoverCommunityModel item;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onMembershipToggle;

  const _CommunityGridCard({
    required this.item,
    required this.isPending,
    required this.onTap,
    required this.onMembershipToggle,
  });

  @override
  Widget build(BuildContext context) {
    final community = item.community;
    return Material(
      color: AppColors.midnightNavy,
      borderRadius: AppSpacing.roundedMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CommunityCover(url: community.coverImageUrl),
            ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
            Positioned(
              top: 8,
              right: 8,
              child: _RoundMembershipAction(
                item: item,
                isPending: isPending,
                onPressed: onMembershipToggle,
              ),
            ),
            Positioned(
              left: 12,
              right: 10,
              bottom: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_compactCount(community.memberCount)} members',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundMembershipAction extends StatelessWidget {
  final DiscoverCommunityModel item;
  final bool isPending;
  final VoidCallback onPressed;

  const _RoundMembershipAction({
    required this.item,
    required this.isPending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final joined = item.isJoined || item.isJoinPending;
    return Material(
      color: joined ? const Color(0xFF0AA7E8) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isPending || item.isJoinPending ? null : onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: isPending
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    joined ? Icons.check_rounded : Icons.add_rounded,
                    color: joined ? Colors.white : const Color(0xFF168DCC),
                    size: 21,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CommunityCover extends StatelessWidget {
  final String? url;

  const _CommunityCover({this.url});

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF123653),
        child: Center(
          child: Icon(Icons.groups_rounded, color: Colors.white54, size: 36),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: Color(0xFF123653)),
      errorWidget: (_, _, _) => const ColoredBox(
        color: Color(0xFF123653),
        child: Center(
          child: Icon(Icons.groups_rounded, color: Colors.white54, size: 36),
        ),
      ),
    );
  }
}

class _NoCommunitiesCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoCommunitiesCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.explore_outlined),
      label: const Text('Explore all communities'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
    );
  }
}

class _BrowseAllRow extends StatelessWidget {
  final VoidCallback onTap;

  const _BrowseAllRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: const Text('Browse all communities'),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: const [
        AppSkeleton.rectangular(height: 48, borderRadius: AppSpacing.roundedMd),
        SizedBox(height: AppSpacing.space16),
        AppSkeleton.rectangular(height: 36, borderRadius: AppSpacing.roundedLg),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.text(width: 150, height: 20),
        SizedBox(height: AppSpacing.space8),
        AppSkeleton.rectangular(
          height: 132,
          borderRadius: AppSpacing.roundedMd,
        ),
        SizedBox(height: AppSpacing.space24),
        AppSkeleton.text(width: 100, height: 20),
        SizedBox(height: AppSpacing.space8),
        Row(
          children: [
            Expanded(
              child: AppSkeleton.rectangular(
                height: 104,
                borderRadius: AppSpacing.roundedMd,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppSkeleton.rectangular(
                height: 104,
                borderRadius: AppSpacing.roundedMd,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

IconData _iconForInterest(String slug) {
  final value = slug.toLowerCase();
  if (value.contains('sport') || value.contains('football')) {
    return Icons.sports_basketball_rounded;
  }
  if (value.contains('game')) return Icons.sports_esports_rounded;
  if (value.contains('music')) return Icons.headphones_rounded;
  if (value.contains('tech')) return Icons.memory_rounded;
  if (value.contains('photo')) return Icons.photo_camera_rounded;
  if (value.contains('fashion')) return Icons.checkroom_rounded;
  return Icons.interests_rounded;
}

String _compactCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(count >= 10000000 ? 0 : 1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}K';
  }
  return '$count';
}
