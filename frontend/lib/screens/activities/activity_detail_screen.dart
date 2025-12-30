import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../providers/service_providers.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  bool _isJoining = false;
  bool _isLeaving = false;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityDetailProvider(widget.activityId));

    return Scaffold(
      body: activityAsync.when(
        data: (activity) => _buildContent(activity),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(activityDetailProvider(widget.activityId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ActivityDetail activity) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (activity.category != null)
                        Text(
                          activity.category!.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                      const SizedBox(height: 8),
                      if (activity.category != null)
                        Text(
                          activity.category!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            if (activity.isHost)
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel Activity', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    // TODO: Navigate to edit screen
                  } else if (value == 'cancel') {
                    _showCancelDialog(activity);
                  }
                },
              ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Host info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        activity.host.displayName.isNotEmpty
                            ? activity.host.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hosted by',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          activity.host.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (activity.isHost) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "You're hosting",
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Date & Time
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Date & Time',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(activity.dateTime),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        timeFormat.format(activity.dateTime),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (activity.durationMinutes != null)
                        Text(
                          'Duration: ${_formatDuration(activity.durationMinutes!)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Location',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity.location.name != null)
                        Text(
                          activity.location.name!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      if (activity.location.address != null)
                        Text(
                          activity.location.address!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      if (activity.distance != null)
                        Text(
                          _formatDistance(activity.distance!),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Participants
                _buildInfoCard(
                  icon: Icons.people,
                  title: 'Participants',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activity.confirmedCount}/${activity.capacity} spots filled',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (activity.spotsLeft > 0)
                        Text(
                          '${activity.spotsLeft} spots remaining',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        const Text(
                          'Activity is full',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: activity.isHost
                      ? TextButton(
                          onPressed: () =>
                              _showParticipantsSheet(activity),
                          child: const Text('Manage'),
                        )
                      : null,
                ),
                const SizedBox(height: 24),

                // Description
                if (activity.description != null &&
                    activity.description!.isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Confirmed participants preview
                if (activity.confirmedParticipants.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'Who\'s Going',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showParticipantsSheet(activity),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activity.confirmedParticipants.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final participant = activity.confirmedParticipants[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  participant.displayName.isNotEmpty
                                      ? participant.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                participant.displayName.split(' ').first,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Chat button for participants
                if (activity.myStatus == ParticipantStatus.confirmed ||
                    activity.isHost) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push('/activities/${activity.id}/chat'),
                    icon: const Icon(Icons.chat),
                    label: const Text('Group Chat'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget content,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                content,
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildBottomBar(ActivityDetail activity) {
    // Host doesn't need join button
    if (activity.isHost) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => context.push('/activities/${activity.id}/chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Open Group Chat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Already joined - show leave button
    if (activity.myStatus != null) {
      final isPending = activity.myStatus == ParticipantStatus.pending;
      final isConfirmed = activity.myStatus == ParticipantStatus.confirmed;

      if (isPending || isConfirmed) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending ? '⏳ Waiting for approval' : '✅ You\'re going!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPending ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isLeaving ? null : () => _leaveActivity(activity),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: _isLeaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Leave'),
              ),
            ],
          ),
        );
      }
    }

    // Not joined - show join button
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: activity.isFull || _isJoining
            ? null
            : () => _showJoinDialog(activity),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isJoining
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                activity.isFull ? 'Activity is Full' : 'Request to Join',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showJoinDialog(ActivityDetail activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a message for the host (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Hi! I\'d love to join...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinActivity(activity);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinActivity(ActivityDetail activity) async {
    setState(() => _isJoining = true);

    try {
      final activityService = ref.read(activityServiceProvider);
      await activityService.joinActivity(
        activity.id,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      _messageController.clear();

      // Refresh activity detail
      ref.refresh(activityDetailProvider(widget.activityId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _leaveActivity(ActivityDetail activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Activity?'),
        content: const Text(
          'Are you sure you want to leave this activity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLeaving = true);

    try {
      final activityService = ref.read(activityServiceProvider);
      await activityService.leaveActivity(activity.id);

      // Refresh activity detail
      ref.refresh(activityDetailProvider(widget.activityId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the activity')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  void _showParticipantsSheet(ActivityDetail activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => _ParticipantsSheet(
          activity: activity,
          scrollController: scrollController,
          isHost: activity.isHost,
          onAction: () {
            Navigator.pop(context);
            ref.refresh(activityDetailProvider(widget.activityId));
          },
        ),
      ),
    );
  }

  void _showCancelDialog(ActivityDetail activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Activity?'),
        content: const Text(
          'This will cancel the activity for all participants. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Activity'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelActivity(activity);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Activity'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelActivity(ActivityDetail activity) async {
    try {
      final activityService = ref.read(activityServiceProvider);
      await activityService.updateActivity(activity.id, {'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity cancelled')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }
}

class _ParticipantsSheet extends ConsumerWidget {
  final ActivityDetail activity;
  final ScrollController scrollController;
  final bool isHost;
  final VoidCallback onAction;

  const _ParticipantsSheet({
    required this.activity,
    required this.scrollController,
    required this.isHost,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = activity.pendingParticipants;
    final confirmed = activity.confirmedParticipants;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Participants',
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
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Pending requests (host only)
              if (isHost && pending.isNotEmpty) ...[
                Text(
                  'Pending Requests (${pending.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...pending.map((p) => _ParticipantTile(
                      participant: p,
                      isHost: true,
                      activityId: activity.id,
                      onAction: onAction,
                    )),
                const SizedBox(height: 24),
              ],

              // Confirmed participants
              Text(
                'Going (${confirmed.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (confirmed.isEmpty)
                const Text(
                  'No confirmed participants yet',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...confirmed.map((p) => _ParticipantTile(
                      participant: p,
                      isHost: isHost,
                      activityId: activity.id,
                      onAction: onAction,
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  final ActivityParticipant participant;
  final bool isHost;
  final int activityId;
  final VoidCallback onAction;

  const _ParticipantTile({
    required this.participant,
    required this.isHost,
    required this.activityId,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = participant.status == ParticipantStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                participant.displayName.isNotEmpty
                    ? participant.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (participant.message != null &&
                      participant.message!.isNotEmpty)
                    Text(
                      participant.message!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isHost && isPending) ...[
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _respond(ref, context, 'approve'),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _respond(ref, context, 'decline'),
              ),
            ] else if (isHost && !isPending) ...[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _respond(ref, context, 'remove'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _respond(WidgetRef ref, BuildContext context, String action) async {
    try {
      final activityService = ref.read(activityServiceProvider);
      await activityService.respondToJoinRequest(
        activityId,
        participant.userId,
        action,
      );

      onAction();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
