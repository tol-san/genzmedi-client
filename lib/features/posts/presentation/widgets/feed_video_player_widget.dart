import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/utils/media_url_resolver.dart';

/// Inline auto-playing video player for feed posts.
/// Automatically starts muted with loop enabled, supporting tap-to-play/pause and mute toggle.
class FeedVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double? aspectRatio;
  final VoidCallback? onTap;

  const FeedVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.aspectRatio,
    this.onTap,
  });

  @override
  State<FeedVideoPlayerWidget> createState() => _FeedVideoPlayerWidgetState();
}

class _FeedVideoPlayerWidgetState extends State<FeedVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final resolvedUrl = resolveMediaUrl(widget.videoUrl);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final uri = Uri.parse(resolvedUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0.0); // Start muted for auto-play
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
          _isMuted = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('[FeedVideoPlayer] Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    final nextMuted = !_isMuted;
    _controller!.setVolume(nextMuted ? 0.0 : 1.0);
    setState(() => _isMuted = nextMuted);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double? naturalRatio = _isInitialized && _controller!.value.aspectRatio > 0
        ? _controller!.value.aspectRatio
        : widget.aspectRatio;

    final targetAspectRatio = naturalRatio ?? 16 / 9;

    final resolvedThumbnail = resolveMediaUrl(widget.thumbnailUrl);

    if (_hasError || (!_isInitialized && resolvedThumbnail != null)) {
      return AspectRatio(
        aspectRatio: targetAspectRatio,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (resolvedThumbnail != null)
                CachedNetworkImage(
                  imageUrl: resolvedThumbnail,
                  fit: (naturalRatio != null && naturalRatio < 1.0) ? BoxFit.cover : BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    child: const Icon(Icons.videocam_off_rounded, color: AppColors.textMuted, size: 40),
                  ),
                )
              else
                Container(
                  color: Colors.black,
                  child: const Icon(Icons.video_library_rounded, color: AppColors.textMuted, size: 40),
                ),
              // Centered sleek play button
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: targetAspectRatio,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCrimson),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: targetAspectRatio,
      child: GestureDetector(
        onTap: widget.onTap ?? _togglePlayPause,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Surface
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Paused State Indicator
            if (!_isPlaying)
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              // Mute / Unmute Button
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
