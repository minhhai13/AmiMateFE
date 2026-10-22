class ChatSessionResponse {
  const ChatSessionResponse({
    required this.chatId,
    required this.lastMessageAt,
    required this.turnCount,
  });

  factory ChatSessionResponse.fromJson(Map<String, dynamic> json) {
    final chatId = json['chatId'];
    final lastMessageAt = json['lastMessageAt'];
    final turnCount = json['turnCount'];
    final parsedLastMessageAt = lastMessageAt is String
        ? DateTime.tryParse(lastMessageAt)
        : null;

    if (chatId is! String ||
        chatId.trim().isEmpty ||
        parsedLastMessageAt == null ||
        turnCount is! int ||
        turnCount < 0) {
      throw const FormatException(
        'Thông tin cuộc trò chuyện trả về không hợp lệ.',
      );
    }

    return ChatSessionResponse(
      chatId: chatId,
      lastMessageAt: parsedLastMessageAt,
      turnCount: turnCount,
    );
  }

  final String chatId;
  final DateTime lastMessageAt;
  final int turnCount;
}
