from django.conf import settings
from django.db import models
from django.utils import timezone


class ChatThread(models.Model):
    """
    Represents a chat conversation between two connected users.
    Automatically created when a connection is accepted.
    """

    user1 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_threads_as_user1",
        help_text="First user in the thread (lower user ID)",
    )
    user2 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_threads_as_user2",
        help_text="Second user in the thread (higher user ID)",
    )
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_message_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Timestamp of the last message sent in this thread",
    )

    class Meta:
        ordering = ["-last_message_at", "-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user1", "user2"],
                name="unique_chat_thread_pair",
            ),
            models.CheckConstraint(
                check=models.Q(user1__lt=models.F("user2")),
                name="user1_less_than_user2",
            ),
        ]
        indexes = [
            models.Index(fields=["user1", "-last_message_at"]),
            models.Index(fields=["user2", "-last_message_at"]),
            models.Index(fields=["-last_message_at"]),
        ]

    def __str__(self):
        return f"Thread: {self.user1.email} ↔ {self.user2.email}"

    @staticmethod
    def get_or_create_thread(user_a, user_b):
        """
        Get or create a chat thread between two users.
        Always stores users with lower ID as user1.
        """
        if user_a.id < user_b.id:
            user1, user2 = user_a, user_b
        else:
            user1, user2 = user_b, user_a

        thread, created = ChatThread.objects.get_or_create(
            user1=user1,
            user2=user2,
        )
        return thread, created

    def get_other_user(self, current_user):
        """Get the other user in this thread."""
        return self.user2 if self.user1 == current_user else self.user1

    def get_unread_count(self, user):
        """Get count of unread messages for a specific user."""
        return self.messages.filter(sender=self.get_other_user(user), read_at__isnull=True).count()

    def mark_as_read(self, user):
        """Mark all messages from the other user as read."""
        other_user = self.get_other_user(user)
        self.messages.filter(sender=other_user, read_at__isnull=True).update(read_at=timezone.now())


class ChatMessage(models.Model):
    """
    Represents a single message in a chat thread.
    """

    thread = models.ForeignKey(
        ChatThread,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_messages",
    )
    content = models.TextField(
        max_length=2000,
        help_text="Message content (max 2000 characters)",
    )
    
    # Timestamps
    sent_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the message was read by the recipient",
    )

    class Meta:
        ordering = ["sent_at"]
        indexes = [
            models.Index(fields=["thread", "sent_at"]),
            models.Index(fields=["thread", "read_at"]),
            models.Index(fields=["sender", "-sent_at"]),
        ]

    def __str__(self):
        preview = self.content[:50] + "..." if len(self.content) > 50 else self.content
        return f"{self.sender.email}: {preview}"

    def save(self, *args, **kwargs):
        """Update thread's last_message_at when a new message is sent."""
        is_new = self.pk is None
        super().save(*args, **kwargs)
        
        if is_new:
            # Update thread's last_message_at
            self.thread.last_message_at = self.sent_at
            self.thread.save(update_fields=["last_message_at"])

