import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// HTTP client for making API requests to the Norvi backend
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to requests
          final accessToken = await storage.read(key: AppConfig.accessTokenKey);
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - attempt token refresh
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request
              final options = error.requestOptions;
              final accessToken = await storage.read(key: AppConfig.accessTokenKey);
              options.headers['Authorization'] = 'Bearer $accessToken';
              
              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Refresh the access token using the refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        '/auth/token-refresh/',
        data: {'refresh': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await storage.write(key: AppConfig.accessTokenKey, value: newAccessToken);
        return true;
      }
      return false;
    } catch (e) {
      // Refresh failed - user needs to login again
      await clearTokens();
      return false;
    }
  }
  
  /// Store authentication tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: AppConfig.accessTokenKey, value: accessToken);
    await storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
  }
  
  /// Clear authentication tokens (logout)
  Future<void> clearTokens() async {
    await storage.delete(key: AppConfig.accessTokenKey);
    await storage.delete(key: AppConfig.refreshTokenKey);
    await storage.delete(key: AppConfig.userIdKey);
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await storage.read(key: AppConfig.accessTokenKey);
    print('[API_CLIENT] Checking authentication, accessToken: ${accessToken != null ? "EXISTS" : "NULL"}');
    return accessToken != null;
  }
  
  // HTTP Methods
  
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// Upload file with multipart/form-data
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?data,
    });
    
    return await _dio.post(
      path,
      data: formData,
      options: Options(
        sendTimeout: Duration(seconds: AppConfig.uploadTimeoutSeconds),
      ),
    );
  }
}
