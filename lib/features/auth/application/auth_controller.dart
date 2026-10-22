import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../data/models/auth_request.dart';
import '../data/models/auth_response.dart';
import '../data/repositories/auth_repository.dart';

enum AuthSessionStatus { checking, unauthenticated, authenticated, error }

class AuthState {
  const AuthState({
    required this.status,
    this.isSubmitting = false,
    this.failureMessage,
  });

  final AuthSessionStatus status;
  final bool isSubmitting;
  final String? failureMessage;

  AuthState copyWith({
    AuthSessionStatus? status,
    bool? isSubmitting,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failureMessage: clearFailure
          ? null
          : failureMessage ?? this.failureMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(status: AuthSessionStatus.checking);

  Future<void> restoreSession() async {
    state = const AuthState(status: AuthSessionStatus.checking);
    try {
      final token = await ref.read(tokenStorageProvider).readToken();
      state = AuthState(
        status: token != null && token.trim().isNotEmpty
            ? AuthSessionStatus.authenticated
            : AuthSessionStatus.unauthenticated,
      );
    } on Object {
      state = const AuthState(
        status: AuthSessionStatus.error,
        failureMessage: 'Không thể kiểm tra phiên đăng nhập. Vui lòng thử lại.',
      );
    }
  }

  Future<void> login(AuthRequest request) =>
      _authenticate(() => ref.read(authRepositoryProvider).login(request));

  Future<void> register(AuthRequest request) =>
      _authenticate(() => ref.read(authRepositoryProvider).register(request));

  void sessionExpired() {
    state = const AuthState(status: AuthSessionStatus.unauthenticated);
  }

  Future<void> signOut() async {
    try {
      await ref.read(tokenStorageProvider).deleteToken();
      state = const AuthState(status: AuthSessionStatus.unauthenticated);
    } on Object {
      state = const AuthState(
        status: AuthSessionStatus.authenticated,
        failureMessage: 'Không thể xóa phiên đăng nhập. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _authenticate(
    Future<AuthResponse> Function() authenticate,
  ) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    try {
      final response = await authenticate();
      await ref.read(tokenStorageProvider).writeToken(response.token);
      state = const AuthState(status: AuthSessionStatus.authenticated);
    } on ApiFailure catch (failure) {
      state = AuthState(
        status: AuthSessionStatus.unauthenticated,
        failureMessage: failure.message,
      );
    } on FormatException {
      state = const AuthState(
        status: AuthSessionStatus.unauthenticated,
        failureMessage: 'Máy chủ trả về dữ liệu xác thực không hợp lệ.',
      );
    } on Object {
      state = const AuthState(
        status: AuthSessionStatus.unauthenticated,
        failureMessage: 'Không thể lưu phiên đăng nhập. Vui lòng thử lại.',
      );
    }
  }
}
