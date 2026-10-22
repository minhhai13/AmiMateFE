import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/models/chat_log_page_response.dart';
import '../data/models/chat_log_response.dart';
import '../data/models/chat_session_page_response.dart';
import '../data/models/chat_session_response.dart';
import '../data/models/xiaozhi_sync_response.dart';
import '../data/repositories/chat_log_repository.dart';

final chatLogRepositoryProvider = Provider<ChatLogRepository>((ref) {
  return ChatLogRepository(ref.watch(dioProvider));
});

final chatHistoryProvider = AsyncNotifierProvider.autoDispose
    .family<ChatHistoryController, ChatHistoryState, String>(
      ChatHistoryController.new,
      retry: (_, _) => null,
    );

final chatSessionsProvider = AsyncNotifierProvider.autoDispose
    .family<ChatSessionsController, ChatSessionsState, String>(
      ChatSessionsController.new,
      retry: (_, _) => null,
    );

typedef ChatConversationKey = ({String deviceId, String chatId});

final chatConversationProvider = AsyncNotifierProvider.autoDispose
    .family<ChatConversationController, ChatHistoryState, ChatConversationKey>(
      ChatConversationController.new,
      retry: (_, _) => null,
    );

class ChatSessionsState {
  const ChatSessionsState({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.hasNext,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  factory ChatSessionsState.fromFirstPage(ChatSessionPageResponse response) {
    return ChatSessionsState(
      items: response.items,
      page: response.page,
      totalElements: response.totalElements,
      hasNext: response.hasNext,
    );
  }

  final List<ChatSessionResponse> items;
  final int page;
  final int totalElements;
  final bool hasNext;
  final bool isLoadingMore;
  final String? loadMoreError;

  ChatSessionsState copyWith({
    List<ChatSessionResponse>? items,
    int? page,
    int? totalElements,
    bool? hasNext,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ChatSessionsState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

class ChatSessionsController extends AsyncNotifier<ChatSessionsState> {
  ChatSessionsController(this.deviceId);

  final String deviceId;
  var _generation = 0;
  var _isLoadingMore = false;
  var _isRefreshing = false;

  @override
  Future<ChatSessionsState> build() async {
    final response = await ref
        .watch(chatLogRepositoryProvider)
        .getSessions(deviceId: deviceId, page: 0);
    return ChatSessionsState.fromFirstPage(response);
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    final generation = ++_generation;
    _isLoadingMore = false;
    _isRefreshing = true;
    try {
      final response = await ref
          .read(chatLogRepositoryProvider)
          .getSessions(deviceId: deviceId, page: 0);
      if (generation == _generation) {
        state = AsyncData(ChatSessionsState.fromFirstPage(response));
      }
    } catch (error, stackTrace) {
      if (generation == _generation) state = AsyncError(error, stackTrace);
    } finally {
      if (generation == _generation) _isRefreshing = false;
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (_isRefreshing ||
        _isLoadingMore ||
        state.isLoading ||
        current == null ||
        !current.hasNext) {
      return;
    }

    _isLoadingMore = true;
    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final response = await ref
          .read(chatLogRepositoryProvider)
          .getSessions(deviceId: deviceId, page: current.page + 1);
      if (generation != _generation) return;
      final latest = state.value;
      if (latest == null) return;
      final seenChatIds = latest.items.map((item) => item.chatId).toSet();
      final newItems = response.items
          .where((item) => seenChatIds.add(item.chatId))
          .toList(growable: false);
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...newItems],
          page: response.page,
          totalElements: response.totalElements,
          hasNext: response.hasNext,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(
          latest.copyWith(
            isLoadingMore: false,
            loadMoreError: error.toString(),
          ),
        );
      }
    } finally {
      if (generation == _generation) _isLoadingMore = false;
    }
  }

  Future<XiaozhiSyncResponse> syncFromXiaozhi() async {
    final result = await ref
        .read(chatLogRepositoryProvider)
        .syncFromXiaozhi(deviceId: deviceId);
    await refresh();
    return result;
  }
}

class ChatConversationController extends AsyncNotifier<ChatHistoryState> {
  ChatConversationController(this.key);

  static const int pageSize = ChatLogRepository.defaultPageSize;

  final ChatConversationKey key;
  var _generation = 0;
  var _isLoadingOlder = false;
  var _isRefreshing = false;

  @override
  Future<ChatHistoryState> build() async {
    final response = await ref
        .read(chatLogRepositoryProvider)
        .getLogs(
          deviceId: key.deviceId,
          sessionId: key.chatId,
          page: 0,
          size: pageSize,
        );
    return ChatHistoryState.fromFirstPage(response);
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    final generation = ++_generation;
    _isLoadingOlder = false;
    _isRefreshing = true;
    try {
      final response = await ref
          .read(chatLogRepositoryProvider)
          .getLogs(
            deviceId: key.deviceId,
            sessionId: key.chatId,
            page: 0,
            size: pageSize,
          );
      if (generation == _generation) {
        state = AsyncData(ChatHistoryState.fromFirstPage(response));
      }
    } catch (error, stackTrace) {
      if (generation == _generation) state = AsyncError(error, stackTrace);
    } finally {
      if (generation == _generation) _isRefreshing = false;
    }
  }

  Future<void> loadOlder() async {
    final current = state.value;
    if (_isRefreshing ||
        _isLoadingOlder ||
        state.isLoading ||
        current == null ||
        !current.hasNext) {
      return;
    }

    _isLoadingOlder = true;
    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final response = await ref
          .read(chatLogRepositoryProvider)
          .getLogs(
            deviceId: key.deviceId,
            sessionId: key.chatId,
            page: current.page + 1,
            size: pageSize,
          );
      if (generation != _generation) return;
      final latest = state.value;
      if (latest == null) return;
      final seenIds = latest.items.map((item) => item.id).toSet();
      final newItems = response.items
          .where((item) => seenIds.add(item.id))
          .toList(growable: false);
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...newItems],
          page: response.page,
          totalElements: response.totalElements,
          hasNext: response.hasNext,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(
          latest.copyWith(
            isLoadingMore: false,
            loadMoreError: error.toString(),
          ),
        );
      }
    } finally {
      if (generation == _generation) _isLoadingOlder = false;
    }
  }
}

