import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/community_detail_notifier.dart';
import 'package:client/features/communities/presentation/notifiers/community_list_notifier.dart';

class EditCommunityScreen extends ConsumerStatefulWidget {
  final String communityId;
  final CommunityModel? initialCommunity;

  const EditCommunityScreen({
    super.key,
    required this.communityId,
    this.initialCommunity,
  });

  @override
  ConsumerState<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends ConsumerState<EditCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  CommunityModel? _community;
  bool _isPrivate = false;
  String? _existingCoverUrl;
  String? _existingAvatarUrl;
  File? _newCoverFile;
  File? _newAvatarFile;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCommunity != null) {
      _applyCommunity(widget.initialCommunity!);
    } else {
      _loadCommunity();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyCommunity(CommunityModel community) {
    _community = community;
    _nameController.text = community.name;
    _descriptionController.text = community.description ?? '';
    _isPrivate = community.isPrivate;
    _existingCoverUrl = community.coverImageUrl;
    _existingAvatarUrl = community.avatarUrl;
  }

  Future<void> _loadCommunity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await ref
          .read(communityRepositoryProvider)
          .getCommunity(widget.communityId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _applyCommunity(detail.community);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load community details.';
        });
      }
    }
  }

  Future<void> _pickCover() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _newCoverFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _newAvatarFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _errorMessage = 'Community name must be at least 2 characters.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(communityRepositoryProvider);

      // 1. Update text metadata & privacy
      var updated = await repository.updateCommunity(
        widget.communityId,
        CommunityUpdateRequestModel(
          name: name,
          description: _descriptionController.text.trim(),
          isPrivate: _isPrivate,
        ),
      );

      // 2. Upload cover if changed
      if (_newCoverFile != null) {
        updated = await repository.uploadCover(widget.communityId, _newCoverFile!);
      }

      // 3. Upload avatar if changed
      if (_newAvatarFile != null) {
        updated = await repository.uploadAvatar(widget.communityId, _newAvatarFile!);
      }

      // Update notifiers
      ref
          .read(communityDetailNotifierProvider(widget.communityId).notifier)
          .updateCommunity(updated);

      if (ref.exists(communityListNotifierProvider)) {
        ref.read(communityListNotifierProvider.notifier).updateCommunity(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community settings updated successfully!'),
            backgroundColor: AppColors.signalMint,
          ),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update community. Please try again.';
        });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final communityName = _community?.name ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteCommunityConfirmDialog(communityName: communityName),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(communityRepositoryProvider)
            .deleteCommunity(widget.communityId);

        if (ref.exists(communityListNotifierProvider)) {
          ref
              .read(communityListNotifierProvider.notifier)
              .removeCommunity(widget.communityId);
        }

        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Community deleted successfully.'),
              backgroundColor: AppColors.signalMint,
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            try {
              context.goNamed(RouteNames.communityList);
            } catch (_) {}
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Failed to delete community. Please try again.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Community')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCrimson),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Community'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryCrimson,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined Visual Header: Cover Banner + Overlapping Avatar Icon Picker
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Cover Banner Picker
                GestureDetector(
                  onTap: _pickCover,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: isDark
                            ? AppColors.navyBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _newCoverFile != null
                        ? Image.file(
                            _newCoverFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : _existingCoverUrl != null && _existingCoverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _existingCoverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (_, _, _) => const Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AppColors.primaryCrimson,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AppColors.primaryCrimson,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Change Cover Banner',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primaryCrimson,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // 2. Overlapping Circular Avatar Picker
                Positioned(
                  left: AppSpacing.space16,
                  bottom: -32,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.midnightNavy
                                  : AppColors.lightCanvas,
                              width: 4,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _newAvatarFile != null
                              ? Image.file(
                                  _newAvatarFile!,
                                  fit: BoxFit.cover,
                                )
                              : _existingAvatarUrl != null &&
                                      _existingAvatarUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _existingAvatarUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const Center(
                                    child: Icon(
                                      Icons.groups_rounded,
                                      color: AppColors.primaryCrimson,
                                      size: 36,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.groups_rounded,
                                    color: AppColors.primaryCrimson,
                                    size: 36,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryCrimson,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 44),

            // Guidance text
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap banner to change cover · Tap circle to change logo',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space20),

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
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

            // Name Field
            AppTextField(
              controller: _nameController,
              label: 'Community Name',
              hintText: 'e.g. Flutter Builders, Tokyo Coffee Lovers...',
              maxLength: 100,
              showCounter: true,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.space16),

            // Description Field
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hintText: 'What is this community about? Guidelines & goals.',
              maxLines: 4,
              maxLength: 1000,
              showCounter: true,
            ),
            const SizedBox(height: AppSpacing.space16),

            // Privacy Switch Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPrivate
                        ? Icons.lock_outline_rounded
                        : Icons.public_rounded,
                    color: _isPrivate
                        ? AppColors.warning
                        : AppColors.signalMint,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPrivate
                              ? 'Private Community'
                              : 'Public Community',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isPrivate
                              ? 'Members must submit a request and be approved by you.'
                              : 'Anyone can discover, join, and post immediately.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPrivate,
                    activeThumbColor: AppColors.primaryCrimson,
                    onChanged: (val) => setState(() => _isPrivate = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Save Button
            AppButton(
              text: 'Save Changes',
              size: AppButtonSize.large,
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
            const SizedBox(height: AppSpacing.space32),

            // Danger Zone
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: AppTypography.label.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently delete this community and all its content. This action cannot be undone.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                    ),
                    onPressed: _isSaving ? null : _showDeleteConfirmationDialog,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'Delete Community',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
          ],
        ),
      ),
    );
  }
}

class DeleteCommunityConfirmDialog extends StatefulWidget {
  final String communityName;

  const DeleteCommunityConfirmDialog({super.key, required this.communityName});

  @override
  State<DeleteCommunityConfirmDialog> createState() =>
      _DeleteCommunityConfirmDialogState();
}

class _DeleteCommunityConfirmDialogState
    extends State<DeleteCommunityConfirmDialog> {
  late final TextEditingController _controller;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: const Text(
        'Delete Community?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action is irreversible. All posts, memberships, and media in this community will be permanently deleted.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'To confirm, type "${widget.communityName}" below:',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.space8),
          TextField(
            key: const Key('confirm_delete_field'),
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.communityName,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _canConfirm = val.trim() == widget.communityName.trim();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: const Text(
            'Delete Community',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
