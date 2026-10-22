class ApiConfiguration {
  const ApiConfiguration({required this.baseUrl});

  factory ApiConfiguration.fromEnvironment() {
    return const ApiConfiguration(
      baseUrl: String.fromEnvironment(
        'AMIMATE_BASE_URL',
        defaultValue: 'https://amimate-backend.onrender.com/api/v1',
      ),
    );
  }

  final String baseUrl;

  String get dioBaseUrl {
    final normalized = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError(
        'AMIMATE_BASE_URL phải là URL http/https hợp lệ, không có query hoặc fragment.',
      );
    }

    return '$normalized/';
  }
}
