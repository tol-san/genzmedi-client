import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProfileRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = ProfileRepository(dio: mockDio);
  });

  group('ProfileRepository Unit Tests', () {
    test('getMyProfile returns UserModel on successful 200 response', () async {
      final responseData = {
        'id': 'u-123',
        'username': 'creator_alex',
        'email': 'alex@example.com',
        'display_name': 'Alex Creator',
        'bio': 'GenZ tech & digital art enthusiast',
        'avatar_url': 'https://example.com/avatar.webp',
        'follower_count': 120,
        'following_count': 45,
        'post_count': 8,
        'is_verified': true,
        'interests': ['gaming', 'coding'],
      };

      when(() => mockDio.get(ApiEndpoints.myProfile)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.myProfile),
          statusCode: 200,
          data: responseData,
        ),
      );

      final UserModel result = await repository.getMyProfile();

      expect(result.id, 'u-123');
      expect(result.username, 'creator_alex');
      expect(result.displayName, 'Alex Creator');
      expect(result.followersCount, 120);
      expect(result.followingCount, 45);
      expect(result.postCount, 8);
      expect(result.isVerified, true);
    });

    test('getUserPosts returns list of PostModel on 200 response', () async {
      final responseData = {
        'items': [
          {
            'id': 'p-1',
            'author': {
              'id': 'u-123',
              'username': 'creator_alex',
              'display_name': 'Alex Creator',
            },
            'post_type': 'image',
            'title': 'My Latest Artwork',
            'content': 'Check out this design!',
            'visibility': 'public',
            'media': [
              {
                'id': 'm-1',
                'media_type': 'image',
                'url': 'https://example.com/art.webp',
              }
            ],
            'like_count': 15,
            'comment_count': 3,
          }
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      };

      when(() => mockDio.get(
            ApiEndpoints.posts,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.posts),
          statusCode: 200,
          data: responseData,
        ),
      );

      final List<PostModel> posts = await repository.getUserPosts(authorId: 'u-123');

      expect(posts.length, 1);
      expect(posts.first.id, 'p-1');
      expect(posts.first.title, 'My Latest Artwork');
      expect(posts.first.likeCount, 15);
      expect(posts.first.media.first.url, 'https://example.com/art.webp');
    });

    test('getSavedPosts returns list of saved PostModel', () async {
      final responseData = {
        'items': [
          {
            'id': 'p-saved-1',
            'author': {
              'id': 'u-456',
              'username': 'designer_sam',
            },
            'post_type': 'text',
            'content': 'Top 10 Flutter UI tips',
            'visibility': 'public',
            'like_count': 88,
            'comment_count': 12,
          }
        ],
        'total': 1,
      };

      when(() => mockDio.get(
            ApiEndpoints.savedPosts,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.savedPosts),
          statusCode: 200,
          data: responseData,
        ),
      );

      final List<PostModel> saved = await repository.getSavedPosts();

      expect(saved.length, 1);
      expect(saved.first.id, 'p-saved-1');
      expect(saved.first.content, 'Top 10 Flutter UI tips');
    });

    test('getMyProfile throws mapped AppException on DioException error', () async {
      when(() => mockDio.get(ApiEndpoints.myProfile)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.myProfile),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.myProfile),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () async => await repository.getMyProfile(),
        throwsA(isA<AppException>()),
      );
    });
  });
}
