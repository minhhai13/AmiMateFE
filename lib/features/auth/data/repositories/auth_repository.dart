import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../models/auth_request.dart';
import '../models/auth_response.dart';

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResponse> login(AuthRequest request) =>
      _send('auth/login', request);

  Future<AuthResponse> register(AuthRequest request) =>
      _send('auth/register', request);

  Future<AuthResponse> _send(String path, AuthRequest request) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: request.toJson(),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi xác thực không hợp lệ.');
      }
      return AuthResponse.fromJson(data);
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
}
