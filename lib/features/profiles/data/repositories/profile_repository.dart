import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/models/relationship_model.dart';

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

  /// Fetch public profile of another user by username
  Future<UserModel> getPublicProfile(String username) async {
    try {
      final response = await dio.get(ApiEndpoints.userProfile(username));
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'User profile not found.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Get directional follow and block relationship status
  Future<RelationshipModel> getRelationship(String userId) async {
    try {
      final response = await dio.get(ApiEndpoints.userRelationship(userId));
      if (response.statusCode == 200 && response.data != null) {
        return RelationshipModel.fromJson(response.data as Map<String, dynamic>);
      }
      return const RelationshipModel();
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Follow a user
  Future<bool> followUser(String userId) async {
    try {
      final response = await dio.post(ApiEndpoints.followUser(userId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['is_following'] as bool? ?? true;
      }
      return true;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String userId) async {
    try {
      final response = await dio.delete(ApiEndpoints.followUser(userId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['is_following'] as bool? ?? false;
      }
      return false;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Block a user
  Future<bool> blockUser(String userId) async {
    try {
      final response = await dio.post(ApiEndpoints.blockUser(userId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['is_blocking'] as bool? ?? true;
      }
      return true;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    try {
      final response = await dio.delete(ApiEndpoints.blockUser(userId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['is_blocking'] as bool? ?? false;
      }
      return false;
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
      if (username != null) data['username'] = username.trim().toLowerCase();
      if (displayName != null) data['display_name'] = displayName.trim();
      if (bio != null) data['bio'] = bio.trim();
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

  /// Fetch interest catalog
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

  /// Update selected interests for authenticated user
  Future<void> updateMyInterests(List<String> interests) async {
    try {
      final response = await dio.put(
        ApiEndpoints.myInterests,
        data: {'interest_ids': interests},
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

  /// Delete current avatar image
  Future<UserModel> deleteAvatar() async {
    try {
      final response = await dio.delete(ApiEndpoints.myAvatar);
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ErrorMapper.fromStatusCode(
        response.statusCode,
        'Failed to delete avatar.',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch followers of a specified user
  Future<List<UserModel>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.userFollowers(userId),
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data
              .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch users followed by a specified user
  Future<List<UserModel>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.userFollowing(userId),
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data
              .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Submit a moderation report against a user, post, comment, etc.
  Future<void> submitReport({
    required String reportType,
    required String targetId,
    required String reason,
    String? description,
    String? communityId,
  }) async {
    try {
      final data = <String, dynamic>{
        'report_type': reportType,
        'target_id': targetId,
        'reason': reason,
      };
      if (description != null && description.isNotEmpty) {
        data['description'] = description.trim();
      }
      if (communityId != null && communityId.isNotEmpty) {
        data['community_id'] = communityId;
      }

      final response = await dio.post(
        ApiEndpoints.reports,
        data: data,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ErrorMapper.fromStatusCode(
          response.statusCode,
          'Failed to submit report.',
        );
      }
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
