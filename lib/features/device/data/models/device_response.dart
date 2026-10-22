class DeviceResponse {
  const DeviceResponse({
    required this.deviceId,
    required this.name,
    required this.createdAt,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    final deviceId = json['deviceId'];
    final name = json['name'];
    final createdAt = json['createdAt'];
    if (deviceId is! String ||
        deviceId.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        createdAt is! String) {
      throw const FormatException('Thông tin thiết bị trả về không hợp lệ.');
    }

    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedCreatedAt == null) {
      throw const FormatException('Thời gian tạo thiết bị không hợp lệ.');
    }

    return DeviceResponse(
      deviceId: deviceId,
      name: name,
      createdAt: parsedCreatedAt,
    );
  }

  final String deviceId;
  final String name;
  final DateTime createdAt;
}
