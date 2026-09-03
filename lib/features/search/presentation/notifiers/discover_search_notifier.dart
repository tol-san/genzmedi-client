import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/notifiers/discover_search_state.dart';

final discoverSearchNotifierProvider = StateNotifierProvider.autoDispose
    .family<DiscoverSearchNotifier, DiscoverSearchState, String>((
      ref,
      initialQuery,
    ) {
      return DiscoverSearchNotifier(
        repository: ref.watch(discoveryRepositoryProvider),
        initialQuery: initialQuery,
      );
    });

class DiscoverSearchNotifier extends StateNotifier<DiscoverSearchState> {
  final DiscoveryRepository repository;
  static const int _pageSize = 20;

  DiscoverSearchNotifier({
    required this.repository,
    required String initialQuery,
  }) : super(DiscoverSearchState(query: initialQuery.trim())) {
    if (state.query.isNotEmpty) search();
  }

  Future<void> updateQuery(String query) async {
    final clean = query.trim();
    if (clean == state.query) return;
    state = state.copyWith(query: clean);
    if (clean.isEmpty) {
      state = DiscoverSearchState(category: state.category);
      return;
    }
    await search();
  }

  Future<void> setCategory(DiscoverSearchCategory category) async {
    if (category == state.category) return;
    state = state.copyWith(category: category);
    if (state.query.isNotEmpty) await search();
  }

