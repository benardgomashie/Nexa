import '../models/connection.dart';
import 'api_client.dart';

/// Service for connection management operations
class ConnectionService {
  final ApiClient _apiClient;

  ConnectionService(this._apiClient);

  /// Get all connections (with optional status filter)
  Future<List<Connection>> getConnections({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      '/connections/',
      queryParameters: queryParams,
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => Connection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get received connection requests
  Future<List<Connection>> getReceivedRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/connections/received/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => Connection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get sent connection requests
  Future<List<Connection>> getSentRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/connections/sent/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => Connection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get accepted connections (matches)
  Future<List<Connection>> getMatches({
    int limit = 20,
    int offset = 0,
  }) async {
    return getConnections(
      status: 'accepted',
      limit: limit,
      offset: offset,
    );
  }

  /// Accept a connection request
  Future<Connection> acceptConnection(int connectionId) async {
    final response = await _apiClient.post(
      '/connections/$connectionId/accept/',
    );

    return Connection.fromJson(response.data);
  }

  /// Reject a connection request
  Future<void> rejectConnection(int connectionId) async {
    await _apiClient.post(
      '/connections/$connectionId/reject/',
    );
  }

  /// Block a user
  Future<void> blockUser(int userId) async {
    await _apiClient.post(
      '/connections/block/',
      data: {'user_id': userId},
    );
  }

  /// Unblock a user
  Future<void> unblockUser(int userId) async {
    await _apiClient.post(
      '/connections/unblock/',
      data: {'user_id': userId},
    );
  }

  /// Get blocked users
  Future<List<Connection>> getBlockedUsers({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/connections/blocked/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final results = response.data['results'] as List;
    return results
        .map((json) => Connection.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
