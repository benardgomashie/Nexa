import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../models/preferences.dart';
import '../services/profile_service.dart';
import 'service_providers.dart';

/// Profile state
class ProfileState {
  final Profile? profile;
  final MatchingPreference? preferences;
  final LocationPreference? locationPreference;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profile,
    this.preferences,
    this.locationPreference,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    Profile? profile,
    MatchingPreference? preferences,
    LocationPreference? locationPreference,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      locationPreference: locationPreference ?? this.locationPreference,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Profile state notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(ProfileState());

  /// Fetch current user's profile
  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profile = await _profileService.getMyProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch preferences
  Future<void> fetchPreferences() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final preferences = await _profileService.getPreferences();
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update profile
  Future<bool> updateProfile({
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
    print('[PROFILE] Starting profile update...');
    print('[PROFILE] displayName: $displayName');
    print('[PROFILE] ageBucket: $ageBucket');
    print('[PROFILE] intentTags: $intentTags');
    print('[PROFILE] interestTags: $interestTags');
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedProfile = await _profileService.updateProfile(
        displayName: displayName,
        bio: bio,
        pronouns: pronouns,
        ageBucket: ageBucket,
        faith: faith,
        latitude: latitude,
        longitude: longitude,
        city: city,
        intentTags: intentTags,
        interestTags: interestTags,
      );
      
      print('[PROFILE] Profile updated successfully');
      print('[PROFILE] is_complete: ${updatedProfile.isComplete}');
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      print('[PROFILE] Error updating profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload photo
  Future<bool> uploadPhoto(File imageFile, {int? order}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final photo = await _profileService.uploadPhoto(imageFile, order: order);
      
      // Add photo to profile
      final currentPhotos = state.profile?.photos ?? [];
      final updatedPhotos = [...currentPhotos, photo];
      
      state = state.copyWith(
        profile: state.profile?.copyWith(photos: updatedPhotos),
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(int photoId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _profileService.deletePhoto(photoId);
      
      // Remove photo from profile
      final currentPhotos = state.profile?.photos ?? [];
      final updatedPhotos = currentPhotos.where((p) => p.id != photoId).toList();
      
      state = state.copyWith(
        profile: state.profile?.copyWith(photos: updatedPhotos),
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update preferences
  Future<bool> updatePreferences({
    List<String>? intents,
    List<String>? interests,
    List<String>? ageBuckets,
    Map<String, bool>? availability,
    String? faithFilter,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedPreferences = await _profileService.updatePreferences(
        intents: intents,
        interests: interests,
        ageBuckets: ageBuckets,
        availability: availability,
        faithFilter: faithFilter,
      );
      
      state = state.copyWith(
        preferences: updatedPreferences,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update location preference
  Future<bool> updateLocationPreference({
    required double latitude,
    required double longitude,
    String? city,
    required int radiusKm,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedLocation = await _profileService.updateLocationPreference(
        latitude: latitude,
        longitude: longitude,
        city: city,
        radiusKm: radiusKm,
      );
      
      state = state.copyWith(
        locationPreference: updatedLocation,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileNotifier(profileService);
});
