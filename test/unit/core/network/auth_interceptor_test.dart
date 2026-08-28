import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/network/interceptors/auth_interceptor.dart';
import 'package:client/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockDio extends Mock implements Dio {}
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late MockSecureStorageService mockStorage;
  late MockDio mockDio;
  late AuthInterceptor interceptor;

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
    interceptor = AuthInterceptor(
      dio: mockDio,
      storage: mockStorage,
    );
  });

  group('AuthInterceptor onRequest Tests', () {
    test('attaches Authorization header when accessToken exists on protected routes', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'mock_token_123');
      final options = RequestOptions(path: '/users/me');
      final handler = MockRequestInterceptorHandler();

      when(() => handler.next(options)).thenReturn(null);

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer mock_token_123');
      verify(() => handler.next(options)).called(1);
    });

    test('does NOT attach Authorization header on /auth/login', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'mock_token_123');
      final options = RequestOptions(path: '/auth/login');
      final handler = MockRequestInterceptorHandler();

      when(() => handler.next(options)).thenReturn(null);

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('does NOT attach Authorization header when accessToken is null', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
      final options = RequestOptions(path: '/posts/feed');
      final handler = MockRequestInterceptorHandler();

      when(() => handler.next(options)).thenReturn(null);

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });
  });

  group('AuthInterceptor onError Tests', () {
    test('triggers onSessionExpired when 401 occurs and refresh token is null', () async {
      bool sessionExpiredCalled = false;
      interceptor = AuthInterceptor(
        dio: mockDio,
        storage: mockStorage,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/posts/feed'),
        response: Response(
          requestOptions: RequestOptions(path: '/posts/feed'),
          statusCode: 401,
        ),
      );
      final handler = MockErrorInterceptorHandler();
      when(() => handler.next(dioErr)).thenReturn(null);

      await interceptor.onError(dioErr, handler);

      expect(sessionExpiredCalled, isTrue);
      verify(() => mockStorage.clearAll()).called(1);
      verify(() => handler.next(dioErr)).called(1);
    });
  });
}
