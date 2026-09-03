import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/settings/data/models/settings_models.dart';
import 'package:client/features/settings/presentation/notifiers/account_settings_notifiers.dart';
import 'package:client/features/settings/presentation/widgets/settings_tile_widget.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  void _confirmRevokeOtherSessions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out Other Devices'),
        content: const Text(
          'Are you sure you want to sign out from all other devices? Any other open sessions will require logging in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ref.read(sessionsProvider.notifier).revokeOthers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Signed out from all other devices.'
                          : 'Could not sign out other devices.',
                    ),
                    backgroundColor:
                        success ? AppColors.signalMint : AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Sign Out Others',
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

  void _confirmRevokeSession(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Session'),
        content: Text(
          'Revoke sign-in on ${session.deviceName ?? "this device"}? That device will be logged out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ref.read(sessionsProvider.notifier).revoke(session.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Session revoked.' : 'Could not revoke session.',
                    ),
                    backgroundColor:
                        success ? AppColors.signalMint : AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Revoke',
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

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionsProvider);
    final notifier = ref.read(sessionsProvider.notifier);
    final sessions = state.sessions;

    final currentSession = sessions.where((s) => s.isCurrent).firstOrNull;
    final otherSessions = sessions.where((s) => !s.isCurrent).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
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
      body: state.isLoading && sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.devices_rounded,
                  title: 'No active sessions found',
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

                      // ── Current Device ─────────────────────────────────────
                      if (currentSession != null) ...[
                        SettingsSectionCard(
                          heading: 'This Device',
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(AppSpacing.space8),
                                decoration: BoxDecoration(
                                  color: AppColors.signalMint.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppColors.signalMint,
                                  size: 22,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentSession.deviceName ?? 'Current Device',
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.space8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.signalMint.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Active Now',
                                      style: TextStyle(
                                        color: AppColors.signalMint,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'IP: ${currentSession.ipAddress ?? "Unknown"} • Last active: ${_formatRelativeTime(currentSession.lastActiveAt)}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space20),
                      ],

                      // ── Other Devices ──────────────────────────────────────
                      SettingsSectionCard(
                        heading: 'Other Signed-In Devices',
                        children: [
                          if (otherSessions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(AppSpacing.space16),
                              child: Text(
                                'No other devices are currently signed in to your account.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          else
                            ...otherSessions.map(
                              (session) => ListTile(
                                leading: const Icon(
                                  Icons.devices_other_rounded,
                                  color: AppColors.textMuted,
                                  size: 24,
                                ),
                                title: Text(
                                  session.deviceName ?? 'Unknown Device',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'IP: ${session.ipAddress ?? "Unknown"} • ${_formatRelativeTime(session.lastActiveAt)}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                trailing: TextButton(
                                  onPressed: state.isSaving
                                      ? null
                                      : () => _confirmRevokeSession(
                                            context,
                                            ref,
                                            session,
                                          ),
                                  child: const Text(
                                    'Revoke',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space24),

                      // ── Sign Out All Other Devices ─────────────────────────
                      if (otherSessions.isNotEmpty)
                        AppButton(
                          text: 'Sign Out All Other Devices',
                          variant: AppButtonVariant.secondary,
                          icon: Icons.logout_rounded,
                          isLoading: state.isSaving,
                          onPressed: () => _confirmRevokeOtherSessions(context, ref),
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
