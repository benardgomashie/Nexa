import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/connection.dart';
import '../../providers/connection_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/report_dialog.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Received',
              icon: Badge(
                label: Text('${connectionState.receivedRequests.length}'),
                isLabelVisible: connectionState.receivedRequests.isNotEmpty,
                child: const Icon(Icons.inbox),
              ),
            ),
            Tab(
              text: 'Sent',
              icon: Badge(
                label: Text('${connectionState.sentRequests.length}'),
                isLabelVisible: connectionState.sentRequests.isNotEmpty,
                child: const Icon(Icons.send),
              ),
            ),
            Tab(
              text: 'Matches',
              icon: Badge(
                label: Text('${connectionState.matches.length}'),
                isLabelVisible: connectionState.matches.isNotEmpty,
                child: const Icon(Icons.favorite),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(connectionProvider.notifier).refresh(),
          ),
        ],
      ),
      body: connectionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ReceivedRequestsTab(
                  requests: connectionState.receivedRequests,
                ),
                _SentRequestsTab(
                  requests: connectionState.sentRequests,
                ),
                _MatchesTab(
                  matches: connectionState.matches,
                ),
              ],
            ),
    );
  }
}

/// Received requests tab
class _ReceivedRequestsTab extends ConsumerWidget {
  final List<Connection> requests;

  const _ReceivedRequestsTab({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No requests',
        subtitle: 'People who like you will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(connectionProvider.notifier).loadReceivedRequests(),
      child: ListView.builder(
        itemCount: requests.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final connection = requests[index];
          return _ConnectionCard(
            connection: connection,
            showActions: true,
            onAccept: () async {
              final success = await ref
                  .read(connectionProvider.notifier)
                  .acceptConnection(connection.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connection accepted!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            onReject: () async {
              final success = await ref
                  .read(connectionProvider.notifier)
                  .rejectConnection(connection.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request rejected'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.headline2),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Sent requests tab
class _SentRequestsTab extends ConsumerWidget {
  final List<Connection> requests;

  const _SentRequestsTab({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('No sent requests', style: AppTheme.headline2),
            const SizedBox(height: 8),
            Text(
              'People you like will appear here',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(connectionProvider.notifier).loadSentRequests(),
      child: ListView.builder(
        itemCount: requests.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final connection = requests[index];
          return _ConnectionCard(
            connection: connection,
            showActions: false,
            subtitle: 'Waiting for response...',
          );
        },
      ),
    );
  }
}

/// Matches tab
class _MatchesTab extends ConsumerWidget {
  final List<Connection> matches;

  const _MatchesTab({required this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('No matches yet', style: AppTheme.headline2),
            const SizedBox(height: 8),
            Text(
              'Start discovering to find matches',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(connectionProvider.notifier).loadMatches(),
      child: ListView.builder(
        itemCount: matches.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final connection = matches[index];
          return _ConnectionCard(
            connection: connection,
            showActions: false,
            showMessageButton: true,
          );
        },
      ),
    );
  }
}

/// Connection card widget
class _ConnectionCard extends ConsumerWidget {
  final Connection connection;
  final bool showActions;
  final bool showMessageButton;
  final String? subtitle;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ConnectionCard({
    required this.connection,
    this.showActions = false,
    this.showMessageButton = false,
    this.subtitle,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = connection.otherUserProfile;
    final hasPhoto = profile?.photos.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile photo
            CircleAvatar(
              radius: 32,
              backgroundImage: hasPhoto
                  ? CachedNetworkImageProvider(profile!.photos.first.image)
                  : null,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: hasPhoto
                  ? null
                  : Icon(
                      Icons.person,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
            ),
            const SizedBox(width: 16),

            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'Anonymous',
                    style: AppTheme.headline3,
                  ),
                  const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else if (profile?.bio != null)
                    Text(
                      profile!.bio!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Action buttons
            if (showActions) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.close),
                color: AppTheme.error,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.error.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAccept,
                icon: const Icon(Icons.check),
                color: AppTheme.success,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.success.withOpacity(0.1),
                ),
              ),
            ],

            // Message button
            if (showMessageButton) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  // Get or create thread and navigate to chat
                  final threadId = await ref
                      .read(chatProvider.notifier)
                      .getOrCreateThread(connection.otherUserProfile!.id);
                  
                  if (threadId != null && context.mounted) {
                    context.push('/chat/$threadId');
                  }
                },
                icon: const Icon(Icons.message),
                color: AppTheme.primaryColor,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
            ],
            
            // Menu button
            IconButton(
              onPressed: () => _showConnectionMenu(context, ref, connection),
              icon: const Icon(Icons.more_vert),
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionMenu(BuildContext context, WidgetRef ref, Connection connection) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.block, color: AppTheme.error),
              title: const Text('Block'),
              onTap: () async {
                Navigator.pop(context);
                
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => BlockConfirmDialog(
                    userName: connection.otherUserProfile?.displayName ?? 'this user',
                    onConfirm: () {},
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final success = await ref
                      .read(connectionProvider.notifier)
                      .blockUser(connection.otherUserProfile!.userId);
                  
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${connection.otherUserProfile?.displayName} has been blocked'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.flag, color: AppTheme.error),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => ReportDialog(
                    userName: connection.otherUserProfile?.displayName ?? 'this user',
                    onReport: (reason, details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your report. We will review it shortly.'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
