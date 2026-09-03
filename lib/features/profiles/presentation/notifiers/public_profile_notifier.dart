import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/public_profile_state.dart';

final publicProfileNotifierProvider = StateNotifierProvider.autoDispose
    .family<PublicProfileNotifier, PublicProfileState, String>((ref, username) {
      final repository = ref.watch(profileRepositoryProvider);
      return PublicProfileNotifier(username: username, repository: repository);
    });

class PublicProfileNotifier extends StateNotifier<PublicProfileState> {
  final String username;
  final ProfileRepository repository;

  PublicProfileNotifier({required this.username, required this.repository})
    : super(const PublicProfileState(isLoading: true)) {
    loadProfile();
  }

  /// Initial fetch of public profile, relationship, and posts
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await repository.getPublicProfile(username);
      state = state.copyWith(user: user, isLoading: false);

      // Concurrently fetch relationship and posts
      final results = await Future.wait([
        repository.getRelationship(user.id),
        repository.getUserPosts(authorId: user.id),
      ]);

      state = state.copyWith(
        relationship: results[0] as dynamic,
        posts: results[1] as dynamic,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user profile.',
      );
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final user = await repository.getPublicProfile(username);
      final results = await Future.wait([
        repository.getRelationship(user.id),
        repository.getUserPosts(authorId: user.id),
      ]);

      state = state.copyWith(
        user: user,
        relationship: results[0] as dynamic,
        posts: results[1] as dynamic,
      );
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Refresh failed.');
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }

  /// Optimistic Follow / Unfollow action
  Future<void> toggleFollow() async {
    final currentUser = state.user;
    if (currentUser == null || state.isActionLoading) return;

    final wasFollowing = state.relationship.isFollowing;
    final targetFollowing = !wasFollowing;
    final previousFollowersCount = currentUser.followersCount;
    final newFollowersCount =
        (previousFollowersCount + (targetFollowing ? 1 : -1)).clamp(
          0,
          999999999,
        );

    // 1. Optimistic UI update
    state = state.copyWith(
      user: currentUser.copyWith(followersCount: newFollowersCount),
      relationship: state.relationship.copyWith(isFollowing: targetFollowing),
      isActionLoading: true,
      clearError: true,
    );

    try {
      if (targetFollowing) {
        await repository.followUser(currentUser.id);
      } else {
        await repository.unfollowUser(currentUser.id);
      }
      state = state.copyWith(isActionLoading: false);
    } on AppException catch (e) {
      // 2. Revert on error
      state = state.copyWith(
        user: currentUser.copyWith(followersCount: previousFollowersCount),
        relationship: state.relationship.copyWith(isFollowing: wasFollowing),
        isActionLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        user: currentUser.copyWith(followersCount: previousFollowersCount),
        relationship: state.relationship.copyWith(isFollowing: wasFollowing),
        isActionLoading: false,
        errorMessage: 'Action failed. Please try again.',
      );
    }
  }

  /// Block / Unblock target user
  Future<bool> toggleBlock() async {
    final currentUser = state.user;
    if (currentUser == null || state.isActionLoading) return false;

    final wasBlocking = state.relationship.isBlocking;
    final targetBlocking = !wasBlocking;

    state = state.copyWith(
      relationship: state.relationship.copyWith(
        isBlocking: targetBlocking,
        isFollowing: targetBlocking ? false : state.relationship.isFollowing,
      ),
      isActionLoading: true,
      clearError: true,
    );

    try {
      if (targetBlocking) {
        await repository.blockUser(currentUser.id);
      } else {
        await repository.unblockUser(currentUser.id);
      }
      state = state.copyWith(isActionLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        relationship: state.relationship.copyWith(isBlocking: wasBlocking),
        isActionLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        relationship: state.relationship.copyWith(isBlocking: wasBlocking),
        isActionLoading: false,
        errorMessage: 'Block action failed.',
      );
      return false;
    }
  }

  /// Submit a moderation report against the target user
  Future<bool> reportUser({required String reason, String? description}) async {
    final targetUser = state.user;
    if (targetUser == null) return false;

    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await repository.submitReport(
        reportType: 'user',
        targetId: targetUser.id,
        reason: reason,
        description: description,
      );
      state = state.copyWith(isActionLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Report submission failed.',
      );
      return false;
    }
  }
}
