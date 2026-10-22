import 'dart:typed_data';

import 'package:amimate/app.dart';
import 'package:amimate/core/network/dio_provider.dart';
import 'package:amimate/core/storage/token_storage.dart';
import 'package:amimate/features/device/data/models/claim_device_request.dart';
import 'package:amimate/features/device/data/repositories/device_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_helpers.dart';

void main() {
  test('claim request trims and uppercases the Device ID', () {
    const request = ClaimDeviceRequest(
      deviceId: ' ami-123456 ',
      pinCode: '001234',
    );

    expect(request.toJson(), {'deviceId': 'AMI-123456', 'pinCode': '001234'});
  });

  test(
    'repository posts claim payload and parses its DeviceResponse',
    () async {
      final adapter = _ClaimApiAdapter([
        _ApiResponse(
          method: 'POST',
          path: '/devices/claim',
          statusCode: 200,
          body: '{"deviceId":"AMI-123456","name":"AmiMate","createdAt":"2026-10-13T09:00:00.000Z"}',
        ),
      ]);
      final dio = _createDio(adapter);
      addTearDown(() => dio.close(force: true));

      final device = await DeviceRepository(dio).claimDevice(
        const ClaimDeviceRequest(deviceId: ' ami-123456 ', pinCode: '001234'),
      );

      expect(device.deviceId, 'AMI-123456');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, 'devices/claim');
      expect(adapter.requests.single.data, {
        'deviceId': 'AMI-123456',
        'pinCode': '001234',
      });
    },
  );

  testWidgets('invalid input does not submit claim request', (tester) async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _ClaimApiAdapter([
      _ApiResponse(
        method: 'GET',
        path: '/devices',
        statusCode: 200,
        body: '[]',
      ),
    ]);
    final dio = _createDio(adapter);

    await _pumpApp(tester, storage, dio);
    await tester.tap(find.byKey(const Key('dashboard-add-device')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('claim-device-id')), '   ');
    await tester.enterText(find.byKey(const Key('claim-pin-code')), '12345');
    await tester.tap(find.byKey(const Key('claim-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập Device ID.'), findsOneWidget);
    expect(find.text('Mã PIN phải gồm đúng 6 chữ số.'), findsOneWidget);
    expect(adapter.requests, hasLength(1));

    dio.close(force: true);
  });

  testWidgets('claim success returns to dashboard and reloads device list', (
    tester,
  ) async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _ClaimApiAdapter([
      _ApiResponse(
        method: 'GET',
        path: '/devices',
        statusCode: 200,
        body: '[]',
      ),
      _ApiResponse(
        method: 'POST',
        path: '/devices/claim',
        statusCode: 200,
        body: '{"deviceId":"AMI-123456","name":"AmiMate","createdAt":"2026-10-13T09:00:00.000Z"}',
      ),
      _ApiResponse(
        method: 'GET',
        path: '/devices',
        statusCode: 200,
        body: '[{"deviceId":"AMI-123456","name":"AmiMate","createdAt":"2026-10-13T09:00:00.000Z"}]',
      ),
    ]);
    final dio = _createDio(adapter);

    await _pumpApp(tester, storage, dio);
    await tester.tap(find.byKey(const Key('dashboard-add-device')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('claim-device-id')),
      ' ami-123456 ',
    );
    await tester.enterText(find.byKey(const Key('claim-pin-code')), '001234');
    await tester.tap(find.byKey(const Key('claim-submit')));
    await tester.pumpAndSettle();

    expect(find.text('AmiMate'), findsOneWidget);
    expect(find.text('AMI-123456'), findsOneWidget);
    expect(adapter.requests, hasLength(3));
    expect(adapter.requests[1].method, 'POST');
    expect(adapter.requests[1].path, 'devices/claim');
    expect(adapter.requests[1].data, {
      'deviceId': 'AMI-123456',
      'pinCode': '001234',
    });

    dio.close(force: true);
  });

  testWidgets('claim failure shows the API detail and stays on the form', (
    tester,
  ) async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _ClaimApiAdapter([
      _ApiResponse(
        method: 'GET',
        path: '/devices',
        statusCode: 200,
        body: '[]',
      ),
      _ApiResponse(
        method: 'POST',
        path: '/devices/claim',
        statusCode: 409,
        body: '{"type":"about:blank","title":"Conflict","status":409,"detail":"Robot này đã được liên kết với tài khoản khác"}',
      ),
    ]);
    final dio = _createDio(adapter);

    await _pumpApp(tester, storage, dio);
    await tester.tap(find.byKey(const Key('dashboard-add-device')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('claim-device-id')),
      'AMI-123456',
    );
    await tester.enterText(find.byKey(const Key('claim-pin-code')), '001234');
    await tester.tap(find.byKey(const Key('claim-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Thêm thiết bị'), findsOneWidget);
    expect(
      find.text('Robot này đã được liên kết với tài khoản khác'),
      findsOneWidget,
    );
    expect(adapter.requests, hasLength(2));

    dio.close(force: true);
  });

  testWidgets('claim shows the BE detail for invalid PIN and missing device', (
    tester,
  ) async {
    const invalidPinMessage = 'Mã PIN xác thực không chính xác';
    const missingDeviceMessage = 'Không tìm thấy thiết bị này trong hệ thống';
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = _ClaimApiAdapter([
      _ApiResponse(
        method: 'GET',
        path: '/devices',
        statusCode: 200,
        body: '[]',
      ),
      _ApiResponse(
        method: 'POST',
        path: '/devices/claim',
        statusCode: 400,
        body: '{"detail":"$invalidPinMessage"}',
      ),
      _ApiResponse(
        method: 'POST',
        path: '/devices/claim',
        statusCode: 404,
        body: '{"detail":"$missingDeviceMessage"}',
      ),
    ]);
    final dio = _createDio(adapter);

    await _pumpApp(tester, storage, dio);
    await tester.tap(find.byKey(const Key('dashboard-add-device')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('claim-device-id')),
      'AMI-123456',
    );
    await tester.enterText(find.byKey(const Key('claim-pin-code')), '001234');
    await tester.tap(find.byKey(const Key('claim-submit')));
    await tester.pumpAndSettle();
    expect(find.text(invalidPinMessage), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('claim-device-id')),
      'AMI-654321',
    );
    await tester.tap(find.byKey(const Key('claim-submit')));
    await tester.pumpAndSettle();
    expect(find.text(missingDeviceMessage), findsOneWidget);
    expect(find.text('Thêm thiết bị'), findsOneWidget);
    expect(adapter.requests, hasLength(3));

    dio.close(force: true);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  MemoryTokenStorage storage,
  Dio dio,
) async {
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
}

class _ApiResponse {
  const _ApiResponse({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.body,
  });

  final String method;
  final String path;
  final int statusCode;
  final String body;
}

class _ClaimApiAdapter implements HttpClientAdapter {
  _ClaimApiAdapter(this.responses);

  final List<_ApiResponse> responses;
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
    if (options.method != response.method ||
        !options.uri.path.endsWith(response.path)) {
      throw StateError(
        'Unexpected request ${options.method} ${options.uri.path}.',
      );
    }
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

Dio _createDio(_ClaimApiAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1/'))
    ..httpClientAdapter = adapter;
}
