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
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

/// Full-screen short video player item with flexible 16:9 landscape and 9:16 portrait support,
/// follow button, audio ticker, right engagement rail, bottom comment bar,
/// playback speed controls (0.5x - 2.0x), auto-scroll toggle, share, and report sheet.
class ShortVideoItemWidget extends StatefulWidget {
  final PostModel post;
  final bool isActive;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final Future<String?> Function()? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onVideoCompleted;

  const ShortVideoItemWidget({
    super.key,
    required this.post,
    required this.isActive,
    this.onLike,
    this.onSave,
    this.onShare,
    this.onComment,
    this.onVideoCompleted,
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
  bool _isFollowing = false;
  bool _isCaptionExpanded = false;
  double _playbackSpeed = 1.0;
  bool _autoScrollOnFinish = true;
  bool _hasTriggeredAutoScroll = false;

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
        _hasTriggeredAutoScroll = false;
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
      await _controller!.setPlaybackSpeed(_playbackSpeed);
      _controller!.addListener(_videoListener);

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

  void _videoListener() {
    if (!mounted || _controller == null || !_isInitialized) return;
    if (_autoScrollOnFinish && widget.isActive) {
      final position = _controller!.value.position;
      final duration = _controller!.value.duration;
      if (duration > Duration.zero &&
          position >= duration - const Duration(milliseconds: 300)) {
        if (!_hasTriggeredAutoScroll) {
          _hasTriggeredAutoScroll = true;
          widget.onVideoCompleted?.call();
        }
      } else if (position < duration - const Duration(milliseconds: 800)) {
        _hasTriggeredAutoScroll = false;
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

  void _setPlaybackSpeed(double speed) {
    if (_controller == null || !_isInitialized) return;
    setState(() => _playbackSpeed = speed);
    _controller!.setPlaybackSpeed(speed);
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
          content: Text('Reel link copied: $urlToCopy'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showReelsOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Group 1: Playback Controls (0.5, 0.75, 1, 1.25, 1.5, 2)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed_rounded, color: textColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Playback Speed',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_playbackSpeed}x',
                            style: const TextStyle(
                              color: AppColors.primaryElectricBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: speedOptions.map((speed) {
                            final isSelected = _playbackSpeed == speed;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${speed}x'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setPlaybackSpeed(speed);
                                    setSheetState(() {});
                                  }
                                },
                                selectedColor: AppColors.primaryElectricBlue,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryElectricBlue
                                        : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Group 2: Auto Play / Auto Scroll on Finish
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(Icons.autorenew_rounded, color: textColor, size: 22),
                    title: Text(
                      'Auto-scroll on finish',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Automatically scroll to next reel when video ends',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    value: _autoScrollOnFinish,
                    activeTrackColor: AppColors.primaryElectricBlue,
                    onChanged: (val) {
                      setState(() => _autoScrollOnFinish = val);
                      setSheetState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Group 3: Share & Report Actions
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.share_rounded, color: textColor, size: 22),
                        title: Text(
                          'Share reel',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Copy link or share to other apps',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _handleShare();
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ListTile(
                        leading: Icon(Icons.flag_outlined, color: AppColors.error, size: 22),
                        title: const Text(
                          'Report reel',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Find support or report inappropriate content',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you for reporting. Our moderation team will review this reel.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openComments() {
    if (widget.onComment != null) {
      widget.onComment!();
    } else {
      PostCommentsSheet.show(context, postId: widget.post.id, post: widget.post);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorName = post.author.displayName ?? post.author.username;
    final thumbnailUrl = post.media.isNotEmpty ? post.media.first.thumbnailUrl : null;

    final isLandscapeMedia = post.media.isNotEmpty &&
        post.media.first.width != null &&
        post.media.first.height != null &&
        post.media.first.width! > post.media.first.height!;

    final isLandscapeVideo = _isInitialized &&
        _controller != null &&
        _controller!.value.aspectRatio > 1.0;

    final isLandscape = isLandscapeVideo || (!_isInitialized && isLandscapeMedia);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Video Player Canvas (Flexible 16:9 Landscape and 9:16 Portrait)
        GestureDetector(
          onTap: _togglePlayPause,
          onDoubleTap: _toggleMute,
          child: Container(
            color: Colors.black,
            child: _isInitialized && _controller != null
                ? (isLandscapeVideo
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumbnailUrl != null)
                        Center(
                          child: CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                            width: isLandscape ? double.infinity : null,
                            height: isLandscape ? null : double.infinity,
                            errorWidget: (context, url, error) => Container(color: Colors.black),
                          ),
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
                  Colors.black.withValues(alpha: 0.7),
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
          height: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top Bar: Back Button on Left, Search & More on Right
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                    onPressed: () {
                      context.pushNamed(RouteNames.discover);
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
                      onPressed: () => _showReelsOptionsSheet(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Right-Side Engagement Rail (Like, Comment, Bookmark)
        Positioned(
          right: 12,
          bottom: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Button (Thumbs up matching screenshot)
              _buildActionButton(
                icon: post.isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                label: _formatCount(post.likeCount),
                color: post.isLiked ? const Color(0xFF1877F2) : Colors.white,
                onTap: widget.onLike,
              ),
              const SizedBox(height: 18),

              // Comments Button
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: _formatCount(post.commentCount),
                color: Colors.white,
                onTap: _openComments,
              ),
              const SizedBox(height: 18),

              // Bookmark / Save Button
              _buildActionButton(
                icon: post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: _formatCount(post.saveCount),
                color: post.isSaved ? AppColors.warning : Colors.white,
                onTap: widget.onSave,
              ),
            ],
          ),
        ),

        // Bottom Left Channel, Audio & Caption Info Area
        Positioned(
          left: 16,
          right: 80,
          bottom: 74,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author Row + Follow Button
              Row(
                children: [
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
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: AppAvatar(
                        name: authorName,
                        size: 38,
                        imageUrl: post.author.avatarUrl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.pushNamed(
                          RouteNames.publicProfile,
                          pathParameters: {'username': post.author.username},
                        );
                      },
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Follow Pill Button
                  InkWell(
                    onTap: () {
                      setState(() => _isFollowing = !_isFollowing);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFollowing ? 'Following $authorName' : 'Unfollowed $authorName'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isFollowing ? Colors.white24 : Colors.transparent,
                        border: Border.all(color: Colors.white, width: 1.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Audio Info Line
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$authorName · Original audio',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Caption / Content Text
              if (post.content != null && post.content!.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    setState(() => _isCaptionExpanded = !_isCaptionExpanded);
                  },
                  child: Text(
                    post.content!,
                    maxLines: _isCaptionExpanded ? null : 2,
                    overflow: _isCaptionExpanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Sticky Bottom Comment Bar
        Positioned(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 8,
          child: GestureDetector(
            onTap: _openComments,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add a comment...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.alternate_email_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Icon(Icons.emoji_emotions_outlined, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 1.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'GIF',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
