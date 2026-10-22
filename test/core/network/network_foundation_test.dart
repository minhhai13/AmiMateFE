import 'dart:typed_data';

import 'package:amimate/core/network/api_configuration.dart';
import 'package:amimate/core/network/api_failure.dart';
import 'package:amimate/core/network/auth_interceptor.dart';
import 'package:amimate/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfiguration', () {
    test('normalizes the API base URL for relative endpoint paths', () {
      const configuration = ApiConfiguration(
        baseUrl: 'http://localhost:8080/api/v1///',
      );

      expect(configuration.dioBaseUrl, 'http://localhost:8080/api/v1/');
    });

    test('rejects invalid or incomplete base URLs', () {
      const configuration = ApiConfiguration(baseUrl: 'localhost:8080/api/v1');

      expect(() => configuration.dioBaseUrl, throwsStateError);
    });
  });

  group('ApiFailure', () {
    test('parses Problem Details and field validation errors', () {
      final failure = ApiFailure.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: 'devices/claim'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: 'devices/claim'),
            statusCode: 400,
            data: {
              'type': 'about:blank',
              'title': 'Bad Request',
              'status': 400,
              'detail': 'Dữ liệu không hợp lệ',
              'errors': {'pinCode': 'Mã PIN phải đúng 6 chữ số'},
            },
          ),
        ),
      );

      expect(failure.kind, ApiFailureKind.client);
      expect(failure.statusCode, 400);
      expect(failure.title, 'Bad Request');
      expect(failure.message, 'Dữ liệu không hợp lệ');
      expect(failure.fieldErrors['pinCode'], 'Mã PIN phải đúng 6 chữ số');
    });

    test(
      'provides a localized network error when no server response exists',
      () {
        final failure = ApiFailure.fromDioException(
          DioException(
            requestOptions: RequestOptions(path: 'devices'),
            type: DioExceptionType.connectionError,
          ),
        );

        expect(failure.kind, ApiFailureKind.network);
        expect(failure.message, contains('Không thể kết nối máy chủ'));
      },
    );

    test('uses the HTTP status fallback when the server returns no detail', () {
      final failure = ApiFailure.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: 'devices'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: 'devices'),
            statusCode: 401,
          ),
        ),
      );

      expect(failure.message, contains('Phiên đăng nhập đã hết hạn'));
    });
  });

  group('AuthInterceptor', () {
    test('adds a bearer token to protected requests', () async {
      final storage = _MemoryTokenStorage('jwt-value');
      final adapter = _RecordingAdapter();
      final dio = _createDio(storage, adapter);

      await dio.get<void>('devices');

      expect(adapter.authorizationHeaders, ['Bearer jwt-value']);
      dio.close(force: true);
    });

    test('does not send the token to login or register endpoints', () async {
      final storage = _MemoryTokenStorage('jwt-value');
      final adapter = _RecordingAdapter();
      final dio = _createDio(storage, adapter);

      await dio.post<void>('auth/login');
      await dio.post<void>('auth/register');

      expect(adapter.authorizationHeaders, [null, null]);
      dio.close(force: true);
    });

    test(
      'clears the session and notifies once for an authenticated 401',
      () async {
        final storage = _MemoryTokenStorage('expired-token');
        final adapter = _RecordingAdapter(statusCode: 401);
        var unauthorizedCount = 0;
        final dio = _createDio(
          storage,
          adapter,
          onUnauthorized: () => unauthorizedCount++,
        );

        await expectLater(
          dio.get<void>('devices'),
          throwsA(isA<DioException>()),
        );

        expect(storage.token, isNull);
        expect(unauthorizedCount, 1);
        dio.close(force: true);
      },
    );

    test('does not clear a session for invalid login credentials', () async {
      final storage = _MemoryTokenStorage('existing-token');
      final adapter = _RecordingAdapter(statusCode: 401);
      var unauthorizedCount = 0;
      final dio = _createDio(
        storage,
        adapter,
        onUnauthorized: () => unauthorizedCount++,
      );

      await expectLater(
        dio.post<void>('auth/login'),
        throwsA(isA<DioException>()),
      );

      expect(storage.token, 'existing-token');
      expect(unauthorizedCount, 0);
      dio.close(force: true);
    });
  });
}

Dio _createDio(
  TokenStorage storage,
  _RecordingAdapter adapter, {
  UnauthorizedCallback? onUnauthorized,
}) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1/'))
    ..httpClientAdapter = adapter
    ..interceptors.add(
      AuthInterceptor(
        tokenStorage: storage,
        onUnauthorized: onUnauthorized ?? () {},
      ),
    );
}

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage(this.token);

  String? token;

  @override
  Future<void> deleteToken() async {
    token = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200});

  final int statusCode;
  final List<String?> authorizationHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizationHeaders.add(options.headers['Authorization'] as String?);
    return ResponseBody.fromString(
      statusCode == 401 ? '{"detail":"Unauthorized"}' : '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
