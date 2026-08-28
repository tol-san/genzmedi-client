import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);

  return AuthNotifier(
    repository: repository,
    storage: storage,
    prefs: prefs,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SecureStorageService storage;
  final PreferencesService prefs;

  AuthNotifier({
    required this.repository,
    required this.storage,
    required this.prefs,
  }) : super(const AuthInitial()) {
    checkSession();
  }

  /// Verifies whether an existing stored session is valid and loads the profile
  Future<void> checkSession() async {
    try {
      final token = await storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = const AuthUnauthenticated();
        return;
      }

      final user = await repository.getMyProfile();
      if (user.interests.isEmpty && !prefs.isOnboardingCompleted()) {
        state = AuthNeedsOnboarding(user);
      } else {
        state = AuthAuthenticated(user);
      }
    } catch (_) {
      // In case session is expired or network fails, transition cleanly
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email or username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final tokenModel = await repository.login(
        LoginRequest(username: username, password: password),
      );

      await storage.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );

      final user = await repository.getMyProfile();

      if (user.interests.isEmpty && !prefs.isOnboardingCompleted()) {
        state = AuthNeedsOnboarding(user);
      } else {
        state = AuthAuthenticated(user);
      }
    } on AppException catch (e) {
      state = AuthUnauthenticated(message: e.message);
      rethrow;
    } catch (e) {
      final ex = UnknownException(e.toString());
      state = AuthUnauthenticated(message: ex.message);
      throw ex;
    }
  }

  /// Register a new account
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final tokenModel = await repository.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
        ),
      );

      if (tokenModel != null) {
        await storage.saveTokens(
          accessToken: tokenModel.accessToken,
          refreshToken: tokenModel.refreshToken,
        );

        UserModel user;
        try {
          user = await repository.getMyProfile();
        } catch (_) {
          user = UserModel(id: username, username: username, email: email);
        }

        state = AuthNeedsOnboarding(user);
      } else {
        state = const AuthUnauthenticated(
          message: 'Account created successfully! Please sign in.',
        );
      }
    } on AppException catch (e) {
      state = AuthUnauthenticated(message: e.message);
      rethrow;
    } catch (e) {
      final ex = UnknownException(e.toString());
      state = AuthUnauthenticated(message: ex.message);
      throw ex;
    }
  }

  /// Save selected onboarding interests and complete onboarding gate
  Future<void> completeOnboarding(List<String> interests) async {
    if (state is! AuthNeedsOnboarding && state is! AuthAuthenticated) return;

    try {
      await repository.updateMyInterests(interests);
      await prefs.setOnboardingCompleted(true);

      final currentUser = (state is AuthNeedsOnboarding)
          ? (state as AuthNeedsOnboarding).user
          : (state as AuthAuthenticated).user;

      state = AuthAuthenticated(currentUser.copyWith(interests: interests));
    } catch (e) {
      rethrow;
    }
  }

  /// Revoke credentials and reset local state
  Future<void> logout() async {
    try {
      await repository.logout();
    } catch (_) {
      // Ignore network failure on logout
    } finally {
      await storage.clearAll();
      state = const AuthUnauthenticated();
    }
  }
}