class ChatHistoryState {
  const ChatHistoryState({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.hasNext,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  factory ChatHistoryState.fromFirstPage(ChatLogPageResponse response) {
    return ChatHistoryState(
      items: response.items,
      page: response.page,
      totalElements: response.totalElements,
      hasNext: response.hasNext,
    );
  }

  final List<ChatLogResponse> items;
  final int page;
  final int totalElements;
  final bool hasNext;
  final bool isLoadingMore;
  final String? loadMoreError;

  ChatHistoryState copyWith({
    List<ChatLogResponse>? items,
    int? page,
    int? totalElements,
    bool? hasNext,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ChatHistoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

class ChatHistoryController extends AsyncNotifier<ChatHistoryState> {
  ChatHistoryController(this.deviceId);

  static const int pageSize = ChatLogRepository.defaultPageSize;

  final String deviceId;

  var _requestGeneration = 0;
  var _isLoadingMore = false;
  var _isRefreshing = false;

  @override
  Future<ChatHistoryState> build() async {
    final response = await ref
        .watch(chatLogRepositoryProvider)
        .getLogs(deviceId: deviceId, page: 0, size: pageSize);
    return ChatHistoryState.fromFirstPage(response);
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    final generation = ++_requestGeneration;
    _isLoadingMore = false;
    _isRefreshing = true;

    try {
      final response = await ref
          .read(chatLogRepositoryProvider)
          .getLogs(deviceId: deviceId, page: 0, size: pageSize);
      if (generation != _requestGeneration) return;
      state = AsyncData(ChatHistoryState.fromFirstPage(response));
    } catch (error, stackTrace) {
      if (generation != _requestGeneration) return;
      state = AsyncError(error, stackTrace);
    } finally {
      if (generation == _requestGeneration) {
        _isRefreshing = false;
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (_isRefreshing ||
        _isLoadingMore ||
        state.isLoading ||
        current == null ||
        !current.hasNext) {
      return;
    }

    _isLoadingMore = true;
    final generation = _requestGeneration;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    try {
      final response = await ref
          .read(chatLogRepositoryProvider)
          .getLogs(deviceId: deviceId, page: current.page + 1, size: pageSize);
      if (generation != _requestGeneration) return;

      final latest = state.value;
      if (latest == null) return;
      final seenIds = latest.items.map((item) => item.id).toSet();
      final newItems = response.items
          .where((item) => seenIds.add(item.id))
          .toList(growable: false);
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...newItems],
          page: response.page,
          totalElements: response.totalElements,
          hasNext: response.hasNext,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (generation != _requestGeneration) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadMoreError: error.toString()),
      );
    } finally {
      if (generation == _requestGeneration) {
        _isLoadingMore = false;
      }
    }
  }

  Future<XiaozhiSyncResponse> syncFromXiaozhi() async {
    final result = await ref
        .read(chatLogRepositoryProvider)
        .syncFromXiaozhi(deviceId: deviceId);
    await refresh();
    return result;
  }
}
