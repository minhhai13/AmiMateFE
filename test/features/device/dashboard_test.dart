import 'dart:typed_data';

import 'package:amimate/app.dart';
import 'package:amimate/core/network/dio_provider.dart';
import 'package:amimate/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_helpers.dart';

void main() {
  testWidgets('shows devices and opens history for the selected device', (
    tester,
  ) async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _DashboardAdapter([
      (
        statusCode: 200,
        body: '[{"deviceId":"AMI-123456","name":"Robot Ami","createdAt":"2026-10-13T09:00:00.000Z"}]',
      ),
      (
        statusCode: 200,
        body: '{"items":[{"chatId":"session-1","lastMessageAt":"2026-10-13T09:30:00.123Z","turnCount":1}],"page":0,"size":50,"totalElements":1,"hasNext":false}',
      ),
      (
        statusCode: 200,
        body: '{"items":[{"id":1,"deviceId":"AMI-123456","sessionId":"session-1","clientMessageId":"client-1","userMessage":"Hôm nay thời tiết thế nào?","botResponse":"Hôm nay trời nắng nhẹ bé nhé.","createdAt":"2026-10-13T09:30:00.123Z"}],"page":0,"size":50,"totalElements":1,"hasNext":false}',
      ),
    ]);
    final dio = _createDashboardDio(adapter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          dioProvider.overrideWithValue(dio),
        ],
        child: const AmiMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Robot Ami'), findsOneWidget);
    expect(find.text('AMI-123456'), findsOneWidget);
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, 'devices');

    await tester.tap(find.byKey(const Key('device-AMI-123456')));
    await tester.pumpAndSettle();
    expect(find.text('Cuộc trò chuyện session-1'), findsOneWidget);
    expect(adapter.requests.last.path, 'logs/sessions');

    await tester.tap(find.byKey(const Key('chat-session-session-1')));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay thời tiết thế nào?'), findsOneWidget);
    expect(find.text('Hôm nay trời nắng nhẹ bé nhé.'), findsOneWidget);
    expect(adapter.requests.last.path, 'logs');
    expect(adapter.requests.last.queryParameters['deviceId'], 'AMI-123456');
    expect(adapter.requests.last.queryParameters['sessionId'], 'session-1');
    expect(adapter.requests.last.queryParameters['page'], 0);
    expect(adapter.requests.last.queryParameters['size'], 50);

    dio.close(force: true);
  });

  testWidgets('shows empty state and offers device claiming', (tester) async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _DashboardAdapter([(statusCode: 200, body: '[]')]);
    final dio = _createDashboardDio(adapter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          dioProvider.overrideWithValue(dio),
        ],
        child: const AmiMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có thiết bị nào'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-add-device')), findsOneWidget);
    expect(find.text('Thêm thiết bị đầu tiên'), findsOneWidget);
    expect(adapter.requests, hasLength(1));

    await tester.tap(find.text('Thêm thiết bị đầu tiên'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối robot AmiMate'), findsOneWidget);

    dio.close(force: true);
  });

  testWidgets('shows API error and retries device loading', (tester) async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _DashboardAdapter([
      (statusCode: 503, body: '{"detail":"Máy chủ tạm thời không khả dụng."}'),
      (statusCode: 200, body: '[]'),
    ]);
    final dio = _createDashboardDio(adapter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          dioProvider.overrideWithValue(dio),
        ],
        child: const AmiMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thiết bị của tôi'), findsOneWidget);
    expect(find.text('Chưa tải được thiết bị'), findsOneWidget);
    expect(find.text('Máy chủ tạm thời không khả dụng.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('devices-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có thiết bị nào'), findsOneWidget);
    expect(adapter.requests, hasLength(2));

    dio.close(force: true);
  });
}

class _DashboardAdapter implements HttpClientAdapter {
  _DashboardAdapter(this.responses);

  final List<({int statusCode, String body})> responses;
  final List<RequestOptions> requests = [];
  var _responseIndex = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = responses[_responseIndex++];
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _createDashboardDio(_DashboardAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1/'))
    ..httpClientAdapter = adapter;
}
