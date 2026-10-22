import 'dart:typed_data';

import 'package:amimate/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage({this.token});

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

class RecordingAuthAdapter implements HttpClientAdapter {
  RecordingAuthAdapter({
    this.statusCode = 200,
    this.responseJson = '{"token":"test-jwt","expiresInSeconds":86400}',
  });

  final int statusCode;
  final String responseJson;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final responseBody = options.uri.path.endsWith('/devices')
        ? '[]'
        : responseJson;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio createTestDio(RecordingAuthAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1/'))
    ..httpClientAdapter = adapter;
}
