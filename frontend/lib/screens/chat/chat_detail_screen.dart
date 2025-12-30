import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/report_dialog.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int threadId;

  const ChatDetailScreen({
    super.key,
    required this.threadId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load messages when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadMessages(widget.threadId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final success = await ref.read(chatProvider.notifier).sendMessage(
          threadId: widget.threadId,
          content: content,
        );

    if (success) {
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final thread = chatState.threads.firstWhere(
      (t) => t.id == widget.threadId,
      orElse: () => throw Exception('Thread not found'),
    );
    final messages = chatState.messagesByThread[widget.threadId] ?? [];
    final profile = thread.otherUserProfile;
    final hasPhoto = profile?.photos.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: hasPhoto
                  ? CachedNetworkImageProvider(profile!.photos.first.image)
                  : null,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: hasPhoto
                  ? null
                  : Icon(
                      Icons.person,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(profile?.displayName ?? 'Anonymous')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatMenu(profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final showTimestamp = index == 0 ||
                          messages[index - 1].sentAt.difference(message.sentAt).inMinutes.abs() > 5;
                      
                      return _MessageBubble(
                        message: message,
                        showTimestamp: showTimestamp,
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatMenu(dynamic profile) {
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
                    userName: profile?.displayName ?? 'this user',
                    onConfirm: () {},
                  ),
                );

                if (confirmed == true && mounted) {
                  final success = await ref
                      .read(connectionProvider.notifier)
                      .blockUser(profile.userId);
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${profile?.displayName} has been blocked'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                    
                    // Navigate back
                    context.pop();
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
                    userName: profile?.displayName ?? 'this user',
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;

  const _MessageBubble({
    required this.message,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  timeago.format(message.sentAt),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                message.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: message.isSender
                      ? AppTheme.primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: AppTheme.bodyMedium.copyWith(
                        color: message.isSender ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.sentAt, locale: 'en_short'),
                          style: AppTheme.caption.copyWith(
                            color: message.isSender
                                ? Colors.white.withOpacity(0.7)
                                : AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        if (message.isSender) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 12,
                            color: message.isRead
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
