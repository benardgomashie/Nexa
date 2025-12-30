import 'dart:io';
import 'package:dio/dio.dart';
import '../models/profile.dart';
import '../models/preferences.dart';
import 'api_client.dart';

/// Service for profile-related API operations
class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  /// Get the current user's profile
  Future<Profile> getMyProfile() async {
    final response = await _apiClient.get('/me/');
    return Profile.fromJson(response.data);
  }

  /// Get a profile by user ID
  Future<Profile> getProfile(int userId) async {
    final response = await _apiClient.get('/profiles/$userId/');
    return Profile.fromJson(response.data);
  }

  /// Update the current user's profile
  Future<Profile> updateProfile({
    String? displayName,
    String? bio,
    String? pronouns,
    String? ageBucket,
    String? faith,
    double? latitude,
    double? longitude,
    String? city,
    List<String>? intentTags,
    List<String>? interestTags,
  }) async {
    final data = <String, dynamic>{};
    
    if (displayName != null) data['display_name'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (pronouns != null) data['pronouns'] = pronouns;
    if (ageBucket != null) data['age_bucket'] = ageBucket;
    if (faith != null) data['faith'] = faith;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (city != null) data['city'] = city;
    if (intentTags != null) data['intent_tags'] = intentTags;
    if (interestTags != null) data['interest_tags'] = interestTags;

    print('[PROFILE_SERVICE] Sending PATCH to /me/');
    print('[PROFILE_SERVICE] Request data: $data');
    
    try {
      final response = await _apiClient.patch('/me/', data: data);
      
      print('[PROFILE_SERVICE] Response status: ${response.statusCode}');
      print('[PROFILE_SERVICE] Response data: ${response.data}');
      
      return Profile.fromJson(response.data);
    } catch (e) {
      print('[PROFILE_SERVICE] Error: $e');
      if (e is DioException && e.response != null) {
        print('[PROFILE_SERVICE] Error response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Upload a profile photo
  Future<ProfilePhoto> uploadPhoto(File imageFile, {int? order}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      if (order != null) 'order': order,
    });

    final response = await _apiClient.post(
      '/me/photos/',
      data: formData,
    );

    return ProfilePhoto.fromJson(response.data);
  }

  /// Delete a profile photo
  Future<void> deletePhoto(int photoId) async {
    await _apiClient.delete('/me/photos/$photoId/');
  }

  /// Reorder profile photos
  Future<void> reorderPhotos(List<int> photoIds) async {
    await _apiClient.post(
      '/me/photos/reorder/',
      data: {'photo_ids': photoIds},
    );
  }

  /// Get matching preferences
  Future<MatchingPreference> getPreferences() async {
    final response = await _apiClient.get('/me/preferences/');
    return MatchingPreference.fromJson(response.data);
  }

  /// Update matching preferences
  Future<MatchingPreference> updatePreferences({
    List<String>? intents,
    List<String>? interests,
    List<String>? ageBuckets,
    Map<String, bool>? availability,
    String? faithFilter,
  }) async {
    final data = <String, dynamic>{};
    
    if (intents != null) data['intents'] = intents;
    if (interests != null) data['interests'] = interests;
    if (ageBuckets != null) data['age_buckets'] = ageBuckets;
    if (availability != null) data['availability'] = availability;
    if (faithFilter != null) data['faith_filter'] = faithFilter;

    final response = await _apiClient.patch(
      '/me/preferences/',
      data: data,
    );
    
    return MatchingPreference.fromJson(response.data);
  }

  /// Update location preferences
  Future<LocationPreference> updateLocationPreference({
    double? latitude,
    double? longitude,
    String? city,
    int? radiusKm,
  }) async {
    final data = <String, dynamic>{};
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (city != null) data['city'] = city;
    if (radiusKm != null) data['radius_km'] = radiusKm;

    final response = await _apiClient.patch(
      '/me/preferences/',
      data: {'location': data},
    );
    
    return LocationPreference.fromJson(response.data['location'] ?? response.data);
  }

  /// Get combined preferences (location + matching)
  Future<Map<String, dynamic>> getCombinedPreferences() async {
    final response = await _apiClient.get('/me/preferences/');
    return {
      'visible': response.data['matching']?['visible'] ?? true,
      'radius_km': response.data['location']?['radius_km'] ?? 25,
      'latitude': response.data['location']?['latitude'],
      'longitude': response.data['location']?['longitude'],
      'city': response.data['location']?['city'],
    };
  }

  /// Update visibility (show/hide profile in discovery)
  Future<void> updateVisibility(bool visible) async {
    await _apiClient.patch(
      '/me/preferences/',
      data: {
        'matching': {'visible': visible}
      },
    );
  }

  /// Get available tags
  Future<Map<String, List<String>>> getAvailableTags() async {
    final response = await _apiClient.get('/profiles/tags/');
    return {
      'intents': List<String>.from(response.data['intents'] ?? []),
      'interests': List<String>.from(response.data['interests'] ?? []),
    };
  }
}
