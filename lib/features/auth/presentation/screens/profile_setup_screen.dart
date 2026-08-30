import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  int _selectedPresetIndex = 0;
  File? _customImageFile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _usernameStatus;
  bool _isCheckingUsername = false;

  // DiceBear avatar styles catalog with valid v9 API keys
  static const List<Map<String, String>> _dicebearStyles = [
    {'name': 'Critters', 'style': 'croodles'},
    {'name': 'Bottts', 'style': 'bottts'},
    {'name': 'Lorelei', 'style': 'lorelei'},
    {'name': 'Fun Emoji', 'style': 'fun-emoji'},
    {'name': 'Adventurer', 'style': 'adventurer'},
    {'name': 'Personas', 'style': 'personas'},
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

  String _getDicebearUrl(int index) {
    final style = _dicebearStyles[index]['style']!;
    final seed = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim().toLowerCase()
        : (_displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim().toLowerCase()
            : 'GenZ');
    return 'https://api.dicebear.com/9.x/$style/png?seed=$seed';
  }

  Future<void> _pickCustomImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _customImageFile = File(picked.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access gallery. Please try again.';
      });
    }
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
      if (_customImageFile != null) {
        await ref.read(authNotifierProvider.notifier).uploadAvatar(_customImageFile!);
        await ref.read(authNotifierProvider.notifier).updateProfile(
              displayName: displayName.isNotEmpty ? displayName : null,
              username: username.isNotEmpty ? username : null,
            );
      } else {
        final avatarUrl = _getDicebearUrl(_selectedPresetIndex);
        await ref.read(authNotifierProvider.notifier).updateProfile(
              displayName: displayName.isNotEmpty ? displayName : null,
              username: username.isNotEmpty ? username : null,
              avatarUrl: avatarUrl,
            );
      }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAvatarUrl = _getDicebearUrl(_selectedPresetIndex);

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

                // Main Avatar Preview with Camera Overlay
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                          border: Border.all(
                            color: AppColors.primaryCrimson.withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryCrimson.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _customImageFile != null
                              ? Image.file(
                                  _customImageFile!,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  currentAvatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickCustomImage,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryCrimson,
                              border: Border.all(
                                color: isDark ? AppColors.midnightNavy : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Upload or Select Style Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _customImageFile != null ? 'Custom Photo Selected' : 'Choose Avatar Style',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_customImageFile != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _customImageFile = null),
                        child: Text(
                          'Reset',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryCrimson,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),

                // DiceBear Avatar Styles Selector Grid / Chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_dicebearStyles.length, (index) {
                    final isSelected = _customImageFile == null && _selectedPresetIndex == index;
                    final name = _dicebearStyles[index]['name']!;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(name),
                      labelStyle: AppTypography.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                      selectedColor: isDark ? AppColors.darkSurfaceElevated : AppColors.midnightNavy,
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                      checkmarkColor: Colors.white,
                      onSelected: (_) {
                        setState(() {
                          _customImageFile = null;
                          _selectedPresetIndex = index;
                        });
                      },
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
                    setState(() {});
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

                // Continue Button
                AppButton(
                  key: const Key('profile_setup_continue_button'),
                  text: 'Continue',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
