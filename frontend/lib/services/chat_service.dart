import '../models/chat.dart';
import 'api_client.dart';

/// Service for chat operations
class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  /// Get all chat threads
  Future<List<ChatThread>> getThreads({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/chat/threads/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => ChatThread.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific thread
  Future<ChatThread> getThread(int threadId) async {
    final response = await _apiClient.get('/chat/threads/$threadId/');
    return ChatThread.fromJson(response.data);
  }

  /// Get messages for a thread
  Future<List<ChatMessage>> getMessages({
    required int threadId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/chat/threads/$threadId/messages/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Send a message
  Future<ChatMessage> sendMessage({
    required int threadId,
    required String content,
  }) async {
    final response = await _apiClient.post(
      '/chat/threads/$threadId/messages/',
      data: {
        'content': content,
      },
    );

    return ChatMessage.fromJson(response.data);
  }

  /// Mark messages as read
  Future<void> markAsRead(int threadId) async {
    await _apiClient.post(
      '/chat/threads/$threadId/read/',
    );
  }

  /// Get or create a thread with a user
  Future<ChatThread> getOrCreateThread(int otherUserId) async {
    final response = await _apiClient.post(
      '/chat/threads/create/',
      data: {
        'other_user_id': otherUserId,
      },
    );

    return ChatThread.fromJson(response.data);
  }
}
