import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/notifiers/home_feed_state.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';

final homeFeedNotifierProvider =
    StateNotifierProvider<HomeFeedNotifier, HomeFeedState>((ref) {
      final repository = ref.watch(feedRepositoryProvider);
      return HomeFeedNotifier(repository: repository, ref: ref);
    });

class HomeFeedNotifier extends StateNotifier<HomeFeedState> {
  final FeedRepository repository;
  final Ref? ref;
  static const int _pageSize = 20;

  HomeFeedNotifier({required this.repository, this.ref})
    : super(const HomeFeedState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repository.getHomeFeed(limit: _pageSize, offset: 0);
      state = state.copyWith(
        posts: items,
        offset: items.length,
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load home feed.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final items = await repository.getHomeFeed(limit: _pageSize, offset: 0);
      state = state.copyWith(
        posts: items,
        offset: items.length,
        hasMore: items.length >= _pageSize,
        isRefreshing: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh feed.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final items = await repository.getHomeFeed(
        limit: _pageSize,
        offset: state.offset,
      );

      state = state.copyWith(
        posts: [...state.posts, ...items],
        offset: state.offset + items.length,
        hasMore: items.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final wasLiked = post.isLiked;
    final targetLiked = !wasLiked;
    final newLikeCount = (post.likeCount + (targetLiked ? 1 : -1)).clamp(
      0,
      999999999,
    );

    final updatedPosts = List<PostModel>.from(state.posts);
    updatedPosts[index] = post.copyWith(
      isLiked: targetLiked,
      likeCount: newLikeCount,
    );

    // 1. Optimistic update
    state = state.copyWith(posts: updatedPosts);

    try {
      if (targetLiked) {
        await repository.likePost(postId);
      } else {
        await repository.unlikePost(postId);
      }
    } catch (_) {
      // 2. Rollback on error
      if (mounted) {
        final revertedPosts = List<PostModel>.from(state.posts);
        revertedPosts[index] = post;
        state = state.copyWith(posts: revertedPosts);
      }
    }
  }

  Future<void> toggleSave(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final wasSaved = post.isSaved;
    final targetSaved = !wasSaved;
    final newSaveCount = (post.saveCount + (targetSaved ? 1 : -1)).clamp(
      0,
      999999999,
    );

    final updatedPosts = List<PostModel>.from(state.posts);
    updatedPosts[index] = post.copyWith(
      isSaved: targetSaved,
      saveCount: newSaveCount,
    );

    // 1. Optimistic update
    state = state.copyWith(posts: updatedPosts);

    try {
      if (targetSaved) {
        await repository.savePost(postId);
      } else {
        await repository.unsavePost(postId);
        if (ref?.exists(myProfileNotifierProvider) == true) {
          ref?.read(myProfileNotifierProvider.notifier).removeSavedPost(postId);
        }
      }
    } catch (_) {
      // 2. Rollback on error
      if (mounted) {
        final revertedPosts = List<PostModel>.from(state.posts);
        revertedPosts[index] = post;
        state = state.copyWith(posts: revertedPosts);
      }
    }
  }

  Future<String?> sharePost(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return null;

    final post = state.posts[index];
    final updatedPosts = List<PostModel>.from(state.posts);
    updatedPosts[index] = post.copyWith(shareCount: post.shareCount + 1);
    state = state.copyWith(posts: updatedPosts);

    try {
      return await repository.sharePost(postId);
    } catch (_) {
      return 'https://genzmedia.app/posts/$postId';
    }
  }

  /// Remove a post from the home feed when deleted
  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }

  /// Update an existing post in the home feed when edited
  void updatePost(PostModel updatedPost) {
    final index = state.posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      final updated = List<PostModel>.from(state.posts);
      updated[index] = updatedPost;
      state = state.copyWith(posts: updated);
    }
  }
}
