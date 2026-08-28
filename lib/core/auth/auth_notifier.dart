import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/token_model.dart';
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

  /// Helper to persist access and refresh tokens and record active session
  Future<void> _saveSession(TokenModel tokenModel) async {
    await storage.saveTokens(
      accessToken: tokenModel.accessToken,
      refreshToken: tokenModel.refreshToken,
    );
    await prefs.setHasSession(true);
  }

  /// Helper to fetch user profile and transition to authenticated or onboarding state
  Future<UserModel> _fetchAndSetUser({bool forceOnboarding = false}) async {
    final user = await repository.getMyProfile();
    final needsOnboarding = forceOnboarding ||
        (user.interests.isEmpty && !prefs.isOnboardingCompleted());

    if (needsOnboarding) {
      state = AuthNeedsOnboarding(user);
    } else {
      state = AuthAuthenticated(user);
    }
    return user;
  }

  /// Verifies whether an existing stored session is valid and loads the profile
  Future<void> checkSession() async {
    // 1. Instant check: If no active session recorded in SharedPreferences, transition immediately
    if (!prefs.hasSession()) {
      state = const AuthUnauthenticated();
      return;
    }

    // 2. Verify stored token and fetch user profile
    try {
      String? token;
      try {
        token = await storage.getAccessToken();
      } catch (_) {
        token = null;
      }

      if (token == null || token.isEmpty) {
        await prefs.setHasSession(false);
        state = const AuthUnauthenticated();
        return;
      }

      try {
        final user = await repository.getMyProfile().timeout(
              const Duration(seconds: 4),
            );
        if (user.interests.isEmpty && !prefs.isOnboardingCompleted()) {
          state = AuthNeedsOnboarding(user);
        } else {
          state = AuthAuthenticated(user);
        }
      } on TimeoutException {
        // Network timeout — retain unauthenticated state without resetting session flag
        state = const AuthUnauthenticated(
          message: 'Connection timed out. Please check your network.',
        );
      } on SocketException {
        // Network offline — retain unauthenticated state without resetting session flag
        state = const AuthUnauthenticated(
          message: 'No internet connection. Please check your network.',
        );
      } catch (_) {
        // Auth rejection (e.g. 401/expired token) — clear session flag
        await prefs.setHasSession(false);
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      await prefs.setHasSession(false);
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email or username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final tokenModel = await repository.login(
        LoginRequest(username: username, password: password),
      );
      await _saveSession(tokenModel);
      await _fetchAndSetUser();
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Verify 6-digit OTP code, save session tokens, and transition to authenticated
  Future<TokenModel> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final tokenModel = await repository.verifyOtp(
        VerifyOtpRequest(email: email, otp: otp),
      );
      await _saveSession(tokenModel);
      await _fetchAndSetUser();
      return tokenModel;
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Request a 6-digit verification code to register a new account
  Future<void> requestSignupOtp({
    required String email,
    required String password,
  }) async {
    try {
      await repository.requestSignupOtp(
        SignupOtpRequest(email: email, password: password),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Verify signup OTP code, save session tokens, and transition to AuthNeedsOnboarding
  Future<TokenModel> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final tokenModel = await repository.verifySignupOtp(
        SignupVerifyOtpRequest(email: email, otp: otp),
      );
      await _saveSession(tokenModel);

      try {
        await _fetchAndSetUser(forceOnboarding: true);
      } catch (_) {
        final prefix = email.split('@')[0];
        final fallbackUser = UserModel(
          id: prefix,
          username: prefix,
          email: email,
          displayName: prefix,
        );
        state = AuthNeedsOnboarding(fallbackUser);
      }

      return tokenModel;
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Check whether candidate username is available
  Future<bool> checkUsername(String username) async {
    return await repository.checkUsername(username);
  }

  /// Update user profile information (display name, avatar, bio, or username)
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final updatedUser = await repository.updateProfile(
        username: username,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      if (state is AuthAuthenticated) {
        state = AuthAuthenticated(updatedUser);
      } else if (state is AuthNeedsOnboarding) {
        state = AuthNeedsOnboarding(updatedUser);
      }

      return updatedUser;
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Upload custom avatar file and update current state
  Future<UserModel> uploadAvatar(File imageFile) async {
    try {
      final updatedUser = await repository.uploadAvatar(imageFile);

      if (state is AuthAuthenticated) {
        state = AuthAuthenticated(updatedUser);
      } else if (state is AuthNeedsOnboarding) {
        state = AuthNeedsOnboarding(updatedUser);
      }

      return updatedUser;
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Register a new account (direct / legacy)
  Future<void> register({
    String? username,
    required String email,
    required String password,
  }) async {
    try {
      final tokenModel = await repository.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
        ),
      );

      if (tokenModel != null) {
        await _saveSession(tokenModel);

        try {
          await _fetchAndSetUser(forceOnboarding: true);
        } catch (_) {
          final uname = username ?? email.split('@')[0];
          state = AuthNeedsOnboarding(
            UserModel(id: uname, username: uname, email: email),
          );
        }
      } else {
        state = const AuthUnauthenticated(
          message: 'Account created successfully! Please sign in.',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Save selected onboarding interests and complete onboarding gate
  Future<void> completeOnboarding(List<String> interests) async {
    if (state is! AuthNeedsOnboarding && state is! AuthAuthenticated) return;

    await repository.updateMyInterests(interests);
    await prefs.setOnboardingCompleted(true);

    final currentUser = (state is AuthNeedsOnboarding)
        ? (state as AuthNeedsOnboarding).user
        : (state as AuthAuthenticated).user;

    state = AuthAuthenticated(currentUser.copyWith(interests: interests));
  }

  /// Revoke credentials and reset local state
  Future<void> logout() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      await repository.logout(refreshToken: refreshToken);
    } catch (_) {
      // Ignore network failure on logout
    } finally {
      await storage.clearAll();
      await prefs.setHasSession(false);
      state = const AuthUnauthenticated();
    }
  }
}
