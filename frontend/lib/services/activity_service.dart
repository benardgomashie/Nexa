import '../models/activity.dart';
import 'api_client.dart';

/// Service for Activity-related API calls
class ActivityService {
  final ApiClient _apiClient;

  ActivityService(this._apiClient);

  /// Get all activity categories
  Future<List<ActivityCategory>> getCategories() async {
    try {
      final response = await _apiClient.get('/activities/categories/');
      final List<dynamic> data = response.data;
      return data.map((json) => ActivityCategory.fromJson(json)).toList();
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching categories: $e');
      rethrow;
    }
  }

  /// Get activities near a location
  Future<List<Activity>> getActivities({
    required double latitude,
    required double longitude,
    double? radius,
    int? categoryId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      if (radius != null) queryParams['radius'] = radius;
      if (categoryId != null) queryParams['category'] = categoryId;
      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

      final response = await _apiClient.get(
        '/activities/',
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching activities: $e');
      rethrow;
    }
  }

  /// Get my hosted activities
  Future<List<Activity>> getMyHostedActivities() async {
    try {
      final response = await _apiClient.get(
        '/activities/',
        queryParameters: {'hosted': 'true'},
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching my hosted activities: $e');
      rethrow;
    }
  }

  /// Get activities I've joined
  Future<List<Activity>> getMyJoinedActivities() async {
    try {
      final response = await _apiClient.get(
        '/activities/',
        queryParameters: {'joined': 'true'},
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching joined activities: $e');
      rethrow;
    }
  }

  /// Get activity details
  Future<ActivityDetail> getActivityDetail(int activityId) async {
    try {
      final response = await _apiClient.get('/activities/$activityId/');
      return ActivityDetail.fromJson(response.data);
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching activity detail: $e');
      rethrow;
    }
  }

  /// Create a new activity
  Future<Activity> createActivity(CreateActivityRequest request) async {
    try {
      final response = await _apiClient.post(
        '/activities/',
        data: request.toJson(),
      );
      return Activity.fromJson(response.data);
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error creating activity: $e');
      rethrow;
    }
  }

  /// Update an activity
  Future<Activity> updateActivity(int activityId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '/activities/$activityId/',
        data: data,
      );
      return Activity.fromJson(response.data);
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error updating activity: $e');
      rethrow;
    }
  }

  /// Delete an activity
  Future<void> deleteActivity(int activityId) async {
    try {
      await _apiClient.delete('/activities/$activityId/');
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error deleting activity: $e');
      rethrow;
    }
  }

  /// Join an activity
  Future<void> joinActivity(int activityId, {String? message}) async {
    try {
      final data = <String, dynamic>{};
      if (message != null && message.isNotEmpty) {
        data['message'] = message;
      }
      await _apiClient.post('/activities/$activityId/join/', data: data);
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error joining activity: $e');
      rethrow;
    }
  }

  /// Leave an activity
  Future<void> leaveActivity(int activityId) async {
    try {
      await _apiClient.delete('/activities/$activityId/join/');
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error leaving activity: $e');
      rethrow;
    }
  }

  /// Get activity participants
  Future<List<ActivityParticipant>> getParticipants(int activityId) async {
    try {
      final response = await _apiClient.get('/activities/$activityId/participants/');
      final List<dynamic> data = response.data;
      return data.map((json) => ActivityParticipant.fromJson(json)).toList();
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching participants: $e');
      rethrow;
    }
  }

  /// Respond to a join request (host only)
  Future<void> respondToJoinRequest(
    int activityId,
    int userId,
    String action, // 'approve', 'decline', 'remove'
  ) async {
    try {
      await _apiClient.post(
        '/activities/$activityId/participants/$userId/',
        data: {'action': action},
      );
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error responding to join request: $e');
      rethrow;
    }
  }

  /// Get activity chat messages
  Future<List<ActivityMessage>> getChatMessages(int activityId) async {
    try {
      final response = await _apiClient.get('/activities/$activityId/chat/');
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => ActivityMessage.fromJson(json)).toList();
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error fetching chat messages: $e');
      rethrow;
    }
  }

  /// Send a chat message
  Future<ActivityMessage> sendChatMessage(int activityId, String content) async {
    try {
      final response = await _apiClient.post(
        '/activities/$activityId/chat/',
        data: {'content': content},
      );
      return ActivityMessage.fromJson(response.data);
    } catch (e) {
      print('[ACTIVITY_SERVICE] Error sending chat message: $e');
      rethrow;
    }
  }
}
