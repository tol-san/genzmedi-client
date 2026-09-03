import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

/// Top-mounted non-intrusive offline notification banner.
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          duration: AppSpacing.durationFast,
          crossFadeState: isOffline
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: AppSpacing.space16,
            ),
            color: AppColors.warning,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: AppColors.midnightNavy,
                ),
                const SizedBox(width: 6),
                Text(
                  'You are currently offline. Some features may be unavailable.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
