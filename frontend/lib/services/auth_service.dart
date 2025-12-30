import 'package:dio/dio.dart';
import 'api_client.dart';

/// Service for handling authentication operations
class AuthService {
  final ApiClient _apiClient;
  
  AuthService(this._apiClient);
  
  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register/',
        data: {
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Verify email with token
  Future<Map<String, dynamic>> verifyEmail({
    required String uidb64,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-email/',
        data: {
          'uidb64': uidb64,
          'token': token,
        },
      );
      
      if (response.data['tokens'] != null) {
        await _apiClient.saveTokens(
          response.data['tokens']['access'],
          response.data['tokens']['refresh'],
        );
      }
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      // Save tokens
      await _apiClient.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );
      
      return {
        'success': true,
        'user': response.data['user'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Logout and blacklist refresh token
  Future<bool> logout() async {
    try {
      // Note: Backend expects refresh token in request body
      final refreshToken = await _apiClient.storage.read(key: 'refresh_token');
      
      if (refreshToken != null) {
        await _apiClient.post(
          '/auth/logout/',
          data: {'refresh': refreshToken},
        );
      }
      
      await _apiClient.clearTokens();
      return true;
    } catch (e) {
      // Even if API call fails, clear local tokens
      await _apiClient.clearTokens();
      return true;
    }
  }
  
  /// Request password reset
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-reset/',
        data: {'email': email},
      );
      
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Confirm password reset with token
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String uidb64,
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-reset/confirm/',
        data: {
          'uidb64': uidb64,
          'token': token,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );
      
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Resend verification email
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/resend-verification/',
        data: {'email': email},
      );
      
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }
  
  /// Delete user account permanently
  Future<Map<String, dynamic>> deleteAccount({String? password}) async {
    try {
      final response = await _apiClient.delete(
        '/auth/delete-account/',
        data: password != null ? {'password': password} : null,
      );
      
      // Clear local tokens after successful deletion
      await _apiClient.clearTokens();
      
      return {
        'success': true,
        'message': response.data['message'] ?? 'Account deleted successfully.',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }
  
  /// Handle DioException and return user-friendly error message
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      
      // Extract error message from response
      if (data is Map) {
        if (data.containsKey('detail')) {
          return data['detail'];
        }
        if (data.containsKey('error')) {
          return data['error'];
        }
        if (data.containsKey('email')) {
          return data['email'] is List ? data['email'][0] : data['email'];
        }
        if (data.containsKey('password')) {
          return data['password'] is List ? data['password'][0] : data['password'];
        }
        // Return first error message found
        for (var value in data.values) {
          if (value is String) return value;
          if (value is List && value.isNotEmpty) return value[0].toString();
        }
      }
      
      return 'Request failed with status ${e.response!.statusCode}';
    }
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to server. Please check your internet connection.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}
