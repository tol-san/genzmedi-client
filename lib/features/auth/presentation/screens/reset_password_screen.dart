import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_logo.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;
  final String? initialEmail;

  const ResetPasswordScreen({
    super.key,
    this.initialToken,
    this.initialEmail,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthNeedsOnboarding) {
      context.goNamed(RouteNames.onboarding);
    } else {
      context.goNamed(RouteNames.homeFeed);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    if (newPassword.isEmpty) {
      _newPasswordError = 'Please enter your new password.';
      hasError = true;
    } else if (newPassword.length < 8) {
      _newPasswordError = 'Password must be at least 8 characters long.';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your new password.';
      hasError = true;
    } else if (newPassword != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final storedToken = await storage.getAccessToken();
      final effectiveToken = (widget.initialToken != null && widget.initialToken!.isNotEmpty)
          ? widget.initialToken!
          : (storedToken ?? '');

      await repository.resetPassword(
        ResetPasswordRequest(
          token: effectiveToken,
          email: widget.initialEmail,
          newPassword: newPassword,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _navigateToNextScreen();
      }
    } catch (e) {
      if (!mounted) return;
      final cleanMessage = e is AppException
          ? e.message
          : e
              .toString()
              .replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '')
              .replaceFirst(RegExp(r'\s*\(statusCode:\s*\d+\)'), '');

      setState(() {
        _errorMessage = cleanMessage;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          onPressed: _navigateToNextScreen,
        ),
        actions: [
          TextButton(
            onPressed: _navigateToNextScreen,
            child: Text(
              'Skip',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space24,
              vertical: AppSpacing.space24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppLogo.icon(width: 60, height: 60),
                ),
                const SizedBox(height: AppSpacing.space20),
                Text(
                  'Set New Password',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Choose a strong password with at least 8 characters.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space32),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                ],

                // New Password Field
                AppTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hintText: 'Enter new password (min. 8 characters)',
                  errorText: _newPasswordError,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_newPasswordError != null) {
                      setState(() => _newPasswordError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // Confirm Password Field
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter your new password',
                  errorText: _confirmPasswordError,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setState(() => _confirmPasswordError = null);
                    }
                  },
                  onSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: AppSpacing.space24),

                AppButton(
                  text: 'Save Password',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSubmit,
                ),
                const SizedBox(height: AppSpacing.space16),

                AppButton.secondary(
                  text: 'Skip to Feed',
                  onPressed: () => context.goNamed(RouteNames.homeFeed),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
