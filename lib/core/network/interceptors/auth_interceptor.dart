import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../storage/secure_storage_service.dart';
import '../api_endpoints.dart';

/// Interceptor that attaches the Bearer token to outgoing requests and
/// coordinates concurrent 401 token refresh with request queueing.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStorageService storage;
  final VoidCallback? onSessionExpired;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required this.dio,
    required this.storage,
    this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid attaching authorization to unauthenticated auth routes
    final isAuthRoute = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh');

    if (!isAuthRoute) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isAuthRoute = err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/register') ||
        err.requestOptions.path.contains('/auth/refresh');

    if (response?.statusCode == 401 && !isAuthRoute) {
      try {
        final newToken = await _refreshTokenSynchronized();
        if (newToken != null) {
          // Retry the original request with new token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final clonedResponse = await dio.fetch(requestOptions);
          return handler.resolve(clonedResponse);
        } else {
          _handleSessionExpired();
          return handler.next(err);
        }
      } catch (refreshError) {
        _handleSessionExpired();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshTokenSynchronized() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter?.complete(null);
        return null;
      }

      // Use a clean Dio instance to avoid interceptor recursion
      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['access_token'] as String;
        final newRefreshToken = (response.data['refresh_token'] as String?) ?? refreshToken;

        await storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _refreshCompleter?.complete(newAccessToken);
        return newAccessToken;
      } else {
        _refreshCompleter?.complete(null);
        return null;
      }
    } catch (_) {
      _refreshCompleter?.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  void _handleSessionExpired() {
    storage.clearAll();
    onSessionExpired?.call();
  }
}
