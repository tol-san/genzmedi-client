import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/posts/data/models/post_models.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return FeedRepository(dio: dio);
});

class FeedRepository {
  final Dio dio;

  FeedRepository({required this.dio});

  /// Fetch personalized home feed
  Future<List<PostModel>> getHomeFeed({int limit = 20, int offset = 0}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.homeFeed,
        queryParameters: {'limit': limit, 'offset': offset},
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

  /// Fetch vertical short video feed
  Future<List<PostModel>> getShortsFeed({int limit = 20, int offset = 0}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.shortsFeed,
        queryParameters: {'limit': limit, 'offset': offset},
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

  /// Like a post (idempotent)
  Future<bool> likePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.likePost(postId));
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['is_liked'] as bool?) ?? true;
      }
      return true;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Remove like from a post
  Future<bool> unlikePost(String postId) async {
    try {
      final response = await dio.delete(ApiEndpoints.likePost(postId));
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['is_liked'] as bool?) ?? false;
      }
      return false;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Save / bookmark a post
  Future<bool> savePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.savePost(postId));
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['is_saved'] as bool?) ?? true;
      }
      return true;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Remove save / bookmark from a post
  Future<bool> unsavePost(String postId) async {
    try {
      final response = await dio.delete(ApiEndpoints.savePost(postId));
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['is_saved'] as bool?) ?? false;
      }
      return false;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Share a post and increment share count
  Future<String> sharePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.sharePost(postId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['share_url'] as String? ??
            'https://genzmedia.app/posts/$postId';
      }
      return 'https://genzmedia.app/posts/$postId';
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
