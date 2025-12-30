import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(chatProvider.notifier).refresh(),
          ),
        ],
      ),
      body: chatState.isLoading && chatState.threads.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chatState.threads.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(chatProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: chatState.threads.length,
                    itemBuilder: (context, index) {
                      final thread = chatState.threads[index];
                      return _ThreadTile(thread: thread);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTheme.headline2,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with someone to start chatting',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  final ChatThread thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = thread.otherUserProfile;
    final hasPhoto = profile?.photos.isNotEmpty ?? false;
    final lastMessage = thread.lastMessage;
    final hasUnread = thread.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Badge(
        isLabelVisible: hasUnread,
        label: Text('${thread.unreadCount}'),
        child: CircleAvatar(
          radius: 28,
          backgroundImage: hasPhoto
              ? CachedNetworkImageProvider(profile!.photos.first.image)
              : null,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: hasPhoto
              ? null
              : Icon(
                  Icons.person,
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
        ),
      ),
      title: Text(
        profile?.displayName ?? 'Anonymous',
        style: AppTheme.headline3.copyWith(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: lastMessage != null
          ? Row(
              children: [
                if (lastMessage.isSender)
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: lastMessage.isRead
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                if (lastMessage.isSender) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lastMessage.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMedium.copyWith(
                      color: hasUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            )
          : null,
      trailing: lastMessage != null
          ? Text(
              timeago.format(lastMessage.sentAt, locale: 'en_short'),
              style: AppTheme.caption.copyWith(
                color: hasUnread ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            )
          : null,
      onTap: () {
        context.push('/chat/${thread.id}');
      },
    );
  }
}
