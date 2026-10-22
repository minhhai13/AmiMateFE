import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/chat_history_controller.dart';

class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  static const double _loadMoreThreshold = 240;

  final ScrollController _scrollController = ScrollController();
  bool _isSyncing = false;

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
        position.extentAfter < _loadMoreThreshold) {
      unawaited(
        ref.read(chatSessionsProvider(widget.deviceId).notifier).loadMore(),
      );
    }
  }

  Future<void> _syncFromXiaozhi() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final result = await ref
          .read(chatSessionsProvider(widget.deviceId).notifier)
          .syncFromXiaozhi();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Đồng bộ xong: thêm ${result.logsImported} lượt chat, '
              'bỏ qua ${result.logsSkipped} lượt đã có.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider(widget.deviceId));
    final controller = ref.read(chatSessionsProvider(widget.deviceId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Các cuộc trò chuyện'),
        actions: [
          IconButton(
            key: const Key('chat-history-sync-xiaozhi'),
            tooltip: 'Đồng bộ lịch sử Xiaozhi',
            onPressed: _isSyncing ? null : _syncFromXiaozhi,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: sessions.when(
        data: (data) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _DeviceHeader(
                  deviceId: widget.deviceId,
                  sessionCount: data.totalElements,
                ),
              ),
              if (data.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptySessions(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  sliver: SliverList.separated(
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final session = data.items[index];
                      return Card(
                        key: Key('chat-session-${session.chatId}'),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.chat_bubble_outline),
                          ),
                          title: Text('Cuộc trò chuyện ${session.chatId}'),
                          subtitle: Text(
                            '${session.turnCount} lượt chat · '
                            '${_formatDate(session.lastMessageAt)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pushNamed(
                            'chat-conversation',
                            pathParameters: {
                              'deviceId': widget.deviceId,
                              'chatId': session.chatId,
                            },
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 2),
                  ),
                ),
              if (data.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (data.loadMoreError != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: controller.loadMore,
                      child: Text('Tải thêm thất bại: ${data.loadMoreError}'),
                    ),
                  ),
                )
              else if (data.hasNext)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Cuộn xuống để xem chat cũ hơn')),
                  ),
                ),
            ],
          ),
        ),
        error: (error, stackTrace) => _SessionsError(
          message: error.toString(),
          onRetry: controller.refresh,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('chat-history-loading')),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} lúc $hour:$minute';
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.deviceId, required this.sessionCount});

  final String deviceId;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ListTile(
        leading: const Icon(Icons.smart_toy_outlined, color: Color(0xFF1677D2)),
        title: Text(deviceId),
        subtitle: Text('$sessionCount cuộc trò chuyện'),
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có cuộc trò chuyện',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn đồng bộ để tải các cuộc trò chuyện từ Xiaozhi.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsError extends StatelessWidget {
  const _SessionsError({required this.message, required this.onRetry});

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
        Text(
          'Chưa tải được danh sách chat',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const Key('chat-history-retry'),
          onPressed: onRetry,
          child: const Text('Thử lại'),
        ),
      ],
    );
  }
}
