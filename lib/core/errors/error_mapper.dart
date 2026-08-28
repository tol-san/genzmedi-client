import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Maps Dio and backend errors into friendly, typed [AppException] objects.
abstract class ErrorMapper {
  static AppException fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        final data = response?.data;

        String serverMessage = 'An unexpected server error occurred.';
        Map<String, dynamic>? fieldErrors;

        if (data is Map<String, dynamic>) {
          if (data['detail'] is String) {
            serverMessage = data['detail'];
          } else if (data['message'] is String) {
            serverMessage = data['message'];
          } else if (data['detail'] is List) {
            // FastAPI 422 validation error format
            serverMessage = 'Validation failed. Please review your input.';
            fieldErrors = {'errors': data['detail']};
          }
        }

        switch (statusCode) {
          case 401:
            return UnauthorizedException(message: serverMessage);
          case 403:
            return ForbiddenException(message: serverMessage);
          case 404:
            return NotFoundException(message: serverMessage);
          case 422:
            return ValidationException(message: serverMessage, fieldErrors: fieldErrors);
          default:
            return ApiException(message: serverMessage, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'Secure connection certificate failed.');

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: dioException.message ?? 'An unknown error occurred.',
        );
    }
  }
}
