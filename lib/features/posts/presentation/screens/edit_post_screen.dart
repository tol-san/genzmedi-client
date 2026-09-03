import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';
import 'package:client/features/feeds/presentation/notifiers/home_feed_notifier.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/notifiers/post_detail_notifier.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final String postId;
  final PostModel? initialPost;

  const EditPostScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _visibility;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  PostModel? _post;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _titleController = TextEditingController(text: _post?.title ?? '');
    _contentController = TextEditingController(text: _post?.content ?? '');
    _visibility = _post?.visibility ?? 'public';

    if (_post == null) {
      _loadPost();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final post = await ref.read(postRepositoryProvider).getPost(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _titleController.text = post.title ?? '';
          _contentController.text = post.content ?? '';
          _visibility = post.visibility;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load post details.';
        });
      }
    }
  }

  Future<void> _handleSave() async {
    final content = _contentController.text.trim();
    final title = _titleController.text.trim();

    if (content.isEmpty && title.isEmpty) {
      setState(() {
        _errorMessage = 'Post content or title cannot be empty.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await ref.read(postRepositoryProvider).updatePost(
        widget.postId,
        title: title.isEmpty ? null : title,
        content: content,
        visibility: _visibility,
      );

      // Update feed and detail providers if they are active
      if (ref.exists(homeFeedNotifierProvider)) {
        ref.read(homeFeedNotifierProvider.notifier).updatePost(updated);
      }
      if (ref.exists(postDetailNotifierProvider(widget.postId))) {
        ref.read(postDetailNotifierProvider(widget.postId).notifier).updatePost(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: AppColors.signalMint,
          ),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update post. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryCrimson,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryCrimson,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.space8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
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
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],

                  // ── Title Input (Optional) ──────────────────────────────────
                  Text(
                    'Title (Optional)',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  AppTextField(
                    controller: _titleController,
                    hintText: 'Add an interesting title...',
                    maxLength: 120,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // ── Content / Caption Input ─────────────────────────────────
                  Text(
                    'Caption / Content',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  AppTextField(
                    controller: _contentController,
                    hintText: 'Write your thoughts...',
                    maxLines: 5,
                    maxLength: 2000,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: AppSpacing.space20),

                  // ── Visibility Selector ─────────────────────────────────────
                  Text(
                    'Post Visibility',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurface,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: isDark
                            ? AppColors.navyBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _VisibilityTile(
                          icon: Icons.public_rounded,
                          title: 'Public',
                          subtitle: 'Visible to everyone on GenZ Media',
                          isSelected: _visibility == 'public',
                          onTap: _isSaving
                              ? () {}
                              : () => setState(() => _visibility = 'public'),
                        ),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.navyBorder
                              : AppColors.lightBorderSubtle,
                        ),
                        _VisibilityTile(
                          icon: Icons.people_outline_rounded,
                          title: 'Followers Only',
                          subtitle: 'Only users following you can see this post',
                          isSelected: _visibility == 'followers_only',
                          onTap: _isSaving
                              ? () {}
                              : () =>
                                  setState(() => _visibility = 'followers_only'),
                        ),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.navyBorder
                              : AppColors.lightBorderSubtle,
                        ),
                        _VisibilityTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Private',
                          subtitle: 'Only you can view this post',
                          isSelected: _visibility == 'private',
                          onTap: _isSaving
                              ? () {}
                              : () => setState(() => _visibility = 'private'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // ── Media Notice & Previews ─────────────────────────────────
                  if (_post != null && _post!.media.isNotEmpty) ...[
                    Text(
                      'Attached Media (${_post!.media.length})',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(
                          color: isDark
                              ? AppColors.navyBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          const Expanded(
                            child: Text(
                              'Media attachments cannot be replaced or re-ordered after publishing.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.roundedMd,
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.navyBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: AppButton(
                          text: 'Save Changes',
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _handleSave,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space32),
                ],
              ),
            ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primaryCrimson : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryCrimson
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryCrimson,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
