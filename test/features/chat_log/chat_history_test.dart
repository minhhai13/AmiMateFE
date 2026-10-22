import 'dart:convert';
import 'dart:typed_data';

import 'package:amimate/core/network/dio_provider.dart';
import 'package:amimate/features/chat_log/application/chat_history_controller.dart';
import 'package:amimate/features/chat_log/data/models/chat_log_page_response.dart';
import 'package:amimate/features/chat_log/presentation/screens/chat_conversation_screen.dart';
import 'package:amimate/features/chat_log/presentation/screens/chat_history_screen.dart';
import 'package:amimate/features/chat_log/data/repositories/chat_log_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses BE chat log and pagination fields, including empty messages',
    () {
      final page = ChatLogPageResponse.fromJson({
        'items': [
          _logJson(2, nullUserMessage: true, emptyBotResponse: true),
          _logJson(1),
        ],
        'page': 0,
        'size': 50,
        'totalElements': 2,
        'hasNext': true,
      });

      expect(page.items.map((item) => item.id), [2, 1]);
      expect(page.items.first.userMessage, isNull);
      expect(page.items.first.botResponse, '');
      expect(page.items.first.createdAt.isUtc, isTrue);
      expect(page.page, 0);
      expect(page.size, 50);
      expect(page.totalElements, 2);
      expect(page.hasNext, isTrue);
    },
  );

  test(
    'repository sends device id and requested pagination parameters',
    () async {
      final adapter = _ScriptedApiAdapter([
        _pageResponse(items: [], page: 2, hasNext: false),
      ]);
      final dio = _createDio(adapter);
      addTearDown(() => dio.close(force: true));

      await ChatLogRepository(dio)
          .getLogs(deviceId: 'AMI-123456', page: 2, size: 50);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, 'logs');
      expect(request.queryParameters, {
        'deviceId': 'AMI-123456',
        'page': 2,
        'size': 50,
      });
    },
  );

  test('sessions repository loads a page for the selected device', () async {
    final adapter = _ScriptedApiAdapter([
      _sessionPageResponse(
        items: [_sessionJson('88720701', turnCount: 8)],
        page: 0,
        hasNext: false,
      ),
    ]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    final result = await ChatLogRepository(dio)
        .getSessions(deviceId: 'AMI-123456', page: 0);

    expect(result.items.single.chatId, '88720701');
    expect(result.items.single.turnCount, 8);
    expect(adapter.requests.single.path, 'logs/sessions');
    expect(adapter.requests.single.queryParameters, {
      'deviceId': 'AMI-123456',
      'page': 0,
      'size': 50,
    });
  });

  test('sync repository posts for the selected owned device', () async {
    final adapter = _ScriptedApiAdapter([
      '{"deviceId":"AMI-123456","chatsFetched":18,"messagesFetched":144,"logsImported":72,"logsSkipped":0}',
    ]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    final result = await ChatLogRepository(dio)
        .syncFromXiaozhi(deviceId: 'AMI-123456');

    expect(result.deviceId, 'AMI-123456');
    expect(result.chatsFetched, 18);
    expect(result.messagesFetched, 144);
    expect(result.logsImported, 72);
    expect(result.logsSkipped, 0);
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, 'logs/sync-xiaozhi');
    expect(adapter.requests.single.queryParameters, {'deviceId': 'AMI-123456'});
  });

  test(
    'controller deduplicates overlapping pages and stops at hasNext false',
    () async {
      final adapter = _ScriptedApiAdapter([
        _pageResponse(
          items: [_logJson(2), _logJson(1)],
          page: 0,
          hasNext: true,
        ),
        _pageResponse(
          items: [_logJson(1), _logJson(3)],
          page: 1,
          hasNext: false,
        ),
      ]);
      final fixture = _createContainer(adapter);
      final container = fixture.container;
      final subscription = container.listen(
        chatHistoryProvider('AMI-123456'),
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
        fixture.dio.close(force: true);
      });

      final notifier = container.read(
        chatHistoryProvider('AMI-123456').notifier,
      );
      final initial = await container.read(
        chatHistoryProvider('AMI-123456').future,
      );
      expect(initial.items.map((item) => item.id), [2, 1]);
      expect(adapter.requests.single.queryParameters['size'], 50);

      await Future.wait([notifier.loadMore(), notifier.loadMore()]);

      final result = container
          .read(chatHistoryProvider('AMI-123456'))
          .requireValue;
      expect(result.items.map((item) => item.id), [2, 1, 3]);
      expect(result.hasNext, isFalse);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.queryParameters['page'], 1);

      await notifier.loadMore();
      expect(adapter.requests, hasLength(2));
    },
  );

  test('refresh replaces loaded pages with the latest first page', () async {
    final adapter = _ScriptedApiAdapter([
      _pageResponse(items: [_logJson(2)], page: 0, hasNext: true),
      _pageResponse(items: [_logJson(1)], page: 1, hasNext: false),
      _pageResponse(items: [_logJson(3)], page: 0, hasNext: false),
    ]);
    final fixture = _createContainer(adapter);
    final container = fixture.container;
    final subscription = container.listen(
      chatHistoryProvider('AMI-123456'),
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
      fixture.dio.close(force: true);
    });

    await container.read(chatHistoryProvider('AMI-123456').future);
    final notifier = container.read(chatHistoryProvider('AMI-123456').notifier);
    await notifier.loadMore();
    expect(
      container
          .read(chatHistoryProvider('AMI-123456'))
          .requireValue
          .items
          .map((item) => item.id),
      [2, 1],
    );

    await notifier.refresh();

    final refreshed = container
        .read(chatHistoryProvider('AMI-123456'))
        .requireValue;
    expect(refreshed.items.map((item) => item.id), [3]);
    expect(refreshed.page, 0);
    expect(refreshed.hasNext, isFalse);
    expect(adapter.requests.last.queryParameters['page'], 0);
  });

  test(
    'load-more failure is exposed and can be retried on the same page',
    () async {
      final adapter = _ScriptedApiAdapter(
        [
          _pageResponse(items: [_logJson(1)], page: 0, hasNext: true),
          '{"detail":"Không tải được trang tiếp theo."}',
          _pageResponse(items: [_logJson(2)], page: 1, hasNext: false),
        ],
        failingIndices: {1},
      );
      final fixture = _createContainer(adapter);
      final container = fixture.container;
      final subscription = container.listen(
        chatHistoryProvider('AMI-123456'),
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
        fixture.dio.close(force: true);
      });

      await container.read(chatHistoryProvider('AMI-123456').future);
      final notifier = container.read(
        chatHistoryProvider('AMI-123456').notifier,
      );
      await notifier.loadMore();
      expect(
        container
            .read(chatHistoryProvider('AMI-123456'))
            .requireValue
            .loadMoreError,
        'Không tải được trang tiếp theo.',
      );

      await notifier.loadMore();

      final result = container
          .read(chatHistoryProvider('AMI-123456'))
          .requireValue;
      expect(result.items.map((item) => item.id), [1, 2]);
      expect(result.loadMoreError, isNull);
      expect(
        adapter.requests.map((request) => request.queryParameters['page']),
        [0, 1, 1],
      );
    },
  );

  testWidgets('shows chats as a selectable session list', (tester) async {
    final adapter = _ScriptedApiAdapter([
      _sessionPageResponse(
        items: [_sessionJson('88720701', turnCount: 4)],
        page: 0,
        hasNext: false,
      ),
    ]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(
          home: ChatHistoryScreen(deviceId: 'AMI-123456'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cuộc trò chuyện 88720701'), findsOneWidget);
    expect(find.textContaining('4 lượt chat'), findsOneWidget);
    expect(find.byKey(const Key('chat-session-88720701')), findsOneWidget);
  });

  testWidgets('initial error offers retry and then shows empty history', (
    tester,
  ) async {
    final adapter = _ScriptedApiAdapter(
      [
        '{"detail":"Máy chủ nhật ký đang bận."}',
        _sessionPageResponse(items: [], page: 0, hasNext: false),
      ],
      failingIndices: {0},
    );
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(
          home: ChatHistoryScreen(deviceId: 'AMI-123456'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa tải được danh sách chat'), findsOneWidget);
    expect(find.text('Máy chủ nhật ký đang bận.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-history-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có cuộc trò chuyện'), findsOneWidget);
    expect(adapter.requests, hasLength(2));
  });

  testWidgets('scrolling near the end loads the next page', (tester) async {
    final adapter = _ScriptedApiAdapter([
      _sessionPageResponse(
        items: List.generate(
          10,
          (index) => _sessionJson('${10 - index}', turnCount: 2),
        ),
        page: 0,
        hasNext: true,
      ),
      _sessionPageResponse(
        items: [_sessionJson('11', turnCount: 3)],
        page: 1,
        hasNext: false,
      ),
    ]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(
          home: ChatHistoryScreen(deviceId: 'AMI-123456'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.queryParameters['page'], 1);
    expect(find.byKey(const Key('chat-session-11')), findsOneWidget);
  });

  testWidgets('sync button refreshes the selected device history', (
    tester,
  ) async {
    final adapter = _ScriptedApiAdapter([
      _sessionPageResponse(
        items: [_sessionJson('88720701', turnCount: 1)],
        page: 0,
        hasNext: false,
      ),
      '{"deviceId":"AMI-123456","chatsFetched":1,"messagesFetched":2,"logsImported":1,"logsSkipped":0}',
      _sessionPageResponse(
        items: [
          _sessionJson('88720701', turnCount: 2),
          _sessionJson('88730633', turnCount: 1),
        ],
        page: 0,
        hasNext: false,
      ),
    ]);
    final dio = _createDio(adapter);
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(
          home: ChatHistoryScreen(deviceId: 'AMI-123456'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-history-sync-xiaozhi')));
    await tester.pumpAndSettle();

    expect(adapter.requests[1].method, 'POST');
    expect(adapter.requests[1].queryParameters['deviceId'], 'AMI-123456');
    expect(adapter.requests[2].queryParameters['page'], 0);
    expect(find.byKey(const Key('chat-session-88730633')), findsOneWidget);
    expect(find.textContaining('thêm 1 lượt chat'), findsOneWidget);
  });

  testWidgets(
    'conversation shows messages oldest at top and newest at bottom',
    (tester) async {
      final adapter = _ScriptedApiAdapter([
        _pageResponse(
          items: [
            _logJson(2, sessionId: '88720701', userMessage: 'Câu hỏi mới'),
            _logJson(1, sessionId: '88720701', userMessage: 'Câu hỏi cũ'),
          ],
          page: 0,
          hasNext: false,
        ),
      ]);
      final dio = _createDio(adapter);
      addTearDown(() => dio.close(force: true));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: const MaterialApp(
            home: ChatConversationScreen(
              deviceId: 'AMI-123456',
              chatId: '88720701',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Câu hỏi cũ'), findsOneWidget);
      expect(find.text('Câu trả lời 1'), findsOneWidget);
      expect(find.text('Câu hỏi mới'), findsOneWidget);
      expect(find.text('Câu trả lời 2'), findsOneWidget);
      expect(
        tester.getCenter(find.text('Câu hỏi cũ')).dy,
        lessThan(tester.getCenter(find.text('Câu hỏi mới')).dy),
      );
      expect(adapter.requests.single.queryParameters['sessionId'], '88720701');
    },
  );
}

Map<String, dynamic> _logJson(
  int id, {
  String? sessionId,
  String? userMessage,
  bool nullUserMessage = false,
  bool emptyBotResponse = false,
}) {
  return {
    'id': id,
    'deviceId': 'AMI-123456',
    'sessionId': sessionId ?? 'session-$id',
    'clientMessageId': 'client-$id',
    'userMessage': nullUserMessage ? null : userMessage ?? 'Câu hỏi $id',
    'botResponse': emptyBotResponse ? '' : 'Câu trả lời $id',
    'createdAt': '2026-10-13T09:30:00.123Z',
  };
}

Map<String, dynamic> _sessionJson(String chatId, {required int turnCount}) {
  return {
    'chatId': chatId,
    'lastMessageAt': '2026-10-21T13:25:39.000Z',
    'turnCount': turnCount,
  };
}

String _pageResponse({
  required List<Map<String, dynamic>> items,
  required int page,
  required bool hasNext,
}) {
  return jsonEncode({
    'items': items,
    'page': page,
    'size': 50,
    'totalElements': items.length,
    'hasNext': hasNext,
  });
}

String _sessionPageResponse({
  required List<Map<String, dynamic>> items,
  required int page,
  required bool hasNext,
}) {
  return jsonEncode({
    'items': items,
    'page': page,
    'size': 50,
    'totalElements': items.length,
    'hasNext': hasNext,
  });
}

({ProviderContainer container, Dio dio}) _createContainer(
  _ScriptedApiAdapter adapter,
) {
  final dio = _createDio(adapter);
  final container = ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dio)],
  );
  return (container: container, dio: dio);
}

Dio _createDio(_ScriptedApiAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1/'))
    ..httpClientAdapter = adapter;
}

class _ScriptedApiAdapter implements HttpClientAdapter {
  _ScriptedApiAdapter(this.responses, {this.failingIndices = const {}});

  final List<String> responses;
  final Set<int> failingIndices;
  final List<RequestOptions> requests = [];
  var _responseIndex = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final responseIndex = _responseIndex++;
    return ResponseBody.fromString(
      responses[responseIndex],
      failingIndices.contains(responseIndex) ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
