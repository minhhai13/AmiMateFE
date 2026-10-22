import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chat_history_controller.dart';
import '../../data/models/chat_log_response.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({
    required this.deviceId,
    required this.chatId,
    super.key,
  });

  final String deviceId;
  final String chatId;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  static const double _loadOlderThreshold = 240;

  late final ChatConversationKey _conversationKey = (
    deviceId: widget.deviceId,
    chatId: widget.chatId,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.userScrollDirection != ScrollDirection.idle &&
        position.extentAfter < _loadOlderThreshold) {
      unawaited(
        ref
            .read(chatConversationProvider(_conversationKey).notifier)
            .loadOlder(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(chatConversationProvider(_conversationKey));
    final controller = ref.read(
      chatConversationProvider(_conversationKey).notifier,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Chat ${widget.chatId}')),
      body: conversation.when(
        data: (data) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            key: const Key('chat-conversation-messages'),
            controller: _scrollController,
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            itemCount:
                data.items.length +
                (data.isLoadingMore ? 1 : 0) +
                (data.loadMoreError != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (data.isLoadingMore && index == data.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      key: Key('chat-conversation-loading-older'),
                    ),
                  ),
                );
              }
              if (data.loadMoreError != null && index == data.items.length) {
                return Center(
                  child: TextButton(
                    onPressed: controller.loadOlder,
                    child: Text('Chưa tải được chat cũ: ${data.loadMoreError}'),
                  ),
                );
              }
              return _ChatTurn(log: data.items[index]);
            },
          ),
        ),
        error: (error, stackTrace) => _ConversationError(
          message: error.toString(),
          onRetry: controller.refresh,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            key: Key('chat-conversation-loading'),
          ),
        ),
      ),
    );
  }
}

class _ChatTurn extends StatelessWidget {
  const _ChatTurn({required this.log});

  final ChatLogResponse log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('chat-turn-${log.id}'),
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          _MessageBubble(
            message: log.userMessage,
            time: log.createdAt,
            isUser: true,
          ),
          if (log.botResponse != null && log.botResponse!.trim().isNotEmpty)
            _MessageBubble(
              message: log.botResponse,
              time: log.createdAt,
              isUser: false,
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isUser,
  });

  final String? message;
  final DateTime time;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground = isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message == null || message!.trim().isEmpty
                    ? 'Không có nội dung'
                    : message!,
                style: TextStyle(color: foreground),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: foreground.withAlpha(190)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ConversationError extends StatelessWidget {
  const _ConversationError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
