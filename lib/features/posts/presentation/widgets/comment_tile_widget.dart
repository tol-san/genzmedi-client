import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/data/models/comment_model.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/presentation/widgets/report_sheet.dart';

class CommentTileWidget extends StatefulWidget {
  final CommentModel comment;
  final String? currentUserId;
  final bool isSuperuser;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onToggleReplies;
  final VoidCallback? onDelete;
  final Future<bool> Function(String newContent)? onEdit;
  final Future<bool> Function(String replyId, String newContent)? onEditReply;
  final void Function(String replyId)? onDeleteReply;

  const CommentTileWidget({
    super.key,
    required this.comment,
    this.currentUserId,
    this.isSuperuser = false,
    this.isReply = false,
    this.onReply,
    this.onToggleReplies,
    this.onDelete,
    this.onEdit,
    this.onEditReply,
    this.onDeleteReply,
  });

  @override
  State<CommentTileWidget> createState() => _CommentTileWidgetState();
}

class _CommentTileWidgetState extends State<CommentTileWidget> {
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void didUpdateWidget(covariant CommentTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.content != widget.comment.content && !_isEditing) {
      _editController.text = widget.comment.content;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _editController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Comment cannot be empty.');
      return;
    }
    if (text.length > 1000) {
      setState(() => _errorMessage = 'Comment cannot exceed 1,000 characters.');
      return;
    }
    if (text == widget.comment.content.trim()) {
      setState(() {
        _isEditing = false;
        _errorMessage = null;
      });
      return;
    }

    if (widget.onEdit == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await widget.onEdit!(text);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to update comment. Please try again.';
      });
    }
  }

  void _handleCancel() {
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _errorMessage = null;
      _editController.text = widget.comment.content;
    });
  }

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
    final isAuthor =
        widget.currentUserId != null &&
        widget.comment.author.id == widget.currentUserId;
    final canEditOrDelete = isAuthor || widget.isSuperuser;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 40.0 : AppSpacing.space16,
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
                    pathParameters: {'username': widget.comment.author.username},
                  );
                },
                child: AppAvatar(
                  name:
                      widget.comment.author.displayName ??
                      widget.comment.author.username,
                  size: widget.isReply ? 28 : 34,
                  imageUrl: widget.comment.author.avatarUrl,
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
                                pathParameters: {
                                  'username': widget.comment.author.username,
                                },
                              );
                            },
                            child: Text(
                              widget.comment.author.displayName ??
                                  widget.comment.author.username,
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: widget.isReply ? 13 : 14,
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
                          '· ${_formatTimeAgo(widget.comment.createdAt)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (widget.comment.isEdited) ...[
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
                        PopupMenuButton<String>(
                          tooltip: 'Comment options',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz_rounded, size: 16),
                          onSelected: (value) {
                            if (value == 'edit') {
                              setState(() {
                                _isEditing = true;
                                _errorMessage = null;
                                _editController.text = widget.comment.content;
                              });
                            } else if (value == 'delete') {
                              widget.onDelete?.call();
                            } else if (value == 'report') {
                              ReportSheet.show(
                                context,
                                targetType: ReportTargetType.comment,
                                targetId: widget.comment.id,
                                targetLabel:
                                    'comment by @${widget.comment.author.username}',
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            if (canEditOrDelete && widget.onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Edit comment'),
                                  ],
                                ),
                              ),
                            if (canEditOrDelete && widget.onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Delete comment',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            if (!canEditOrDelete)
                              const PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_outlined,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Report comment'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Inline Editor or Static Comment Text
                    if (_isEditing) ...[
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurfaceElevated,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(
                            color: _errorMessage != null
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.navyBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _editController,
                              maxLines: null,
                              maxLength: 1000,
                              enabled: !_isSaving,
                              style: AppTypography.body.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Edit your comment...',
                                hintStyle: AppTypography.body.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                counterText: '',
                              ),
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _editController,
                                  builder: (context, value, _) {
                                    final len = value.text.length;
                                    return Text(
                                      '$len/1000',
                                      style: AppTypography.caption.copyWith(
                                        color: len > 1000
                                            ? AppColors.error
                                            : AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed:
                                          _isSaving ? null : _handleCancel,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: AppTypography.label.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _isSaving ? null : _handleSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryCrimson,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Save',
                                              style:
                                                  AppTypography.label.copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 12,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.error,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ] else ...[
                      Text(
                        widget.comment.content,
                        style: AppTypography.body.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Action Row: Reply on Left, Like on Right
                      Row(
                        children: [
                          if (widget.onReply != null)
                            GestureDetector(
                              onTap: widget.onReply,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: 16,
                                  top: 2,
                                  bottom: 2,
                                ),
                                child: Text(
                                  'Reply',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite_border_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.textSecondaryLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Replies Toggle & Expanded Sub-Replies
          if (!widget.isReply && widget.comment.replyCount > 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: GestureDetector(
                onTap: widget.onToggleReplies,
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
                      widget.comment.isRepliesExpanded
                          ? 'Hide replies'
                          : 'View ${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.comment.isRepliesExpanded &&
                widget.comment.replies.isNotEmpty)
              ...widget.comment.replies.map(
                (reply) => CommentTileWidget(
                  key: ValueKey(reply.id),
                  comment: reply,
                  currentUserId: widget.currentUserId,
                  isSuperuser: widget.isSuperuser,
                  isReply: true,
                  onDelete: () => (widget.onDeleteReply != null)
                      ? widget.onDeleteReply!(reply.id)
                      : widget.onDelete?.call(),
                  onEdit: (newContent) => widget.onEditReply != null
                      ? widget.onEditReply!(reply.id, newContent)
                      : (widget.onEdit != null
                          ? widget.onEdit!(newContent)
                          : Future.value(false)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
