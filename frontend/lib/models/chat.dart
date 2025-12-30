import 'profile.dart';

/// ChatThread model matching backend schema
class ChatThread {
  final int id;
  final int user1Id;
  final int user2Id;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final Profile? otherUserProfile;
  final ChatMessage? lastMessage;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.lastMessageAt,
    this.otherUserProfile,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as int,
      user1Id: json['user1'] as int,
      user2Id: json['user2'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      otherUserProfile: json['other_user_profile'] != null
          ? Profile.fromJson(json['other_user_profile'] as Map<String, dynamic>)
          : null,
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  DateTime get updatedAt => lastMessageAt ?? createdAt;

  ChatThread copyWith({
    int? id,
    int? user1Id,
    int? user2Id,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    Profile? otherUserProfile,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      otherUserProfile: otherUserProfile ?? this.otherUserProfile,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// ChatMessage model matching backend schema
class ChatMessage {
  final int id;
  final int threadId;
  final int senderId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isSender;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.readAt,
    this.isSender = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      threadId: json['thread'] as int,
      senderId: json['sender'] as int,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      isSender: json['is_sender'] as bool? ?? false,
    );
  }

  bool get isRead => readAt != null;
}
