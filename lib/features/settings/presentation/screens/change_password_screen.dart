import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/settings/presentation/notifiers/change_password_notifier.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref
        .read(changePasswordNotifierProvider.notifier)
        .submit(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully. Please sign in again.',
          ),
          backgroundColor: AppColors.signalMint,
        ),
      );
      // Log out to revoke session and prompt sign-in with the new password
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protect your account',
                style: AppTypography.heading.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Your new password must be at least 8 characters long and different from your current password.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // Error banner
              if (state.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
              ],

              // Current Password
              AppTextField(
                controller: _currentPasswordController,
                label: 'Current password',
                hintText: 'Enter your current password',
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
              const SizedBox(height: AppSpacing.space16),

              // New Password
              AppTextField(
                controller: _newPasswordController,
                label: 'New password',
                hintText: 'Enter at least 8 characters',
                isPassword: true,
                prefixIcon: const Icon(Icons.key_rounded),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Confirm New Password
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm new password',
                hintText: 'Re-enter your new password',
                isPassword: true,
                prefixIcon: const Icon(Icons.check_circle_outline_rounded),
              ),
              const SizedBox(height: AppSpacing.space32),

              AppButton(
                text: 'Update Password',
                isLoading: state.isLoading,
                variant: AppButtonVariant.primary,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
