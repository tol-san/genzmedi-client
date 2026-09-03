import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CommunityRepository(dio: dio);
});

class CommunityRepository {
  final Dio dio;

  CommunityRepository({required this.dio});

  /// Explore / List communities with optional filters
  Future<List<CommunityModel>> listCommunities({
    String? search,
    String? interestId,
    bool? isPrivate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.communities,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (interestId != null && interestId.isNotEmpty)
            'interest_id': interestId,
          'is_private': ?isPrivate,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Get communities joined by current user
  Future<List<CommunityModel>> getMyJoinedCommunities({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.myJoinedCommunities,
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Retrieve full community details & user membership status
  Future<CommunityDetailModel> getCommunity(String communityId) async {
    try {
      final response = await dio.get(ApiEndpoints.communityDetail(communityId));
      return CommunityDetailModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Create new community (creator becomes Owner)
  Future<CommunityModel> createCommunity(
    CommunityCreateRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.communities,
        data: request.toJson(),
      );
      return CommunityModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Upload community cover banner image
  Future<CommunityModel> uploadCover(String communityId, File file) async {
    try {
      final fileName = file.path.split('/').last.split(r'\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dio.post(
        ApiEndpoints.communityCover(communityId),
        data: formData,
      );
      return CommunityModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Upload community avatar / logo image
  Future<CommunityModel> uploadAvatar(String communityId, File file) async {
    try {
      final fileName = file.path.split('/').last.split(r'\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dio.post(
        ApiEndpoints.communityAvatar(communityId),
        data: formData,
      );
      return CommunityModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Join community (instant for public, creates join request for private)
  Future<Map<String, dynamic>> joinCommunity(String communityId) async {
    try {
      final response = await dio.post(ApiEndpoints.joinCommunity(communityId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Leave community
  Future<void> leaveCommunity(String communityId) async {
    try {
      await dio.delete(ApiEndpoints.leaveCommunity(communityId));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// List members of community
  Future<List<CommunityMemberModel>> listMembers(
    String communityId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.communityMembers(communityId),
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map(
              (e) => CommunityMemberModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Kick member (Owner only)
  Future<void> kickMember(String communityId, String userId) async {
    try {
      await dio.delete(ApiEndpoints.kickCommunityMember(communityId, userId));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// List pending join requests for private community (Owner only)
  Future<List<JoinRequestModel>> listJoinRequests(
    String communityId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.communityJoinRequests(communityId),
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => JoinRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Approve join request (Owner only)
  Future<void> approveJoinRequest(String communityId, String requestId) async {
    try {
      await dio.post(ApiEndpoints.approveJoinRequest(communityId, requestId));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Reject join request (Owner only)
  Future<void> rejectJoinRequest(String communityId, String requestId) async {
    try {
      await dio.post(ApiEndpoints.rejectJoinRequest(communityId, requestId));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch community scoped posts
  Future<List<PostModel>> getCommunityPosts(
    String communityId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.posts,
        queryParameters: {
          'community_id': communityId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
