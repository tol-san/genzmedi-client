import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = AuthRepository(dio: mockDio);
  });

  group('AuthRepository Unit Tests', () {
    test('login returns TokenModel when backend returns 200', () async {
      when(() => mockDio.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiEndpoints.login),
            statusCode: 200,
            data: {
              'access_token': 'access_token_jwt_123',
              'refresh_token': 'refresh_token_jwt_456',
              'token_type': 'Bearer',
            },
          ));

      final result = await repository.login(
        const LoginRequest(username: 'sovandara', password: 'password123'),
      );

      expect(result, isA<TokenModel>());
      expect(result.accessToken, 'access_token_jwt_123');
      expect(result.refreshToken, 'refresh_token_jwt_456');
    });

    test('login throws UnauthorizedException when backend returns 401', () async {
      when(() => mockDio.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.login),
        response: Response(
          requestOptions: RequestOptions(path: ApiEndpoints.login),
          statusCode: 401,
          data: {'detail': 'Incorrect username or password'},
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () => repository.login(
          const LoginRequest(username: 'sovandara', password: 'wrongpassword'),
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('register returns TokenModel when backend returns 201 with tokens', () async {
      when(() => mockDio.post(
            ApiEndpoints.register,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiEndpoints.register),
            statusCode: 201,
            data: {
              'access_token': 'new_user_token',
              'refresh_token': 'new_user_refresh',
              'token_type': 'Bearer',
            },
          ));

      final result = await repository.register(
        const RegisterRequest(
          username: 'sovandara',
          email: 'sovandara@example.com',
          password: 'password123',
        ),
      );

      expect(result, isA<TokenModel>());
      expect(result!.accessToken, 'new_user_token');
    });

    test('getMyProfile returns valid UserModel', () async {
      when(() => mockDio.get(ApiEndpoints.myProfile)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.myProfile),
          statusCode: 200,
          data: {
            'id': 'user-1',
            'username': 'sovandara',
            'email': 'sovandara@example.com',
            'interests': ['Anime', 'Tech'],
          },
        ),
      );

      final user = await repository.getMyProfile();
      expect(user.id, 'user-1');
      expect(user.username, 'sovandara');
      expect(user.interests, contains('Anime'));
    });

    test('getInterests parses interest catalog correctly', () async {
      when(() => mockDio.get(ApiEndpoints.interests)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.interests),
          statusCode: 200,
          data: [
            {'id': '1', 'name': 'Anime', 'slug': 'anime', 'icon': '⚡'},
            {'id': '2', 'name': 'Gaming', 'slug': 'gaming', 'icon': '🎮'},
          ],
        ),
      );

      final list = await repository.getInterests();
      expect(list.length, 2);
      expect(list[0].slug, 'anime');
      expect(list[1].name, 'Gaming');
    });
  });
}
