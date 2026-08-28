import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_typography.dart';

/// User or community avatar with initials fallback and live/online indicator ring.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isLive;
  final bool isOnline;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40.0,
    this.isLive = false,
    this.isOnline = false,
    this.onTap,
  });

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String? get _cleanUrl {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return null;
    var trimmed = imageUrl!.trim();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (trimmed.contains('http://localhost:9000')) {
        trimmed = trimmed.replaceAll('http://localhost:9000', 'http://10.0.2.2:9000');
      } else if (trimmed.contains('http://127.0.0.1:9000')) {
        trimmed = trimmed.replaceAll('http://127.0.0.1:9000', 'http://10.0.2.2:9000');
      } else if (trimmed.contains('http://localhost:8000')) {
        trimmed = trimmed.replaceAll('http://localhost:8000', 'http://10.0.2.2:8000');
      }
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = _cleanUrl;

    Widget avatarChild;
    if (url != null && url.isNotEmpty) {
      avatarChild = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (context, url) => Container(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightBorder,
          child: const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(isDark),
      );
    } else {
      avatarChild = _buildFallback(isDark);
    }

    Widget content = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarChild,
      ),
    );

    // Live or Online indicator
    if (isLive) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryCrimson, width: 2),
            ),
            child: content,
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryCrimson,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textInverse,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (isOnline) {
      content = Stack(
        children: [
          content,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.signalMint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.midnightNavy : AppColors.lightSurface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildFallback(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.primarySoft,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.label.copyWith(
          fontSize: size * 0.4,
          color: isDark ? AppColors.textPrimaryDark : AppColors.primaryCrimson,
        ),
      ),
    );
  }
}
