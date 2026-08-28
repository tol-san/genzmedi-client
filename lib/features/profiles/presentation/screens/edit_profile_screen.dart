import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  File? _customImageFile;
  bool _removeAvatar = false;
  Set<String> _selectedInterests = {};
  List<InterestModel> _availableInterests = [];
  bool _isLoading = false;
  bool _isLoadingInterests = false;
  String? _errorMessage;
  String? _usernameStatus;
  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
      _loadInterestsCatalog();
    });
  }

  void _initializeUserData() {
    final authState = ref.read(authNotifierProvider);
    final user = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthNeedsOnboarding ? authState.user : null);

    if (user != null) {
      _displayNameController.text = user.displayName ?? user.username;
      _usernameController.text = user.username;
      _bioController.text = user.bio ?? '';
      setState(() {
        _selectedInterests = Set<String>.from(user.interests);
      });
    }
  }

  Future<void> _loadInterestsCatalog() async {
    setState(() => _isLoadingInterests = true);
    try {
      final repository = ref.read(profileRepositoryProvider);
      final catalog = await repository.getInterests();
      if (mounted) {
        setState(() {
          _availableInterests = catalog;
          _isLoadingInterests = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInterests = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _customImageFile = File(picked.path);
          _removeAvatar = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access image picker.';
      });
    }
  }

  void _showImagePickerSheet(BuildContext context) {
    final authState = ref.read(authNotifierProvider);
    final user = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthNeedsOnboarding ? authState.user : null);
    final hasAvatar = _customImageFile != null || (user?.avatarUrl != null && !_removeAvatar);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change Profile Photo', style: AppTypography.title),
              const SizedBox(height: AppSpacing.space16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primaryCrimson),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryCrimson),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _customImageFile = null;
                      _removeAvatar = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterestsPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.all(AppSpacing.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text('Select Interests', style: AppTypography.title),
                  const SizedBox(height: 4),
                  Text(
                    'Pick topics that best represent your passions.',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Expanded(
                    child: _isLoadingInterests
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            controller: scrollController,
                            child: Wrap(
                              spacing: AppSpacing.space8,
                              runSpacing: AppSpacing.space8,
                              children: _availableInterests.map((interest) {
                                final isSelected =
                                    _selectedInterests.contains(interest.slug) ||
                                    _selectedInterests.contains(interest.name);

                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    interest.icon != null
                                        ? '${interest.icon} ${interest.name}'
                                        : interest.name,
                                  ),
                                  selectedColor: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.primarySoft,
                                  checkmarkColor: AppColors.primaryCrimson,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? (isDark ? AppColors.textPrimaryDark : AppColors.primaryCrimson)
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  onSelected: (selected) {
                                    setSheetState(() {
                                      if (selected) {
                                        _selectedInterests.add(interest.slug);
                                      } else {
                                        _selectedInterests.remove(interest.slug);
                                        _selectedInterests.remove(interest.name);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  AppButton(
                    text: 'Done',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkUsername(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.length < 3) {
      setState(() => _usernameStatus = 'Username must be at least 3 characters.');
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
        _usernameStatus = isAvailable ? '✓ Available' : '✗ Taken';
      });
    }
  }

  Future<void> _handleSave() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // 1. Upload custom avatar if chosen or delete if removed
      if (_customImageFile != null) {
        await authNotifier.uploadAvatar(_customImageFile!);
      } else if (_removeAvatar) {
        await repository.deleteAvatar();
        await authNotifier.updateProfile(avatarUrl: '');
      }

      // 2. Update profile text details
      await authNotifier.updateProfile(
        displayName: displayName.isNotEmpty ? displayName : null,
        username: username.isNotEmpty ? username : null,
        bio: bio.isNotEmpty ? bio : null,
      );

      // 3. Update interests
      if (_selectedInterests.isNotEmpty) {
        await repository.updateMyInterests(_selectedInterests.toList());
      }

      // 4. Refresh profile state
      await ref.read(myProfileNotifierProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthNeedsOnboarding ? authState.user : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.space12),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _handleSave,
                    child: Text(
                      'Save',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primaryCrimson,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.space8),

            // Avatar Preview & Change Action
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: _customImageFile != null
                        ? Image.file(_customImageFile!, fit: BoxFit.cover)
                        : (_removeAvatar
                            ? AppAvatar(
                                size: 96,
                                name: user?.displayName ?? user?.username ?? 'User',
                                imageUrl: null,
                              )
                            : AppAvatar(
                                size: 96,
                                name: user?.displayName ?? user?.username ?? 'User',
                                imageUrl: user?.avatarUrl,
                              )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImagePickerSheet(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryCrimson,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.midnightNavy : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            TextButton(
              onPressed: () => _showImagePickerSheet(context),
              child: Text(
                'Change Photo',
                style: AppTypography.label.copyWith(
                  color: AppColors.primaryCrimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
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

            // Input Fields
            AppTextField(
              controller: _displayNameController,
              label: 'Display Name',
              hintText: 'Your name or creator alias',
              maxLength: 50,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.space16),

            AppTextField(
              controller: _usernameController,
              label: 'Username',
              hintText: 'unique_handle',
              textInputAction: TextInputAction.next,
              onChanged: (val) {
                if (val.trim().length >= 3 && val.trim().toLowerCase() != user?.username.toLowerCase()) {
                  _checkUsername(val);
                } else {
                  setState(() => _usernameStatus = null);
                }
              },
            ),
            if (_usernameStatus != null || _isCheckingUsername) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isCheckingUsername ? 'Checking availability...' : _usernameStatus!,
                  style: AppTypography.caption.copyWith(
                    color: _usernameStatus?.startsWith('✓') == true
                        ? AppColors.signalMint
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space16),

            AppTextField(
              controller: _bioController,
              label: 'Bio',
              hintText: 'Tell creators what you love building and sharing...',
              maxLength: 160,
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.space24),

            // Interests Manager Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Interests',
                  style: AppTypography.label.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () => _showInterestsPickerSheet(context),
                  child: Text(
                    '+ Add / Edit',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            if (_selectedInterests.isNotEmpty)
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: _selectedInterests
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space12,
                          vertical: AppSpacing.space4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                          borderRadius: AppSpacing.roundedFull,
                          border: Border.all(
                            color: isDark ? AppColors.navyBorder : AppColors.primarySoft,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#$item',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.primaryCrimson,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedInterests.remove(item));
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: isDark ? AppColors.textMuted : AppColors.primaryCrimson,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No interests selected. Tap "+ Add / Edit" to customize.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
