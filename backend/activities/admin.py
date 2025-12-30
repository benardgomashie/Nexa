from django.contrib import admin
from .models import ActivityCategory, Activity, ActivityParticipant, ActivityChat, ActivityMessage


@admin.register(ActivityCategory)
class ActivityCategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "icon", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name",)


class ActivityParticipantInline(admin.TabularInline):
    model = ActivityParticipant
    extra = 0
    readonly_fields = ("requested_at", "responded_at")


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ("title", "host", "date", "time", "location_name", "status", "visibility", "current_participant_count", "max_participants")
    list_filter = ("status", "visibility", "category", "date")
    search_fields = ("title", "description", "host__email", "location_name")
    date_hierarchy = "date"
    inlines = [ActivityParticipantInline]
    readonly_fields = ("created_at", "updated_at")


@admin.register(ActivityParticipant)
class ActivityParticipantAdmin(admin.ModelAdmin):
    list_display = ("activity", "user", "status", "requested_at", "responded_at")
    list_filter = ("status",)
    search_fields = ("activity__title", "user__email")


@admin.register(ActivityChat)
class ActivityChatAdmin(admin.ModelAdmin):
    list_display = ("activity", "created_at")
    search_fields = ("activity__title",)


@admin.register(ActivityMessage)
class ActivityMessageAdmin(admin.ModelAdmin):
    list_display = ("chat", "sender", "content_preview", "created_at")
    search_fields = ("chat__activity__title", "sender__email", "content")

    def content_preview(self, obj):
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content
    content_preview.short_description = "Content"
