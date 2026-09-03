import 'package:equatable/equatable.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';

class DiscoverState extends Equatable {
  final List<PostModel> posts;
  final List<DiscoverUserModel> users;
  final List<DiscoverCommunityModel> communities;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMorePosts;
  final Set<String> pendingUserIds;
  final Set<String> pendingCommunityIds;
  final String? errorMessage;

  const DiscoverState({
    this.posts = const [],
    this.users = const [],
    this.communities = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMorePosts = true,
    this.pendingUserIds = const {},
    this.pendingCommunityIds = const {},
    this.errorMessage,
  });

  DiscoverState copyWith({
    List<PostModel>? posts,
    List<DiscoverUserModel>? users,
    List<DiscoverCommunityModel>? communities,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMorePosts,
    Set<String>? pendingUserIds,
    Set<String>? pendingCommunityIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoverState(
      posts: posts ?? this.posts,
      users: users ?? this.users,
      communities: communities ?? this.communities,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      pendingUserIds: pendingUserIds ?? this.pendingUserIds,
      pendingCommunityIds: pendingCommunityIds ?? this.pendingCommunityIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    posts,
    users,
    communities,
    isLoading,
    isRefreshing,
    isLoadingMore,
    hasMorePosts,
    pendingUserIds,
    pendingCommunityIds,
    errorMessage,
  ];
}
