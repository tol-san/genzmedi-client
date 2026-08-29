import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/posts/data/models/comment_model.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CommentRepository(dio: dio);
});

class CommentRepository {
  final Dio dio;

  CommentRepository({required this.dio});

  /// Fetch top-level comments on a post
  Future<List<CommentModel>> getComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.postComments(postId),
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Fetch nested replies under a comment
  Future<List<CommentModel>> getReplies(
    String commentId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.commentReplies(commentId),
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items
            .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Create top-level comment or nested reply
  Future<CommentModel> createComment(
    String postId, {
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.postComments(postId),
        data: {
          'content': content,
          if (parentId != null && parentId.isNotEmpty) 'parent_id': parentId,
        },
      );
      return CommentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Update comment content
  Future<CommentModel> updateComment(
    String commentId, {
    required String content,
  }) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.commentDetail(commentId),
        data: {'content': content},
      );
      return CommentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      await dio.delete(ApiEndpoints.commentDetail(commentId));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
