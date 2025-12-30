from rest_framework import serializers

from profiles.serializers import PublicProfileSerializer

from .models import ChatMessage, ChatThread


class ChatMessageSerializer(serializers.ModelSerializer):
    """Serializer for chat messages."""

    is_mine = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = (
            "id",
            "thread",
            "sender",
            "content",
            "sent_at",
            "read_at",
            "is_mine",
        )
        read_only_fields = ("id", "sender", "sent_at", "read_at", "is_mine")

    def get_is_mine(self, obj):
        """Check if the current user is the sender."""
        request = self.context.get("request")
        if request and request.user:
            return obj.sender == request.user
        return False


class ChatMessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new chat message."""

    class Meta:
        model = ChatMessage
        fields = ("content",)

    def validate_content(self, value):
        """Validate message content."""
        if not value or not value.strip():
            raise serializers.ValidationError("Message cannot be empty.")
        if len(value) > 2000:
            raise serializers.ValidationError("Message too long (max 2000 characters).")
        return value.strip()


class ChatThreadSerializer(serializers.ModelSerializer):
    """Serializer for chat threads with last message preview."""

    other_user_profile = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = ChatThread
        fields = (
            "id",
            "user1",
            "user2",
            "other_user_profile",
            "last_message",
            "unread_count",
            "created_at",
            "last_message_at",
        )
        read_only_fields = ("id", "user1", "user2", "created_at", "last_message_at")

    def get_other_user_profile(self, obj):
        """Get the profile of the other user in the thread."""
        request = self.context.get("request")
        if request and request.user:
            other_user = obj.get_other_user(request.user)
            return PublicProfileSerializer(other_user.profile).data
        return None

    def get_last_message(self, obj):
        """Get the last message in the thread."""
        last_message = obj.messages.last()
        if last_message:
            return {
                "id": last_message.id,
                "sender_id": last_message.sender.id,
                "content": last_message.content,
                "sent_at": last_message.sent_at,
                "read_at": last_message.read_at,
            }
        return None

    def get_unread_count(self, obj):
        """Get unread message count for current user."""
        request = self.context.get("request")
        if request and request.user:
            return obj.get_unread_count(request.user)
        return 0
