import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/posts/data/models/post_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProfileRepository(dio: dio);
});

class ProfileRepository {
  final Dio dio;

  ProfileRepository({required this.dio});

  /// Fetch authenticated user's profile and stats
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

  /// Update user display name, bio, and avatar
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (displayName != null) data['display_name'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await dio.patch(
        ApiEndpoints.myProfile,
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'Failed to update profile.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Upload new avatar image file
  Future<UserModel> uploadAvatar(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        ApiEndpoints.myAvatar,
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'Failed to upload avatar.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch posts created by a specific user or current user
  Future<List<PostModel>> getUserPosts({
    required String authorId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.posts,
        queryParameters: {
          'author_id': authorId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data
              .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch bookmarked / saved posts for authenticated user
  Future<List<PostModel>> getSavedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.savedPosts,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data
              .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
