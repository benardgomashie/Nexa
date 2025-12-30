import 'profile.dart';

/// Connection model matching backend schema
class Connection {
  final int id;
  final int fromUserId;
  final int toUserId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final Profile? otherUserProfile;

  Connection({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.otherUserProfile,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as int,
      fromUserId: json['from_user'] as int,
      toUserId: json['to_user'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      otherUserProfile: json['other_user_profile'] != null
          ? Profile.fromJson(json['other_user_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isBlocked => status == 'blocked';
}

/// Connection status constants
class ConnectionStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String blocked = 'blocked';
}
