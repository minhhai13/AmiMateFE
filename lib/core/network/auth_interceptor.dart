import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

typedef UnauthorizedCallback = void Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStorage, required this.onUnauthorized});

  final TokenStorage tokenStorage;
  final UnauthorizedCallback onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicAuthEndpoint(options)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final token = await tokenStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      options.headers.remove('Authorization');
    } else {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final hasToken = err.requestOptions.headers['Authorization'] != null;
    if (err.response?.statusCode == 401 &&
        hasToken &&
        !_isPublicAuthEndpoint(err.requestOptions)) {
      try {
        await tokenStorage.deleteToken();
      } finally {
        onUnauthorized();
      }
    }

    handler.next(err);
  }

  bool _isPublicAuthEndpoint(RequestOptions options) {
    final segments = options.uri.pathSegments;
    if (segments.length < 2 || segments[segments.length - 2] != 'auth') {
      return false;
    }
    final endpoint = segments.last;
    return endpoint == 'login' || endpoint == 'register';
  }
}
