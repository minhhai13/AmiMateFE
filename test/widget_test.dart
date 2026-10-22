import 'package:flutter/material.dart';
import 'package:amimate/app.dart';
import 'package:amimate/core/network/dio_provider.dart';
import 'package:amimate/core/network/auth_interceptor.dart';
import 'package:amimate/core/router/app_router.dart';
import 'package:amimate/core/storage/token_storage.dart';
import 'package:amimate/features/auth/application/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_helpers.dart';

void main() {
  testWidgets(
    'login restores routing, authenticates, and guards protected routes',
    (tester) async {
      final storage = MemoryTokenStorage();
      final adapter = RecordingAuthAdapter();
      final dio = createTestDio(adapter);

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

      expect(find.text('Đăng nhập'), findsNWidgets(2));
      expect(find.byKey(const Key('login-email')), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AmiMateApp)),
      );
      container.read(appRouterProvider).go('/devices/claim');
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập'), findsNWidgets(2));
      expect(find.text('Thêm thiết bị'), findsNothing);

      container.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'parent@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Thiết bị của tôi'), findsOneWidget);
      expect(storage.token, 'test-jwt');
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].path, 'auth/login');
      expect(adapter.requests[0].data, {
        'email': 'parent@example.com',
        'password': 'password',
      });
      expect(adapter.requests[1].path, 'devices');

      dio.close(force: true);
    },
  );

  testWidgets(
    'register validates BE constraints and starts an authenticated session',
    (tester) async {
      final storage = MemoryTokenStorage();
      final adapter = RecordingAuthAdapter();
      final dio = createTestDio(adapter);

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
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();

      expect(find.text('Tạo tài khoản'), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email.'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      expect(adapter.requests, isEmpty);

      await tester.enterText(
        find.byKey(const Key('register-email')),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'short',
      );
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email hợp lệ.'), findsOneWidget);
      expect(find.text('Mật khẩu phải có từ 8 đến 72 ký tự.'), findsOneWidget);
      expect(adapter.requests, isEmpty);

      await tester.enterText(
        find.byKey(const Key('register-email')),
        'parent@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Thiết bị của tôi'), findsOneWidget);
      expect(storage.token, 'test-jwt');
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].path, 'auth/register');
      expect(adapter.requests[0].data, {
        'email': 'parent@example.com',
        'password': 'password123',
      });
      expect(adapter.requests[1].path, 'devices');

      dio.close(force: true);
    },
  );

  testWidgets('restored token opens the dashboard from splash', (tester) async {
    final storage = MemoryTokenStorage(token: 'existing-jwt');
    final adapter = RecordingAuthAdapter();
    final dio = createTestDio(adapter);

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
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.path, 'devices');

    dio.close(force: true);
  });

  testWidgets(
    'settings confirms sign-out and back navigation stays signed out',
    (tester) async {
      final storage = MemoryTokenStorage(token: 'existing-jwt');
      final adapter = RecordingAuthAdapter();
      final dio = createTestDio(adapter);

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
      await tester.tap(find.byKey(const Key('dashboard-settings')));
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('AmiMate'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-sign-out-cancel')));
      await tester.pumpAndSettle();

      expect(storage.token, 'existing-jwt');
      expect(find.text('Cài đặt'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-sign-out-confirm')));
      await tester.pumpAndSettle();

      expect(storage.token, isNull);
      expect(find.text('Đăng nhập'), findsNWidgets(2));
      expect(find.text('Cài đặt'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập'), findsNWidgets(2));
      expect(find.text('Thiết bị của tôi'), findsNothing);

      dio.close(force: true);
    },
  );

  testWidgets('authenticated 401 clears token and returns to login', (
    tester,
  ) async {
    final storage = MemoryTokenStorage(token: 'expired-jwt');
    final adapter = RecordingAuthAdapter(statusCode: 401);
    late final Dio dio;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          dioProvider.overrideWith((ref) {
            dio = createTestDio(adapter)
              ..interceptors.add(
                AuthInterceptor(
                  tokenStorage: storage,
                  onUnauthorized: () => ref
                      .read(authControllerProvider.notifier)
                      .sessionExpired(),
                ),
              );
            return dio;
          }),
        ],
        child: const AmiMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(storage.token, isNull);
    expect(find.text('Đăng nhập'), findsNWidgets(2));
    expect(find.text('Thiết bị của tôi'), findsNothing);
    expect(adapter.requests.single.path, 'devices');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer expired-jwt',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsNWidgets(2));
    expect(find.text('Thiết bị của tôi'), findsNothing);

    dio.close(force: true);
  });
}
