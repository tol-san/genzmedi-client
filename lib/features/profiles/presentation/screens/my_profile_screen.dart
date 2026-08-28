import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    final user = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthNeedsOnboarding ? authState.user : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? '@${user.username}' : 'My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account Settings (Phase 1)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authNotifierProvider.notifier).logout();
                      },
                      child: Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.space8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Stats Row
            Row(
              children: [
                AppAvatar(
                  name: user?.displayName ?? user?.username ?? 'GenZ User',
                  size: 72,
                  imageUrl: user?.avatarUrl,
                ),
                const SizedBox(width: AppSpacing.space24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('0', 'Posts', isDark),
                      _buildStatColumn('${user?.followersCount ?? 0}', 'Followers', isDark),
                      _buildStatColumn('${user?.followingCount ?? 0}', 'Following', isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),

            // Bio / Display Name
            Text(
              user?.displayName ?? user?.username ?? 'Gen Z Creator',
              style: AppTypography.title.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.bio!,
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space16),

            // Edit Profile CTA
            AppButton.secondary(
              text: 'Edit Profile',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile (Phase 1)')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.space24),

            // My Interests
            Text(
              'My Interests',
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            if (user?.interests != null && user!.interests.isNotEmpty)
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: user.interests
                    .map(
                      (interest) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space12, vertical: AppSpacing.space4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                          borderRadius: AppSpacing.roundedFull,
                          border: Border.all(
                            color: isDark ? AppColors.navyBorder : AppColors.primarySoft,
                          ),
                        ),
                        child: Text(
                          interest,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'No interests selected yet.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
