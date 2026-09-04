import 'package:equatable/equatable.dart';
import 'package:client/features/search/data/models/discovery_models.dart';

class DiscoverState extends Equatable {
  final List<DiscoverCommunityModel> communities;
  final bool isLoading;
  final bool isRefreshing;
  final Set<String> pendingCommunityIds;
  final String? errorMessage;

  const DiscoverState({
    this.communities = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.pendingCommunityIds = const {},
    this.errorMessage,
  });

  DiscoverState copyWith({
    List<DiscoverCommunityModel>? communities,
    bool? isLoading,
    bool? isRefreshing,
    Set<String>? pendingCommunityIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoverState(
      communities: communities ?? this.communities,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pendingCommunityIds: pendingCommunityIds ?? this.pendingCommunityIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    communities,
    isLoading,
    isRefreshing,
    pendingCommunityIds,
    errorMessage,
  ];
}
