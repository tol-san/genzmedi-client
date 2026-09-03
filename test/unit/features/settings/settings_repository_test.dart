import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SettingsRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = SettingsRepository(dio: mockDio);
  });

  group('SettingsRepository Unit Tests', () {
    test('changePassword posts correct body to changePassword endpoint', () async {
      when(() => mockDio.post(
            ApiEndpoints.changePassword,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiEndpoints.changePassword),
            statusCode: 200,
            data: {'message': 'Password changed successfully.'},
          ));

      await repository.changePassword(
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
      );

      verify(() => mockDio.post(
            ApiEndpoints.changePassword,
            data: {
              'current_password': 'oldPassword123',
              'new_password': 'newPassword123',
            },
          )).called(1);
    });

    test('changePassword throws ApiException on 400 bad request', () async {
      when(() => mockDio.post(
            ApiEndpoints.changePassword,
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.changePassword),
        response: Response(
          requestOptions: RequestOptions(path: ApiEndpoints.changePassword),
          statusCode: 400,
          data: {'detail': 'Incorrect current password'},
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () => repository.changePassword(
          currentPassword: 'wrongPassword',
          newPassword: 'newPassword123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('getBlockedUsers returns BlockedUsersPage on 200', () async {
      when(() => mockDio.get(
            ApiEndpoints.myBlockedUsers,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiEndpoints.myBlockedUsers),
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'user-1',
                  'username': 'troll_user',
                  'email': 'troll@example.com',
                  'display_name': 'Troll',
                  'avatar_url': 'https://example.com/avatar.jpg',
                }
              ],
              'total': 1,
              'limit': 20,
              'offset': 0,
            },
          ));

      final page = await repository.getBlockedUsers();

      expect(page.items.length, 1);
      expect(page.items.first.username, 'troll_user');
      expect(page.total, 1);
      expect(page.hasMore, isFalse);
    });

    test('unblockUser sends DELETE to block endpoint', () async {
      final endpoint = ApiEndpoints.blockUser('user-1');
      when(() => mockDio.delete(endpoint)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: endpoint),
            statusCode: 200,
            data: {'message': 'Unblocked'},
          ));

      await repository.unblockUser('user-1');

      verify(() => mockDio.delete(endpoint)).called(1);
    });
  });
}
