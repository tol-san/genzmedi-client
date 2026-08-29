import 'dart:io';
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
import 'package:client/features/communities/presentation/notifiers/create_community_notifier.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        ref
            .read(createCommunityNotifierProvider.notifier)
            .setCover(File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(createCommunityNotifierProvider.notifier);
    notifier.setName(_nameController.text);
    notifier.setDescription(_descriptionController.text);

    final success = await notifier.submitCommunity();
    if (success && mounted) {
      final created = ref.read(createCommunityNotifierProvider).createdCommunity;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community "${created?.name ?? 'New Community'}" created!'),
          backgroundColor: AppColors.success,
        ),
      );
      notifier.reset();
      if (created != null) {
        context.pushReplacementNamed(
          RouteNames.communityDetail,
          pathParameters: {'communityId': created.id},
        );
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(createCommunityNotifierProvider);
    final notifier = ref.read(createCommunityNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Selector
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
                child: state.selectedCover != null
                    ? ClipRRect(
                        borderRadius: AppSpacing.roundedMd,
                        child: Image.file(
                          state.selectedCover!,
                          fit: BoxFit.cover,
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
                            'Add Community Banner (Optional)',
                            style: AppTypography.label.copyWith(
                              color: AppColors.primaryCrimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Error Banner
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
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
              hintText: 'e.g. Neo Tokyo Aesthetics, Dev Hub...',
              maxLength: 100,
              showCounter: true,
              onChanged: notifier.setName,
            ),
            const SizedBox(height: AppSpacing.space16),

            // Description Field
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hintText: 'What is this community about? Set guidelines & goals.',
              maxLines: 4,
              maxLength: 1000,
              showCounter: true,
              onChanged: notifier.setDescription,
            ),
            const SizedBox(height: AppSpacing.space16),

            // Privacy Switch Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color:
                      isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isPrivate
                        ? Icons.lock_outline_rounded
                        : Icons.public_rounded,
                    color: state.isPrivate
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
                          state.isPrivate
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
                          state.isPrivate
                              ? 'Members must submit a request and be approved by you.'
                              : 'Anyone can discover, join, and post immediately.',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.isPrivate,
                    activeThumbColor: AppColors.primaryCrimson,
                    onChanged: (val) => notifier.setIsPrivate(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space32),

            // Submit Button
            AppButton(
              text: 'Create Community',
              size: AppButtonSize.large,
              isLoading: state.isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
