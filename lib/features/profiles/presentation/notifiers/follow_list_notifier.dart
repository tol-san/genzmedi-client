import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/follow_list_state.dart';

final followListNotifierProvider = StateNotifierProvider.autoDispose
    .family<FollowListNotifier, FollowListState, String>((ref, userId) {
      final repository = ref.watch(profileRepositoryProvider);
      return FollowListNotifier(userId: userId, repository: repository);
    });

class FollowListNotifier extends StateNotifier<FollowListState> {
  final String userId;
  final ProfileRepository repository;
  static const int _pageSize = 20;

  FollowListNotifier({required this.userId, required this.repository})
    : super(
        const FollowListState(
          isLoadingFollowers: true,
          isLoadingFollowing: true,
        ),
      ) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(
      isLoadingFollowers: true,
      isLoadingFollowing: true,
      clearError: true,
    );

    await Future.wait([
      loadFollowers(refresh: true),
      loadFollowing(refresh: true),
    ]);
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    await Future.wait([
      loadFollowers(refresh: true),
      loadFollowing(refresh: true),
    ]);
    state = state.copyWith(isRefreshing: false);
  }

  Future<void> loadFollowers({bool refresh = false}) async {
    final offset = refresh ? 0 : state.followersOffset;
    if (!refresh && (state.isLoadingFollowers || !state.hasMoreFollowers)) {
      return;
    }

    state = state.copyWith(isLoadingFollowers: true);
    try {
      final items = await repository.getFollowers(
        userId,
        limit: _pageSize,
        offset: offset,
      );

      final newFollowers = refresh ? items : [...state.followers, ...items];
      state = state.copyWith(
        followers: newFollowers,
        followersOffset: offset + items.length,
        hasMoreFollowers: items.length >= _pageSize,
        isLoadingFollowers: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingFollowers: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingFollowers: false,
        errorMessage: 'Failed to load followers.',
      );
    }
  }

  Future<void> loadFollowing({bool refresh = false}) async {
    final offset = refresh ? 0 : state.followingOffset;
    if (!refresh && (state.isLoadingFollowing || !state.hasMoreFollowing)) {
      return;
    }

    state = state.copyWith(isLoadingFollowing: true);
    try {
      final items = await repository.getFollowing(
        userId,
        limit: _pageSize,
        offset: offset,
      );

      final newFollowing = refresh ? items : [...state.following, ...items];
      // Mark all in the following list as isFollowing = true
      final statusMap = Map<String, bool>.from(state.followingStatusMap);
      for (final u in items) {
        statusMap[u.id] = true;
      }

      state = state.copyWith(
        following: newFollowing,
        followingStatusMap: statusMap,
        followingOffset: offset + items.length,
        hasMoreFollowing: items.length >= _pageSize,
        isLoadingFollowing: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingFollowing: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingFollowing: false,
        errorMessage: 'Failed to load following list.',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> toggleFollowUser(
    String targetUserId, {
    required bool isCurrentlyFollowing,
  }) async {
    final targetFollowing = !isCurrentlyFollowing;
    final updatedMap = Map<String, bool>.from(state.followingStatusMap);
    updatedMap[targetUserId] = targetFollowing;

    // 1. Optimistic update
    state = state.copyWith(followingStatusMap: updatedMap, clearError: true);

    try {
      if (targetFollowing) {
        await repository.followUser(targetUserId);
      } else {
        await repository.unfollowUser(targetUserId);
      }
    } on AppException catch (e) {
      // 2. Revert on error
      updatedMap[targetUserId] = isCurrentlyFollowing;
      state = state.copyWith(
        followingStatusMap: updatedMap,
        errorMessage: e.message,
      );
    } catch (_) {
      updatedMap[targetUserId] = isCurrentlyFollowing;
      state = state.copyWith(
        followingStatusMap: updatedMap,
        errorMessage: 'Action failed. Please try again.',
      );
    }
  }
}
