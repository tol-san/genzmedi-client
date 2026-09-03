import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
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
  static const int _postPageSize = 10;

  DiscoverNotifier({required this.repository})
    : super(const DiscoverState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait<Object>([
        repository.getDiscoverPosts(limit: _postPageSize),
        repository.getRecommendedUsers(),
        repository.getRecommendedCommunities(),
      ]);
      final posts = results[0] as DiscoveryPage<PostModel>;
      final users = results[1] as DiscoveryPage<DiscoverUserModel>;
      final communities = results[2] as DiscoveryPage<DiscoverCommunityModel>;
      state = state.copyWith(
        posts: posts.items,
        users: users.items,
        communities: communities.items,
        hasMorePosts: posts.hasMore,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not load Discover.'),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final results = await Future.wait<Object>([
        repository.getDiscoverPosts(limit: _postPageSize),
        repository.getRecommendedUsers(),
        repository.getRecommendedCommunities(),
      ]);
      final posts = results[0] as DiscoveryPage<PostModel>;
      state = state.copyWith(
        posts: posts.items,
        users: (results[1] as DiscoveryPage<DiscoverUserModel>).items,
        communities:
            (results[2] as DiscoveryPage<DiscoverCommunityModel>).items,
        hasMorePosts: posts.hasMore,
        isRefreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _message(error, 'Could not refresh Discover.'),
      );
    }
  }

  Future<void> loadMorePosts() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePosts) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await repository.getDiscoverPosts(
        limit: _postPageSize,
        offset: state.posts.length,
      );
      state = state.copyWith(
        posts: [...state.posts, ...page.items],
        hasMorePosts: page.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _message(error, 'Could not load more posts.'),
      );
    }
  }

  Future<void> toggleFollow(String userId) async {
    final index = state.users.indexWhere((item) => item.user.id == userId);
    if (index < 0 || state.pendingUserIds.contains(userId)) return;
    final original = state.users[index];
    final target = !original.isFollowing;
    final pending = {...state.pendingUserIds, userId};
    final users = [...state.users]
      ..[index] = original.copyWith(isFollowing: target);
    state = state.copyWith(users: users, pendingUserIds: pending);
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
      final reverted = [...state.users]..[index] = original;
      state = state.copyWith(
        users: reverted,
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

  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((post) => post.id == postId);
    if (index < 0) return;
    final original = state.posts[index];
    final target = !original.isLiked;
    final posts = [...state.posts]
      ..[index] = original.copyWith(
        isLiked: target,
        likeCount: (original.likeCount + (target ? 1 : -1)).clamp(0, 1 << 31),
      );
    state = state.copyWith(posts: posts);
    try {
      await repository.likePost(postId, like: target);
    } catch (_) {
      state = state.copyWith(posts: [...state.posts]..[index] = original);
    }
  }

  Future<void> toggleSave(String postId) async {
    final index = state.posts.indexWhere((post) => post.id == postId);
    if (index < 0) return;
    final original = state.posts[index];
    final target = !original.isSaved;
    final posts = [...state.posts]
      ..[index] = original.copyWith(
        isSaved: target,
        saveCount: (original.saveCount + (target ? 1 : -1)).clamp(0, 1 << 31),
      );
    state = state.copyWith(posts: posts);
    try {
      await repository.savePost(postId, save: target);
    } catch (_) {
      state = state.copyWith(posts: [...state.posts]..[index] = original);
    }
  }

  Future<String?> sharePost(String postId) async {
    try {
      return await repository.sharePost(postId);
    } catch (_) {
      return 'https://genzmedia.app/posts/$postId';
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _message(Object error, String fallback) {
    return error is AppException ? error.message : fallback;
  }
}
