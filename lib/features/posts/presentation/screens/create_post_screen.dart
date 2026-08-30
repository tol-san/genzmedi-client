import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_notifier.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String initialPostType;

  const CreatePostScreen({
    super.key,
    this.initialPostType = 'text',
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(createPostNotifierProvider.notifier)
          .setPostType(widget.initialPostType);
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
      final XFile? picked =
          await _picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        ref.read(createPostNotifierProvider.notifier).setVideo(File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      notifier.reset();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(createPostNotifierProvider);
    final notifier = ref.read(createPostNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.space16),
            child: AppButton(
              text: state.isUploadingMedia
                  ? 'Uploading...'
                  : (state.isSubmitting ? 'Posting...' : 'Publish'),
              size: AppButtonSize.small,
              isFullWidth: false,
              isLoading: state.isSubmitting || state.isUploadingMedia,
              onPressed: _handlePublish,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Post Type Segmented Switcher
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: AppSpacing.roundedSm,
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTypeTab('text', 'Text', Icons.article_outlined, state.postType),
                  _buildTypeTab('image', 'Photos', Icons.photo_library_outlined, state.postType),
                  _buildTypeTab('video', 'Short Video', Icons.videocam_outlined, state.postType),
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
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
            ],

            // 2. Content / Caption Field
            AppTextField(
              controller: _contentController,
              label: state.postType == 'text' ? 'Post Content' : 'Caption',
              hintText: state.postType == 'text'
                  ? 'What do you want to share?'
                  : 'Write a caption and hashtags...',
              maxLines: 6,
              maxLength: 1000,
              showCounter: true,
              onChanged: notifier.setContent,
            ),
            const SizedBox(height: AppSpacing.space16),

            // 4. Media Section for Photos
            if (state.postType == 'image') ...[
              Text(
                'Photos (Up to 10)',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              if (state.selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.selectedImages.length +
                        (state.selectedImages.length < 10 ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                              child: Icon(Icons.add_photo_alternate_outlined, size: 28),
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
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: AppColors.primaryCrimson,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select Photos from Gallery',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
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
                'Short Video',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                      color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam, color: AppColors.primaryCrimson, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.selectedVideo!.path.split('/').last.split(r'\').last,
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
                              'Ready for upload',
                              style: AppTypography.caption.copyWith(color: AppColors.success),
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
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                        color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
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
                          const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
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
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.video_call_outlined,
                          size: 40,
                          color: AppColors.primaryCrimson,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select Video from Gallery',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
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
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildVisibilityChip('public', 'Public', Icons.public_rounded, state.visibility),
                const SizedBox(width: 8),
                _buildVisibilityChip('followers_only', 'Followers Only', Icons.people_rounded, state.visibility),
                const SizedBox(width: 8),
                _buildVisibilityChip('private', 'Private', Icons.lock_rounded, state.visibility),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, IconData icon, String currentType) {
    final isSelected = type == currentType;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(createPostNotifierProvider.notifier).setPostType(type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
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
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryCrimson
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
