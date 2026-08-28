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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    // Field-level validation
    if (username.isEmpty) {
      _usernameError = 'Please enter a username.';
      hasError = true;
    } else if (username.length < 3) {
      _usernameError = 'Username must be at least 3 characters long.';
      hasError = true;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      _emailError = 'Please enter an email address.';
      hasError = true;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Please enter a valid email address.';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter a password.';
      hasError = true;
    } else if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters long.';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password.';
      hasError = true;
    } else if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match.';
      hasError = true;
    }

    if (hasError) {
      setState(() {
        _errorMessage = 'Please fix the errors above.';
      });
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).register(
            username: username,
            email: email,
            password: password,
          );
      // If server requires login or directs to onboarding, GoRouter handles redirection
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
        final msgLower = cleanMessage.toLowerCase();
        if (msgLower.contains('username')) {
          _usernameError = cleanMessage;
        } else if (msgLower.contains('email')) {
          _emailError = cleanMessage;
        } else if (msgLower.contains('password')) {
          _passwordError = cleanMessage;
        }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space24,
              vertical: AppSpacing.space16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: AppLogo.icon(width: 60, height: 60),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    'Create Account',
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
                    'Join GenZ Media communities and creators.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space32),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('register_error_banner'),
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

                  // Username field
                  AppTextField(
                    key: const Key('register_username_field'),
                    controller: _usernameController,
                    label: 'Username',
                    hintText: 'e.g. sovandara',
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

                  // Email field
                  AppTextField(
                    key: const Key('register_email_field'),
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'e.g. sovandara@example.com',
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_emailError != null || _errorMessage != null) {
                        setState(() {
                          _emailError = null;
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Password field
                  AppTextField(
                    key: const Key('register_password_field'),
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Minimum 8 characters',
                    errorText: _passwordError,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_passwordError != null || _errorMessage != null) {
                        setState(() {
                          _passwordError = null;
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Confirm Password field
                  AppTextField(
                    key: const Key('register_confirm_password_field'),
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    errorText: _confirmPasswordError,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_confirmPasswordError != null || _errorMessage != null) {
                        setState(() {
                          _confirmPasswordError = null;
                          _errorMessage = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _handleRegister(),
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // Submit Button
                  AppButton(
                    key: const Key('register_submit_button'),
                    text: 'Create Account',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleRegister,
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed(RouteNames.login),
                        child: Text(
                          'Sign In',
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
                  const SizedBox(height: AppSpacing.space16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
