import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import 'package:intl/intl.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Load activities with current location
      ref.read(activitiesProvider.notifier).loadActivities(
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showLocationError('Failed to get location: $e');
    }
  }

  void _showLocationError(String message) {
    setState(() => _isLoadingLocation = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activityCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nearby'),
            Tab(text: 'My Events'),
            Tab(text: 'Joined'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          categoriesAsync.when(
            data: (categories) => _buildCategoryChips(categories, selectedCategory),
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNearbyTab(),
                _buildMyEventsTab(),
                _buildJoinedTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/activities/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Activity'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildCategoryChips(List<ActivityCategory> categories, int? selectedCategory) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: selectedCategory == null,
                onSelected: (_) {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                  ref.read(activitiesProvider.notifier).filterByCategory(null);
                },
              ),
            );
          }

          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${category.icon} ${category.name}'),
              selected: selectedCategory == category.id,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).state = category.id;
                ref.read(activitiesProvider.notifier).filterByCategory(category.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyTab() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Location unavailable'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final activitiesState = ref.watch(activitiesProvider);

    if (activitiesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activitiesState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${activitiesState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(activitiesProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (activitiesState.activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No activities nearby'),
            const SizedBox(height: 8),
            Text(
              'Be the first to create one!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(activitiesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activitiesState.activities.length,
        itemBuilder: (context, index) {
          final activity = activitiesState.activities[index];
          return ActivityCard(
            activity: activity,
            onTap: () => context.push('/activities/${activity.id}'),
          );
        },
      ),
    );
  }

  Widget _buildMyEventsTab() {
    final myHostedAsync = ref.watch(myHostedActivitiesProvider);

    return myHostedAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No events created yet'),
                SizedBox(height: 8),
                Text(
                  'Create your first activity!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myHostedActivitiesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ActivityCard(
                activity: activity,
                onTap: () => context.push('/activities/${activity.id}'),
                showHostBadge: true,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildJoinedTab() {
    final joinedAsync = ref.watch(myJoinedActivitiesProvider);

    return joinedAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No activities joined'),
                SizedBox(height: 8),
                Text(
                  'Explore nearby activities!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myJoinedActivitiesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ActivityCard(
                activity: activity,
                onTap: () => context.push('/activities/${activity.id}'),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ActivityFilterSheet(
        currentRadius: 50.0,
        onRadiusChanged: (radius) {
          ref.read(activitiesProvider.notifier).setRadius(radius);
        },
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final bool showHostBadge;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.showHostBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and badge
              Row(
                children: [
                  if (activity.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activity.category!.icon} ${activity.category!.name}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  if (showHostBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Host',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (activity.distance != null)
                    Text(
                      _formatDistance(activity.distance!),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description preview
              if (activity.description != null &&
                  activity.description!.isNotEmpty)
                Text(
                  activity.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Date and time
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(activity.dateTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (activity.location.name != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.location.name!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Participants
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.confirmedCount}/${activity.capacity} spots',
                    style: TextStyle(
                      color: activity.isFull ? Colors.orange : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: activity.isFull ? FontWeight.w600 : null,
                    ),
                  ),
                  if (activity.isFull) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FULL',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Host info
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      activity.host.displayName.isNotEmpty
                          ? activity.host.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hosted by ${activity.host.displayName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    }
    return '${distanceKm.toStringAsFixed(1)}km away';
  }
}

class _ActivityFilterSheet extends StatefulWidget {
  final double currentRadius;
  final ValueChanged<double> onRadiusChanged;

  const _ActivityFilterSheet({
    required this.currentRadius,
    required this.onRadiusChanged,
  });

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.currentRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Distance slider
          Text(
            'Distance: ${_radius.round()} km',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: _radius,
            min: 1,
            max: 100,
            divisions: 99,
            label: '${_radius.round()} km',
            onChanged: (value) {
              setState(() => _radius = value);
            },
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onRadiusChanged(_radius);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
