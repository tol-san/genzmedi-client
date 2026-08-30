import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/notifiers/post_detail_notifier.dart';
import 'package:client/features/posts/presentation/screens/post_reactions_screen.dart';
import 'package:client/features/posts/presentation/widgets/comment_tile_widget.dart';

/// Modal bottom sheet for viewing and creating comments on a post.
/// Matches Facebook-style layout with top reaction summary row and sticky bottom composer.
class PostCommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  final PostModel? initialPost;

  const PostCommentsSheet({
    super.key,
    required this.postId,
    this.initialPost,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    PostModel? post,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentsSheet(
        postId: postId,
        initialPost: post,
      ),
    );
  }

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedSort = 'Most relevant';

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _openReactionsScreen(BuildContext context) async {
    final mentionResult = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => PostReactionsScreen(postId: widget.postId),
      ),
    );

    if (mentionResult != null && mounted) {
      _commentController.text = '${_commentController.text}$mentionResult';
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(postDetailNotifierProvider(widget.postId));
    final notifier = ref.read(postDetailNotifierProvider(widget.postId).notifier);
    final authState = ref.watch(authNotifierProvider);

    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final currentUserName = currentUser?.displayName ?? currentUser?.username ?? 'User';
    final currentAvatarUrl = currentUser?.avatarUrl;

    final post = state.post ?? widget.initialPost;
    final likeCount = post?.likeCount ?? 0;
    final isLiked = post?.isLiked ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.midnightNavy : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 1. Reactions summary row (matching Screenshot 2)
          InkWell(
            onTap: () => _openReactionsScreen(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  // Stacked reaction icons
                  SizedBox(
                    width: 46,
                    height: 22,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryCrimson,
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryElectricBlue,
                            ),
                            child: const Icon(Icons.thumb_up_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          left: 28,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF7B125),
                            ),
                            child: const Icon(Icons.emoji_emotions_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLiked
                        ? 'You + ${_formatCount((likeCount - 1).clamp(0, 999999))}'
                        : (likeCount > 0 ? '${_formatCount(likeCount)} reactions' : 'Be the first to react'),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
          ),

          // 2. Sort Filter Header (e.g. "Most relevant ⌵")
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: 8,
            ),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  initialValue: _selectedSort,
                  onSelected: (value) => setState(() => _selectedSort = value),
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Most relevant', child: Text('Most relevant')),
                    const PopupMenuItem(value: 'Newest', child: Text('Newest')),
                    const PopupMenuItem(value: 'All comments', child: Text('All comments')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedSort,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Comments List
          Expanded(
            child: state.isLoadingComments && state.comments.isEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    itemCount: 4,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.space16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton.circle(size: 36),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSkeleton(width: 120, height: 14),
                                SizedBox(height: 6),
                                AppSkeleton(width: 200, height: 36),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : state.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No comments yet.',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              'Be the first to share your thoughts!',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.comments.length,
                        itemBuilder: (context, index) {
                          final comment = state.comments[index];
                          return CommentTileWidget(
                            key: ValueKey(comment.id),
                            comment: comment,
                            currentUserId: currentUser?.id,
                            onReply: () {
                              notifier.setReplyingTo(comment);
                              _focusNode.requestFocus();
                            },
                            onToggleReplies: () => notifier.toggleReplies(comment.id),
                            onDelete: () => notifier.deleteComment(comment.id),
                          );
                        },
                      ),
          ),

          // 4. Sticky Bottom Comment Composer
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.space16,
              right: AppSpacing.space16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.midnightNavy : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replying Indicator Banner
                if (state.replyingToComment != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(
                          'Replying to ${state.replyingToComment!.author.displayName ?? state.replyingToComment!.author.username}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => notifier.setReplyingTo(null),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    AppAvatar(
                      name: currentUserName,
                      size: 34,
                      imageUrl: currentAvatarUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _focusNode,
                                maxLines: null,
                                style: AppTypography.body.copyWith(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Comment as $currentUserName',
                                  hintStyle: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            // Camera / Attachment Icon
                            IconButton(
                              icon: const Icon(Icons.camera_alt_outlined, size: 20),
                              color: AppColors.textMuted,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            // Emoji / Sticker Icon
                            IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined, size: 20),
                              color: AppColors.textMuted,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            // Send Button
                            state.isPostingComment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryCrimson,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.send_rounded, size: 20),
                                    color: AppColors.primaryCrimson,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final text = _commentController.text;
                                      if (text.trim().isEmpty) return;
                                      final success = await notifier.postComment(text);
                                      if (success) {
                                        _commentController.clear();
                                      }
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
