import 'chat_log_response.dart';

class ChatLogPageResponse {
  const ChatLogPageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.hasNext,
  });

  factory ChatLogPageResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final page = json['page'];
    final size = json['size'];
    final totalElements = json['totalElements'];
    final hasNext = json['hasNext'];

    if (items is! List ||
        page is! int ||
        page < 0 ||
        size is! int ||
        size <= 0 ||
        totalElements is! int ||
        totalElements < 0 ||
        hasNext is! bool) {
      throw const FormatException('Trang nhật ký trả về không hợp lệ.');
    }

    return ChatLogPageResponse(
      items: items
          .map((item) {
            if (item is! Map) {
              throw const FormatException(
                'Thông tin nhật ký trả về không hợp lệ.',
              );
            }
            return ChatLogResponse.fromJson(Map<String, dynamic>.from(item));
          })
          .toList(growable: false),
      page: page,
      size: size,
      totalElements: totalElements,
      hasNext: hasNext,
    );
  }

  final List<ChatLogResponse> items;
  final int page;
  final int size;
  final int totalElements;
  final bool hasNext;
}
