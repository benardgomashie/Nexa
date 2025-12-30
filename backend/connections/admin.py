from django.contrib import admin

from .models import Connection


@admin.register(Connection)
class ConnectionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "from_user",
        "to_user",
        "status",
        "created_at",
        "accepted_at",
    )
    list_filter = ("status", "created_at")
    search_fields = (
        "from_user__email",
        "from_user__profile__display_name",
        "to_user__email",
        "to_user__profile__display_name",
    )
    readonly_fields = ("created_at", "updated_at", "accepted_at")
    date_hierarchy = "created_at"
    ordering = ["-created_at"]
    
    fieldsets = (
        (None, {
            "fields": ("from_user", "to_user", "status")
        }),
        ("Timestamps", {
            "fields": ("created_at", "updated_at", "accepted_at"),
            "classes": ("collapse",),
        }),
    )

    def has_add_permission(self, request):
        # Prevent manual creation in admin
        return False

