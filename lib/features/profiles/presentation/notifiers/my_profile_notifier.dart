import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
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

  MyProfileNotifier({
    required this.repository,
    UserModel? initialUser,
  }) : super(MyProfileState(
          user: initialUser,
          isLoadingProfile: initialUser == null,
        )) {
    loadProfile();
  }

  /// Initial full fetch of user profile and their content
  Future<void> loadProfile() async {
    state = state.copyWith(isLoadingProfile: true, clearError: true);
    try {
      final user = await repository.getMyProfile();
      state = state.copyWith(
        user: user,
        isLoadingProfile: false,
      );
      // Fetch posts and saved posts concurrently
      await Future.wait([
        loadPosts(userId: user.id),
        loadSavedPosts(),
      ]);
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingProfile: false,
        errorMessage: e.message,
      );
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

      await Future.wait([
        loadPosts(userId: user.id),
        loadSavedPosts(),
      ]);
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
      state = state.copyWith(
        posts: posts,
        isLoadingPosts: false,
      );
    } on AppException {
      state = state.copyWith(isLoadingPosts: false);
    } catch (_) {
      state = state.copyWith(isLoadingPosts: false);
    }
  }

  /// Load bookmarked/saved posts for the authenticated user
  Future<void> loadSavedPosts() async {
    state = state.copyWith(isLoadingSaved: true);
    try {
      final savedPosts = await repository.getSavedPosts();
      state = state.copyWith(
        savedPosts: savedPosts,
        isLoadingSaved: false,
      );
    } on AppException {
      state = state.copyWith(isLoadingSaved: false);
    } catch (_) {
      state = state.copyWith(isLoadingSaved: false);
    }
  }
}
