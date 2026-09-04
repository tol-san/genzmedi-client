import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/comment_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/comment_repository.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/notifiers/post_detail_state.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';

final postDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<PostDetailNotifier, PostDetailState, String>((ref, postId) {
      final postRepo = ref.watch(postRepositoryProvider);
      final commentRepo = ref.watch(commentRepositoryProvider);
      return PostDetailNotifier(
        postId: postId,
        postRepository: postRepo,
        commentRepository: commentRepo,
        ref: ref,
      );
    });

class PostDetailNotifier extends StateNotifier<PostDetailState> {
  final String postId;
  final PostRepository postRepository;
  final CommentRepository commentRepository;
  final Ref? ref;
  static const int _pageSize = 20;

  PostDetailNotifier({
    required this.postId,
    required this.postRepository,
    required this.commentRepository,
    this.ref,
  }) : super(
         const PostDetailState(isLoadingPost: true, isLoadingComments: true),
       ) {
    loadPost();
    loadComments();
  }

  Future<void> loadPost() async {
    state = state.copyWith(isLoadingPost: true, clearError: true);
    try {
      final post = await postRepository.getPost(postId);
      state = state.copyWith(post: post, isLoadingPost: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoadingPost: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoadingPost: false,
        errorMessage: 'Failed to load post.',
      );
    }
  }

  Future<void> loadComments() async {
    state = state.copyWith(isLoadingComments: true);
    try {
      final comments = await commentRepository.getComments(
        postId,
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        comments: comments,
        commentsOffset: comments.length,
        hasMoreComments: comments.length >= _pageSize,
        isLoadingComments: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingComments: false);
    }
  }

  Future<void> loadMoreComments() async {
    if (state.isLoadingComments || !state.hasMoreComments) return;
    try {
      final items = await commentRepository.getComments(
        postId,
        limit: _pageSize,
        offset: state.commentsOffset,
      );
      state = state.copyWith(
        comments: [...state.comments, ...items],
        commentsOffset: state.commentsOffset + items.length,
        hasMoreComments: items.length >= _pageSize,
      );
    } catch (_) {}
  }

  Future<void> toggleReplies(String commentId) async {
    final index = state.comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = state.comments[index];
    if (comment.isRepliesExpanded) {
      // Collapse
      final updated = List<CommentModel>.from(state.comments);
      updated[index] = comment.copyWith(isRepliesExpanded: false);
      state = state.copyWith(comments: updated);
      return;
    }

    // Expand & fetch replies
    try {
      final replies = await commentRepository.getReplies(commentId);
      final updated = List<CommentModel>.from(state.comments);
      updated[index] = comment.copyWith(
        replies: replies,
        isRepliesExpanded: true,
      );
      state = state.copyWith(comments: updated);
    } catch (_) {}
  }

  void setReplyingTo(CommentModel? comment) {
    if (comment == null) {
      state = state.copyWith(clearReplyingTo: true);
    } else {
      state = state.copyWith(replyingToComment: comment);
    }
  }

  Future<bool> postComment(String text) async {
    if (text.trim().isEmpty) return false;

    state = state.copyWith(isPostingComment: true, clearError: true);
    try {
      final parentId = state.replyingToComment?.id;
      final newComment = await commentRepository.createComment(
        postId,
        content: text.trim(),
        parentId: parentId,
      );

      if (parentId != null) {
        // Nested reply added
        final parentIndex = state.comments.indexWhere((c) => c.id == parentId);
        if (parentIndex != -1) {
          final parent = state.comments[parentIndex];
          final updatedReplies = [...parent.replies, newComment];
          final updatedComments = List<CommentModel>.from(state.comments);
          updatedComments[parentIndex] = parent.copyWith(
            replies: updatedReplies,
            replyCount: parent.replyCount + 1,
            isRepliesExpanded: true,
          );
          state = state.copyWith(
            comments: updatedComments,
            isPostingComment: false,
            clearReplyingTo: true,
          );
        }
      } else {
        // Top-level comment added
        state = state.copyWith(
          comments: [newComment, ...state.comments],
          isPostingComment: false,
        );
      }

      // Update post comment count
      if (state.post != null) {
        state = state.copyWith(
          post: state.post!.copyWith(
            commentCount: state.post!.commentCount + 1,
          ),
        );
      }

      return true;
    } on AppException catch (e) {
      state = state.copyWith(isPostingComment: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isPostingComment: false,
        errorMessage: 'Failed to post comment.',
      );
      return false;
    }
  }

