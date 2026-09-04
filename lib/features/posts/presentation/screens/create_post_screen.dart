import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/utils/media_url_resolver.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/communities/presentation/notifiers/community_list_notifier.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_notifier.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_state.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String initialPostType;
  final String? communityId;
  final String? communityName;
  final String? communityAvatarUrl;
  final bool isCommunityLocked;

  const CreatePostScreen({
    super.key,
    this.initialPostType = 'text',
    this.communityId,
    this.communityName,
    this.communityAvatarUrl,
    this.isCommunityLocked = false,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();
  String? _currentCommunityName;
  String? _currentCommunityAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentCommunityName = widget.communityName;
    _currentCommunityAvatarUrl = widget.communityAvatarUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(createPostNotifierProvider.notifier)
          .setPostType(widget.initialPostType);
      if (widget.communityId != null) {
        ref
            .read(createPostNotifierProvider.notifier)
            .setCommunityId(widget.communityId);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        final files = picked.map((x) => File(x.path)).toList();
        ref.read(createPostNotifierProvider.notifier).addImages(files);
      }
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        ref
            .read(createPostNotifierProvider.notifier)
            .setVideo(File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        ref
            .read(createPostNotifierProvider.notifier)
            .setThumbnail(File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _handlePublish() async {
    final notifier = ref.read(createPostNotifierProvider.notifier);
    notifier.setContent(_contentController.text);

    final success = await notifier.submitPost();
    if (success && mounted) {
      final post = ref.read(createPostNotifierProvider).createdPost;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      notifier.reset();
      context.pop(post);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(createPostNotifierProvider);
    final notifier = ref.read(createPostNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _composerTitle(state.postType),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Your draft stays while you create',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space12,
            AppSpacing.space16,
            AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: AppButton(
            text: state.isUploadingMedia
                ? (state.uploadProgress > 0
                      ? 'Uploading ${(state.uploadProgress * 100).toInt()}%'
                      : 'Preparing upload...')
                : (state.isSubmitting ? 'Publishing post...' : 'Publish post'),
            icon: state.isUploadingMedia
                ? Icons.cloud_upload_rounded
                : Icons.arrow_upward_rounded,
            isLoading: state.isSubmitting && !state.isUploadingMedia,
            onPressed: (state.isSubmitting || state.isUploadingMedia)
                ? null
                : _handlePublish,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space16,
          AppSpacing.space12,
          AppSpacing.space16,
          AppSpacing.space32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Progress Banner
            if (state.isUploadingMedia ||
                (state.isSubmitting && state.uploadProgress > 0)) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primarySoft,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(
                    color: AppColors.primaryCrimson.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCrimson,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publishing your post',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                state.uploadStatusText ?? 'Uploading media...',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(state.uploadProgress * 100).toInt()}%',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryCrimson,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.uploadProgress > 0
                            ? state.uploadProgress
                            : null,
                        backgroundColor: isDark
                            ? AppColors.navyBorder
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryCrimson,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'Keep this screen open until publishing is complete.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
            ],

            // Post Destination Banner (Community or Profile)
            _buildDestinationBanner(context, state, isDark),

            // 1. Post Type Segmented Switcher
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurfaceElevated,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTypeTab(
                    'text',
                    'Text',
                    Icons.notes_rounded,
                    state.postType,
                  ),
                  _buildTypeTab(
                    'image',
                    'Photos',
                    Icons.photo_library_outlined,
                    state.postType,
                  ),
                  _buildTypeTab(
                    'video',
                    'Short',
                    Icons.play_circle_outline_rounded,
                    state.postType,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // Error Banner
            if (state.errorMessage != null) ...[
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
                        state.errorMessage!,
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

            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppSpacing.roundedLg,
                border: Border.all(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
              ),
              child: AppTextField(
                controller: _contentController,
                label: state.postType == 'text' ? 'Post Content' : 'Caption',
                hintText: state.postType == 'text'
                    ? 'What do you want to share?'
                    : 'Add context, mentions, or hashtags...',
                maxLines: state.postType == 'text' ? 9 : 5,
                maxLength: 1000,
                showCounter: true,
                onChanged: notifier.setContent,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // 4. Media Section for Photos
            if (state.postType == 'image') ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Photo carousel',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    '${state.selectedImages.length}/10',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              if (state.selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        state.selectedImages.length +
                        (state.selectedImages.length < 10 ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == state.selectedImages.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated,
                              borderRadius: AppSpacing.roundedSm,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.navyBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 28,
                              ),
                            ),
                          ),
                        );
                      }

                      final file = state.selectedImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppSpacing.roundedSm,
                            child: Image.file(
                              file,
                              width: 100,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => notifier.removeImageAt(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
              ] else ...[
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space24,
                      vertical: AppSpacing.space32,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.primarySoft,
                      borderRadius: AppSpacing.roundedLg,
                      border: Border.all(
                        color: AppColors.primaryCrimson.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCrimson.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                            color: AppColors.primaryCrimson,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        Text(
                          'Select Photos from Gallery',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          'Choose up to 10 images for your carousel',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
              ],
            ],

            // 5. Media Section for Short Video
            if (state.postType == 'video') ...[
              Text(
                'Short video',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              if (state.selectedVideo != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.navyBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: AppColors.primaryCrimson,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.selectedVideo!.path
                                  .split('/')
                                  .last
                                  .split(r'\')
                                  .last,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.isUploadingMedia
                                  ? (state.uploadStatusText ?? 'Uploading...')
                                  : 'Ready for upload',
                              style: AppTypography.caption.copyWith(
                                color: state.isUploadingMedia
                                    ? AppColors.primaryElectricBlue
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickVideo,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Video Thumbnail Picker
                Text(
                  'Custom Thumbnail (Optional)',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickThumbnail,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: isDark
                            ? AppColors.navyBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (state.selectedThumbnail != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              state.selectedThumbnail!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(
                            Icons.image_outlined,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.selectedThumbnail != null
                                ? 'Custom thumbnail selected'
                                : 'Tap to choose custom thumbnail',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
              ] else ...[
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space24,
                      vertical: AppSpacing.space32,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.primarySoft,
                      borderRadius: AppSpacing.roundedLg,
                      border: Border.all(
                        color: AppColors.primaryCrimson.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCrimson.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.video_call_outlined,
                            size: 30,
                            color: AppColors.primaryCrimson,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        Text(
                          'Select Video from Gallery',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          'Vertical videos work best for Shorts',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
              ],
            ],

            // 6. Visibility Selector
            Text(
              'Visibility',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              children: [
                _buildVisibilityChip(
                  'public',
                  'Public',
                  Icons.public_rounded,
                  state.visibility,
                ),
                _buildVisibilityChip(
                  'followers_only',
                  'Followers',
                  Icons.people_rounded,
                  state.visibility,
                ),
                _buildVisibilityChip(
                  'private',
                  'Only me',
                  Icons.lock_rounded,
                  state.visibility,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _composerTitle(String postType) {
    switch (postType) {
      case 'image':
        return 'New photo post';
      case 'video':
        return 'New short video';
      default:
        return 'New text post';
    }
  }

  Widget _buildTypeTab(
    String type,
    String label,
    IconData icon,
    String currentType,
  ) {
    final isSelected = type == currentType;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(createPostNotifierProvider.notifier).setPostType(type);
          },
          borderRadius: AppSpacing.roundedSm,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryCrimson : Colors.transparent,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(
    String value,
    String label,
    IconData icon,
    String currentValue,
  ) {
    final isSelected = value == currentValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ref.read(createPostNotifierProvider.notifier).setVisibility(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCrimson.withValues(alpha: 0.15)
              : (isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated),
          borderRadius: AppSpacing.roundedFull,
          border: Border.all(
            color: isSelected ? AppColors.primaryCrimson : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.primaryCrimson
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryCrimson
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationBanner(
    BuildContext context,
    CreatePostState state,
    bool isDark,
  ) {
    if (state.communityId != null) {
      final isLocked =
          widget.isCommunityLocked && widget.communityId == state.communityId;
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space16),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryCrimson.withValues(alpha: 0.1),
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(
            color: AppColors.primaryCrimson.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            if (_currentCommunityAvatarUrl != null &&
                _currentCommunityAvatarUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl:
                      resolveMediaUrl(_currentCommunityAvatarUrl) ??
                      _currentCommunityAvatarUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorWidget:
                      (_, _, _) => const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primaryCrimson,
                        size: 18,
                      ),
                ),
              )
            else
              const Icon(
                Icons.groups_rounded,
                color: AppColors.primaryCrimson,
                size: 18,
              ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Text(
                'Posting to: ${_currentCommunityName ?? "Community"}',
                style: const TextStyle(
                  color: AppColors.primaryCrimson,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryCrimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: AppColors.primaryCrimson,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Locked',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryCrimson,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentCommunityName = null;
                    _currentCommunityAvatarUrl = null;
                  });
                  ref
                      .read(createPostNotifierProvider.notifier)
                      .setCommunityId(null);
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primaryCrimson,
                ),
              ),
          ],
        ),
      );
    }

    // Unlocked and no community selected: offer selector to post to personal or joined community
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space16),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              'Destination: My Profile (Default)',
              style: AppTypography.bodySmall.copyWith(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showDestinationPicker(context),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text(
              'Change',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDestinationPicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final communityState = ref.watch(communityListNotifierProvider);
              final joined = communityState.joinedCommunities;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                      ),
                      child: Text(
                        'Select Post Destination',
                        style: AppTypography.title.copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryElectricBlue,
                        radius: 16,
                        child: Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                      title: const Text('My Profile'),
                      subtitle: const Text('Publish directly to your followers'),
                      onTap: () {
                        setState(() {
                          _currentCommunityName = null;
                          _currentCommunityAvatarUrl = null;
                        });
                        ref
                            .read(createPostNotifierProvider.notifier)
                            .setCommunityId(null);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    if (joined.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space16,
                          vertical: AppSpacing.space4,
                        ),
                        child: Text(
                          'Your Communities',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...joined.map(
                        (comm) => ListTile(
                          leading:
                              comm.avatarUrl != null &&
                                      comm.avatarUrl!.isNotEmpty
                                  ? CircleAvatar(
                                    radius: 16,
                                    backgroundImage: CachedNetworkImageProvider(
                                      resolveMediaUrl(comm.avatarUrl) ??
                                          comm.avatarUrl!,
                                    ),
                                  )
                                  : const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primaryCrimson,
                                    child: Icon(
                                      Icons.groups_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          title: Text(comm.name),
                          subtitle: Text(
                            '${comm.memberCount} members · ${comm.isPrivate ? "Private" : "Public"}',
                          ),
                          onTap: () {
                            setState(() {
                              _currentCommunityName = comm.name;
                              _currentCommunityAvatarUrl = comm.avatarUrl;
                            });
                            ref
                                .read(createPostNotifierProvider.notifier)
                                .setCommunityId(comm.id);
                            Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
