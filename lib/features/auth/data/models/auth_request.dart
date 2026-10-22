class AuthRequest {
  const AuthRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, Object> toJson() => {'email': email, 'password': password};
}
