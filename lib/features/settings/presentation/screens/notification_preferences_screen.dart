import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/settings/presentation/notifiers/account_settings_notifiers.dart';
import 'package:client/features/settings/presentation/widgets/settings_tile_widget.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final prefs = state.preferences;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.space16),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: prefs == null
          ? state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : EmptyStateWidget(
                  icon: Icons.notifications_off_outlined,
                  title: 'Could not load notifications',
                  subtitle: state.errorMessage,
                  actionText: 'Retry',
                  onAction: notifier.load,
                )
          : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                children: [
                  if (state.errorMessage != null) ...[
                    _ErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: AppSpacing.space16),
                  ],

                  // ── Section 1: Interactions ──────────────────────────────────
                  SettingsSectionCard(
                    heading: 'Interactions',
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.favorite_outline_rounded),
                        title: const Text('Likes'),
                        subtitle: const Text('When someone likes your posts or comments'),
                        value: prefs.likesEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'likes_enabled': val}),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.chat_bubble_outline_rounded),
                        title: const Text('Comments'),
                        subtitle: const Text('When someone comments on your posts'),
                        value: prefs.commentsEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'comments_enabled': val}),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.alternate_email_rounded),
                        title: const Text('Mentions & Replies'),
                        subtitle: const Text('When someone mentions you or replies to you'),
                        value: prefs.mentionsEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'mentions_enabled': val}),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space20),

                  // ── Section 2: Social & Communities ──────────────────────────
                  SettingsSectionCard(
                    heading: 'Social & Communities',
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.person_add_outlined),
                        title: const Text('New Followers'),
                        subtitle: const Text('When another user follows your account'),
                        value: prefs.followsEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'follows_enabled': val}),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.groups_outlined),
                        title: const Text('Community Activity'),
                        subtitle: const Text('Updates, announcements, and join requests'),
                        value: prefs.communityEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'community_enabled': val}),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space20),

                  // ── Section 3: Delivery Channels ─────────────────────────────
                  SettingsSectionCard(
                    heading: 'Delivery Channels',
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Instant alerts sent to your device'),
                        value: prefs.pushEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'push_enabled': val}),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.mail_outline_rounded),
                        title: const Text('Email Notifications'),
                        subtitle: const Text('Security notices and digest emails'),
                        value: prefs.emailEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({'email_enabled': val}),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space20),

                  // ── Section 4: Quiet Hours ───────────────────────────────────
                  SettingsSectionCard(
                    heading: 'Quiet Hours',
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.bedtime_outlined),
                        title: const Text('Pause During Quiet Hours'),
                        subtitle: Text(
                          prefs.quietHoursEnabled
                              ? 'Notifications muted from ${prefs.quietHoursStart ?? "22:00"} to ${prefs.quietHoursEnd ?? "07:00"}'
                              : 'Temporarily mute push alerts while sleeping or focusing',
                        ),
                        value: prefs.quietHoursEnabled,
                        onChanged: state.isSaving
                            ? null
                            : (val) => notifier.update({
                                  'quiet_hours_enabled': val,
                                  if (val && prefs.quietHoursStart == null)
                                    'quiet_hours_start': '22:00',
                                  if (val && prefs.quietHoursEnd == null)
                                    'quiet_hours_end': '07:00',
                                }),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space32),
                ],
              ),
            ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
