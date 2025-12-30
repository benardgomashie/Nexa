import 'profile.dart';

/// Discovery result model matching backend schema
class DiscoveryProfile {
  final int userId;
  final Profile profile;
  final double? distanceKm;
  final int mutualInterestCount;
  final double relevanceScore;
  final String? connectionStatus;

  DiscoveryProfile({
    required this.userId,
    required this.profile,
    this.distanceKm,
    required this.mutualInterestCount,
    required this.relevanceScore,
    this.connectionStatus,
  });

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    return DiscoveryProfile(
      userId: json['user_id'] as int,
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      mutualInterestCount: json['mutual_interest_count'] as int? ?? 0,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      connectionStatus: json['connection_status'] as String?,
    );
  }

  bool get hasConnection => connectionStatus != null;
  bool get isPendingConnection => connectionStatus == 'pending';
  bool get isConnected => connectionStatus == 'accepted';
}
