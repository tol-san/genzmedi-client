import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class ShortVideoItemWidget extends StatefulWidget {
  final PostModel post;
  final bool isActive;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final Future<String?> Function()? onShare;
  final VoidCallback? onComment;

  const ShortVideoItemWidget({
    super.key,
    required this.post,
    required this.isActive,
    this.onLike,
    this.onSave,
    this.onShare,
    this.onComment,
  });

  @override
  State<ShortVideoItemWidget> createState() => _ShortVideoItemWidgetState();
}

class _ShortVideoItemWidgetState extends State<ShortVideoItemWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isPlaying = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant ShortVideoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _play();
      } else {
        _pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.post.media.isNotEmpty
        ? widget.post.media.first.url
        : null;

    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      if (mounted) setState(() => _hasError = false);
      final uri = Uri.parse(videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      _controller!.setLooping(true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _play();
        }
      }
    } catch (e) {
      debugPrint('[ShortVideoItemWidget] Video init error for $videoUrl: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _play() {
    if (_controller != null && _isInitialized) {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  void _pause() {
    if (_controller != null && _isInitialized) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) {
      if (_hasError) {
        _initializeVideo();
      }
      return;
    }
    if (_controller!.value.isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
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
          content: Text('Short link copied: $urlToCopy'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final thumbnailUrl = post.media.isNotEmpty ? post.media.first.thumbnailUrl : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Video Player Surface
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.black,
            child: _isInitialized && _controller != null
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: Colors.black),
                        ),
                      Container(color: Colors.black.withValues(alpha: 0.4)),
                      if (_hasError)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.replay_circle_filled_rounded,
                                size: 52,
                                color: AppColors.primaryCrimson,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to retry loading video',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryCrimson,
                          ),
                        ),
                    ],
                  ),
          ),
        ),

        // Pause Indicator Overlay
        if (_isInitialized && !_isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),

        // Top Gradient Scrim
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom Gradient Scrim
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top Controls: Mute Button
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.space8,
          right: AppSpacing.space16,
          child: IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _toggleMute,
          ),
        ),

        // Right-Side Engagement Rail
        Positioned(
          right: AppSpacing.space12,
          bottom: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author Avatar
              GestureDetector(
                onTap: () {
                  context.pushNamed(
                    RouteNames.publicProfile,
                    pathParameters: {'username': post.author.username},
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: AppAvatar(
                    name: post.author.displayName ?? post.author.username,
                    size: 46,
                    imageUrl: post.author.avatarUrl,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space20),

              // Like Button
              _buildActionButton(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: _formatCount(post.likeCount),
                color: post.isLiked ? AppColors.primaryCrimson : Colors.white,
                onTap: widget.onLike,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Comments Button
              _buildActionButton(
                icon: Icons.chat_bubble_rounded,
                label: _formatCount(post.commentCount),
                color: Colors.white,
                onTap: widget.onComment,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Save / Bookmark Button
              _buildActionButton(
                icon: post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: _formatCount(post.saveCount),
                color: post.isSaved ? AppColors.signalMint : Colors.white,
                onTap: widget.onSave,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Share Button
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: Colors.white,
                onTap: _handleShare,
              ),
            ],
          ),
        ),

        // Bottom Left Author & Description
        Positioned(
          left: AppSpacing.space16,
          right: 90,
          bottom: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  context.pushNamed(
                    RouteNames.publicProfile,
                    pathParameters: {'username': post.author.username},
                  );
                },
                child: Text(
                  '@${post.author.username}',
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (post.title != null && post.title!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.title!,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.content != null && post.content!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.content!,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
