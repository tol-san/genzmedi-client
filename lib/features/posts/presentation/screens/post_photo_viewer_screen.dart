import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/services/photo_download_service.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

/// Full-screen Photo Lightbox viewer with black canvas, close button,
/// zoom/pan, author and description overlay, matching Facebook single image viewer.
class PostPhotoViewerScreen extends ConsumerStatefulWidget {
  final PostModel post;
  final int initialIndex;

  const PostPhotoViewerScreen({
    super.key,
    required this.post,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<PostPhotoViewerScreen> createState() =>
      _PostPhotoViewerScreenState();
}

class _PostPhotoViewerScreenState extends ConsumerState<PostPhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late bool _isLiked;
  late int _likeCount;
  bool _isTextExpanded = false;
  bool _showOverlays = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';

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
    final mediaList = widget.post.media;
    final isMulti = mediaList.length > 1;

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
              title: Text(
                isMulti ? 'Save this photo' : 'Save to phone',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Save photo #${_currentIndex + 1} to device gallery',
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _handleSaveCurrentImage();
              },
            ),
            if (isMulti)
              ListTile(
                leading: const Icon(Icons.download_for_offline_rounded, color: Colors.white),
                title: Text(
                  'Save all photos (${mediaList.length})',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Download all ${mediaList.length} photos to gallery',
                  style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleSaveAllImages();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.white),
              title: const Text(
                'Share photo',
                style: TextStyle(color: Colors.white),
              ),
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

  Future<void> _handleSaveCurrentImage() async {
    if (_isDownloading) return;

    final mediaList = widget.post.media;
    if (mediaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo available to download')),
      );
      return;
    }

    final currentMedia = mediaList[_currentIndex];
    final url = currentMedia.url;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid photo URL')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = 'Preparing download...';
    });

    final service = ref.read(photoDownloadServiceProvider);
    final result = await service.downloadPhoto(
      url: url,
      postId: widget.post.id,
      mediaId: currentMedia.id,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _downloadProgress = p;
            _downloadStatusText = p < 1.0
                ? 'Downloading photo (${(p * 100).toInt()}%)'
                : 'Saving to device gallery...';
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _downloadStatusText = '';
    });

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text('Photo saved to gallery (${result.filename})'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (result.isPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Photo library permission required.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: result.isPermanentlyDenied
              ? SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => service.openSettings(),
                )
              : null,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Download failed.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleSaveCurrentImage,
          ),
        ),
      );
    }
  }

  Future<void> _handleSaveAllImages() async {
    if (_isDownloading) return;

    final mediaList = widget.post.media;
    if (mediaList.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = 'Preparing to download ${mediaList.length} photos...';
    });

    final service = ref.read(photoDownloadServiceProvider);
    final results = await service.downloadAllPhotos(
      mediaList: mediaList,
      postId: widget.post.id,
      onProgress: (current, total, p) {
        if (mounted) {
          setState(() {
            _downloadProgress = (current + p) / total;
            _downloadStatusText =
                'Saving photo ${current + 1} of $total (${(p * 100).toInt()}%)';
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _downloadStatusText = '';
    });

    final successCount = results.where((r) => r.isSuccess).length;
    final anyPermissionDenied = results.any((r) => r.isPermissionDenied);

    if (successCount == results.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: AppSpacing.space8),
              Text('All $successCount photos saved to gallery!'),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
    } else if (anyPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo library permission required to save photos.'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => service.openSettings(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $successCount of ${results.length} photos.'),
          backgroundColor: const Color(0xFF1E293B),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleSaveAllImages,
          ),
        ),
      );
    }
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
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.white38,
                  size: 64,
                ),
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
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
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
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => _showOptionsModal(context),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Download Progress Banner
            if (_isDownloading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withAlpha(245),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryCrimson,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _downloadStatusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_downloadProgress > 0) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _downloadProgress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryCrimson,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
                            overflow: _isTextExpanded
                                ? null
                                : TextOverflow.ellipsis,
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
                          // Likes Button
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: _isLiked
                                      ? AppColors.primaryCrimson
                                      : Colors.white70,
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
                                      color: _isLiked
                                          ? AppColors.primaryCrimson
                                          : Colors.white,
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
                              PostCommentsSheet.show(
                                context,
                                postId: post.id,
                                post: post,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mode_comment_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatCount(post.commentCount)} comments',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
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
                                const Icon(
                                  Icons.share_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatCount(post.shareCount)} shares',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
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
