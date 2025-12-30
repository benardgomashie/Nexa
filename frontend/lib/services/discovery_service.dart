import '../models/discover.dart';
import '../models/connection.dart';
import 'api_client.dart';

/// Discovery filter options
class DiscoveryFilters {
  final int? radiusKm;
  final String? intent;
  final String? interest;
  final String? faith; // 'same' or 'all'

  DiscoveryFilters({
    this.radiusKm,
    this.intent,
    this.interest,
    this.faith,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (radiusKm != null) params['radius_km'] = radiusKm;
    if (intent != null && intent!.isNotEmpty) params['intent'] = intent;
    if (interest != null && interest!.isNotEmpty) params['interest'] = interest;
    if (faith != null && faith!.isNotEmpty) params['faith'] = faith;
    return params;
  }

  DiscoveryFilters copyWith({
    int? radiusKm,
    String? intent,
    String? interest,
    String? faith,
    bool clearRadius = false,
    bool clearIntent = false,
    bool clearInterest = false,
    bool clearFaith = false,
  }) {
    return DiscoveryFilters(
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
      intent: clearIntent ? null : (intent ?? this.intent),
      interest: clearInterest ? null : (interest ?? this.interest),
      faith: clearFaith ? null : (faith ?? this.faith),
    );
  }

  bool get hasActiveFilters =>
      radiusKm != null || 
      (intent != null && intent!.isNotEmpty) || 
      (interest != null && interest!.isNotEmpty) ||
      (faith != null && faith!.isNotEmpty);
}

/// Service for discovery and matching operations
class DiscoveryService {
  final ApiClient _apiClient;

  DiscoveryService(this._apiClient);

  /// Get discovery recommendations
  Future<List<DiscoveryProfile>> getDiscovery({
    int limit = 10,
    int offset = 0,
    DiscoveryFilters? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    
    // Add filter params if provided
    if (filters != null) {
      queryParams.addAll(filters.toQueryParams());
    }

    final response = await _apiClient.get(
      '/discover/',
      queryParameters: queryParams,
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => DiscoveryProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Express interest (like/pass)
  Future<Connection?> expressInterest({
    required int targetUserId,
    required String action,
    String? introMessage,
  }) async {
    final response = await _apiClient.post(
      '/matching/interest/',
      data: {
        'target_user_id': targetUserId,
        'action': action, // 'like' or 'pass'
        if (introMessage != null && introMessage.isNotEmpty) 
          'intro_message': introMessage,
      },
    );

    // Returns connection if mutual, null otherwise
    if (response.data['mutual'] == true) {
      return Connection.fromJson(response.data['connection']);
    }
    return null;
  }

  /// Get discovery statistics
  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.get('/matching/stats/');
    return {
      'total_profiles': response.data['total_profiles'] as int,
      'profiles_viewed': response.data['profiles_viewed'] as int,
      'profiles_remaining': response.data['profiles_remaining'] as int,
    };
  }
}
