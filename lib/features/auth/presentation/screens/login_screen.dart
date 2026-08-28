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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  String? _usernameError;
  String? _passwordError;

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
      _usernameError = null;
      _passwordError = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    bool hasValidationError = false;
    if (username.isEmpty) {
      _usernameError = 'Please enter your username or email';
      hasValidationError = true;
    } else if (username.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(username)) {
        _usernameError = 'Please enter a valid email address';
        hasValidationError = true;
      }
    } else if (username.length < 3) {
      _usernameError = 'Username must be at least 3 characters';
      hasValidationError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password';
      hasValidationError = true;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      hasValidationError = true;
    }

    if (hasValidationError) {
      setState(() {
        if (username.isEmpty && password.isEmpty) {
          _errorMessage = 'Please enter both your username/email and password.';
        } else {
          _errorMessage = 'Please fix the errors above.';
        }
      });
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).login(
            username: username,
            password: password,
          );
      // Navigation is automatically handled by GoRouter redirect
    } catch (e) {
      if (!mounted) return;
      final String cleanMessage = e is AppException
          ? e.message
          : e
              .toString()
              .replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '')
              .replaceFirst(RegExp(r'\s*\(statusCode:\s*\d+\)'), '');

      setState(() {
        _errorMessage = cleanMessage;
        _usernameError = 'Invalid username or email';
        _passwordError = 'Invalid password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

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
                  const Center(
                    child: AppLogo.wordmark(width: 220, height: 40),
                  ),
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

                  // Error Message Banner
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
                    errorText: _usernameError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_usernameError != null || _errorMessage != null) {
                        setState(() {
                          _usernameError = null;
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
                    errorText: _passwordError,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_passwordError != null || _errorMessage != null) {
                        setState(() {
                          _passwordError = null;
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
                      onPressed: () => context.pushNamed(RouteNames.forgotPassword),
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
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleLogin,
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
