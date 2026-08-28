import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/auth/data/models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRepository(dio: dio);
});

class AuthRepository {
  final Dio dio;

  AuthRepository({required this.dio});

  /// Authenticate user credentials and return access + refresh tokens
  Future<TokenModel> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return TokenModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'Invalid login response from server.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Register a new account
  Future<TokenModel?> register(RegisterRequest request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['access_token'] != null) {
          return TokenModel.fromJson(response.data as Map<String, dynamic>);
        }
        return null;
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'Registration failed.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Revoke session and logout
  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      // Non-fatal if session is already expired
      ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch the authenticated user's profile
  Future<UserModel> getMyProfile() async {
    try {
      final response = await dio.get(ApiEndpoints.myProfile);
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'Failed to fetch user profile.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch available platform interest categories for onboarding
  Future<List<InterestModel>> getInterests() async {
    try {
      final response = await dio.get(ApiEndpoints.interests);
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data;
        if (list is List) {
          return list
              .map((item) => InterestModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (list is Map && list['items'] is List) {
          return (list['items'] as List)
              .map((item) => InterestModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Save selected interests for the current user
  Future<void> updateMyInterests(List<String> interests) async {
    try {
      final response = await dio.put(
        ApiEndpoints.myInterests,
        data: {'interests': interests},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ErrorMapper.fromStatusCode(
          response.statusCode,
          'Failed to update user interests.',
        );
      }
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Request password reset email
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.forgotPassword,
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 202) {
        throw ErrorMapper.fromStatusCode(
          response.statusCode,
          'Failed to process password reset request.',
        );
      }
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Reset password with verification token
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.resetPassword,
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ErrorMapper.fromStatusCode(
          response.statusCode,
          'Password reset failed. Invalid or expired token.',
        );
      }
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
