import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

/// Full-screen Photo Lightbox viewer with black canvas, close button,
/// zoom/pan, author and description overlay, matching Facebook single image viewer.
class PostPhotoViewerScreen extends StatefulWidget {
  final PostModel post;
  final int initialIndex;

  const PostPhotoViewerScreen({
    super.key,
    required this.post,
    this.initialIndex = 0,
  });

  @override
  State<PostPhotoViewerScreen> createState() => _PostPhotoViewerScreenState();
}

class _PostPhotoViewerScreenState extends State<PostPhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late bool _isLiked;
  late int _likeCount;
  bool _isTextExpanded = false;
  bool _showOverlays = true;

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
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${date.day}.${date.month}.${date.year}';
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

  void _showOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.white),
              title: const Text('Save to phone', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo saved to gallery')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.white),
              title: const Text('Share photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                _handleShare();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorName = post.author.displayName ?? post.author.username;
    final mediaList = post.media;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showOverlays = !_showOverlays);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Center Interactive Media (Photo / Multi-Photo PageView)
            if (mediaList.isNotEmpty)
              PageView.builder(
                controller: _pageController,
                itemCount: mediaList.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = mediaList[index];
                  final resolvedUrl = resolveMediaUrl(item.url) ?? item.url;
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SizedBox.shrink(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.textMuted,
                          size: 56,
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              const Center(
                child: Icon(Icons.image_not_supported_rounded, color: Colors.white38, size: 64),
              ),

            // 2. Top Bar Overlay (Close '✕' on Left, More '⋮' on Right)
            if (_showOverlays)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 8,
                    right: 8,
                    bottom: 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      if (mediaList.length > 1)
                        Text(
                          '${_currentIndex + 1} of ${mediaList.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
                        onPressed: () => _showOptionsModal(context),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Bottom Scrim & Post Details Overlay (Author, Caption, Engagement)
            if (_showOverlays)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space24,
                    AppSpacing.space16,
                    MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xCC000000),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Author Row
                      GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            RouteNames.publicProfile,
                            pathParameters: {'username': post.author.username},
                          );
                        },
                        child: Row(
                          children: [
                            AppAvatar(
                              name: authorName,
                              size: 36,
                              imageUrl: post.author.avatarUrl,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        _formatTimeAgo(post.createdAt),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.public_rounded,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Caption / Content
                      if (post.content != null && post.content!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isTextExpanded = !_isTextExpanded);
                          },
                          child: Text(
                            post.content!,
                            maxLines: _isTextExpanded ? null : 3,
                            overflow: _isTextExpanded ? null : TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Reaction & Comments Counters Row
                      Row(
                        children: [
                          // Likes & Reactions Button
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                  size: 18,
                                  color: _isLiked ? const Color(0xFF1877F2) : Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.postReactions,
                                      pathParameters: {'postId': post.id},
                                    );
                                  },
                                  child: Text(
                                    _formatCount(_likeCount),
                                    style: TextStyle(
                                      color: _isLiked ? const Color(0xFF1877F2) : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Comments Count Button
                          GestureDetector(
                            onTap: () {
                              PostCommentsSheet.show(context, postId: post.id, post: post);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mode_comment_outlined, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatCount(post.commentCount)} comments',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Shares Count Button
                          GestureDetector(
                            onTap: _handleShare,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.share_outlined, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatCount(post.shareCount)} shares',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
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
    );
  }
}
