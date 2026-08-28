import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  int _selectedPresetIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _usernameStatus;
  bool _isCheckingUsername = false;

  // Preset avatar colors for instant personalization
  static const List<List<Color>> _avatarGradients = [
    [AppColors.primaryCrimson, AppColors.primaryPressed],
    [AppColors.midnightNavy, AppColors.darkSurface],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // Cyan
    [Color(0xFF10B981), Color(0xFF059669)], // Emerald
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthNeedsOnboarding) {
        _displayNameController.text = authState.user.displayName ?? authState.user.username;
        _usernameController.text = authState.user.username;
      } else if (authState is AuthAuthenticated) {
        _displayNameController.text = authState.user.displayName ?? authState.user.username;
        _usernameController.text = authState.user.username;
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.length < 3) {
      setState(() {
        _usernameStatus = 'Username must be at least 3 characters.';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameStatus = null;
    });

    final isAvailable = await ref.read(authNotifierProvider.notifier).checkUsername(clean);

    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
        _usernameStatus = isAvailable ? '✓ Username is available' : '✗ Username is already taken';
      });
    }
  }

  Future<void> _handleSave() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            displayName: displayName.isNotEmpty ? displayName : null,
            username: username.isNotEmpty ? username : null,
          );

      if (mounted) {
        context.goNamed(RouteNames.onboarding);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '');
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSkip() {
    context.goNamed(RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialLetter = _displayNameController.text.isNotEmpty
        ? _displayNameController.text.trim()[0].toUpperCase()
        : 'G';

    return Scaffold(
      backgroundColor: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
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
                // Header Title
                Text(
                  'Set Up Your Profile',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Personalize how creators and friends see you on GenZ Media.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),

                // Main Avatar Preview
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _avatarGradients[_selectedPresetIndex],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _avatarGradients[_selectedPresetIndex][0].withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Avatar Presets Row
                Text(
                  'Choose Avatar Style',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_avatarGradients.length, (index) {
                    final isSelected = _selectedPresetIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPresetIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _avatarGradients[index],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: isSelected
                              ? Border.all(
                                  color: isDark ? Colors.white : AppColors.midnightNavy,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.space24),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                ],

                // Display Name Input
                AppTextField(
                  key: const Key('profile_setup_display_name_field'),
                  controller: _displayNameController,
                  label: 'Display Name',
                  hintText: 'e.g. Alex Rivera',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Username Input
                AppTextField(
                  key: const Key('profile_setup_username_field'),
                  controller: _usernameController,
                  label: 'Username',
                  hintText: 'e.g. alex_rivera',
                  textInputAction: TextInputAction.done,
                  onChanged: (val) {
                    if (val.trim().length >= 3) {
                      _checkUsernameAvailability(val);
                    }
                  },
                ),
                if (_usernameStatus != null || _isCheckingUsername) ...[
                  const SizedBox(height: 6),
                  Text(
                    _isCheckingUsername ? 'Checking availability...' : _usernameStatus!,
                    style: AppTypography.caption.copyWith(
                      color: _usernameStatus?.startsWith('✓') == true
                          ? AppColors.signalMint
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space24),

                // Save & Continue Button
                AppButton(
                  key: const Key('profile_setup_continue_button'),
                  text: 'Save & Continue',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSave,
                ),
                const SizedBox(height: AppSpacing.space12),

                // Skip for Now Button
                AppButton(
                  key: const Key('profile_setup_skip_button'),
                  text: 'Skip for Now',
                  variant: AppButtonVariant.secondary,
                  onPressed: _handleSkip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
