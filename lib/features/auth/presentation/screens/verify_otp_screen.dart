import 'dart:async';

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
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String? initialOtp;
  final String? flow;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.initialOtp,
    this.flow,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  late final TextEditingController _otpController;
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  String? _resetToken;
  String? _errorMessage;
  String? _otpError;
  String? _successBanner;

  int _resendCooldown = 30;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: widget.initialOtp ?? '');
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successBanner = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.forgotPassword(
        ForgotPasswordRequest(email: widget.email),
      );
      if (mounted) {
        setState(() {
          _isResending = false;
          _successBanner = 'A new 6-digit code has been sent to your email.';
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = e is AppException
              ? e.message
              : 'Failed to resend verification code.';
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    setState(() {
      _errorMessage = null;
      _otpError = null;
      _successBanner = null;
    });

    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() => _otpError = 'Please enter the 6-digit code.');
      return;
    } else if (otp.length != 6) {
      setState(() => _otpError = 'Verification code must be 6 digits.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.flow == 'signup') {
        await ref
            .read(authNotifierProvider.notifier)
            .verifySignupOtp(email: widget.email, otp: otp);

        if (mounted) {
          context.goNamed(RouteNames.profileSetup);
        }
      } else {
        final verification = await ref
            .read(authNotifierProvider.notifier)
            .verifyOtp(email: widget.email, otp: otp);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isVerified = true;
            _resetToken = verification.resetToken;
          });
        }
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
      });
    }
  }

  void _navigateToFeedOrOnboarding() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthNeedsOnboarding) {
      context.goNamed(RouteNames.onboarding);
    } else if (authState is AuthAuthenticated) {
      context.goNamed(RouteNames.homeFeed);
    } else {
      context.goNamed(RouteNames.login);
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
        leading: _isVerified
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
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
            child: _isVerified
                ? _buildDecisionView(isDark)
                : _buildOtpInputView(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.space20),
        Text(
          'Verification Successful! 🎉',
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
          'Your email is verified. Update your password now, or return to sign in without changing it.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space32),
        AppButton(
          text: 'Update Password Now',
          onPressed: () {
            context.goNamed(
              RouteNames.resetPassword,
              queryParameters: {
                'email': widget.email,
                if (_resetToken != null && _resetToken!.isNotEmpty)
                  'token': _resetToken!,
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.space12),
        AppButton.secondary(
          text: 'Back to Sign In',
          onPressed: _navigateToFeedOrOnboarding,
        ),
      ],
    );
  }

  Widget _buildOtpInputView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppLogo.icon(width: 60, height: 60)),
        const SizedBox(height: AppSpacing.space20),
        Text(
          'Confirm Verification Code',
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
          'Enter the 6-digit code sent to\n${widget.email}',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space32),
        if (_successBanner != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Text(
                    _successBanner!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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

        // 6-digit Verification Code Input
        AppTextField(
          controller: _otpController,
          label: 'Verification Code',
          hintText: 'Enter 6-digit code (e.g. 549001)',
          errorText: _otpError,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (val) {
            if (_otpError != null) {
              setState(() => _otpError = null);
            }
            if (val.trim().length == 6) {
              _handleVerify();
            }
          },
          onSubmitted: (_) => _handleVerify(),
        ),
        const SizedBox(height: AppSpacing.space24),

        AppButton(
          text: 'Verify Code',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleVerify,
        ),
        const SizedBox(height: AppSpacing.space16),

        // Resend Code / Change Email Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Change Email',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: _resendCooldown > 0 ? null : _handleResend,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : 'Resend Code',
                style: AppTypography.bodySmall.copyWith(
                  color: _resendCooldown > 0
                      ? (isDark
                            ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                            : AppColors.textSecondaryLight.withValues(
                                alpha: 0.5,
                              ))
                      : AppColors.primaryCrimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
