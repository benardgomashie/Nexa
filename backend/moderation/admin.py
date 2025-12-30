from django.contrib import admin
from django.utils import timezone

from .models import Report


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "reporter",
        "reported_user",
        "reason",
        "handled",
        "handled_by",
        "created_at",
    )
    list_filter = ("handled", "reason", "created_at")
    search_fields = (
        "reporter__email",
        "reporter__profile__display_name",
        "reported_user__email",
        "reported_user__profile__display_name",
        "description",
        "moderator_notes",
    )
    readonly_fields = ("created_at", "updated_at", "handled_at")
    date_hierarchy = "created_at"
    ordering = ["-created_at"]

    fieldsets = (
        ("Report Details", {
            "fields": ("reporter", "reported_user", "reason", "description")
        }),
        ("Moderation", {
            "fields": ("handled", "handled_by", "moderator_notes"),
        }),
        ("Timestamps", {
            "fields": ("created_at", "updated_at", "handled_at"),
            "classes": ("collapse",),
        }),
    )

    actions = ["mark_as_handled", "mark_as_unhandled"]

    def mark_as_handled(self, request, queryset):
        """Mark selected reports as handled."""
        count = 0
        for report in queryset.filter(handled=False):
            report.mark_handled(request.user)
            count += 1
        self.message_user(request, f"{count} report(s) marked as handled.")
    mark_as_handled.short_description = "Mark selected reports as handled"

    def mark_as_unhandled(self, request, queryset):
        """Mark selected reports as unhandled."""
        queryset.update(handled=False, handled_by=None, handled_at=None)
        self.message_user(request, f"{queryset.count()} report(s) marked as unhandled.")
    mark_as_unhandled.short_description = "Mark selected reports as unhandled"

    def has_add_permission(self, request):
        # Prevent manual creation in admin
        return False

