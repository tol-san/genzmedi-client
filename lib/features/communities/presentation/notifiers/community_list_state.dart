import 'package:equatable/equatable.dart';
import 'package:client/features/communities/data/models/community_models.dart';

class CommunityListState extends Equatable {
  final List<CommunityModel> exploreCommunities;
  final List<CommunityModel> joinedCommunities;
  final bool isLoadingExplore;
  final bool isLoadingJoined;
  final bool isRefreshing;
  final String searchQuery;
  final bool?
  privacyFilter; // null = all, false = public only, true = private only
  final String? errorMessage;

  const CommunityListState({
    this.exploreCommunities = const [],
    this.joinedCommunities = const [],
    this.isLoadingExplore = false,
    this.isLoadingJoined = false,
    this.isRefreshing = false,
    this.searchQuery = '',
    this.privacyFilter,
    this.errorMessage,
  });

  CommunityListState copyWith({
    List<CommunityModel>? exploreCommunities,
    List<CommunityModel>? joinedCommunities,
    bool? isLoadingExplore,
    bool? isLoadingJoined,
    bool? isRefreshing,
    String? searchQuery,
    bool? privacyFilter,
    bool clearPrivacyFilter = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityListState(
      exploreCommunities: exploreCommunities ?? this.exploreCommunities,
      joinedCommunities: joinedCommunities ?? this.joinedCommunities,
      isLoadingExplore: isLoadingExplore ?? this.isLoadingExplore,
      isLoadingJoined: isLoadingJoined ?? this.isLoadingJoined,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
      privacyFilter: clearPrivacyFilter
          ? null
          : (privacyFilter ?? this.privacyFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    exploreCommunities,
    joinedCommunities,
    isLoadingExplore,
    isLoadingJoined,
    isRefreshing,
    searchQuery,
    privacyFilter,
    errorMessage,
  ];
}
