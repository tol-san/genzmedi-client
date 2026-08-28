import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';
import 'auth_state.dart';
import 'token_model.dart';
import 'user_model.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);

  return AuthNotifier(
    dio: dio,
    storage: storage,
    prefs: prefs,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio dio;
  final SecureStorageService storage;
  final PreferencesService prefs;

  AuthNotifier({
    required this.dio,
    required this.storage,
    required this.prefs,
  }) : super(const AuthInitial()) {
    checkSession();
  }

  /// Verifies if a stored session exists and loads profile.
  Future<void> checkSession() async {
    try {
      final token = await storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = const AuthUnauthenticated();
        return;
      }

      // Fetch active user profile
      final response = await dio.get(ApiEndpoints.myProfile);
      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        if (user.interests.isEmpty && !prefs.isOnboardingCompleted()) {
          state = AuthNeedsOnboarding(user);
        } else {
          state = AuthAuthenticated(user);
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      // In case offline, try to rely on stored user or unauthenticated
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email/username and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokenModel = TokenModel.fromJson(response.data as Map<String, dynamic>);
        await storage.saveTokens(
          accessToken: tokenModel.accessToken,
          refreshToken: tokenModel.refreshToken,
        );

        // Fetch user profile after authentication
        final profileRes = await dio.get(ApiEndpoints.myProfile);
        final user = UserModel.fromJson(profileRes.data as Map<String, dynamic>);

        if (user.interests.isEmpty && !prefs.isOnboardingCompleted()) {
          state = AuthNeedsOnboarding(user);
        } else {
          state = AuthAuthenticated(user);
        }
      } else {
        state = const AuthUnauthenticated(message: 'Invalid credentials.');
      }
    } on DioException catch (e) {
      final appEx = ErrorMapper.fromDioException(e);
      state = AuthUnauthenticated(message: appEx.message);
      throw appEx;
    } catch (e) {
      state = AuthUnauthenticated(message: e.toString());
      throw ApiException(message: e.toString());
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
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['access_token'] != null) {
          final tokenModel = TokenModel.fromJson(response.data as Map<String, dynamic>);
          await storage.saveTokens(
            accessToken: tokenModel.accessToken,
            refreshToken: tokenModel.refreshToken,
          );
          final user = UserModel(id: username, username: username, email: email);
          state = AuthNeedsOnboarding(user);
        } else {
          state = const AuthUnauthenticated(message: 'Account created. Please log in.');
        }
      }
    } on DioException catch (e) {
      final appEx = ErrorMapper.fromDioException(e);
      state = AuthUnauthenticated(message: appEx.message);
      throw appEx;
    } catch (e) {
      state = AuthUnauthenticated(message: e.toString());
      throw ApiException(message: e.toString());
    }
  }

  /// Complete interest onboarding
  Future<void> completeOnboarding(List<String> interests) async {
    if (state is! AuthNeedsOnboarding && state is! AuthAuthenticated) return;

    try {
      await dio.put(
        ApiEndpoints.myInterests,
        data: {'interests': interests},
      );
      await prefs.setOnboardingCompleted(true);

      final currentUser = (state is AuthNeedsOnboarding)
          ? (state as AuthNeedsOnboarding).user
          : (state as AuthAuthenticated).user;

      state = AuthAuthenticated(currentUser.copyWith(interests: interests));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Clear all stored tokens and session state
  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network failure on logout
    } finally {
      await storage.clearAll();
      state = const AuthUnauthenticated();
    }
  }
}
