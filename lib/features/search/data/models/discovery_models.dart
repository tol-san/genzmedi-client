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

  const DiscoverInterestModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
  });

  factory DiscoverInterestModel.fromJson(Map<String, dynamic> json) {
    return DiscoverInterestModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, description, iconUrl];
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

PostModel postFromSearchJson(Map<String, dynamic> json) {
  return PostModel.fromJson({
    ...json,
    'author': {
      'id': json['author_id']?.toString() ?? '',
      'username': json['author_username'] as String? ?? 'creator',
    },
    'media': json['media'] ?? const [],
  });
}
