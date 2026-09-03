import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/settings/presentation/notifiers/account_settings_notifiers.dart';
import 'package:client/features/settings/presentation/widgets/settings_tile_widget.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacySettingsProvider);
    final notifier = ref.read(privacySettingsProvider.notifier);
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
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
      body: settings == null
          ? state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : EmptyStateWidget(
                  icon: Icons.shield_outlined,
                  title: 'Could not load privacy settings',
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
                  SettingsSectionCard(
                    heading: 'Profile visibility',
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Private account'),
                        subtitle: const Text(
                          'Only approved followers can see private profile content',
                        ),
                        value: settings.isPrivate,
                        onChanged: state.isSaving
                            ? null
                            : (value) => notifier.update({'is_private': value}),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.search_rounded),
                        title: const Text('Appear in search'),
                        subtitle: const Text(
                          'Allow your profile to appear in discovery results',
                        ),
                        value: settings.searchDiscoverable,
                        onChanged: state.isSaving
                            ? null
                            : (value) => notifier
                                .update({'search_discoverable': value}),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.circle_outlined),
                        title: const Text('Show activity status'),
                        subtitle: const Text(
                          'Let others see when you are active',
                        ),
                        value: settings.showActivityStatus,
                        onChanged: state.isSaving
                            ? null
                            : (value) => notifier
                                .update({'show_activity_status': value}),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space20),
                  SettingsSectionCard(
                    heading: 'Interactions',
                    children: [
                      _AudiencePicker(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Who can comment',
                        value: settings.allowComments,
                        enabled: !state.isSaving,
                        onChanged: (value) => notifier
                            .update({'allow_comments': value}),
                      ),
                      _AudiencePicker(
                        icon: Icons.alternate_email_rounded,
                        title: 'Who can mention you',
                        value: settings.allowMentions,
                        enabled: !state.isSaving,
                        onChanged: (value) => notifier
                            .update({'allow_mentions': value}),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  const Text(
                    'Follower-list visibility and custom follow permissions are not available yet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _AudiencePicker extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _AudiencePicker({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = const ['everyone', 'following', 'no_one'].contains(value)
        ? value
        : 'everyone';
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: safeValue,
        underline: const SizedBox.shrink(),
        onChanged: enabled
            ? (selected) {
                if (selected != null) onChanged(selected);
              }
            : null,
        items: const [
          DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
          DropdownMenuItem(value: 'following', child: Text('Following')),
          DropdownMenuItem(value: 'no_one', child: Text('No one')),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppSpacing.roundedMd,
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.space8),
            Expanded(child: Text(message)),
          ],
        ),
      );
}
