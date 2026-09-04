import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/notifiers/shorts_feed_state.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';

final shortsFeedNotifierProvider =
    StateNotifierProvider<ShortsFeedNotifier, ShortsFeedState>((ref) {
      final repository = ref.watch(feedRepositoryProvider);
      return ShortsFeedNotifier(repository: repository, ref: ref);
    });

class ShortsFeedNotifier extends StateNotifier<ShortsFeedState> {
  final FeedRepository repository;
  final Ref? ref;
  static const int _pageSize = 20;

  ShortsFeedNotifier({required this.repository, this.ref})
    : super(const ShortsFeedState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repository.getShortsFeed(limit: _pageSize, offset: 0);
      state = state.copyWith(
        shorts: items,
        offset: items.length,
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load shorts feed.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final items = await repository.getShortsFeed(limit: _pageSize, offset: 0);
      state = state.copyWith(
        shorts: items,
        offset: items.length,
        hasMore: items.length >= _pageSize,
        isRefreshing: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh shorts feed.',
      );
    }
  }

  void setActiveIndex(int index) {
    if (state.activeIndex != index) {
      state = state.copyWith(activeIndex: index);
      if (index >= state.shorts.length - 3 &&
          state.hasMore &&
          !state.isLoadingMore) {
        loadMore();
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final items = await repository.getShortsFeed(
        limit: _pageSize,
        offset: state.offset,
      );

      state = state.copyWith(
        shorts: [...state.shorts, ...items],
        offset: state.offset + items.length,
        hasMore: items.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = state.shorts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.shorts[index];
    final wasLiked = post.isLiked;
    final targetLiked = !wasLiked;
    final newLikeCount = (post.likeCount + (targetLiked ? 1 : -1)).clamp(
      0,
      999999999,
    );

    final updated = List<PostModel>.from(state.shorts);
    updated[index] = post.copyWith(
      isLiked: targetLiked,
      likeCount: newLikeCount,
    );

    state = state.copyWith(shorts: updated);

    try {
      if (targetLiked) {
        await repository.likePost(postId);
      } else {
        await repository.unlikePost(postId);
      }
    } catch (_) {
      if (mounted) {
        final reverted = List<PostModel>.from(state.shorts);
        reverted[index] = post;
        state = state.copyWith(shorts: reverted);
      }
    }
  }

  Future<void> toggleSave(String postId) async {
    final index = state.shorts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.shorts[index];
    final wasSaved = post.isSaved;
    final targetSaved = !wasSaved;
    final newSaveCount = (post.saveCount + (targetSaved ? 1 : -1)).clamp(
      0,
      999999999,
    );

    final updated = List<PostModel>.from(state.shorts);
    updated[index] = post.copyWith(
      isSaved: targetSaved,
      saveCount: newSaveCount,
    );

    state = state.copyWith(shorts: updated);

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
      if (mounted) {
        final reverted = List<PostModel>.from(state.shorts);
        reverted[index] = post;
        state = state.copyWith(shorts: reverted);
      }
    }
  }

  Future<String?> sharePost(String postId) async {
    final index = state.shorts.indexWhere((p) => p.id == postId);
    if (index == -1) return null;

    final post = state.shorts[index];
    final updated = List<PostModel>.from(state.shorts);
    updated[index] = post.copyWith(shareCount: post.shareCount + 1);
    state = state.copyWith(shorts: updated);

    try {
      return await repository.sharePost(postId);
    } catch (_) {
      return 'https://genzmedia.app/posts/$postId';
    }
  }
}
