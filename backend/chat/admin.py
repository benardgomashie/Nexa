from django.contrib import admin

from .models import ChatMessage, ChatThread


@admin.register(ChatThread)
class ChatThreadAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user1",
        "user2",
        "last_message_at",
        "created_at",
    )
    list_filter = ("created_at", "last_message_at")
    search_fields = (
        "user1__email",
        "user1__profile__display_name",
        "user2__email",
        "user2__profile__display_name",
    )
    readonly_fields = ("created_at", "updated_at", "last_message_at")
    date_hierarchy = "created_at"
    ordering = ["-last_message_at", "-created_at"]

    def has_add_permission(self, request):
        # Prevent manual creation in admin
        return False


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "thread",
        "sender",
        "content_preview",
        "sent_at",
        "read_at",
    )
    list_filter = ("sent_at", "read_at")
    search_fields = (
        "sender__email",
        "sender__profile__display_name",
        "content",
    )
    readonly_fields = ("sent_at", "read_at")
    date_hierarchy = "sent_at"
    ordering = ["-sent_at"]

    def content_preview(self, obj):
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content
    content_preview.short_description = "Content"

    def has_add_permission(self, request):
        # Prevent manual creation in admin
        return False

