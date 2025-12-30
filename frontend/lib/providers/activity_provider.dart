import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import 'service_providers.dart';

/// State for activities list
class ActivitiesState {
  final List<Activity> activities;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const ActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  ActivitiesState copyWith({
    List<Activity>? activities,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return ActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier for activities list
class ActivitiesNotifier extends StateNotifier<ActivitiesState> {
  final Ref _ref;
  double? _latitude;
  double? _longitude;
  double _radius = 50.0;
  int? _categoryId;

  ActivitiesNotifier(this._ref) : super(const ActivitiesState());

  /// Set user location and fetch activities
  Future<void> loadActivities({
    required double latitude,
    required double longitude,
    double? radius,
    int? categoryId,
    bool refresh = false,
  }) async {
    if (state.isLoading && !refresh) return;

    _latitude = latitude;
    _longitude = longitude;
    if (radius != null) _radius = radius;
    if (categoryId != null) _categoryId = categoryId;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final activityService = _ref.read(activityServiceProvider);
      final activities = await activityService.getActivities(
        latitude: latitude,
        longitude: longitude,
        radius: _radius,
        categoryId: _categoryId,
        status: 'open',
      );

      state = state.copyWith(
        activities: activities,
        isLoading: false,
        hasMore: activities.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh activities with current location
  Future<void> refresh() async {
    if (_latitude != null && _longitude != null) {
      await loadActivities(
        latitude: _latitude!,
        longitude: _longitude!,
        refresh: true,
      );
    }
  }

  /// Filter by category
  void filterByCategory(int? categoryId) {
    _categoryId = categoryId;
    if (_latitude != null && _longitude != null) {
      loadActivities(
        latitude: _latitude!,
        longitude: _longitude!,
        categoryId: categoryId,
        refresh: true,
      );
    }
  }

  /// Update radius filter
  void setRadius(double radius) {
    _radius = radius;
    if (_latitude != null && _longitude != null) {
      loadActivities(
        latitude: _latitude!,
        longitude: _longitude!,
        refresh: true,
      );
    }
  }
}

/// Provider for activities list
final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, ActivitiesState>((ref) {
  return ActivitiesNotifier(ref);
});

/// Provider for activity categories
final activityCategoriesProvider =
    FutureProvider<List<ActivityCategory>>((ref) async {
  final activityService = ref.read(activityServiceProvider);
  return activityService.getCategories();
});

/// Provider for my hosted activities
final myHostedActivitiesProvider =
    FutureProvider<List<Activity>>((ref) async {
  final activityService = ref.read(activityServiceProvider);
  return activityService.getMyHostedActivities();
});

/// Provider for my joined activities
final myJoinedActivitiesProvider =
    FutureProvider<List<Activity>>((ref) async {
  final activityService = ref.read(activityServiceProvider);
  return activityService.getMyJoinedActivities();
});

/// Provider for activity detail
final activityDetailProvider =
    FutureProvider.family<ActivityDetail, int>((ref, activityId) async {
  final activityService = ref.read(activityServiceProvider);
  return activityService.getActivityDetail(activityId);
});

/// Provider for activity participants
final activityParticipantsProvider =
    FutureProvider.family<List<ActivityParticipant>, int>((ref, activityId) async {
  final activityService = ref.read(activityServiceProvider);
  return activityService.getParticipants(activityId);
});

/// State for activity chat
class ActivityChatState {
  final List<ActivityMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ActivityChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ActivityChatState copyWith({
    List<ActivityMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ActivityChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Notifier for activity chat
class ActivityChatNotifier extends StateNotifier<ActivityChatState> {
  final Ref _ref;
  final int activityId;

  ActivityChatNotifier(this._ref, this.activityId)
      : super(const ActivityChatState()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final activityService = _ref.read(activityServiceProvider);
      final messages = await activityService.getChatMessages(activityId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(isSending: true, error: null);

    try {
      final activityService = _ref.read(activityServiceProvider);
      final message = await activityService.sendChatMessage(activityId, content);
      state = state.copyWith(
        messages: [...state.messages, message],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  void refresh() => loadMessages();
}

/// Provider factory for activity chat
final activityChatProvider = StateNotifierProvider.family<ActivityChatNotifier,
    ActivityChatState, int>((ref, activityId) {
  return ActivityChatNotifier(ref, activityId);
});

/// Selected category filter provider
final selectedCategoryProvider = StateProvider<int?>((ref) => null);
