import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_logo.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
      _emailError = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email address.';
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailError = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.forgotPassword(ForgotPasswordRequest(email: email));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
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
        _isLoading = false;
        _errorMessage = cleanMessage;
        _emailError = cleanMessage;
      });
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space24,
              vertical: AppSpacing.space24,
            ),
            child: _isSuccess
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 64,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      Text(
                        'Check your email',
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      Text(
                        'We sent a password reset link to ${_emailController.text}. Follow the instructions to reset your account password.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space32),
                      AppButton(
                        text: 'Back to Sign In',
                        onPressed: () => context.goNamed(RouteNames.login),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: AppLogo.icon(width: 60, height: 60),
                      ),
                      const SizedBox(height: AppSpacing.space20),
                      Text(
                        'Reset Password',
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
                        'Enter your account email and we\'ll send you instructions to reset your password.',
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

                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Enter your registered email',
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_emailError != null || _errorMessage != null) {
                            setState(() {
                              _emailError = null;
                              _errorMessage = null;
                            });
                          }
                        },
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: AppSpacing.space24),

                      AppButton(
                        text: 'Send Reset Link',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleSubmit,
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Cancel',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
