import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_typography.dart';

/// User or community avatar with initials fallback and live/online indicator ring.
import 'package:client/core/utils/media_url_resolver.dart';

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

  String? get _cleanUrl => resolveMediaUrl(imageUrl);

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
        placeholder: (context, url) => _buildFallback(isDark),
        errorWidget: (context, url, error) => _buildFallback(isDark),
      );
    } else {
      avatarChild = _buildFallback(isDark);
    }

    Widget content = ClipOval(
      child: SizedBox(width: size, height: size, child: avatarChild),
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
                  color: isDark
                      ? AppColors.midnightNavy
                      : AppColors.lightSurface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
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
