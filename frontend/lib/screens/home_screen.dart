import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'discover/discovery_screen.dart';
import 'connections/connections_screen.dart';
import 'chat/chat_list_screen.dart';

// Navigation state provider
final selectedIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    // Define pages
    final pages = [
      const DiscoveryScreen(),
      const ConnectionsScreen(),
      const ChatListScreen(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Connections',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Profile page - user profile and settings
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profile = authState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                // TODO: Upload photo
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name
                  Text(
                    profile?.displayName ?? user?.fullName ?? 'User',
                    style: AppTheme.headline1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile completeness card
                  if (profile != null && !profile.isComplete)
                    Card(
                      color: AppTheme.warning.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete your profile to start discovering',
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Edit profile button
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/profile/edit');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Logout button
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      // Router will automatically redirect to login
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                  const SizedBox(height: 32),
                  
                  // Bio section
                  if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                    Text(
                      'About Me',
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.bio!,
                      style: AppTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Tags section
                  if (profile?.intentTags != null &&
                      profile!.intentTags!.isNotEmpty) ...[
                    Text(
                      'Looking for',
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.intentTags!
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.1),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (profile?.interestTags != null &&
                      profile!.interestTags!.isNotEmpty) ...[
                    Text(
                      'Interests',
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interestTags!
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    AppTheme.accentColor.withOpacity(0.1),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
