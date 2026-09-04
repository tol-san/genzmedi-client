import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_state.dart';

final myProfileNotifierProvider =
    StateNotifierProvider.autoDispose<MyProfileNotifier, MyProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      final authState = ref.watch(authNotifierProvider);

      final initialUser = authState is AuthAuthenticated
          ? authState.user
          : (authState is AuthNeedsOnboarding ? authState.user : null);

      return MyProfileNotifier(
        repository: repository,
        initialUser: initialUser,
      );
    });

class MyProfileNotifier extends StateNotifier<MyProfileState> {
  final ProfileRepository repository;

  MyProfileNotifier({required this.repository, UserModel? initialUser})
    : super(
        MyProfileState(
          user: initialUser,
          isLoadingProfile: initialUser == null,
        ),
      ) {
    loadProfile();
  }

  /// Initial full fetch of user profile and their content
  Future<void> loadProfile() async {
    state = state.copyWith(isLoadingProfile: true, clearError: true);
    try {
      final user = await repository.getMyProfile();
      state = state.copyWith(user: user, isLoadingProfile: false);
      // Fetch posts and saved posts concurrently
      await Future.wait([loadPosts(userId: user.id), loadSavedPosts()]);
    } on AppException catch (e) {
      state = state.copyWith(isLoadingProfile: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoadingProfile: false,
        errorMessage: 'Failed to load profile.',
      );
    }
  }

  /// Pull-to-refresh handler for the profile screen
  Future<void> refreshProfile() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final user = await repository.getMyProfile();
      state = state.copyWith(user: user);

      await Future.wait([loadPosts(userId: user.id), loadSavedPosts()]);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Refresh failed.');
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }

  /// Load personal posts for the authenticated user
  Future<void> loadPosts({String? userId}) async {
    final targetId = userId ?? state.user?.id;
    if (targetId == null || targetId.isEmpty) return;

    state = state.copyWith(isLoadingPosts: true);
    try {
      final posts = await repository.getUserPosts(authorId: targetId);
      state = state.copyWith(posts: posts, isLoadingPosts: false);
    } on AppException {
      state = state.copyWith(isLoadingPosts: false);
    } catch (_) {
      state = state.copyWith(isLoadingPosts: false);
    }
  }

  static const int _savedPostsPageSize = 20;

  /// Load bookmarked/saved posts for the authenticated user
  Future<void> loadSavedPosts() async {
    state = state.copyWith(isLoadingSaved: true, clearSavedError: true);
    try {
      final savedPosts = await repository.getSavedPosts(
        limit: _savedPostsPageSize,
        offset: 0,
      );
      state = state.copyWith(
        savedPosts: savedPosts,
        isLoadingSaved: false,
        hasMoreSaved: savedPosts.length >= _savedPostsPageSize,
        clearSavedError: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingSaved: false,
        savedErrorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingSaved: false,
        savedErrorMessage: 'Failed to load saved posts. Please retry.',
      );
    }
  }

  /// Load more saved posts with offset pagination
  Future<void> loadMoreSavedPosts() async {
    if (state.isLoadingSaved ||
        state.isLoadingMoreSaved ||
        !state.hasMoreSaved) {
      return;
    }

    state = state.copyWith(isLoadingMoreSaved: true);
    try {
      final nextPosts = await repository.getSavedPosts(
        limit: _savedPostsPageSize,
        offset: state.savedPosts.length,
      );
      state = state.copyWith(
        savedPosts: [...state.savedPosts, ...nextPosts],
        isLoadingMoreSaved: false,
        hasMoreSaved: nextPosts.length >= _savedPostsPageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMoreSaved: false);
    }
  }

  /// Immediately remove an unsaved post from the profile list
  void removeSavedPost(String postId) {
    if (state.savedPosts.any((p) => p.id == postId)) {
      final updated = state.savedPosts.where((p) => p.id != postId).toList();
      state = state.copyWith(savedPosts: updated);
    }
  }

  /// Optimistically update a post in the saved list
  void updateSavedPost(PostModel updatedPost) {
    final index = state.savedPosts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      if (updatedPost.isSaved == false) {
        removeSavedPost(updatedPost.id);
      } else {
        final updated = List<PostModel>.from(state.savedPosts);
        updated[index] = updatedPost;
        state = state.copyWith(savedPosts: updated);
      }
    }
  }
}
