import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/posts/data/models/post_models.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PostRepository(dio: dio);
});

class PostRepository {
  final Dio dio;

  PostRepository({required this.dio});

  /// Retrieve single post details
  Future<PostModel> getPost(String postId) async {
    try {
      final response = await dio.get(ApiEndpoints.postDetail(postId));
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Create a new post (text, image, video)
  Future<PostModel> createPost(PostCreateRequestModel request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.posts,
        data: request.toJson(),
      );
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Upload media asset (image / video) to MinIO
  Future<MediaUploadModel> uploadMedia(File file, {String? mediaType}) async {
    try {
      final fileName = file.path.split('/').last.split(r'\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        ApiEndpoints.uploadMedia,
        data: formData,
      );

      return MediaUploadModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    try {
      await dio.delete(ApiEndpoints.postDetail(postId));
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Like post
  Future<bool> likePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.likePost(postId));
      return (response.data['liked'] as bool?) ?? true;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Unlike post
  Future<bool> unlikePost(String postId) async {
    try {
      final response = await dio.delete(ApiEndpoints.likePost(postId));
      return (response.data['liked'] as bool?) ?? false;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Save post
  Future<bool> savePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.savePost(postId));
      return (response.data['saved'] as bool?) ?? true;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Unsave post
  Future<bool> unsavePost(String postId) async {
    try {
      final response = await dio.delete(ApiEndpoints.savePost(postId));
      return (response.data['saved'] as bool?) ?? false;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// Share post
  Future<String> sharePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.sharePost(postId));
      return response.data['share_url'] as String? ??
          'https://genzmedia.app/posts/$postId';
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
