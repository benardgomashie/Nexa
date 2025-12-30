import '../models/discover.dart';
import '../models/connection.dart';
import 'api_client.dart';

/// Service for discovery and matching operations
class DiscoveryService {
  final ApiClient _apiClient;

  DiscoveryService(this._apiClient);

  /// Get discovery recommendations
  Future<List<DiscoveryProfile>> getDiscovery({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/discover/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
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
  }) async {
    final response = await _apiClient.post(
      '/matching/interest/',
      data: {
        'target_user_id': targetUserId,
        'action': action, // 'like' or 'pass'
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
