import 'package:equatable/equatable.dart';

/// Base sealed class for all application and domain errors.
abstract class AppException extends Equatable implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';
}

/// Network connectivity / DNS / timeout error
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Unable to connect to server. Please check your internet connection.',
    super.statusCode,
  });
}

/// Generic backend HTTP 4xx/5xx API exception
class ApiException extends AppException {
  const ApiException({
    required super.message,
    super.statusCode,
  });
}

/// 401 Unauthorized — Session expired or invalid credentials
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    String message = 'Your session has expired. Please sign in again.',
  ]) : super(
          message: message,
          statusCode: 401,
        );
}

/// 403 Forbidden — Insufficient permissions
class ForbiddenException extends AppException {
  const ForbiddenException([
    String message = 'You do not have permission to perform this action.',
  ]) : super(
          message: message,
          statusCode: 403,
        );
}

/// 404 Not Found — Entity deleted or not found
class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'The requested content was not found.',
  ]) : super(
          message: message,
          statusCode: 404,
        );
}

/// 422 Unprocessable Entity — Field-level validation failure
class ValidationException extends AppException {
  final Map<String, dynamic>? fieldErrors;

  const ValidationException({
    super.message = 'Please check the highlighted fields.',
    super.statusCode = 422,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

/// Unhandled or generic runtime exception
class UnknownException extends AppException {
  const UnknownException([
    String message = 'An unexpected error occurred.',
  ]) : super(message: message);
}
