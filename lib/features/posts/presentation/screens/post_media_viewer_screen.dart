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
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

/// Full-screen media viewer screen for single and multi-image posts.
/// Supports smooth horizontal swiping for multi-image albums, pinch-to-zoom, and post details.
class PostMediaViewerScreen extends StatefulWidget {
  final PostModel post;
  final int initialIndex;

  const PostMediaViewerScreen({
    super.key,
    required this.post,
    this.initialIndex = 0,
  });

  @override
  State<PostMediaViewerScreen> createState() => _PostMediaViewerScreenState();
}

class _PostMediaViewerScreenState extends State<PostMediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;
  bool _isTextExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.post.media.isNotEmpty ? widget.post.media.length - 1 : 0,
    );
    _pageController = PageController(initialPage: _currentIndex);
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _shareCount = widget.post.shareCount;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  Future<void> _handleShare() async {
    final urlToCopy = 'https://genzmedia.app/posts/${widget.post.id}';
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
    final authorName = post.author.displayName ?? post.author.username;
    final mediaList = post.media;

    return Scaffold(
      backgroundColor: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          "$authorName's post",
          style: AppTypography.heading.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.space16),
            child: AppAvatar(
              name: authorName,
              size: 32,
              imageUrl: post.author.avatarUrl,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Info Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.pushNamed(
                      RouteNames.publicProfile,
                      pathParameters: {'username': post.author.username},
                    );
                  },
                  child: AppAvatar(
                    name: authorName,
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
                          authorName,
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
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
                              post.visibility == 'private'
                                  ? Icons.lock_outline_rounded
                                  : Icons.public_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Post Caption / Description
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                0,
                AppSpacing.space16,
                AppSpacing.space12,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _isTextExpanded = !_isTextExpanded);
                },
                child: Text(
                  post.content!,
                  maxLines: _isTextExpanded ? null : 3,
                  overflow: _isTextExpanded ? null : TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ),

          // 3. Reaction Counters Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space8,
            ),
            child: Row(
              children: [
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
                        _formatCount(_likeCount),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    PostCommentsSheet.show(context, postId: post.id, post: post);
                  },
                  child: Text(
                    '${_formatCount(_commentCount)} comments',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Text(
                  '${_formatCount(_shareCount)} shares',
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
          ),

          // 4. Full-Screen Interactive Media Area
          Expanded(
            child: mediaList.isEmpty
                ? const SizedBox.shrink()
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: mediaList.length,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final item = mediaList[index];
                          final resolvedUrl =
                              resolveMediaUrl(item.url) ?? item.url;
                          return InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: GestureDetector(
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.photoViewer,
                                  pathParameters: {'postId': post.id},
                                  queryParameters: {'index': '$index'},
                                  extra: post,
                                );
                              },
                              child: Center(
                                child: CachedNetworkImage(
                                  imageUrl: resolvedUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const SizedBox.shrink(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.broken_image_rounded,
                                    color: AppColors.textMuted,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Multi-image Page Counter Badge (e.g. 1/4)
                      if (mediaList.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentIndex + 1}/${mediaList.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
          ),

          // 5. Action Buttons Bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: _isLiked
                                  ? AppColors.primaryCrimson
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Like',
                              style: AppTypography.buttonText.copyWith(
                                color: _isLiked
                                    ? AppColors.primaryCrimson
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                fontSize: 13,
                                fontWeight: _isLiked
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        PostCommentsSheet.show(context, postId: post.id, post: post);
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Comment',
                              style: AppTypography.buttonText.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _handleShare,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Share',
                              style: AppTypography.buttonText.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
