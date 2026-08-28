import 'dart:async';
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
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String? initialOtp;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.initialOtp,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  late final TextEditingController _otpController;
  bool _isLoading = false;
  bool _isResending = false;
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
          _errorMessage = e is AppException ? e.message : 'Failed to resend verification code.';
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
      final tokenModel = await ref.read(authNotifierProvider.notifier).verifyOtp(
            email: widget.email,
            otp: otp,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        _showPostVerificationDecision(tokenModel.accessToken);
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

  void _showPostVerificationDecision(String? token) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space24,
              vertical: AppSpacing.space24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  'Verification Successful!',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Your account is verified and you are now signed in. Would you like to update your password now or continue to your feed?',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                AppButton(
                  text: 'Update Password Now',
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    context.pushReplacementNamed(
                      RouteNames.resetPassword,
                      queryParameters: {
                        'email': widget.email,
                        if (token != null && token.isNotEmpty) 'token': token,
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space12),
                AppButton.secondary(
                  text: 'Skip to Feed',
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    context.goNamed(RouteNames.homeFeed);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppLogo.icon(width: 60, height: 60),
                ),
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
                                  : AppColors.textSecondaryLight.withValues(alpha: 0.5))
                              : AppColors.primaryCrimson,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
