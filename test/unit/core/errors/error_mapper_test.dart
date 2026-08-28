import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/errors/error_mapper.dart';

void main() {
  group('ErrorMapper Unit Tests', () {
    group('fromStatusCode', () {
      test('maps 401 to UnauthorizedException', () {
        final err = ErrorMapper.fromStatusCode(401, 'Invalid credentials');
        expect(err, isA<UnauthorizedException>());
        expect(err.message, 'Invalid credentials');
      });

      test('maps 403 to ForbiddenException', () {
        final err = ErrorMapper.fromStatusCode(403, 'Forbidden');
        expect(err, isA<ForbiddenException>());
        expect(err.message, 'Forbidden');
      });

      test('maps 404 to NotFoundException', () {
        final err = ErrorMapper.fromStatusCode(404, 'User not found');
        expect(err, isA<NotFoundException>());
        expect(err.message, 'User not found');
      });

      test('maps 422 to ValidationException', () {
        final err = ErrorMapper.fromStatusCode(422, 'Invalid input');
        expect(err, isA<ValidationException>());
        expect(err.message, 'Invalid input');
      });

      test('maps 500 to ApiException with statusCode', () {
        final err = ErrorMapper.fromStatusCode(500, 'Server crashed');
        expect(err, isA<ApiException>());
        expect((err as ApiException).statusCode, 500);
      });
    });

    group('fromDioException', () {
      test('maps connection timeout to NetworkException', () {
        final dioErr = DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          type: DioExceptionType.connectionTimeout,
        );
        final err = ErrorMapper.fromDioException(dioErr);
        expect(err, isA<NetworkException>());
      });

      test('maps connectionError to NetworkException', () {
        final dioErr = DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          type: DioExceptionType.connectionError,
        );
        final err = ErrorMapper.fromDioException(dioErr);
        expect(err, isA<NetworkException>());
      });

      test('extracts detail string from badResponse', () {
        final dioErr = DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/auth/login'),
            statusCode: 401,
            data: {'detail': 'Invalid email or password.'},
          ),
        );
        final err = ErrorMapper.fromDioException(dioErr);
        expect(err, isA<UnauthorizedException>());
        expect(err.message, 'Invalid email or password.');
      });

      test('parses FastAPI 422 validation detail array', () {
        final dioErr = DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/auth/register'),
            statusCode: 422,
            data: {
              'detail': [
                {'loc': ['body', 'password'], 'msg': 'Password too short'}
              ]
            },
          ),
        );
        final err = ErrorMapper.fromDioException(dioErr);
        expect(err, isA<ValidationException>());
        expect((err as ValidationException).fieldErrors, isNotNull);
      });
    });
  });
}