  Future<void> search() async {
    if (state.query.isEmpty) return;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      if (state.category == DiscoverSearchCategory.all) {
        final result = await repository.searchAll(state.query);
        state = state.copyWith(
          users: result.users,
          communities: result.communities,
          posts: result.posts,
          interests: result.interests,
          totalResults: result.totalResults,
          hasMore: false,
          isLoading: false,
        );
      } else {
        final page = await repository.searchCategory(
          state.query,
          state.category,
          limit: _pageSize,
        );
        _applyCategoryPage(page, replace: true);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Search is unavailable right now.'),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.category == DiscoverSearchCategory.all ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await repository.searchCategory(
        state.query,
        state.category,
        limit: _pageSize,
        offset: state.activeCount,
      );
      _applyCategoryPage(page, replace: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _message(error, 'Could not load more results.'),
      );
    }
  }

  void _applyCategoryPage(
    DiscoveryPage<dynamic> page, {
    required bool replace,
  }) {
    switch (state.category) {
      case DiscoverSearchCategory.users:
        final items = page.items.cast<DiscoverUserModel>();
        state = state.copyWith(
          users: replace ? items : [...state.users, ...items],
          totalResults: page.total,
          hasMore: page.hasMore,
          isLoading: false,
          isLoadingMore: false,
        );
      case DiscoverSearchCategory.communities:
        final items = page.items.cast<DiscoverCommunityModel>();
        state = state.copyWith(
          communities: replace ? items : [...state.communities, ...items],
          totalResults: page.total,
          hasMore: page.hasMore,
          isLoading: false,
          isLoadingMore: false,
        );
      case DiscoverSearchCategory.posts:
        final items = page.items.cast<PostModel>();
        state = state.copyWith(
          posts: replace ? items : [...state.posts, ...items],
          totalResults: page.total,
          hasMore: page.hasMore,
          isLoading: false,
          isLoadingMore: false,
        );
      case DiscoverSearchCategory.interests:
        final items = page.items.cast<DiscoverInterestModel>();
        state = state.copyWith(
          interests: replace ? items : [...state.interests, ...items],
          totalResults: page.total,
          hasMore: page.hasMore,
          isLoading: false,
          isLoadingMore: false,
        );
      case DiscoverSearchCategory.all:
        break;
    }
  }

  Future<void> toggleFollow(String userId) async {
    final index = state.users.indexWhere((item) => item.user.id == userId);
    if (index < 0 || state.pendingUserIds.contains(userId)) return;
    final original = state.users[index];
    final target = !original.isFollowing;
    state = state.copyWith(
      users: [...state.users]..[index] = original.copyWith(isFollowing: target),
      pendingUserIds: {...state.pendingUserIds, userId},
    );
    try {
      if (target) {
        await repository.followUser(userId);
      } else {
        await repository.unfollowUser(userId);
      }
      state = state.copyWith(
        pendingUserIds: {...state.pendingUserIds}..remove(userId),
      );
    } catch (error) {
      state = state.copyWith(
        users: [...state.users]..[index] = original,
        pendingUserIds: {...state.pendingUserIds}..remove(userId),
        errorMessage: _message(error, 'Could not update follow status.'),
      );
    }
  }

  Future<void> toggleCommunity(String communityId) async {
    final index = state.communities.indexWhere(
      (item) => item.community.id == communityId,
    );
    if (index < 0 || state.pendingCommunityIds.contains(communityId)) return;
    final original = state.communities[index];
    final target = !original.isJoined;
    state = state.copyWith(
      communities: [...state.communities]
        ..[index] = original.copyWith(isJoined: target, isJoinPending: false),
      pendingCommunityIds: {...state.pendingCommunityIds, communityId},
    );
    try {
      var pending = false;
      if (target) {
        pending = await repository.joinCommunity(communityId);
      } else {
        await repository.leaveCommunity(communityId);
      }
      state = state.copyWith(
        communities: [...state.communities]
          ..[index] = original.copyWith(
            isJoined: target && !pending,
            isJoinPending: pending,
          ),
        pendingCommunityIds: {...state.pendingCommunityIds}
          ..remove(communityId),
      );
    } catch (error) {
      state = state.copyWith(
        communities: [...state.communities]..[index] = original,
        pendingCommunityIds: {...state.pendingCommunityIds}
          ..remove(communityId),
        errorMessage: _message(error, 'Could not update membership.'),
      );
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index < 0 || state.pendingPostLikeIds.contains(postId)) return;
    final original = state.posts[index];
    final target = !original.isLiked;
    final newLikeCount = target
        ? original.likeCount + 1
        : (original.likeCount > 0 ? original.likeCount - 1 : 0);

    state = state.copyWith(
      posts: [...state.posts]
        ..[index] = original.copyWith(isLiked: target, likeCount: newLikeCount),
      pendingPostLikeIds: {...state.pendingPostLikeIds, postId},
    );

    try {
      await repository.likePost(postId, like: target);
      state = state.copyWith(
        pendingPostLikeIds: {...state.pendingPostLikeIds}..remove(postId),
      );
    } catch (error) {
      state = state.copyWith(
        posts: [...state.posts]..[index] = original,
        pendingPostLikeIds: {...state.pendingPostLikeIds}..remove(postId),
        errorMessage: _message(error, 'Could not update like status.'),
      );
    }
  }

  Future<void> toggleSave(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index < 0 || state.pendingPostSaveIds.contains(postId)) return;
    final original = state.posts[index];
    final target = !original.isSaved;
    final newSaveCount = target
        ? original.saveCount + 1
        : (original.saveCount > 0 ? original.saveCount - 1 : 0);

    state = state.copyWith(
      posts: [...state.posts]
        ..[index] = original.copyWith(isSaved: target, saveCount: newSaveCount),
      pendingPostSaveIds: {...state.pendingPostSaveIds, postId},
    );

    try {
      await repository.savePost(postId, save: target);
      state = state.copyWith(
        pendingPostSaveIds: {...state.pendingPostSaveIds}..remove(postId),
      );
    } catch (error) {
      state = state.copyWith(
        posts: [...state.posts]..[index] = original,
        pendingPostSaveIds: {...state.pendingPostSaveIds}..remove(postId),
        errorMessage: _message(error, 'Could not update saved status.'),
      );
    }
  }

  Future<String?> sharePost(String postId) async {
    try {
      return await repository.sharePost(postId);
    } catch (error) {
      state = state.copyWith(
        errorMessage: _message(error, 'Could not generate share link.'),
      );
      return null;
    }
  }

  Future<void> toggleInterest(DiscoverInterestModel interest) async {
    final index = state.interests.indexWhere((item) => item.id == interest.id);
    if (index < 0 || state.pendingInterestIds.contains(interest.id)) return;
    final original = state.interests[index];
    final target = !original.isAdded;

    state = state.copyWith(
      interests: [...state.interests]
        ..[index] = original.copyWith(isAdded: target),
      pendingInterestIds: {...state.pendingInterestIds, interest.id},
    );

    try {
      await repository.toggleUserInterest(interest.id, add: target);
      state = state.copyWith(
        pendingInterestIds: {...state.pendingInterestIds}..remove(interest.id),
      );
    } catch (error) {
      state = state.copyWith(
        interests: [...state.interests]..[index] = original,
        pendingInterestIds: {...state.pendingInterestIds}..remove(interest.id),
        errorMessage: _message(error, 'Could not update interest.'),
      );
    }
  }

  String _message(Object error, String fallback) {
    return error is AppException ? error.message : fallback;
  }
}
