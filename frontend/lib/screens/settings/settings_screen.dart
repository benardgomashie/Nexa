import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Safety section
          _buildSectionHeader('Safety & Privacy'),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage users you have blocked'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/blocked-users');
            },
          ),
          const Divider(),
          
          // Discovery section
          _buildSectionHeader('Discovery'),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('Discovery Settings'),
            subtitle: const Text('Distance, visibility & location'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/discovery');
            },
          ),
          const Divider(),
          
          // About section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Norvi'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Norvi',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Norvi',
                children: [
                  const SizedBox(height: 16),
                  const Text('Human connection, simplified.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          const Divider(),
          
          // Account section (Danger zone)
          _buildSectionHeader('Account'),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.textSecondary),
            title: const Text('Log Out'),
            onTap: () => _confirmLogout(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete your account'),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTheme.headline3.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/auth/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Deleting your account will:'),
            SizedBox(height: 8),
            Text('• Remove your profile permanently'),
            Text('• Delete all your matches and chats'),
            Text('• Remove all your data from our servers'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              _showDeleteConfirmationInput(context, ref);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmationInput(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(ref: ref),
    );
  }
}

class _DeleteConfirmationDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const _DeleteConfirmationDialog({required this.ref});

  @override
  ConsumerState<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends ConsumerState<_DeleteConfirmationDialog> {
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type "DELETE" to confirm account deletion:'),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmationController,
            decoration: InputDecoration(
              hintText: 'Type DELETE',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _handleDelete,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete Account'),
        ),
      ],
    );
  }
  
  Future<void> _handleDelete() async {
    if (_confirmationController.text.toUpperCase() != 'DELETE') {
      setState(() => _error = 'Please type DELETE to confirm');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await ref.read(authProvider.notifier).deleteAccount();
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/auth/login');
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error'] ?? 'Failed to delete account';
      });
    }
  }
}