  Future<void> deleteComment(String commentId, {String? parentId}) async {
    try {
      await commentRepository.deleteComment(commentId);

      if (parentId != null) {
        final parentIndex = state.comments.indexWhere((c) => c.id == parentId);
        if (parentIndex != -1) {
          final parent = state.comments[parentIndex];
          final updatedReplies = parent.replies
              .where((r) => r.id != commentId)
              .toList();
          final updatedComments = List<CommentModel>.from(state.comments);
          updatedComments[parentIndex] = parent.copyWith(
            replies: updatedReplies,
            replyCount: (parent.replyCount - 1).clamp(0, 999999),
          );
          state = state.copyWith(comments: updatedComments);
        }
      } else {
        final updatedComments = state.comments
            .where((c) => c.id != commentId)
            .toList();
        state = state.copyWith(comments: updatedComments);
      }

      if (state.post != null) {
        state = state.copyWith(
          post: state.post!.copyWith(
            commentCount: (state.post!.commentCount - 1).clamp(0, 999999),
          ),
        );
      }
    } catch (_) {}
  }

  /// Update comment content for a top-level comment or nested reply
  Future<bool> updateComment(
    String commentId,
    String newContent, {
    String? parentId,
  }) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) return false;

    try {
      final updatedComment = await commentRepository.updateComment(
        commentId,
        content: trimmed,
      );

      if (parentId != null) {
        final parentIndex = state.comments.indexWhere((c) => c.id == parentId);
        if (parentIndex != -1) {
          final parent = state.comments[parentIndex];
          final replyIndex =
              parent.replies.indexWhere((r) => r.id == commentId);
          if (replyIndex != -1) {
            final updatedReplies = List<CommentModel>.from(parent.replies);
            updatedReplies[replyIndex] = updatedComment;
            final updatedComments = List<CommentModel>.from(state.comments);
            updatedComments[parentIndex] =
                parent.copyWith(replies: updatedReplies);
            state = state.copyWith(comments: updatedComments);
          }
        }
      } else {
        final commentIndex =
            state.comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          final updatedComments = List<CommentModel>.from(state.comments);
          final existing = updatedComments[commentIndex];
          updatedComments[commentIndex] = updatedComment.copyWith(
            replies: existing.replies,
            isRepliesExpanded: existing.isRepliesExpanded,
            replyCount: existing.replyCount,
          );
          state = state.copyWith(comments: updatedComments);
        }
      }
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to update comment.');
      return false;
    }
  }

  Future<void> toggleLike() async {
    if (state.post == null) return;
    final post = state.post!;
    final wasLiked = post.isLiked;
    final targetLiked = !wasLiked;
    final newCount = (post.likeCount + (targetLiked ? 1 : -1)).clamp(0, 999999);

    state = state.copyWith(
      post: post.copyWith(isLiked: targetLiked, likeCount: newCount),
    );

    try {
      if (targetLiked) {
        await postRepository.likePost(postId);
      } else {
        await postRepository.unlikePost(postId);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(post: post);
      }
    }
  }

  Future<void> toggleSave() async {
    if (state.post == null) return;
    final post = state.post!;
    final wasSaved = post.isSaved;
    final targetSaved = !wasSaved;
    final newCount = (post.saveCount + (targetSaved ? 1 : -1)).clamp(0, 999999);

    state = state.copyWith(
      post: post.copyWith(isSaved: targetSaved, saveCount: newCount),
    );

    try {
      if (targetSaved) {
        await postRepository.savePost(postId);
      } else {
        await postRepository.unsavePost(postId);
        if (ref?.exists(myProfileNotifierProvider) == true) {
          ref?.read(myProfileNotifierProvider.notifier).removeSavedPost(postId);
        }
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(post: post);
      }
    }
  }

  Future<String?> sharePost() async {
    if (state.post == null) return null;
    final post = state.post!;
    state = state.copyWith(
      post: post.copyWith(shareCount: post.shareCount + 1),
    );
    try {
      return await postRepository.sharePost(postId);
    } catch (_) {
      return 'https://genzmedia.app/posts/$postId';
    }
  }

  /// Update the current post when edited
  void updatePost(PostModel updatedPost) {
    state = state.copyWith(post: updatedPost);
  }

  /// Delete the current post
  Future<bool> deletePost() async {
    try {
      await postRepository.deletePost(postId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
