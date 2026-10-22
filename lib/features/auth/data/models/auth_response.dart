class AuthResponse {
  const AuthResponse({required this.token, required this.expiresInSeconds});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final expiresInSeconds = json['expiresInSeconds'];
    if (token is! String ||
        token.trim().isEmpty ||
        expiresInSeconds is! num ||
        expiresInSeconds <= 0) {
      throw const FormatException('Phản hồi xác thực không hợp lệ.');
    }

    return AuthResponse(
      token: token,
      expiresInSeconds: expiresInSeconds.toInt(),
    );
  }

  final String token;
  final int expiresInSeconds;
}
