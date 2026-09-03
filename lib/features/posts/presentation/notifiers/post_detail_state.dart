import 'package:equatable/equatable.dart';
import 'package:client/features/posts/data/models/comment_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class PostDetailState extends Equatable {
  final PostModel? post;
  final List<CommentModel> comments;
  final bool isLoadingPost;
  final bool isLoadingComments;
  final bool isPostingComment;
  final CommentModel? replyingToComment;
  final bool hasMoreComments;
  final int commentsOffset;
  final String? errorMessage;

  const PostDetailState({
    this.post,
    this.comments = const [],
    this.isLoadingPost = false,
    this.isLoadingComments = false,
    this.isPostingComment = false,
    this.replyingToComment,
    this.hasMoreComments = true,
    this.commentsOffset = 0,
    this.errorMessage,
  });

  PostDetailState copyWith({
    PostModel? post,
    List<CommentModel>? comments,
    bool? isLoadingPost,
    bool? isLoadingComments,
    bool? isPostingComment,
    CommentModel? replyingToComment,
    bool clearReplyingTo = false,
    bool? hasMoreComments,
    int? commentsOffset,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoadingPost: isLoadingPost ?? this.isLoadingPost,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isPostingComment: isPostingComment ?? this.isPostingComment,
      replyingToComment: clearReplyingTo
          ? null
          : (replyingToComment ?? this.replyingToComment),
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      commentsOffset: commentsOffset ?? this.commentsOffset,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    post,
    comments,
    isLoadingPost,
    isLoadingComments,
    isPostingComment,
    replyingToComment,
    hasMoreComments,
    commentsOffset,
    errorMessage,
  ];
}
