import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Dialog for reporting inappropriate behavior
class ReportDialog extends StatefulWidget {
  final String userName;
  final Function(String reason, String? details) onReport;

  const ReportDialog({
    super.key,
    required this.userName,
    required this.onReport,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();

  final List<String> _reasons = [
    'Inappropriate photos',
    'Harassment or bullying',
    'Spam or scam',
    'Fake profile',
    'Offensive language',
    'Underage user',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.userName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Help us understand what\'s happening',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason dropdown
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              items: _reasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Additional details
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                border: OutlineInputBorder(),
                hintText: 'Provide more context...',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Reports are confidential and help keep our community safe.',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  widget.onReport(
                    _selectedReason!,
                    _detailsController.text.trim().isEmpty
                        ? null
                        : _detailsController.text.trim(),
                  );
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}

/// Confirmation dialog for blocking a user
class BlockConfirmDialog extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const BlockConfirmDialog({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Block User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to block $userName?'),
          const SizedBox(height: 16),
          Text(
            'Blocked users will:',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('Not see your profile'),
          _buildBulletPoint('Not be able to message you'),
          _buildBulletPoint('Be removed from your connections'),
          _buildBulletPoint('Not appear in your discovery'),
          const SizedBox(height: 16),
          Text(
            'You can unblock them later in Settings.',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
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
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Block'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
