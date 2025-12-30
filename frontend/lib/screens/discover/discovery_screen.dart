import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/discover.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/report_dialog.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryState = ref.watch(discoveryProvider);

    // Show match dialog if new match
    if (discoveryState.newMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMatchDialog(context, ref, discoveryState.newMatch!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(discoveryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: discoveryState.isLoading && discoveryState.profiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : discoveryState.profiles.isEmpty
              ? _buildEmptyState(context, ref)
              : Stack(
                  children: [
                    _buildProfileStack(context, ref, discoveryState.profiles),
                    if (discoveryState.error != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Material(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              discoveryState.error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No more profiles',
            style: AppTheme.headline2,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new connections',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(discoveryProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStack(
    BuildContext context,
    WidgetRef ref,
    List<DiscoveryProfile> profiles,
  ) {
    return Stack(
      children: [
        // Show top 3 profiles for depth effect
        ...profiles.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final profile = entry.value;
          
          return Positioned.fill(
            top: index * 8.0,
            bottom: -(index * 8.0),
            child: Padding(
              padding: EdgeInsets.all(16.0 + (index * 4.0)),
              child: index == 0
                  ? _ProfileCard(
                      profile: profile,
                      onLike: () => ref.read(discoveryProvider.notifier).like(profile.userId),
                      onPass: () => ref.read(discoveryProvider.notifier).pass(profile.userId),
                    )
                  : Opacity(
                      opacity: 1.0 - (index * 0.3),
                      child: _ProfileCardPreview(profile: profile),
                    ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showMatchDialog(BuildContext context, WidgetRef ref, dynamic match) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            const Text('It\'s a Match!'),
          ],
        ),
        content: const Text(
          'You and this person both liked each other. Start chatting now!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(discoveryProvider.notifier).clearNewMatch();
              Navigator.pop(context);
            },
            child: const Text('Continue Discovering'),
          ),
          ElevatedButton(
            onPressed: () async {
              ref.read(discoveryProvider.notifier).clearNewMatch();
              Navigator.pop(context);
              
              // Get or create thread and navigate to chat
              final threadId = await ref
                  .read(chatProvider.notifier)
                  .getOrCreateThread(match['other_user_profile']['id']);
              
              if (threadId != null && context.mounted) {
                context.push('/chat/$threadId');
              }
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  final DiscoveryProfile profile;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const _ProfileCard({
    required this.profile,
    required this.onLike,
    required this.onPass,
  });

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.block, color: AppTheme.error),
              title: const Text('Block'),
              onTap: () {
                Navigator.pop(context);
                _handleBlock();
              },
            ),
            ListTile(
              leading: Icon(Icons.flag, color: AppTheme.error),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _handleReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BlockConfirmDialog(
        userName: widget.profile.profile.displayName ?? 'this user',
        onConfirm: () {},
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(connectionProvider.notifier)
          .blockUser(widget.profile.profile.userId);
      
      if (success && mounted) {
        // Remove from discovery
        widget.onPass();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.profile.profile.displayName} has been blocked'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  void _handleReport() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        userName: widget.profile.profile.displayName ?? 'this user',
        onReport: (reason, details) {
          // TODO: Implement report API call
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your report. We will review it shortly.'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: (details) {
        final threshold = MediaQuery.of(context).size.width * 0.3;
        
        if (_dragOffset.dx.abs() > threshold) {
          // Swipe action
          if (_dragOffset.dx > 0) {
            widget.onLike();
          } else {
            widget.onPass();
          }
        }
        
        setState(() {
          _dragOffset = Offset.zero;
          _isDragging = false;
        });
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _dragOffset.dx * 0.0005,
          child: Stack(
            children: [
              _ProfileCardContent(profile: widget.profile),
              
              // Menu button
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: _showProfileMenu,
                  icon: const Icon(Icons.more_vert),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              
              // Like/Nope overlays
              if (_isDragging && _dragOffset.dx > 0)
                Positioned(
                  top: 40,
                  left: 40,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.success,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIKE',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isDragging && _dragOffset.dx < 0)
                Positioned(
                  top: 40,
                  right: 40,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.error,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PASS',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Action buttons
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'pass',
                      onPressed: widget.onPass,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: AppTheme.error, size: 32),
                    ),
                    FloatingActionButton(
                      heroTag: 'like',
                      onPressed: widget.onLike,
                      backgroundColor: AppTheme.accentColor,
                      child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCardContent extends StatelessWidget {
  final DiscoveryProfile profile;

  const _ProfileCardContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.profile.photos.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: hasPhoto
            ? BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(profile.profile.photos.first.image),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Name and age
              Text(
                '${profile.profile.displayName ?? "Anonymous"}, ${profile.profile.ageBucket ?? ""}',
                style: AppTheme.headline1.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              
              // Distance
              if (profile.distanceKm != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.distanceKm!.toStringAsFixed(1)} km away',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              
              // Bio
              if (profile.profile.bio != null)
                Text(
                  profile.profile.bio!,
                  style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              
              // Intent tags
              if (profile.profile.intentTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.profile.intentTags.take(3).map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                        labelStyle: const TextStyle(color: Colors.white),
                      )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCardPreview extends StatelessWidget {
  final DiscoveryProfile profile;

  const _ProfileCardPreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        color: Colors.grey[300],
      ),
    );
  }
}
