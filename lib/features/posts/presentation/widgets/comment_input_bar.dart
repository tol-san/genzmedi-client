import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/features/posts/data/models/comment_model.dart';

class CommentInputBar extends StatefulWidget {
  final CommentModel? replyingTo;
  final bool isPosting;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onCancelReply;

  const CommentInputBar({
    super.key,
    this.replyingTo,
    this.isPosting = false,
    required this.onSubmit,
    this.onCancelReply,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingTo != null &&
        oldWidget.replyingTo != widget.replyingTo) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isPosting) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.space16,
        right: AppSpacing.space16,
        top: AppSpacing.space8,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Replying banner
          if (widget.replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    size: 16,
                    color: AppColors.primaryCrimson,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to @${widget.replyingTo!.author.username}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryCrimson,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancelReply,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          // Input field row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.replyingTo != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: 10.0,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: AppSpacing.roundedFull,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              widget.isPosting
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryCrimson,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.primaryCrimson,
                      onPressed: _submit,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
