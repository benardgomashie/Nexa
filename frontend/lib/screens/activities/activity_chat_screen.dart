import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import 'package:intl/intl.dart';

class ActivityChatScreen extends ConsumerStatefulWidget {
  final int activityId;

  const ActivityChatScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityChatScreen> createState() => _ActivityChatScreenState();
}

class _ActivityChatScreenState extends ConsumerState<ActivityChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityDetailProvider(widget.activityId));
    final chatState = ref.watch(activityChatProvider(widget.activityId));

    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: activityAsync.when(
          data: (activity) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${activity.confirmedCount} participants',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          loading: () => const Text('Group Chat'),
          error: (_, __) => const Text('Group Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show activity info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${chatState.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(activityChatProvider(widget.activityId)
                                      .notifier)
                                  .refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : chatState.messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref
                                  .read(activityChatProvider(widget.activityId)
                                      .notifier)
                                  .refresh();
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: chatState.messages.length,
                              itemBuilder: (context, index) {
                                final message = chatState.messages[index];
                                final showDateHeader = index == 0 ||
                                    !_isSameDay(
                                      chatState.messages[index - 1].timestamp,
                                      message.timestamp,
                                    );

                                return Column(
                                  children: [
                                    if (showDateHeader)
                                      _buildDateHeader(message.timestamp),
                                    _MessageBubble(
                                      message: message,
                                      // TODO: Get current user ID
                                      isMe: false,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),

          // Message input
          _buildMessageInput(chatState.isSending),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday = _isSameDay(date, now.subtract(const Duration(days: 1)));

    String text;
    if (isToday) {
      text = 'Today';
    } else if (isYesterday) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isSending) {
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref
        .read(activityChatProvider(widget.activityId).notifier)
        .sendMessage(content);

    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final ActivityMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight:
                          isMe ? Radius.zero : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }
}
