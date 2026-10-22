import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../models/claim_device_request.dart';
import '../models/device_response.dart';

class DeviceRepository {
  const DeviceRepository(this._dio);

  final Dio _dio;

  Future<List<DeviceResponse>> getMyDevices() async {
    try {
      final response = await _dio.get<Object?>('devices');
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Danh sách thiết bị trả về không hợp lệ.');
      }

      return data.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Thông tin thiết bị trả về không hợp lệ.',
          );
        }
        return DeviceResponse.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false);
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<DeviceResponse> claimDevice(ClaimDeviceRequest request) async {
    try {
      final response = await _dio.post<Object?>(
        'devices/claim',
        data: request.toJson(),
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Thông tin thiết bị trả về không hợp lệ.');
      }
      return DeviceResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
}
