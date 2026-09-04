import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space20,
          AppSpacing.space16,
          AppSpacing.space20,
          AppSpacing.space32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose a format',
              style: AppTypography.label.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _CreateFormatCard(
              icon: Icons.notes_rounded,
              title: 'Text post',
              subtitle: 'Start a thought, story, or discussion',
              accent: AppColors.primaryElectricBlue,
              onTap: () => _openComposer(context, 'text'),
            ),
            const SizedBox(height: AppSpacing.space12),
            _CreateFormatCard(
              icon: Icons.photo_library_rounded,
              title: 'Multi-image post',
              subtitle: 'Share a carousel of up to 10 photos',
              accent: AppColors.signalMint,
              onTap: () => _openComposer(context, 'image'),
            ),
            const SizedBox(height: AppSpacing.space12),
            _CreateFormatCard(
              icon: Icons.play_arrow_rounded,
              title: 'Short video',
              subtitle: 'Upload a vertical clip with a cover image',
              accent: AppColors.primaryCrimson,
              onTap: () => _openComposer(context, 'video'),
            ),
          ],
        ),
      ),
    );
  }

  void _openComposer(BuildContext context, String type) {
    context.pushNamed(RouteNames.createPost, queryParameters: {'type': type});
  }
}

class _CreateFormatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _CreateFormatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
