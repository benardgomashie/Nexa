import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'service_providers.dart';

/// Auth state notifier
class AuthState {
  final User? user;
  final Profile? profile;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    Profile? profile,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiClient _apiClient;

  AuthNotifier(this._authService, this._apiClient) : super(AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkAuthStatus() async {
    print('[AUTH] Starting auth check...');
    state = state.copyWith(isLoading: true);
    print('[AUTH] State set to loading');
    
    try {
      final isAuth = await _authService.isAuthenticated();
      print('[AUTH] isAuthenticated result: $isAuth');
      
      if (isAuth) {
        print('[AUTH] User appears authenticated, fetching profile...');
        // Fetch user profile
        await fetchCurrentUser();
      } else {
        print('[AUTH] No authentication found, setting authenticated=false');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        print('[AUTH] State updated: isLoading=false, isAuthenticated=false');
      }
    } catch (e) {
      print('[AUTH] Error during auth check: $e');
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  /// Fetch current user and profile
  Future<void> fetchCurrentUser() async {
    print('[AUTH] Fetching current user from /me/...');
    try {
      final response = await _apiClient.get('/me/');
      print('[AUTH] Response received: ${response.statusCode}');
      print('[AUTH] Response data: ${response.data}');
      print('[AUTH] Photos in response: ${response.data['photos']}');
      
      // The /me/ endpoint returns profile data directly
      final profile = Profile.fromJson(response.data);
      print('[AUTH] Parsed profile photos count: ${profile.photos.length}');
      for (var photo in profile.photos) {
        print('[AUTH] Photo: id=${photo.id}, image=${photo.image}');
      }
      
      // Create a basic User object from the profile data
      final user = User(
        id: response.data['id'],
        email: response.data['email'],
        firstName: response.data['first_name'],
        lastName: response.data['last_name'],
        isActive: true,
      );
      
      print('[AUTH] User parsed successfully: ${user.email}');
      state = state.copyWith(
        user: user,
        profile: profile,
        isAuthenticated: true,
        isLoading: false,
      );
      print('[AUTH] State updated: authenticated=true, loading=false');
    } catch (e) {
      print('[AUTH] Error fetching user: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Failed to fetch user data',
      );
      print('[AUTH] State updated after error: authenticated=false, loading=false');
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.login(
      email: email,
      password: password,
    );
    
    if (result['success'] == true) {
      await fetchCurrentUser();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'],
      );
      return false;
    }
  }

  /// Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.register(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      firstName: firstName,
      lastName: lastName,
    );
    
    state = state.copyWith(isLoading: false);
    return result;
  }

  /// Verify email
  Future<Map<String, dynamic>> verifyEmail({
    required String uidb64,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.verifyEmail(
      uidb64: uidb64,
      token: token,
    );
    
    state = state.copyWith(isLoading: false);
    return result;
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(isAuthenticated: false);
  }

  /// Update profile in state
  void updateProfile(Profile profile) {
    state = state.copyWith(profile: profile);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(authService, apiClient);
});
