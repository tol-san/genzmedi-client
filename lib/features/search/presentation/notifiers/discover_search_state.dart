import 'package:equatable/equatable.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';

class DiscoverSearchState extends Equatable {
  final String query;
  final DiscoverSearchCategory category;
  final List<DiscoverUserModel> users;
  final List<DiscoverCommunityModel> communities;
  final List<PostModel> posts;
  final List<DiscoverInterestModel> interests;
  final int totalResults;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Set<String> pendingUserIds;
  final Set<String> pendingCommunityIds;
  final String? errorMessage;

  const DiscoverSearchState({
    this.query = '',
    this.category = DiscoverSearchCategory.all,
    this.users = const [],
    this.communities = const [],
    this.posts = const [],
    this.interests = const [],
    this.totalResults = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.pendingUserIds = const {},
    this.pendingCommunityIds = const {},
    this.errorMessage,
  });

  bool get isEmpty =>
      users.isEmpty &&
      communities.isEmpty &&
      posts.isEmpty &&
      interests.isEmpty;

  int get activeCount {
    switch (category) {
      case DiscoverSearchCategory.all:
        return totalResults;
      case DiscoverSearchCategory.users:
        return users.length;
      case DiscoverSearchCategory.communities:
        return communities.length;
      case DiscoverSearchCategory.posts:
        return posts.length;
      case DiscoverSearchCategory.interests:
        return interests.length;
    }
  }

  DiscoverSearchState copyWith({
    String? query,
    DiscoverSearchCategory? category,
    List<DiscoverUserModel>? users,
    List<DiscoverCommunityModel>? communities,
    List<PostModel>? posts,
    List<DiscoverInterestModel>? interests,
    int? totalResults,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Set<String>? pendingUserIds,
    Set<String>? pendingCommunityIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoverSearchState(
      query: query ?? this.query,
      category: category ?? this.category,
      users: users ?? this.users,
      communities: communities ?? this.communities,
      posts: posts ?? this.posts,
      interests: interests ?? this.interests,
      totalResults: totalResults ?? this.totalResults,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      pendingUserIds: pendingUserIds ?? this.pendingUserIds,
      pendingCommunityIds: pendingCommunityIds ?? this.pendingCommunityIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    query,
    category,
    users,
    communities,
    posts,
    interests,
    totalResults,
    isLoading,
    isLoadingMore,
    hasMore,
    pendingUserIds,
    pendingCommunityIds,
    errorMessage,
  ];
}
