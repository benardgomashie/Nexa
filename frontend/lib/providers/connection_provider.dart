import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/profile.dart';
import '../services/connection_service.dart';
import 'service_providers.dart';

/// Connection state
class ConnectionState {
  final List<Connection> receivedRequests;
  final List<Connection> sentRequests;
  final List<Connection> matches;
  final bool isLoading;
  final String? error;

  ConnectionState({
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.matches = const [],
    this.isLoading = false,
    this.error,
  });

  ConnectionState copyWith({
    List<Connection>? receivedRequests,
    List<Connection>? sentRequests,
    List<Connection>? matches,
    bool? isLoading,
    String? error,
  }) {
    return ConnectionState(
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalPendingCount => receivedRequests.length;
}

/// Connection state notifier
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final ConnectionService _connectionService;

  ConnectionNotifier(this._connectionService) : super(ConnectionState()) {
    loadAll();
  }

  /// Load all connection data
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _connectionService.getReceivedRequests(),
        _connectionService.getSentRequests(),
        _connectionService.getMatches(),
      ]);

      state = state.copyWith(
        receivedRequests: results[0],
        sentRequests: results[1],
        matches: results[2],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load received requests
  Future<void> loadReceivedRequests() async {
    try {
      final requests = await _connectionService.getReceivedRequests();
      state = state.copyWith(receivedRequests: requests);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load sent requests
  Future<void> loadSentRequests() async {
    try {
      final requests = await _connectionService.getSentRequests();
      state = state.copyWith(sentRequests: requests);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load matches
  Future<void> loadMatches() async {
    try {
      final matches = await _connectionService.getMatches();
      state = state.copyWith(matches: matches);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Accept a connection request
  Future<bool> acceptConnection(int connectionId) async {
    try {
      await _connectionService.acceptConnection(connectionId);
      
      // Remove from received, reload matches
      final updatedReceived = state.receivedRequests
          .where((c) => c.id != connectionId)
          .toList();
      
      state = state.copyWith(receivedRequests: updatedReceived);
      
      // Reload matches to include the new one
      await loadMatches();
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reject a connection request
  Future<bool> rejectConnection(int connectionId) async {
    try {
      await _connectionService.rejectConnection(connectionId);
      
      // Remove from received requests
      final updatedReceived = state.receivedRequests
          .where((c) => c.id != connectionId)
          .toList();
      
      state = state.copyWith(receivedRequests: updatedReceived);
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Block a user
  Future<bool> blockUser(int userId) async {
    try {
      await _connectionService.blockUser(userId);
      
      // Remove from all lists
      final updatedReceived = state.receivedRequests
          .where((c) => c.otherUserProfile?.userId != userId)
          .toList();
      final updatedSent = state.sentRequests
          .where((c) => c.otherUserProfile?.userId != userId)
          .toList();
      final updatedMatches = state.matches
          .where((c) => c.otherUserProfile?.userId != userId)
          .toList();
      
      state = state.copyWith(
        receivedRequests: updatedReceived,
        sentRequests: updatedSent,
        matches: updatedMatches,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(int userId) async {
    try {
      await _connectionService.unblockUser(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get blocked users
  Future<List<Profile>> getBlockedUsers() async {
    try {
      final connections = await _connectionService.getBlockedUsers();
      // Extract profiles from connections
      return connections
          .where((c) => c.otherUserProfile != null)
          .map((c) => c.otherUserProfile!)
          .toList();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadAll();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Connection provider
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return ConnectionNotifier(connectionService);
});
