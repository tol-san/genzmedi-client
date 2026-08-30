import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/feed_video_player_widget.dart';
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

/// Full-width seamless post item (No isolated card containers) for home and community feeds.
/// Features auto-playing inline video, edge-to-edge media collages, author header, and 3-button action bar (Like, Comment, Share).
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
    if (date == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w';
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

  void _showOptionsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share post'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleShare();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Copy link'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleShare();
                },
              ),
              ListTile(
                leading: Icon(
                  widget.post.isSaved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
                ),
                title: Text(widget.post.isSaved ? 'Remove from saved' : 'Save post'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSave?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.error),
                title: const Text('Report post', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported. Thank you for keeping our community safe.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final post = widget.post;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Header Row
          _buildHeader(context, post, isDark),

          // 2. Title & Post Content Text
          _buildContentText(post, isDark),

          // 3. Edge-to-Edge Media Grid (Collage Layout with Auto-Playing Video)
          if (post.media.isNotEmpty) _buildMediaCollage(context, post.media, isDark),

          // 4. Reactions & Counters Row
          _buildCountersRow(post, isDark),

          // 5. Action Buttons Bar (Like, Comment, Share)
          _buildActionBar(context, post, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PostModel post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space12,
        AppSpacing.space8,
        AppSpacing.space8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.author.displayName ?? post.author.username,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        post.visibility == 'private' ? Icons.lock_outline_rounded : Icons.public_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            splashRadius: 20,
            onPressed: () => _showOptionsModal(context),
          ),
        ],
      ),
    );
  }

  void _onMediaTap(BuildContext context, int index) {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    final media = widget.post.media;
    if (media.isNotEmpty && index < media.length) {
      final item = media[index];
      if (item.isVideo || widget.post.isVideo) {
        context.pushNamed(
          RouteNames.shortsViewer,
          queryParameters: {'postId': widget.post.id},
          extra: widget.post,
        );
        return;
      }
    } else if (widget.post.isVideo) {
      context.pushNamed(
        RouteNames.shortsViewer,
        queryParameters: {'postId': widget.post.id},
        extra: widget.post,
      );
      return;
    }

    if (media.isNotEmpty) {
      // Single image post OR tapping any specific image in a multi-image collage
      // -> Opens full-screen photo lightbox (Image 3)
      context.pushNamed(
        RouteNames.photoViewer,
        pathParameters: {'postId': widget.post.id},
        queryParameters: {'index': '$index'},
        extra: widget.post,
      );
    } else {
      // Text-only post -> Open Comments Bottom Sheet directly
      PostCommentsSheet.show(context, postId: widget.post.id, post: widget.post);
    }
  }

  Widget _buildContentText(PostModel post, bool isDark) {
    final hasContent = post.content != null && post.content!.trim().isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        0,
        AppSpacing.space16,
        AppSpacing.space12,
      ),
      child: GestureDetector(
        onTap: () {
          if (post.isVideo) {
            context.pushNamed(
              RouteNames.shortsViewer,
              queryParameters: {'postId': post.id},
              extra: post,
            );
          } else if (post.media.length > 1) {
            // Multi-image post text tap -> Show full post with image carousel (Image 4)
            context.pushNamed(
              RouteNames.mediaViewer,
              pathParameters: {'postId': post.id},
              queryParameters: {'index': '0'},
              extra: post,
            );
          } else if (post.media.length == 1) {
            // Single image post text tap -> Show full-screen photo lightbox (Image 3)
            context.pushNamed(
              RouteNames.photoViewer,
              pathParameters: {'postId': post.id},
              queryParameters: {'index': '0'},
              extra: post,
            );
          } else {
            // Text-only post -> Comments Sheet
            PostCommentsSheet.show(context, postId: post.id, post: post);
          }
        },
        child: Text(
          post.content!,
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCollage(BuildContext context, List<MediaItemModel> media, bool isDark) {
    if (media.isEmpty) return const SizedBox.shrink();

    if (media.length == 1) {
      final item = media[0];
      if (item.isVideo) {
        final explicitRatio = (item.width != null && item.height != null && item.height! > 0)
            ? (item.width! / item.height!).clamp(9 / 16, 16 / 9)
            : null;

        return FeedVideoPlayerWidget(
          videoUrl: item.url,
          thumbnailUrl: item.thumbnailUrl,
          aspectRatio: explicitRatio,
          onTap: () => _onMediaTap(context, 0),
        );
      }
      return AspectRatio(
        aspectRatio: (item.width != null && item.height != null && item.height! > 0)
            ? (item.width! / item.height!).clamp(0.75, 1.8)
            : 16 / 9,
        child: _buildMediaItem(context, item, isDark, index: 0),
      );
    }

    if (media.length == 2) {
      return SizedBox(
        height: 320,
        child: Row(
          children: [
            Expanded(child: _buildMediaItem(context, media[0], isDark, index: 0)),
            const SizedBox(width: 2),
            Expanded(child: _buildMediaItem(context, media[1], isDark, index: 1)),
          ],
        ),
      );
    }

    if (media.length == 3) {
      return SizedBox(
        height: 320,
        child: Row(
          children: [
            Expanded(flex: 3, child: _buildMediaItem(context, media[0], isDark, index: 0)),
            const SizedBox(width: 2),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: _buildMediaItem(context, media[1], isDark, index: 1)),
                  const SizedBox(height: 2),
                  Expanded(child: _buildMediaItem(context, media[2], isDark, index: 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (media.length == 4) {
      return SizedBox(
        height: 320,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, media[0], isDark, index: 0)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildMediaItem(context, media[1], isDark, index: 1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, media[2], isDark, index: 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildMediaItem(context, media[3], isDark, index: 3)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 5+ media items: 2x2 grid with +N counter on the 4th item
    return SizedBox(
      height: 320,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, media[0], isDark, index: 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildMediaItem(context, media[1], isDark, index: 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, media[2], isDark, index: 2)),
                const SizedBox(width: 2),
                Expanded(
                  child: _buildMediaItem(
                    context,
                    media[3],
                    isDark,
                    index: 3,
                    overlayCount: media.length - 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(
    BuildContext context,
    MediaItemModel item,
    bool isDark, {
    required int index,
    int? overlayCount,
  }) {
    if (item.isVideo) {
      return FeedVideoPlayerWidget(
        videoUrl: item.url,
        thumbnailUrl: item.thumbnailUrl,
        onTap: () => _onMediaTap(context, index),
      );
    }

    final resolvedImageUrl = resolveMediaUrl(item.url) ?? item.url;

    return GestureDetector(
      onTap: () => _onMediaTap(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: resolvedImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
            ),
          ),
          if (overlayCount != null && overlayCount > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Text(
                '+$overlayCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountersRow(PostModel post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space8,
      ),
      child: Row(
        children: [
          // Left: Reaction / Likes badge & count
          GestureDetector(
            onTap: () {
              context.pushNamed(
                RouteNames.postReactions,
                pathParameters: {'postId': post.id},
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryCrimson,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCount(post.likeCount),
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right: Comments and Shares counts
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  PostCommentsSheet.show(context, postId: post.id, post: post);
                },
                child: Text(
                  '${_formatCount(post.commentCount)} comments',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Text(
                '${_formatCount(post.shareCount)} shares',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, PostModel post, bool isDark) {
    final borderColor = isDark ? AppColors.navyBorder : AppColors.lightBorder;
    return Column(
      children: [
        Divider(height: 1, thickness: 0.8, color: borderColor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: 'Like',
                activeColor: AppColors.primaryCrimson,
                isActive: post.isLiked,
                onTap: widget.onLike,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
                activeColor: AppColors.primaryCrimson,
                isActive: false,
                onTap: widget.onComment ??
                    () {
                      PostCommentsSheet.show(context, postId: post.id, post: post);
                    },
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                activeColor: AppColors.primaryCrimson,
                isActive: false,
                onTap: _handleShare,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? activeColor
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.buttonText.copyWith(
                  color: color,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
