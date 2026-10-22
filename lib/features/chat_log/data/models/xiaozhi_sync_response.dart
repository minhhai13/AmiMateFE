class XiaozhiSyncResponse {
  const XiaozhiSyncResponse({
    required this.deviceId,
    required this.chatsFetched,
    required this.messagesFetched,
    required this.logsImported,
    required this.logsSkipped,
  });

  factory XiaozhiSyncResponse.fromJson(Map<String, dynamic> json) {
    final deviceId = json['deviceId'];
    final chatsFetched = json['chatsFetched'];
    final messagesFetched = json['messagesFetched'];
    final logsImported = json['logsImported'];
    final logsSkipped = json['logsSkipped'];

    if (deviceId is! String ||
        chatsFetched is! int ||
        messagesFetched is! int ||
        logsImported is! int ||
        logsSkipped is! int) {
      throw const FormatException('Kết quả đồng bộ Xiaozhi không hợp lệ.');
    }

    return XiaozhiSyncResponse(
      deviceId: deviceId,
      chatsFetched: chatsFetched,
      messagesFetched: messagesFetched,
      logsImported: logsImported,
      logsSkipped: logsSkipped,
    );
  }

  final String deviceId;
  final int chatsFetched;
  final int messagesFetched;
  final int logsImported;
  final int logsSkipped;
}
