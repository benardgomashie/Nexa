import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover.dart';
import '../models/connection.dart';
import '../services/discovery_service.dart';
import 'service_providers.dart';

// Re-export DiscoveryFilters for convenience
export '../services/discovery_service.dart' show DiscoveryFilters;

/// Discovery state
class DiscoveryState {
  final List<DiscoveryProfile> profiles;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final Connection? newMatch;
  final DiscoveryFilters filters;

  DiscoveryState({
    this.profiles = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.newMatch,
    DiscoveryFilters? filters,
  }) : filters = filters ?? DiscoveryFilters();

  DiscoveryState copyWith({
    List<DiscoveryProfile>? profiles,
    bool? isLoading,
    String? error,
    bool? hasMore,
    Connection? newMatch,
    bool clearNewMatch = false,
    DiscoveryFilters? filters,
  }) {
    return DiscoveryState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      newMatch: clearNewMatch ? null : (newMatch ?? this.newMatch),
      filters: filters ?? this.filters,
    );
  }
}

/// Discovery state notifier
class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final DiscoveryService _discoveryService;

  DiscoveryNotifier(this._discoveryService) : super(DiscoveryState()) {
    loadProfiles();
  }

  /// Load discovery profiles
  Future<void> loadProfiles({bool refresh = false}) async {
    if (state.isLoading) return;
    
    if (refresh) {
      state = DiscoveryState(isLoading: true, filters: state.filters);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final profiles = await _discoveryService.getDiscovery(
        limit: 20,
        offset: refresh ? 0 : state.profiles.length,
        filters: state.filters,
      );

      state = state.copyWith(
        profiles: refresh ? profiles : [...state.profiles, ...profiles],
        isLoading: false,
        hasMore: profiles.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Apply filters and reload profiles
  Future<void> applyFilters(DiscoveryFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadProfiles(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(filters: DiscoveryFilters());
    await loadProfiles(refresh: true);
  }

  /// Express interest (like)
  Future<void> like(int userId, {String? introMessage}) async {
    await _expressInterest(userId, 'like', introMessage: introMessage);
  }

  /// Pass on a profile
  Future<void> pass(int userId) async {
    await _expressInterest(userId, 'pass');
  }

  Future<void> _expressInterest(int userId, String action, {String? introMessage}) async {
    try {
      // Remove profile from list optimistically
      final updatedProfiles = state.profiles
          .where((p) => p.userId != userId)
          .toList();
      
      state = state.copyWith(profiles: updatedProfiles);

      // Send to backend
      final connection = await _discoveryService.expressInterest(
        targetUserId: userId,
        action: action,
        introMessage: introMessage,
      );

      // If mutual match, show notification
      if (connection != null) {
        state = state.copyWith(newMatch: connection);
      }

      // Load more if running low
      if (updatedProfiles.length < 5 && state.hasMore) {
        loadProfiles();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Don't reload profiles on error - user can retry
    }
  }

  /// Clear new match notification
  void clearNewMatch() {
    state = state.copyWith(clearNewMatch: true);
  }

  /// Refresh profiles
  Future<void> refresh() async {
    await loadProfiles(refresh: true);
  }
}

/// Discovery provider
final discoveryProvider = StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final discoveryService = ref.watch(discoveryServiceProvider);
  return DiscoveryNotifier(discoveryService);
});
