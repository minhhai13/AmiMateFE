import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../core/storage/token_storage.dart';
import 'api_configuration.dart';
import 'auth_interceptor.dart';

final apiConfigurationProvider = Provider<ApiConfiguration>((ref) {
  return ApiConfiguration.fromEnvironment();
});

final dioProvider = Provider<Dio>((ref) {
  final configuration = ref.watch(apiConfigurationProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: configuration.dioBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      onUnauthorized: () =>
          ref.read(authControllerProvider.notifier).sessionExpired(),
    ),
  );

  ref.onDispose(() => dio.close(force: true));
  return dio;
});
