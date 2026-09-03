import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/core/network/interceptors/auth_interceptor.dart';
import 'package:client/core/network/interceptors/logging_interceptor.dart';
import 'package:client/core/storage/secure_storage_service.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.defaultBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(dio: dio, storage: storage),
    LoggingInterceptor(),
  ]);

  return dio;
});
