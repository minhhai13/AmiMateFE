class ChatLogResponse {
  const ChatLogResponse({
    required this.id,
    required this.deviceId,
    required this.sessionId,
    required this.clientMessageId,
    required this.userMessage,
    required this.botResponse,
    required this.createdAt,
  });

  factory ChatLogResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final deviceId = json['deviceId'];
    final sessionId = _optionalString(json, 'sessionId');
    final clientMessageId = _optionalString(json, 'clientMessageId');
    final userMessage = _optionalString(json, 'userMessage');
    final botResponse = _optionalString(json, 'botResponse');
    final createdAt = json['createdAt'];

    if (id is! int ||
        deviceId is! String ||
        deviceId.trim().isEmpty ||
        createdAt is! String) {
      throw const FormatException('Thông tin nhật ký trả về không hợp lệ.');
    }

    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedCreatedAt == null) {
      throw const FormatException('Thời gian nhật ký không hợp lệ.');
    }

    return ChatLogResponse(
      id: id,
      deviceId: deviceId,
      sessionId: sessionId,
      clientMessageId: clientMessageId,
      userMessage: userMessage,
      botResponse: botResponse,
      createdAt: parsedCreatedAt,
    );
  }

  final int id;
  final String deviceId;
  final String? sessionId;
  final String? clientMessageId;
  final String? userMessage;
  final String? botResponse;
  final DateTime createdAt;
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value;
  throw FormatException('Trường $field trong nhật ký không hợp lệ.');
}
