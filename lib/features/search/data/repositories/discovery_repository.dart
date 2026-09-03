import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(dio: ref.watch(dioClientProvider));
});

class DiscoveryRepository {
  final Dio dio;

  DiscoveryRepository({required this.dio});

  Future<DiscoveryPage<PostModel>> getDiscoverPosts({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.discoverFeed,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data as Map<String, dynamic>;
      return _page(data, (json) => PostModel.fromJson(json), limit, offset);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<DiscoveryPage<DiscoverUserModel>> getRecommendedUsers({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.recommendUsers,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return _page(
        response.data as Map<String, dynamic>,
        DiscoverUserModel.fromJson,
        limit,
        offset,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<DiscoveryPage<DiscoverCommunityModel>> getRecommendedCommunities({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.recommendCommunities,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return _page(
        response.data as Map<String, dynamic>,
        DiscoverCommunityModel.fromJson,
        limit,
        offset,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<UnifiedDiscoverySearch> searchAll(
    String query, {
    int limit = 6,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.search,
        queryParameters: {
          'q': query,
          'type': DiscoverSearchCategory.all.apiValue,
          'limit': limit,
          'offset': 0,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return UnifiedDiscoverySearch(
        query: data['query'] as String? ?? query,
        users: _items(data, 'users').map(DiscoverUserModel.fromJson).toList(),
        communities: _items(
          data,
          'communities',
        ).map(DiscoverCommunityModel.fromJson).toList(),
        posts: _items(data, 'posts').map(postFromSearchJson).toList(),
        interests: _items(
          data,
          'interests',
        ).map(DiscoverInterestModel.fromJson).toList(),
        totalResults: (data['total_results'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<DiscoveryPage<dynamic>> searchCategory(
    String query,
    DiscoverSearchCategory category, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.search,
        queryParameters: {
          'q': query,
          'type': category.apiValue,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data as Map<String, dynamic>;
      switch (category) {
        case DiscoverSearchCategory.users:
          return _page(data, DiscoverUserModel.fromJson, limit, offset);
        case DiscoverSearchCategory.communities:
          return _page(data, DiscoverCommunityModel.fromJson, limit, offset);
        case DiscoverSearchCategory.posts:
          return _page(data, postFromSearchJson, limit, offset);
        case DiscoverSearchCategory.interests:
          return _page(data, DiscoverInterestModel.fromJson, limit, offset);
        case DiscoverSearchCategory.all:
          throw ArgumentError('Use searchAll for the All category.');
      }
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> followUser(String userId) async {
    try {
      await dio.post(ApiEndpoints.followUser(userId));
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await dio.delete(ApiEndpoints.followUser(userId));
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<bool> joinCommunity(String communityId) async {
    try {
      final response = await dio.post(ApiEndpoints.joinCommunity(communityId));
      final data = response.data as Map<String, dynamic>? ?? const {};
      return data['status'] == 'pending' ||
          data['join_request_status'] == 'pending';
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    try {
      await dio.delete(ApiEndpoints.leaveCommunity(communityId));
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<bool> likePost(String postId, {required bool like}) async {
    try {
      if (like) {
        await dio.post(ApiEndpoints.likePost(postId));
      } else {
        await dio.delete(ApiEndpoints.likePost(postId));
      }
      return like;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<bool> savePost(String postId, {required bool save}) async {
    try {
      if (save) {
        await dio.post(ApiEndpoints.savePost(postId));
      } else {
        await dio.delete(ApiEndpoints.savePost(postId));
      }
      return save;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<String> sharePost(String postId) async {
    try {
      final response = await dio.post(ApiEndpoints.sharePost(postId));
      return (response.data as Map<String, dynamic>?)?['share_url']
              as String? ??
          'https://genzmedia.app/posts/$postId';
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  DiscoveryPage<T> _page<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) parser,
    int fallbackLimit,
    int fallbackOffset,
  ) {
    final items = _items(data, 'items').map(parser).toList();
    return DiscoveryPage<T>(
      items: items,
      total: (data['total'] as num?)?.toInt() ?? items.length,
      limit: (data['limit'] as num?)?.toInt() ?? fallbackLimit,
      offset: (data['offset'] as num?)?.toInt() ?? fallbackOffset,
    );
  }

  Iterable<Map<String, dynamic>> _items(Map<String, dynamic> data, String key) {
    return (data[key] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
  }
}
