import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../models/chat_log_page_response.dart';
import '../models/chat_session_page_response.dart';
import '../models/xiaozhi_sync_response.dart';

class ChatLogRepository {
  const ChatLogRepository(this._dio);

  static const int defaultPageSize = 50;

  final Dio _dio;

  Future<ChatLogPageResponse> getLogs({
    required String deviceId,
    required int page,
    String? sessionId,
    int size = defaultPageSize,
  }) async {
    final sessionParameters = sessionId == null
        ? const <String, String>{}
        : {'sessionId': sessionId};
    try {
      final response = await _dio.get<Object?>(
        'logs',
        queryParameters: {
          'deviceId': deviceId,
          ...sessionParameters,
          'page': page,
          'size': size,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Trang nhật ký trả về không hợp lệ.');
      }
      return ChatLogPageResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<ChatSessionPageResponse> getSessions({
    required String deviceId,
    required int page,
    int size = defaultPageSize,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        'logs/sessions',
        queryParameters: {'deviceId': deviceId, 'page': page, 'size': size},
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Danh sách cuộc trò chuyện không hợp lệ.');
      }
      return ChatSessionPageResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<XiaozhiSyncResponse> syncFromXiaozhi({
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        'logs/sync-xiaozhi',
        queryParameters: {'deviceId': deviceId},
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Kết quả đồng bộ Xiaozhi không hợp lệ.');
      }
      return XiaozhiSyncResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
}
