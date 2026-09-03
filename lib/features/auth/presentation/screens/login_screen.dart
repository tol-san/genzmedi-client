import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_logo.dart';
import 'package:client/core/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty && password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your username/email and password.';
      });
      return;
    }

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your username or email.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(username: username, password: password);
      // Upon success, GoRouter redirect automatically navigates to /feed
    } catch (e) {
      if (!mounted) return;
      final String cleanMessage = e is AppException
          ? e.message
          : e
                .toString()
                .replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '')
                .replaceFirst(RegExp(r'\s*\(statusCode:\s*\d+\)'), '');

      setState(() {
        _isLoading = false;
        _errorMessage = cleanMessage;
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space24,
              vertical: AppSpacing.space32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Minimal Logo Wordmark
                  const Center(child: AppLogo.wordmark(width: 220, height: 40)),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space48),

                  // Error Message Banner - Single place for all errors
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('login_error_banner'),
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

                  // Username / Email input
                  AppTextField(
                    key: const Key('login_username_field'),
                    controller: _usernameController,
                    label: 'Username or Email',
                    hintText: 'Enter your username or email',
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Password input
                  AppTextField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: AppSpacing.space8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.forgotPassword),
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Submit Button
                  AppButton(
                    key: const Key('login_submit_button'),
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed(RouteNames.register),
                        child: Text(
                          'Create Account',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
