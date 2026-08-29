import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/comment_model.dart';

class CommentTileWidget extends StatelessWidget {
  final CommentModel comment;
  final String? currentUserId;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onToggleReplies;
  final VoidCallback? onDelete;

  const CommentTileWidget({
    super.key,
    required this.comment,
    this.currentUserId,
    this.isReply = false,
    this.onReply,
    this.onToggleReplies,
    this.onDelete,
  });

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthor = currentUserId != null && comment.author.id == currentUserId;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 40.0 : AppSpacing.space16,
        right: AppSpacing.space16,
        top: AppSpacing.space8,
        bottom: AppSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  context.pushNamed(
                    RouteNames.publicProfile,
                    pathParameters: {'username': comment.author.username},
                  );
                },
                child: AppAvatar(
                  name: comment.author.displayName ?? comment.author.username,
                  size: isReply ? 28 : 34,
                  imageUrl: comment.author.avatarUrl,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),

              // Comment Body & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              context.pushNamed(
                                RouteNames.publicProfile,
                                pathParameters: {'username': comment.author.username},
                              );
                            },
                            child: Text(
                              comment.author.displayName ?? comment.author.username,
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isReply ? 12 : 13,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '@${comment.author.username} · ${_formatTimeAgo(comment.createdAt)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (isAuthor && onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            color: AppColors.textMuted,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.content,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Reply Action
                    if (!isReply && onReply != null)
                      GestureDetector(
                        onTap: onReply,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Reply',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryCrimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Replies Toggle & Expanded Sub-Replies
          if (!isReply && comment.replyCount > 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: GestureDetector(
                onTap: onToggleReplies,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.isRepliesExpanded
                          ? 'Hide replies'
                          : 'View ${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (comment.isRepliesExpanded && comment.replies.isNotEmpty)
              ...comment.replies.map(
                (reply) => CommentTileWidget(
                  key: ValueKey(reply.id),
                  comment: reply,
                  currentUserId: currentUserId,
                  isReply: true,
                  onDelete: () => onDelete?.call(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
