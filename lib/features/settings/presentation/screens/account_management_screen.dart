import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/settings/presentation/notifiers/account_settings_notifiers.dart';
import 'package:client/features/settings/presentation/widgets/settings_tile_widget.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  void _showDeactivateDialog() {
    final passwordController = TextEditingController();
    final reasonController = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final actionState = ref.watch(accountActionProvider);

          return AlertDialog(
            title: const Text('Deactivate Account'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deactivating your account hides your profile, posts, and comments from everyone. You will be signed out immediately.',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  if (localError != null || actionState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        localError ?? actionState.errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                  ],
                  AppTextField(
                    controller: passwordController,
                    label: 'Current Password',
                    isPassword: true,
                    hintText: 'Enter your password',
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  AppTextField(
                    controller: reasonController,
                    label: 'Reason (Optional)',
                    hintText: 'Tell us why you are taking a break',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              AppButton(
                text: 'Deactivate',
                variant: AppButtonVariant.destructive,
                isLoading: actionState.isLoading,
                onPressed: () async {
                  if (passwordController.text.trim().isEmpty) {
                    setModalState(() {
                      localError = 'Password is required to deactivate';
                    });
                    return;
                  }
                  setModalState(() => localError = null);

                  final success = await ref
                      .read(accountActionProvider.notifier)
                      .deactivate(
                        passwordController.text.trim(),
                        reason: reasonController.text.trim(),
                      );

                  if (success) {
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.goNamed(RouteNames.login);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final actionState = ref.watch(accountActionProvider);

          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete Account'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action is PERMANENT and cannot be undone. All your posts, likes, followers, and media will be permanently deleted.',
                    style: TextStyle(
                      height: 1.4,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  if (localError != null || actionState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        localError ?? actionState.errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                  ],
                  AppTextField(
                    controller: passwordController,
                    label: 'Current Password',
                    isPassword: true,
                    hintText: 'Enter your password',
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  const Text(
                    'Type "DELETE" below to confirm:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: confirmController,
                    label: 'Confirmation',
                    hintText: 'DELETE',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              AppButton(
                text: 'Delete Forever',
                variant: AppButtonVariant.destructive,
                isLoading: actionState.isLoading,
                onPressed: () async {
                  if (passwordController.text.trim().isEmpty) {
                    setModalState(() {
                      localError = 'Password is required to delete account';
                    });
                    return;
                  }
                  if (confirmController.text.trim() != 'DELETE') {
                    setModalState(() {
                      localError = 'Please type "DELETE" exactly to confirm';
                    });
                    return;
                  }
                  setModalState(() => localError = null);

                  final success = await ref
                      .read(accountActionProvider.notifier)
                      .delete(
                        passwordController.text.trim(),
                        confirmController.text.trim(),
                      );

                  if (success) {
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.goNamed(RouteNames.login);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        children: [
          // ── Data & Exports ─────────────────────────────────────────────────
          SettingsSectionCard(
            heading: 'Your Data',
            children: [
              SettingsTileWidget(
                icon: Icons.download_rounded,
                title: 'Download Your Data',
                subtitle: 'Request an archive of your profile, posts, and media',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data export request created. A download link will be emailed to you.',
                      ),
                      backgroundColor: AppColors.signalMint,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),

          // ── Account Lifecycle Actions ─────────────────────────────────────
          SettingsSectionCard(
            heading: 'Account Status',
            children: [
              SettingsTileWidget(
                icon: Icons.pause_circle_outline_rounded,
                title: 'Deactivate Account',
                subtitle: 'Temporarily hide your profile and take a break',
                onTap: _showDeactivateDialog,
              ),
              SettingsTileWidget(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and all data',
                isDestructive: true,
                onTap: _showDeleteDialog,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space32),
        ],
      ),
    );
  }
}
