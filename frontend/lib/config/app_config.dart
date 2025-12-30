/// Application configuration constants
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  
  // App Information
  static const String appName = 'Nexa';
  static const String appTagline = 'Human connection, simplified.';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int discoverPageSize = 10;
  
  // Image Settings
  static const int maxProfilePhotos = 3;
  static const double maxImageSizeMB = 5.0;
  
  // Location Settings
  static const double defaultRadiusKm = 25.0;
  static const double minRadiusKm = 5.0;
  static const double maxRadiusKm = 50.0;
  
  // Chat Settings
  static const int messageRefreshIntervalSeconds = 5;
  
  // Timeouts
  static const int apiTimeoutSeconds = 10;
  static const int uploadTimeoutSeconds = 60;
}
