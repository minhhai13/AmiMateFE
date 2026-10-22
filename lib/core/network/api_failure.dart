import 'package:dio/dio.dart';

enum ApiFailureKind { network, timeout, client, server, cancelled, unknown }

class ApiFailure implements Exception {
  const ApiFailure({
    required this.kind,
    required this.message,
    this.statusCode,
    this.title,
    this.fieldErrors = const {},
  });

  factory ApiFailure.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final body = exception.response?.data;
    final problem = _readProblem(body);

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiFailure(
          kind: ApiFailureKind.timeout,
          statusCode: statusCode,
          title: problem.title,
          message: problem.detail ?? 'Kết nối quá thời gian chờ. Vui lòng thử lại.',
          fieldErrors: problem.fieldErrors,
        );
      case DioExceptionType.connectionError:
        return ApiFailure(
          kind: ApiFailureKind.network,
          statusCode: statusCode,
          title: problem.title,
          message:
              problem.detail ?? 'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối.',
          fieldErrors: problem.fieldErrors,
        );
      case DioExceptionType.badResponse:
        final kind = statusCode != null && statusCode >= 500
            ? ApiFailureKind.server
            : ApiFailureKind.client;
        return ApiFailure(
          kind: kind,
          statusCode: statusCode,
          title: problem.title,
          message:
              problem.detail ?? _fallbackMessage(statusCode) ?? 'Đã xảy ra lỗi API.',
          fieldErrors: problem.fieldErrors,
        );
      case DioExceptionType.cancel:
        return ApiFailure(
          kind: ApiFailureKind.cancelled,
          statusCode: statusCode,
          title: problem.title,
          message: 'Yêu cầu đã bị hủy.',
          fieldErrors: problem.fieldErrors,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiFailure(
          kind: ApiFailureKind.unknown,
          statusCode: statusCode,
          title: problem.title,
          message:
              problem.detail ?? 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
          fieldErrors: problem.fieldErrors,
        );
    }
  }

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;
  final String? title;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class _ProblemDetails {
  const _ProblemDetails({this.title, this.detail, this.fieldErrors = const {}});

  final String? title;
  final String? detail;
  final Map<String, String> fieldErrors;
}

_ProblemDetails _readProblem(Object? body) {
  if (body is! Map) return const _ProblemDetails();

  final title = body['title'];
  final detail = body['detail'];
  final errors = body['errors'];
  final fieldErrors = <String, String>{};

  if (errors is Map) {
    for (final entry in errors.entries) {
      if (entry.key is String && entry.value is String) {
        fieldErrors[entry.key as String] = entry.value as String;
      }
    }
  }

  return _ProblemDetails(
    title: title is String && title.trim().isNotEmpty ? title : null,
    detail: detail is String && detail.trim().isNotEmpty ? detail : null,
    fieldErrors: Map.unmodifiable(fieldErrors),
  );
}

String? _fallbackMessage(int? statusCode) {
  return switch (statusCode) {
    400 => 'Thông tin gửi lên không hợp lệ.',
    401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    403 => 'Bạn không có quyền thực hiện thao tác này.',
    404 => 'Không tìm thấy dữ liệu yêu cầu.',
    409 => 'Dữ liệu bị trùng hoặc không thể thực hiện thao tác này.',
    final code? when code >= 500 =>
      'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
    _ => null,
  };
}
