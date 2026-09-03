import 'package:equatable/equatable.dart';
import 'package:client/core/auth/user_model.dart';

class FollowListState extends Equatable {
  final List<UserModel> followers;
  final List<UserModel> following;
  final Map<String, bool> followingStatusMap;
  final bool isLoadingFollowers;
  final bool isLoadingFollowing;
  final bool isRefreshing;
  final bool hasMoreFollowers;
  final bool hasMoreFollowing;
  final int followersOffset;
  final int followingOffset;
  final String searchQuery;
  final String? errorMessage;

  const FollowListState({
    this.followers = const [],
    this.following = const [],
    this.followingStatusMap = const {},
    this.isLoadingFollowers = false,
    this.isLoadingFollowing = false,
    this.isRefreshing = false,
    this.hasMoreFollowers = true,
    this.hasMoreFollowing = true,
    this.followersOffset = 0,
    this.followingOffset = 0,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<UserModel> get filteredFollowers {
    if (searchQuery.trim().isEmpty) return followers;
    final query = searchQuery.trim().toLowerCase();
    return followers.where((user) {
      final name = (user.displayName ?? '').toLowerCase();
      final username = user.username.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  List<UserModel> get filteredFollowing {
    if (searchQuery.trim().isEmpty) return following;
    final query = searchQuery.trim().toLowerCase();
    return following.where((user) {
      final name = (user.displayName ?? '').toLowerCase();
      final username = user.username.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  FollowListState copyWith({
    List<UserModel>? followers,
    List<UserModel>? following,
    Map<String, bool>? followingStatusMap,
    bool? isLoadingFollowers,
    bool? isLoadingFollowing,
    bool? isRefreshing,
    bool? hasMoreFollowers,
    bool? hasMoreFollowing,
    int? followersOffset,
    int? followingOffset,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FollowListState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      followingStatusMap: followingStatusMap ?? this.followingStatusMap,
      isLoadingFollowers: isLoadingFollowers ?? this.isLoadingFollowers,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMoreFollowers: hasMoreFollowers ?? this.hasMoreFollowers,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      followersOffset: followersOffset ?? this.followersOffset,
      followingOffset: followingOffset ?? this.followingOffset,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    followers,
    following,
    followingStatusMap,
    isLoadingFollowers,
    isLoadingFollowing,
    isRefreshing,
    hasMoreFollowers,
    hasMoreFollowing,
    followersOffset,
    followingOffset,
    searchQuery,
    errorMessage,
  ];
}
