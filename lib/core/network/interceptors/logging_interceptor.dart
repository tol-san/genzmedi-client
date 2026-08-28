import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Secure debug logger for HTTP network requests with token/password redaction.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ [DIO REQ] ${options.method} ${options.uri}');
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = 'Bearer [REDACTED]';
      }
      debugPrint('   Headers: $sanitizedHeaders');
      if (options.data != null) {
        var dataString = options.data.toString();
        if (dataString.contains('password')) {
          dataString = '[REDACTED DATA CONTAINING PASSWORD]';
        }
        debugPrint('   Body: $dataString');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('⬅️ [DIO RES] ${response.statusCode} ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('❌ [DIO ERR] ${err.response?.statusCode} ${err.requestOptions.uri} - ${err.message}');
    }
    super.onError(err, handler);
  }
}
