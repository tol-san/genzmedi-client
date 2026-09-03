import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/theme/theme_mode_notifier.dart';
import 'package:client/features/settings/presentation/widgets/legal_sheet_widget.dart';
import 'package:client/features/settings/presentation/widgets/settings_tile_widget.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space20,
                  vertical: AppSpacing.space8,
                ),
                child: Text(
                  'Choose Theme',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ThemeOptionTile(
                title: 'System Default',
                subtitle: 'Matches your operating system settings',
                icon: Icons.brightness_auto_rounded,
                isSelected: currentTheme == ThemeMode.system,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                title: 'Light Mode',
                subtitle: 'Crisp crimson and pearl white aesthetics',
                icon: Icons.light_mode_rounded,
                isSelected: currentTheme == ThemeMode.light,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                title: 'Dark Mode',
                subtitle: 'Sleek obsidian and deep navy theme',
                icon: Icons.dark_mode_rounded,
                isSelected: currentTheme == ThemeMode.dark,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }


  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of GenZ Media?',
        ),
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
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
        children: [
          // ── Section 1: Account ──────────────────────────────────────────
          SettingsSectionCard(
            heading: 'Account & Profile',
            children: [
              SettingsTileWidget(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, username, bio, avatar, and interests',
                onTap: () => context.pushNamed(RouteNames.editProfile),
              ),
              SettingsTileWidget(
                icon: Icons.manage_accounts_outlined,
                title: 'Account Management',
                subtitle: 'Deactivation, deletion, and data download',
                onTap: () => context.pushNamed(RouteNames.accountManagement),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Section 2: Security ─────────────────────────────────────────
          SettingsSectionCard(
            heading: 'Security',
            children: [
              SettingsTileWidget(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your security credentials',
                onTap: () => context.pushNamed(RouteNames.changePassword),
              ),
              SettingsTileWidget(
                icon: Icons.devices_rounded,
                title: 'Active Sessions & Devices',
                subtitle: 'Manage signed-in devices and open sessions',
                onTap: () => context.pushNamed(RouteNames.sessions),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Section 3: Privacy & Safety ─────────────────────────────────
          SettingsSectionCard(
            heading: 'Privacy & Safety',
            children: [
              SettingsTileWidget(
                icon: Icons.shield_outlined,
                title: 'Privacy Settings',
                subtitle: 'Profile visibility, interactions, and discovery',
                onTap: () => context.pushNamed(RouteNames.privacySettings),
              ),
              SettingsTileWidget(
                icon: Icons.block_rounded,
                title: 'Blocked Accounts',
                subtitle: 'Manage creators and users you have blocked',
                onTap: () => context.pushNamed(RouteNames.blockedUsers),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Section 4: Notifications ────────────────────────────────────
          SettingsSectionCard(
            heading: 'Notifications',
            children: [
              SettingsTileWidget(
                icon: Icons.notifications_none_rounded,
                title: 'Notification Preferences',
                subtitle: 'Likes, comments, mentions, and quiet hours',
                onTap: () => context.pushNamed(RouteNames.notificationSettings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Section 5: Preferences ───────────────────────────────────────
          SettingsSectionCard(
            heading: 'Preferences',
            children: [
              SettingsTileWidget(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: _themeLabel(themeMode),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _themeLabel(themeMode),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryCrimson,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                onTap: () => _showThemePicker(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Section 4: About & Legal ────────────────────────────────────
          SettingsSectionCard(
            heading: 'About & Support',
            children: [
              SettingsTileWidget(
                icon: Icons.menu_book_outlined,
                title: 'Community Guidelines',
                subtitle: 'Standards for a safe and authentic community',
                onTap: () => LegalSheetWidget.show(
                  context,
                  title: 'Community Guidelines',
                  content:
                      'Welcome to GenZ Media!\n\n'
                      'Our mission is to empower authentic creativity, self-expression, and positive digital connections. We ask all members to uphold these core principles:\n\n'
                      '1. Respect and Inclusivity: Treat others with kindness. Harassment, hate speech, bullying, defamation, and discrimination based on identity are strictly prohibited.\n\n'
                      '2. Authenticity: Share original and genuine content. Impersonation, automated spam, and deceitful engagement manipulation are not allowed.\n\n'
                      '3. Safety First: Do not share sexually explicit material involving minors, self-harm encouragement, violence, or dangerous illegal activities.\n\n'
                      '4. Intellectual Property: Respect copyright and creative rights. Always credit fellow creators when using their work.',
                ),
              ),
              SettingsTileWidget(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'User agreement and platform guidelines',
                onTap: () => LegalSheetWidget.show(
                  context,
                  title: 'Terms of Service',
                  content:
                      'Last updated: September 2026\n\n'
                      '1. Acceptance of Terms: By accessing or using GenZ Media, you agree to comply with and be bound by these Terms of Service.\n\n'
                      '2. User Accounts: You are responsible for safeguarding your password and credentials. You agree not to disclose your password to any third party.\n\n'
                      '3. Content Rights: You retain your rights to any content you submit, post or display on or through GenZ Media. By submitting content, you grant GenZ Media a worldwide, non-exclusive license to host and display your content.\n\n'
                      '4. Termination: We may suspend or terminate your account if you breach these Terms or engage in behavior harmful to other users.',
                ),
              ),
              SettingsTileWidget(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we collect, protect, and use your data',
                onTap: () => LegalSheetWidget.show(
                  context,
                  title: 'Privacy Policy',
                  content:
                      'Last updated: September 2026\n\n'
                      '1. Information We Collect: We collect account registration data (username, email), profile details (bio, avatar, interests), and user activity (posts, likes, bookmarks).\n\n'
                      '2. How We Use Data: We use your data to personalize your feeds, enable real-time messaging, provide discovery recommendations, and enforce community safety.\n\n'
                      '3. Security: We use industry-standard encryption, Argon2id password hashing, and token-based authentication to secure your personal data.\n\n'
                      '4. Data Rights: You may edit your profile or request data deletion by contacting support.',
                ),
              ),
              SettingsTileWidget(
                icon: Icons.support_agent_outlined,
                title: 'Report a Problem',
                subtitle: 'Send feedback or report bugs to support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Support desk: support@genzmedia.app — feedback submitted!',
                      ),
                    ),
                  );
                },
              ),
              SettingsTileWidget(
                icon: Icons.info_outline_rounded,
                title: 'Application Version',
                subtitle: 'GenZ Media v1.0.0 (Build 42) — Production',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Section 5: Session ──────────────────────────────────────────
          SettingsSectionCard(
            children: [
              SettingsTileWidget(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Log out from this device',
                isDestructive: true,
                onTap: () => _showSignOutDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space32),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space20,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryCrimson : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryCrimson : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryCrimson,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

