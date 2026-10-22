import 'package:amimate/core/network/dio_provider.dart';
import 'package:amimate/core/storage/token_storage.dart';
import 'package:amimate/features/auth/application/auth_controller.dart';
import 'package:amimate/features/auth/data/models/auth_request.dart';
import 'package:amimate/features/auth/data/models/auth_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_helpers.dart';

void main() {
  group('Auth models', () {
    test('serializes the request and parses the BE response', () {
      const request = AuthRequest(
        email: 'parent@example.com',
        password: 'password123',
      );
      expect(request.toJson(), {
        'email': 'parent@example.com',
        'password': 'password123',
      });

      final response = AuthResponse.fromJson({
        'token': 'jwt-value',
        'expiresInSeconds': 86400,
      });
      expect(response.token, 'jwt-value');
      expect(response.expiresInSeconds, 86400);
    });

    test('rejects invalid authentication response data', () {
      expect(
        () => AuthResponse.fromJson({'token': '', 'expiresInSeconds': -1}),
        throwsFormatException,
      );
    });
  });

  test(
    'register posts to BE endpoint and persists the returned token',
    () async {
      final storage = MemoryTokenStorage();
      final adapter = RecordingAuthAdapter();
      final dio = createTestDio(adapter);
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(() {
        container.dispose();
        dio.close(force: true);
      });

      await container
          .read(authControllerProvider.notifier)
          .register(
            const AuthRequest(
              email: 'parent@example.com',
              password: 'password123',
            ),
          );

      expect(adapter.requests.single.path, 'auth/register');
      expect(adapter.requests.single.data, {
        'email': 'parent@example.com',
        'password': 'password123',
      });
      expect(storage.token, 'test-jwt');
      expect(
        container.read(authControllerProvider).status,
        AuthSessionStatus.authenticated,
      );
    },
  );

  test('login surfaces API errors without saving a token', () async {
    final storage = MemoryTokenStorage();
    final adapter = RecordingAuthAdapter(
      statusCode: 401,
      responseJson: '{"detail":"Email hoặc mật khẩu không đúng"}',
    );
    final dio = createTestDio(adapter);
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(() {
      container.dispose();
      dio.close(force: true);
    });

    await container
        .read(authControllerProvider.notifier)
        .login(
          const AuthRequest(email: 'parent@example.com', password: 'wrong'),
        );

    final state = container.read(authControllerProvider);
    expect(state.status, AuthSessionStatus.unauthenticated);
    expect(state.failureMessage, 'Email hoặc mật khẩu không đúng');
    expect(storage.token, isNull);
    expect(adapter.requests.single.path, 'auth/login');
  });

  test('restores session based only on token presence', () async {
    final storage = MemoryTokenStorage(token: 'expired-jwt');
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();

    expect(
      container.read(authControllerProvider).status,
      AuthSessionStatus.authenticated,
    );
  });

  test('signs out by deleting the stored token', () async {
    final storage = MemoryTokenStorage(token: 'existing-jwt');
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();
    await container.read(authControllerProvider.notifier).signOut();

    expect(storage.token, isNull);
    expect(
      container.read(authControllerProvider).status,
      AuthSessionStatus.unauthenticated,
    );
  });
}
