import 'dart:typed_data';

import 'package:amimate/core/network/dio_provider.dart';
import 'package:amimate/core/storage/token_storage.dart';
import 'package:amimate/features/device/application/device_controller.dart';
import 'package:amimate/features/device/data/models/device_response.dart';
import 'package:amimate/features/device/data/repositories/device_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_helpers.dart';

void main() {
  test('parses device fields and UTC creation time', () {
    final device = DeviceResponse.fromJson({
      'deviceId': 'AMI-123456',
      'name': 'AmiMate',
      'createdAt': '2026-10-13T09:00:00.000Z',
    });

    expect(device.deviceId, 'AMI-123456');
    expect(device.name, 'AmiMate');
    expect(device.createdAt.isUtc, isTrue);
  });

  test('repository parses the direct BE device array', () async {
    final adapter = ScriptedApiAdapter([
      (
        statusCode: 200,
        body: '[{"deviceId":"AMI-123456","name":"AmiMate","createdAt":"2026-10-13T09:00:00.000Z"}]',
      ),
    ]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    final devices = await DeviceRepository(dio).getMyDevices();

    expect(devices, hasLength(1));
    expect(devices.single.deviceId, 'AMI-123456');
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, 'devices');
  });

  test('repository accepts an empty BE device array', () async {
    final adapter = ScriptedApiAdapter([(statusCode: 200, body: '[]')]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    expect(await DeviceRepository(dio).getMyDevices(), isEmpty);
  });

  test('controller exposes retry results after a failed request', () async {
    final storage = MemoryTokenStorage(token: 'test-jwt');
    final adapter = ScriptedApiAdapter([
      (statusCode: 503, body: '{"detail":"Máy chủ đang bảo trì"}'),
      (statusCode: 200, body: '[]'),
    ]);
    final dio = _createDio(adapter);
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        dioProvider.overrideWithValue(dio),
      ],
    );
    final subscription = container.listen(deviceListProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
      dio.close(force: true);
    });

    await expectLater(
      container.read(deviceListProvider.future),
      throwsA(anything),
    );
    expect(container.read(deviceListProvider).hasError, isTrue);

    await container.read(deviceListProvider.notifier).reload();

    expect(container.read(deviceListProvider).hasValue, isTrue);
    expect(container.read(deviceListProvider).value, isEmpty);
    expect(adapter.requests, hasLength(2));
  });
}

class ScriptedApiAdapter implements HttpClientAdapter {
  ScriptedApiAdapter(this.responses);

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

Dio _createDio(ScriptedApiAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1/'))
    ..httpClientAdapter = adapter;
}
