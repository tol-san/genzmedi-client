import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/community_list_state.dart';

final communityListNotifierProvider =
    StateNotifierProvider<CommunityListNotifier, CommunityListState>((ref) {
      final repository = ref.watch(communityRepositoryProvider);
      return CommunityListNotifier(repository: repository);
    });

class CommunityListNotifier extends StateNotifier<CommunityListState> {
  final CommunityRepository repository;

  CommunityListNotifier({required this.repository})
    : super(
        const CommunityListState(isLoadingExplore: true, isLoadingJoined: true),
      ) {
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([fetchExploreCommunities(), fetchJoinedCommunities()]);
  }

  Future<void> fetchExploreCommunities() async {
    state = state.copyWith(isLoadingExplore: true, clearError: true);
    try {
      final items = await repository.listCommunities(
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        isPrivate: state.privacyFilter,
      );
      state = state.copyWith(
        exploreCommunities: items,
        isLoadingExplore: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoadingExplore: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoadingExplore: false,
        errorMessage: 'Failed to load communities.',
      );
    }
  }

  Future<void> fetchJoinedCommunities() async {
    state = state.copyWith(isLoadingJoined: true);
    try {
      final items = await repository.getMyJoinedCommunities();
      state = state.copyWith(joinedCommunities: items, isLoadingJoined: false);
    } catch (_) {
      state = state.copyWith(isLoadingJoined: false);
    }
  }

  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    await fetchExploreCommunities();
  }

  Future<void> setPrivacyFilter(bool? isPrivate) async {
    if (isPrivate == null) {
      state = state.copyWith(clearPrivacyFilter: true);
    } else {
      state = state.copyWith(privacyFilter: isPrivate);
    }
    await fetchExploreCommunities();
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    await loadAll();
    state = state.copyWith(isRefreshing: false);
  }
}
