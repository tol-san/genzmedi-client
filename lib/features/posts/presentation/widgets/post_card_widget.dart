import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final Future<String?> Function()? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onTap;

  const PostCardWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onSave,
    this.onShare,
    this.onComment,
    this.onTap,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  int _currentImageIndex = 0;

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleShare() async {
    String? shareUrl;
    if (widget.onShare != null) {
      shareUrl = await widget.onShare!();
    }
    final urlToCopy = shareUrl ?? 'https://genzmedia.app/posts/${widget.post.id}';
    await Clipboard.setData(ClipboardData(text: urlToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post link copied: $urlToCopy'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final post = widget.post;
    final mediaList = post.media;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Author Row
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(
                        RouteNames.publicProfile,
                        pathParameters: {'username': post.author.username},
                      );
                    },
                    child: AppAvatar(
                      name: post.author.displayName ?? post.author.username,
                      size: 40,
                      imageUrl: post.author.avatarUrl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.pushNamed(
                          RouteNames.publicProfile,
                          pathParameters: {'username': post.author.username},
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.displayName ?? post.author.username,
                            style: AppTypography.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${post.author.username} · ${_formatTimeAgo(post.createdAt)}',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),

              // 2. Title & Content
              if (post.title != null && post.title!.isNotEmpty) ...[
                Text(
                  post.title!,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (post.content != null && post.content!.isNotEmpty) ...[
                Text(
                  post.content!,
                  style: AppTypography.body.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
              ],

              // 3. Media Carousel or Single Media Preview
              if (mediaList.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: AppSpacing.roundedSm,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: mediaList.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            final media = mediaList[index];
                            if (media.isVideo) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(color: Colors.black87),
                                  if (media.thumbnailUrl != null)
                                    CachedNetworkImage(
                                      imageUrl: media.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.video_library_rounded,
                                        color: AppColors.textMuted,
                                        size: 48,
                                      ),
                                    ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryCrimson.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return CachedNetworkImage(
                              imageUrl: media.url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                              ),
                            );
                          },
                        ),
                        // Page indicator dots for multi-media
                        if (mediaList.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                mediaList.length,
                                (idx) => Container(
                                  width: _currentImageIndex == idx ? 16 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == idx
                                        ? AppColors.primaryCrimson
                                        : Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
              ],

              // 4. Interactive Engagement Bar (Like, Comment, Save, Share)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like
                  _buildEngagementButton(
                    icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    activeColor: AppColors.primaryCrimson,
                    isActive: post.isLiked,
                    count: post.likeCount,
                    onTap: widget.onLike,
                  ),
                  // Comment
                  _buildEngagementButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeColor: AppColors.primaryCrimson,
                    isActive: false,
                    count: post.commentCount,
                    onTap: widget.onComment,
                  ),
                  // Save
                  _buildEngagementButton(
                    icon: post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    activeColor: AppColors.signalMint,
                    isActive: post.isSaved,
                    count: post.saveCount,
                    onTap: widget.onSave,
                  ),
                  // Share
                  _buildEngagementButton(
                    icon: Icons.share_outlined,
                    activeColor: AppColors.primaryCrimson,
                    isActive: false,
                    count: post.shareCount,
                    onTap: _handleShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required Color activeColor,
    required bool isActive,
    required int count,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive ? activeColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              _formatCount(count),
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
