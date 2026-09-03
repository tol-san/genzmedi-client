import 'package:equatable/equatable.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';

enum DiscoverSearchCategory { all, users, communities, posts, interests }

extension DiscoverSearchCategoryX on DiscoverSearchCategory {
  String get apiValue => name;

  String get label {
    switch (this) {
      case DiscoverSearchCategory.all:
        return 'All';
      case DiscoverSearchCategory.users:
        return 'Creators';
      case DiscoverSearchCategory.communities:
        return 'Communities';
      case DiscoverSearchCategory.posts:
        return 'Posts';
      case DiscoverSearchCategory.interests:
        return 'Interests';
    }
  }
}

class DiscoverUserModel extends Equatable {
  final UserModel user;
  final bool isFollowing;
  final int mutualInterestCount;
  final List<String> sharedInterests;

  const DiscoverUserModel({
    required this.user,
    this.isFollowing = false,
    this.mutualInterestCount = 0,
    this.sharedInterests = const [],
  });

  factory DiscoverUserModel.fromJson(Map<String, dynamic> json) {
    return DiscoverUserModel(
      user: UserModel.fromJson({...json, 'email': json['email'] ?? ''}),
      isFollowing: json['is_following'] as bool? ?? false,
      mutualInterestCount:
          (json['mutual_interest_count'] as num?)?.toInt() ?? 0,
      sharedInterests: (json['shared_interests'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  DiscoverUserModel copyWith({bool? isFollowing}) {
    return DiscoverUserModel(
      user: user,
      isFollowing: isFollowing ?? this.isFollowing,
      mutualInterestCount: mutualInterestCount,
      sharedInterests: sharedInterests,
    );
  }

  @override
  List<Object?> get props => [
    user,
    isFollowing,
    mutualInterestCount,
    sharedInterests,
  ];
}

class DiscoverCommunityModel extends Equatable {
  final CommunityModel community;
  final bool isJoined;
  final bool isJoinPending;
  final bool isMatchedInterest;
  final String? interestName;

  const DiscoverCommunityModel({
    required this.community,
    this.isJoined = false,
    this.isJoinPending = false,
    this.isMatchedInterest = false,
    this.interestName,
  });

  factory DiscoverCommunityModel.fromJson(Map<String, dynamic> json) {
    return DiscoverCommunityModel(
      community: CommunityModel.fromJson({
        ...json,
        'owner_id': json['owner_id'] ?? '',
      }),
      isJoined:
          json['is_member'] as bool? ?? json['is_joined'] as bool? ?? false,
      isJoinPending: json['join_request_status'] == 'pending',
      isMatchedInterest: json['is_matched_interest'] as bool? ?? false,
      interestName: json['interest_name'] as String?,
    );
  }

  DiscoverCommunityModel copyWith({bool? isJoined, bool? isJoinPending}) {
    return DiscoverCommunityModel(
      community: community,
      isJoined: isJoined ?? this.isJoined,
      isJoinPending: isJoinPending ?? this.isJoinPending,
      isMatchedInterest: isMatchedInterest,
      interestName: interestName,
    );
  }

  @override
  List<Object?> get props => [
    community,
    isJoined,
    isJoinPending,
    isMatchedInterest,
    interestName,
  ];
}

class DiscoverInterestModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final bool isAdded;

  const DiscoverInterestModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.isAdded = false,
  });

  factory DiscoverInterestModel.fromJson(Map<String, dynamic> json) {
    return DiscoverInterestModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      isAdded: json['is_added'] as bool? ?? false,
    );
  }

  DiscoverInterestModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? iconUrl,
    bool? isAdded,
  }) {
    return DiscoverInterestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      isAdded: isAdded ?? this.isAdded,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, description, iconUrl, isAdded];
}

class DiscoveryPage<T> {
  final List<T> items;
  final int total;
  final int limit;
  final int offset;

  const DiscoveryPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  bool get hasMore => offset + items.length < total;
}

class UnifiedDiscoverySearch {
  final String query;
  final List<DiscoverUserModel> users;
  final List<DiscoverCommunityModel> communities;
  final List<PostModel> posts;
  final List<DiscoverInterestModel> interests;
  final int totalResults;

  const UnifiedDiscoverySearch({
    required this.query,
    this.users = const [],
    this.communities = const [],
    this.posts = const [],
    this.interests = const [],
    this.totalResults = 0,
  });
}

/// Wraps a [PostModel] with search-specific enrichment fields returned by
/// the Meilisearch-backed search endpoint (not available on the regular post API).
class SearchPostResult extends Equatable {
  final PostModel post;

  /// Pre-signed thumbnail URL from the Meilisearch index (first media item).
  /// Only non-null for image/video posts. Prefer this over constructing a URL
  /// from the post media list, since search results may not include full media.
  final String? thumbnailUrl;

  /// Highlighted snippet dict from Meilisearch `_formatted` field.
  /// Keys are field names (e.g. `"title"`, `"content"`), values are HTML
  /// strings with `<em>` tags wrapping matched tokens.
  final Map<String, dynamic>? highlight;

  const SearchPostResult({
    required this.post,
    this.thumbnailUrl,
    this.highlight,
  });

  factory SearchPostResult.fromJson(Map<String, dynamic> json) {
    return SearchPostResult(
      post: postFromSearchJson(json),
      thumbnailUrl: json['thumbnail_url'] as String?,
      highlight: json['highlight'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [post, thumbnailUrl, highlight];
}

PostModel postFromSearchJson(Map<String, dynamic> json) {
  final commId = json['community_id']?.toString();
  final commName = json['community_name'] as String?;
  final thumbnailUrl = json['thumbnail_url'] as String?;

  // When the search result carries a thumbnail_url but no full media array,
  // inject a synthetic media entry so the card widget shows the thumbnail.
  final existingMedia = json['media'] as List<dynamic>?;
  final List<dynamic> media;
  if ((existingMedia == null || existingMedia.isEmpty) &&
      thumbnailUrl != null &&
      thumbnailUrl.trim().isNotEmpty) {
    final postType = json['post_type'] as String? ?? 'image';
    media = [
      {
        'id': '${json['id']}_thumb',
        'media_type': postType == 'video' ? 'video' : 'image',
        'url': thumbnailUrl,
        'thumbnail_url': thumbnailUrl,
        'order': 0,
      }
    ];
  } else {
    media = existingMedia ?? const [];
  }

  return PostModel.fromJson({
    ...json,
    'author': {
      'id': json['author_id']?.toString() ?? '',
      'username': json['author_username'] as String? ?? 'creator',
      // Thread through author_avatar_url from the enriched search schema
      'avatar_url': json['author_avatar_url'] as String?,
    },
    'community_id': commId,
    'community_name': commName,
    'media': media,
  });
}
