import 'package:equatable/equatable.dart';

class CommentAuthorModel extends Equatable {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const CommentAuthorModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory CommentAuthorModel.fromJson(Map<String, dynamic> json) {
    return CommentAuthorModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'avatar_url': avatarUrl,
  };

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl];
}

class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String? parentId;
  final CommentAuthorModel author;
  final String content;
  final int likeCount;
  final int replyCount;
  final bool isEdited;
  final DateTime? createdAt;
  final List<CommentModel> replies;
  final bool isRepliesExpanded;

  const CommentModel({
    required this.id,
    required this.postId,
    this.parentId,
    required this.author,
    required this.content,
    this.likeCount = 0,
    this.replyCount = 0,
    this.isEdited = false,
    this.createdAt,
    this.replies = const [],
    this.isRepliesExpanded = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      author: CommentAuthorModel.fromJson(authorJson),
      content: json['content'] as String? ?? '',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'parent_id': parentId,
    'author': author.toJson(),
    'content': content,
    'like_count': likeCount,
    'reply_count': replyCount,
    'is_edited': isEdited,
    'created_at': createdAt?.toIso8601String(),
  };

  CommentModel copyWith({
    String? id,
    String? postId,
    String? parentId,
    CommentAuthorModel? author,
    String? content,
    int? likeCount,
    int? replyCount,
    bool? isEdited,
    DateTime? createdAt,
    List<CommentModel>? replies,
    bool? isRepliesExpanded,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      author: author ?? this.author,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      isRepliesExpanded: isRepliesExpanded ?? this.isRepliesExpanded,
    );
  }

  @override
  List<Object?> get props => [
    id,
    postId,
    parentId,
    author,
    content,
    likeCount,
    replyCount,
    isEdited,
    createdAt,
    replies,
    isRepliesExpanded,
  ];
}
