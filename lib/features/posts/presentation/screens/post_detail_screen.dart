import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/features/posts/presentation/notifiers/post_detail_notifier.dart';
import 'package:client/features/posts/presentation/widgets/comment_input_bar.dart';
import 'package:client/features/posts/presentation/widgets/comment_tile_widget.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(postDetailNotifierProvider(widget.postId).notifier)
          .loadMoreComments();
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleShare() async {
    final notifier = ref.read(
      postDetailNotifierProvider(widget.postId).notifier,
    );
    final shareUrl = await notifier.sharePost();
    final urlToCopy =
        shareUrl ?? 'https://genzmedia.app/posts/${widget.postId}';
    await Clipboard.setData(ClipboardData(text: urlToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post link copied: $urlToCopy'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(postDetailNotifierProvider(widget.postId));
    final notifier = ref.read(
      postDetailNotifierProvider(widget.postId).notifier,
    );
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    final post = state.post;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _handleShare,
          ),
          const SizedBox(width: AppSpacing.space8),
        ],
      ),
      body: state.isLoadingPost && post == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCrimson),
            )
          : post == null
          ? Center(
              child: Text(
                state.errorMessage ?? 'Post not found',
                style: AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryCrimson,
                    onRefresh: () async {
                      await notifier.loadPost();
                      await notifier.loadComments();
                    },
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // 1. Author Row
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.space16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    RouteNames.publicProfile,
                                    pathParameters: {
                                      'username': post.author.username,
                                    },
                                  );
                                },
                                child: AppAvatar(
                                  name:
                                      post.author.displayName ??
                                      post.author.username,
                                  size: 44,
                                  imageUrl: post.author.avatarUrl,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.author.displayName ??
                                          post.author.username,
                                      style: AppTypography.title.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      '@${post.author.username} · ${_formatTimeAgo(post.createdAt)}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Post Content (Description)
                        if (post.content != null && post.content!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space16,
                              vertical: AppSpacing.space8,
                            ),
                            child: Text(
                              post.content!,
                              style: AppTypography.body.copyWith(
                                fontSize: 16,
                                height: 1.5,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),

                        // 3. Media Carousel
                        if (post.media.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space8),
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              children: [
                                PageView.builder(
                                  itemCount: post.media.length,
                                  onPageChanged: (idx) {
                                    setState(() => _currentImageIndex = idx);
                                  },
                                  itemBuilder: (context, idx) {
                                    final media = post.media[idx];
                                    return CachedNetworkImage(
                                      imageUrl: media.url,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(
                                        color: isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.lightSurfaceElevated,
                                      ),
                                      errorWidget: (c, u, e) => Container(
                                        color: isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.lightSurfaceElevated,
                                        child: const Icon(
                                          Icons.broken_image_rounded,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (post.media.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        post.media.length,
                                        (idx) => Container(
                                          width: _currentImageIndex == idx
                                              ? 16
                                              : 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _currentImageIndex == idx
                                                ? AppColors.primaryCrimson
                                                : Colors.white.withValues(
                                                    alpha: 0.6,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // 4. Engagement Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space16,
                            vertical: AppSpacing.space12,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  post.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: post.isLiked
                                      ? AppColors.primaryCrimson
                                      : AppColors.textMuted,
                                ),
                                onPressed: notifier.toggleLike,
                              ),
                              Text(
                                '${post.likeCount}',
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: post.isLiked
                                      ? AppColors.primaryCrimson
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space16),
                              IconButton(
                                icon: Icon(
                                  post.isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: post.isSaved
                                      ? AppColors.signalMint
                                      : AppColors.textMuted,
                                ),
                                onPressed: notifier.toggleSave,
                              ),
                              Text(
                                '${post.saveCount}',
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: post.isSaved
                                      ? AppColors.signalMint
                                      : AppColors.textMuted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${post.commentCount} comments',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: isDark
                              ? AppColors.navyBorder
                              : AppColors.lightBorder,
                          height: 1,
                        ),

                        // 5. Comments Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space16,
                            AppSpacing.space16,
                            AppSpacing.space16,
                            AppSpacing.space8,
                          ),
                          child: Text(
                            'Discussion (${post.commentCount})',
                            style: AppTypography.title.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),

                        if (state.isLoadingComments && state.comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.space24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryCrimson,
                              ),
                            ),
                          )
                        else if (state.comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.space32,
                              horizontal: AppSpacing.space16,
                            ),
                            child: Center(
                              child: Text(
                                'No comments yet. Be the first to share your thoughts!',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          ...state.comments.map(
                            (comment) => CommentTileWidget(
                              key: ValueKey(comment.id),
                              comment: comment,
                              currentUserId: currentUserId,
                              onReply: () => notifier.setReplyingTo(comment),
                              onToggleReplies: () =>
                                  notifier.toggleReplies(comment.id),
                              onDelete: () =>
                                  notifier.deleteComment(comment.id),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.space24),
                      ],
                    ),
                  ),
                ),

                // Sticky Comment Composer
                CommentInputBar(
                  replyingTo: state.replyingToComment,
                  isPosting: state.isPostingComment,
                  onCancelReply: () => notifier.setReplyingTo(null),
                  onSubmit: (text) => notifier.postComment(text),
                ),
              ],
            ),
    );
  }
}
