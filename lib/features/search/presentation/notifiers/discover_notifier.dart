import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/notifiers/discover_state.dart';

final discoverNotifierProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
      return DiscoverNotifier(
        repository: ref.watch(discoveryRepositoryProvider),
      );
    });

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final DiscoveryRepository repository;

  DiscoverNotifier({required this.repository})
    : super(const DiscoverState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _loadCommunities();
      state = state.copyWith(
        communities: data.$1,
        interests: data.$2,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not load communities.'),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final data = await _loadCommunities();
      state = state.copyWith(
        communities: data.$1,
        interests: data.$2,
        isRefreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _message(error, 'Could not refresh communities.'),
      );
    }
  }

  Future<(List<DiscoverCommunityModel>, List<DiscoverInterestModel>)>
  _loadCommunities() async {
    final results = await Future.wait<Object>([
      repository.getRecommendedCommunities(limit: 20),
      repository.getJoinedCommunities(limit: 20),
      repository.getInterests(),
    ]);
    final recommended =
        (results[0] as DiscoveryPage<DiscoverCommunityModel>).items;
    final joined = (results[1] as DiscoveryPage<DiscoverCommunityModel>).items;
    final interests = results[2] as List<DiscoverInterestModel>;
    final interestNames = {for (final item in interests) item.id: item.name};
    final merged = <String, DiscoverCommunityModel>{};

    for (final item in [...recommended, ...joined]) {
      merged[item.community.id] = DiscoverCommunityModel(
        community: item.community,
        isJoined: item.isJoined,
        isJoinPending: item.isJoinPending,
        isMatchedInterest: item.isMatchedInterest,
        interestName:
            item.interestName ?? interestNames[item.community.interestId],
      );
    }

    return (merged.values.toList(), interests);
  }

  Future<void> toggleCommunity(String communityId) async {
    final index = state.communities.indexWhere(
      (item) => item.community.id == communityId,
    );
    if (index < 0 || state.pendingCommunityIds.contains(communityId)) return;
    final original = state.communities[index];
    final targetJoined = !original.isJoined;
    final communities = [...state.communities]
      ..[index] = original.copyWith(
        isJoined: targetJoined,
        isJoinPending: false,
      );
    state = state.copyWith(
      communities: communities,
      pendingCommunityIds: {...state.pendingCommunityIds, communityId},
    );
    try {
      var joinPending = false;
      if (targetJoined) {
        joinPending = await repository.joinCommunity(communityId);
      } else {
        await repository.leaveCommunity(communityId);
      }
      final updated = [...state.communities]
        ..[index] = original.copyWith(
          isJoined: targetJoined && !joinPending,
          isJoinPending: joinPending,
        );
      state = state.copyWith(
        communities: updated,
        pendingCommunityIds: {...state.pendingCommunityIds}
          ..remove(communityId),
      );
    } catch (error) {
      final reverted = [...state.communities]..[index] = original;
      state = state.copyWith(
        communities: reverted,
        pendingCommunityIds: {...state.pendingCommunityIds}
          ..remove(communityId),
        errorMessage: _message(error, 'Could not update membership.'),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _message(Object error, String fallback) {
    return error is AppException ? error.message : fallback;
  }
}
