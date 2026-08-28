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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (email.isEmpty) {
      _emailError = 'Please enter an email address.';
      hasError = true;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Please enter a valid email address.';
      hasError = true;
    }

    // Password validation
    if (password.isEmpty) {
      _passwordError = 'Please enter a password.';
      hasError = true;
    } else if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters long.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).requestSignupOtp(
            email: email,
            password: password,
          );

      if (mounted) {
        context.goNamed(
          RouteNames.verifyOtp,
          queryParameters: {
            'email': email,
            'flow': 'signup',
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      final cleanMessage = e is AppException
          ? e.message
          : e
              .toString()
              .replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '')
              .replaceFirst(RegExp(r'\s*\(statusCode:\s*\d+\)'), '');

      final msgLower = cleanMessage.toLowerCase();
      setState(() {
        _isLoading = false;
        if (msgLower.contains('email')) {
          _emailError = cleanMessage;
          _errorMessage = null;
        } else if (msgLower.contains('password')) {
          _passwordError = cleanMessage;
          _errorMessage = null;
        } else {
          _errorMessage = cleanMessage;
        }
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
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_passwordError != null || _errorMessage != null) {
                        setState(() {
                          _passwordError = null;
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
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleRegister,
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
