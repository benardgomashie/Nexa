import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/discovery_service.dart';
import '../services/connection_service.dart';
import '../services/chat_service.dart';

/// API Client provider (singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

/// Profile Service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient);
});

/// Discovery Service provider
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DiscoveryService(apiClient);
});

/// Connection Service provider
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConnectionService(apiClient);
});

/// Chat Service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});
