import 'package:equatable/equatable.dart';

/// Post author representation for feeds and profile posts
class PostAuthorModel extends Equatable {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const PostAuthorModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory PostAuthorModel.fromJson(Map<String, dynamic> json) {
    return PostAuthorModel(
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

/// Media item attached to a post (image carousel or video)
class MediaItemModel extends Equatable {
  final String id;
  final String mediaType;
  final String url;
  final String? thumbnailUrl;
  final double? duration;
  final int? width;
  final int? height;
  final int order;

  const MediaItemModel({
    required this.id,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.width,
    this.height,
    this.order = 0,
  });

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      id: json['id']?.toString() ?? '',
      mediaType: json['media_type'] as String? ?? 'image',
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'media_type': mediaType,
    'url': url,
    'thumbnail_url': thumbnailUrl,
    'duration': duration,
    'width': width,
    'height': height,
    'order': order,
  };

  @override
  List<Object?> get props => [
    id,
    mediaType,
    url,
    thumbnailUrl,
    duration,
    width,
    height,
    order,
  ];
}

/// Core Post model for personal profile, feeds, and community feeds
class PostModel extends Equatable {
  final String id;
  final PostAuthorModel author;
  final String postType;
  final String? title;
  final String? content;
  final String visibility;
  final String? communityId;
  final String? communityName;
  final List<MediaItemModel> media;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int saveCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime? createdAt;

  const PostModel({
    required this.id,
    required this.author,
    this.postType = 'text',
    this.title,
    this.content,
    this.visibility = 'public',
    this.communityId,
    this.communityName,
    this.media = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.createdAt,
  });

  bool get isTextOnly => postType == 'text' || media.isEmpty;
  bool get isVideo => postType == 'video' || media.any((m) => m.isVideo);
  bool get isImage => postType == 'image' || media.any((m) => m.isImage);

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>? ?? {};
    final mediaList =
        (json['media'] as List<dynamic>?)
            ?.map((e) => MediaItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final communityJson = json['community'] as Map<String, dynamic>?;
    final commId =
        json['community_id']?.toString() ?? communityJson?['id']?.toString();
    final commName =
        json['community_name'] as String? ?? communityJson?['name'] as String?;

    return PostModel(
      id: json['id']?.toString() ?? '',
      author: PostAuthorModel.fromJson(authorJson),
      postType: json['post_type'] as String? ?? 'text',
      title: json['title'] as String?,
      content: json['content'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      communityId: commId,
      communityName: commName,
      media: mediaList,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author.toJson(),
    'post_type': postType,
    'title': title,
    'content': content,
    'visibility': visibility,
    if (communityId != null) 'community_id': communityId,
    if (communityName != null) 'community_name': communityName,
    'media': media.map((e) => e.toJson()).toList(),
    'like_count': likeCount,
    'comment_count': commentCount,
    'share_count': shareCount,
    'save_count': saveCount,
    'is_liked': isLiked,
    'is_saved': isSaved,
    'created_at': createdAt?.toIso8601String(),
  };

  PostModel copyWith({
    String? id,
    PostAuthorModel? author,
    String? postType,
    String? title,
    String? content,
    String? visibility,
    String? communityId,
    String? communityName,
    List<MediaItemModel>? media,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? saveCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      author: author ?? this.author,
      postType: postType ?? this.postType,
      title: title ?? this.title,
      content: content ?? this.content,
      visibility: visibility ?? this.visibility,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      media: media ?? this.media,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      saveCount: saveCount ?? this.saveCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    author,
    postType,
    title,
    content,
    visibility,
    communityId,
    communityName,
    media,
    likeCount,
    commentCount,
    shareCount,
    saveCount,
    isLiked,
    isSaved,
    createdAt,
  ];
}

/// Response returned from POST /posts/media
class MediaUploadModel extends Equatable {
  final String url;
  final String mediaType;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final double? duration;

  const MediaUploadModel({
    required this.url,
    required this.mediaType,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.duration,
  });

  factory MediaUploadModel.fromJson(Map<String, dynamic> json) {
    return MediaUploadModel(
      url: json['url'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? 'image',
      thumbnailUrl: json['thumbnail_url'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'media_type': mediaType,
    'thumbnail_url': thumbnailUrl,
    'width': width,
    'height': height,
    'duration': duration,
  };

  @override
  List<Object?> get props => [
    url,
    mediaType,
    thumbnailUrl,
    width,
    height,
    duration,
  ];
}

/// Request payload for POST /posts
class PostCreateRequestModel {
  final String postType;
  final String? title;
  final String? content;
  final String visibility;
  final String? communityId;
  final List<MediaItemModel> media;

  const PostCreateRequestModel({
    this.postType = 'text',
    this.title,
    this.content,
    this.visibility = 'public',
    this.communityId,
    this.media = const [],
  });

  Map<String, dynamic> toJson() => {
    'post_type': postType,
    if (title != null && title!.isNotEmpty) 'title': title,
    if (content != null && content!.isNotEmpty) 'content': content,
    'visibility': visibility,
    if (communityId != null && communityId!.isNotEmpty)
      'community_id': communityId,
    if (media.isNotEmpty)
      'media': media
          .map(
            (m) => {
              'media_type': m.mediaType,
              'url': m.url,
              if (m.thumbnailUrl != null) 'thumbnail_url': m.thumbnailUrl,
              if (m.duration != null) 'duration': m.duration,
              if (m.width != null) 'width': m.width,
              if (m.height != null) 'height': m.height,
              'order': m.order,
            },
          )
          .toList(),
  };
}
