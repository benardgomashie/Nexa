import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import 'service_providers.dart';

/// Chat state
class ChatState {
  final List<ChatThread> threads;
  final Map<int, List<ChatMessage>> messagesByThread;
  final bool isLoading;
  final String? error;
  final int totalUnreadCount;

  ChatState({
    this.threads = const [],
    this.messagesByThread = const {},
    this.isLoading = false,
    this.error,
    this.totalUnreadCount = 0,
  });

  ChatState copyWith({
    List<ChatThread>? threads,
    Map<int, List<ChatMessage>>? messagesByThread,
    bool? isLoading,
    String? error,
    int? totalUnreadCount,
  }) {
    return ChatState(
      threads: threads ?? this.threads,
      messagesByThread: messagesByThread ?? this.messagesByThread,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }
}

/// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatNotifier(this._chatService) : super(ChatState()) {
    loadThreads();
  }

  /// Load all threads
  Future<void> loadThreads() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final threads = await _chatService.getThreads();
      
      // Calculate total unread count
      final unreadCount = threads.fold<int>(
        0,
        (sum, thread) => sum + thread.unreadCount,
      );

      state = state.copyWith(
        threads: threads,
        isLoading: false,
        totalUnreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load messages for a thread
  Future<void> loadMessages(int threadId) async {
    try {
      final messages = await _chatService.getMessages(threadId: threadId);
      
      // Update messages map
      final updatedMap = Map<int, List<ChatMessage>>.from(state.messagesByThread);
      updatedMap[threadId] = messages;
      
      state = state.copyWith(messagesByThread: updatedMap);
      
      // Mark as read
      await _chatService.markAsRead(threadId);
      
      // Update thread to mark as read
      final updatedThreads = state.threads.map((thread) {
        if (thread.id == threadId) {
          return thread.copyWith(unreadCount: 0);
        }
        return thread;
      }).toList();
      
      // Recalculate unread count
      final unreadCount = updatedThreads.fold<int>(
        0,
        (sum, thread) => sum + thread.unreadCount,
      );
      
      state = state.copyWith(
        threads: updatedThreads,
        totalUnreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required int threadId,
    required String content,
  }) async {
    try {
      final message = await _chatService.sendMessage(
        threadId: threadId,
        content: content,
      );

      // Add message to the thread
      final updatedMap = Map<int, List<ChatMessage>>.from(state.messagesByThread);
      final threadMessages = updatedMap[threadId] ?? [];
      updatedMap[threadId] = [...threadMessages, message];

      // Update thread's last message
      final updatedThreads = state.threads.map((thread) {
        if (thread.id == threadId) {
          return thread.copyWith(
            lastMessage: message,
            updatedAt: message.sentAt,
          );
        }
        return thread;
      }).toList();

      // Sort threads by last message time
      updatedThreads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(
        messagesByThread: updatedMap,
        threads: updatedThreads,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get or create thread with a user
  Future<int?> getOrCreateThread(int otherUserId) async {
    try {
      final thread = await _chatService.getOrCreateThread(otherUserId);
      
      // Check if thread already exists in state
      final existingIndex = state.threads.indexWhere((t) => t.id == thread.id);
      
      if (existingIndex == -1) {
        // Add new thread
        state = state.copyWith(
          threads: [thread, ...state.threads],
        );
      }
      
      return thread.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Refresh threads
  Future<void> refresh() async {
    await loadThreads();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService);
});
