import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';

// ─── Creator Card ─────────────────────────────────────────────────────────────

class DiscoverCreatorCard extends StatelessWidget {
  final DiscoverUserModel item;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;
  final double? width;

  const DiscoverCreatorCard({
    super.key,
    required this.item,
    required this.isPending,
    required this.onTap,
    required this.onFollowToggle,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = item.user;

    return SizedBox(
      width: width,
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  width != null ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Avatar + Name row
                Row(
                  children: [
                    AppAvatar(
                      name: user.displayName ?? user.username,
                      imageUrl: user.avatarUrl,
                      size: 52,
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.displayName ?? user.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              if (user.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: AppColors.primaryCrimson,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Follower count
                const SizedBox(height: AppSpacing.space8),
                _MetaRow(
                  icon: Icons.people_outline_rounded,
                  label: _formatCount(user.followersCount),
                  suffix: ' followers',
                ),

                // Bio
                if (user.bio?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    user.bio!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],

                // Shared interests pill
                if (item.sharedInterests.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InterestPill(
                    count: item.mutualInterestCount,
                    interests: item.sharedInterests,
                  ),
                ],

                if (width != null)
                  const Spacer()
                else
                  const SizedBox(height: AppSpacing.space12),
                AppButton(
                  text: item.isFollowing ? 'Following' : 'Follow',
                  variant: item.isFollowing
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  size: AppButtonSize.small,
                  isLoading: isPending,
                  borderRadius: AppSpacing.roundedMd,
                  onPressed: isPending ? null : onFollowToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Community Card ───────────────────────────────────────────────────────────

class DiscoverCommunityCard extends StatelessWidget {
  final DiscoverCommunityModel item;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onMembershipToggle;
  final double? width;

  const DiscoverCommunityCard({
    super.key,
    required this.item,
    required this.isPending,
    required this.onTap,
    required this.onMembershipToggle,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final community = item.community;
    final hasCover = community.coverImageUrl?.trim().isNotEmpty == true;

    return SizedBox(
      width: width,
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image banner
              if (hasCover)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: resolveMediaUrl(community.coverImageUrl) ?? '',
                    height: 72,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (ctx, url, err) => const SizedBox.shrink(),
                    placeholder: (ctx, url) => Container(
                      height: 72,
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                )
              else
                // Gradient banner fallback
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.darkSurfaceElevated,
                                AppColors.darkSurface,
                              ]
                            : [
                                AppColors.primarySoft,
                                AppColors.lightBorderSubtle,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

              // Card body
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  borderRadius: hasCover
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(AppSpacing.radiusLg),
                        )
                      : AppSpacing.roundedLg,
                  border: Border.all(
                    color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name row
                    Row(
                      children: [
                        AppAvatar(
                          name: community.name,
                          imageUrl: community.avatarUrl,
                          size: 44,
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
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    community.isPrivate
                                        ? Icons.lock_outline_rounded
                                        : Icons.public_rounded,
                                    size: 12,
                                    color: community.isPrivate
                                        ? AppColors.warning
                                        : AppColors.signalMint,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    community.isPrivate ? 'Private' : 'Public',
                                    style: AppTypography.caption.copyWith(
                                      color: community.isPrivate
                                          ? AppColors.warning
                                          : AppColors.signalMint,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Description
                    if (community.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        community.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],

                    // Stats row
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MetaRow(
                          icon: Icons.people_outline_rounded,
                          label: _formatCount(community.memberCount),
                          suffix: '',
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        _MetaRow(
                          icon: Icons.article_outlined,
                          label: _formatCount(community.postCount),
                          suffix: '',
                        ),
                        if (item.isMatchedInterest &&
                            item.interestName != null) ...[
                          const Spacer(),
                          _MatchedInterestBadge(name: item.interestName!),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space12),
                    AppButton(
                      text: item.isJoinPending
                          ? 'Requested'
                          : item.isJoined
                          ? 'Joined'
                          : community.isPrivate
                          ? 'Request to join'
                          : 'Join community',
                      variant: item.isJoined || item.isJoinPending
                          ? AppButtonVariant.secondary
                          : AppButtonVariant.primary,
                      size: AppButtonSize.small,
                      isLoading: isPending,
                      borderRadius: AppSpacing.roundedMd,
                      onPressed: isPending || item.isJoinPending
                          ? null
                          : onMembershipToggle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Post Result Card ─────────────────────────────────────────────────────────

class DiscoverPostResultCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const DiscoverPostResultCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    final thumbUrl = firstMedia?.thumbnailUrl ?? firstMedia?.url;
    final hasThumb = thumbUrl?.trim().isNotEmpty == true;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedLg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    Row(
                      children: [
                        AppAvatar(
                          name: post.author.displayName ?? post.author.username,
                          imageUrl: post.author.avatarUrl,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: Text(
                            post.author.displayName ??
                                '@${post.author.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _PostTypeBadge(postType: post.postType),
                      ],
                    ),

                    // Title
                    if (post.title?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        post.title!.trim(),
                        maxLines: hasThumb ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],

                    // Body preview
                    if (post.content?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        post.content!.trim(),
                        maxLines: hasThumb ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],

                    // Engagement row
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MetaRow(
                          icon: Icons.favorite_border_rounded,
                          label: _formatCount(post.likeCount),
                          suffix: '',
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        _MetaRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: _formatCount(post.commentCount),
                          suffix: '',
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Media thumbnail
              if (hasThumb) ...[
                const SizedBox(width: AppSpacing.space12),
                ClipRRect(
                  borderRadius: AppSpacing.roundedMd,
                  child: CachedNetworkImage(
                    imageUrl: resolveMediaUrl(thumbUrl) ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (ctx, url, err) => Container(
                      width: 80,
                      height: 80,
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightBorderSubtle,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textMuted,
                        size: 28,
                      ),
                    ),
                    placeholder: (ctx, url) => Container(
                      width: 80,
                      height: 80,
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Interest Tile ────────────────────────────────────────────────────────────

class DiscoverInterestTile extends StatelessWidget {
  final DiscoverInterestModel interest;
  final VoidCallback onTap;

  const DiscoverInterestTile({
    super.key,
    required this.interest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentForSlug(interest.slug);

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              // Colored icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Icon(
                  _iconForSlug(interest.slug),
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interest.name,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (interest.description?.isNotEmpty == true)
                      Text(
                        interest.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      )
                    else
                      Text(
                        '#${interest.slug}',
                        style: AppTypography.caption,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.north_east_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String suffix;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$label$suffix',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _InterestPill extends StatelessWidget {
  final int count;
  final List<String> interests;

  const _InterestPill({required this.count, required this.interests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryCrimson.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.interests_rounded,
            size: 12,
            color: AppColors.primaryCrimson,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$count shared \u00b7 ${interests.take(2).join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryCrimson,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchedInterestBadge extends StatelessWidget {
  final String name;
  const _MatchedInterestBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.signalMint.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Text(
        '\u2713 $name',
        style: AppTypography.caption.copyWith(
          color: AppColors.signalMint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  final String postType;
  const _PostTypeBadge({required this.postType});

  Color get _badgeColor {
    switch (postType) {
      case 'video':
        return AppColors.primaryCrimson;
      case 'image':
        return AppColors.primaryElectricBlue;
      case 'poll':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  IconData get _badgeIcon {
    switch (postType) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'image':
        return Icons.image_outlined;
      case 'poll':
        return Icons.poll_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_badgeIcon, size: 16, color: _badgeColor);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

Color _accentForSlug(String slug) {
  final lower = slug.toLowerCase();
  if (lower.contains('gaming') || lower.contains('game')) {
    return const Color(0xFF7C3AED);
  }
  if (lower.contains('music') || lower.contains('audio')) {
    return const Color(0xFF0EA5E9);
  }
  if (lower.contains('fashion') || lower.contains('streetwear')) {
    return const Color(0xFFEC4899);
  }
  if (lower.contains('tech') || lower.contains('ai') || lower.contains('code')) {
    return const Color(0xFF10B981);
  }
  if (lower.contains('design') || lower.contains('art')) {
    return const Color(0xFFF59E0B);
  }
  if (lower.contains('anime') || lower.contains('manga')) {
    return const Color(0xFFF97316);
  }
  if (lower.contains('sport') || lower.contains('fitness')) {
    return const Color(0xFF22C55E);
  }
  if (lower.contains('food') || lower.contains('cook')) {
    return const Color(0xFFEF4444);
  }
  if (lower.contains('travel') || lower.contains('nature')) {
    return const Color(0xFF06B6D4);
  }
  return AppColors.primaryCrimson;
}

IconData _iconForSlug(String slug) {
  final lower = slug.toLowerCase();
  if (lower.contains('gaming') || lower.contains('game')) {
    return Icons.sports_esports_rounded;
  }
  if (lower.contains('music') || lower.contains('audio')) {
    return Icons.headphones_rounded;
  }
  if (lower.contains('fashion') || lower.contains('streetwear')) {
    return Icons.checkroom_rounded;
  }
  if (lower.contains('tech') || lower.contains('ai')) return Icons.memory_rounded;
  if (lower.contains('code') || lower.contains('dev')) return Icons.code_rounded;
  if (lower.contains('design') || lower.contains('art')) return Icons.palette_outlined;
  if (lower.contains('anime') || lower.contains('manga')) return Icons.auto_awesome_rounded;
  if (lower.contains('sport') || lower.contains('fitness')) return Icons.fitness_center_rounded;
  if (lower.contains('food') || lower.contains('cook')) return Icons.restaurant_outlined;
  if (lower.contains('travel') || lower.contains('nature')) return Icons.flight_takeoff_rounded;
  if (lower.contains('photo')) return Icons.camera_alt_outlined;
  if (lower.contains('film') || lower.contains('video')) return Icons.movie_outlined;
  return Icons.interests_rounded;
}
