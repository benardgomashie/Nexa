from django.contrib import admin

from .models import (
    IntentTag,
    InterestTag,
    LocationPreference,
    MatchingPreference,
    Profile,
    ProfilePhoto,
)


class ProfilePhotoInline(admin.TabularInline):
    model = ProfilePhoto
    extra = 1
    max_num = 3


class LocationPreferenceInline(admin.StackedInline):
    model = LocationPreference
    can_delete = False


class MatchingPreferenceInline(admin.StackedInline):
    model = MatchingPreference
    can_delete = False


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "display_name", "age_bucket", "faith", "is_complete", "updated_at")
    list_filter = ("age_bucket", "faith", "is_complete", "faith_visible")
    search_fields = ("user__email", "display_name", "bio")
    filter_horizontal = ("interests", "intents")
    inlines = [ProfilePhotoInline, LocationPreferenceInline, MatchingPreferenceInline]
    readonly_fields = ("created_at", "updated_at")


@admin.register(LocationPreference)
class LocationPreferenceAdmin(admin.ModelAdmin):
    list_display = ("profile", "city", "country", "radius_km", "share_precision")
    list_filter = ("country", "share_precision")
    search_fields = ("profile__user__email", "city")


@admin.register(MatchingPreference)
class MatchingPreferenceAdmin(admin.ModelAdmin):
    list_display = ("profile", "faith_filter", "visible", "updated_at")
    list_filter = ("faith_filter", "visible")
    search_fields = ("profile__user__email",)


@admin.register(IntentTag)
class IntentTagAdmin(admin.ModelAdmin):
    list_display = ("name", "description", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(InterestTag)
class InterestTagAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "is_active")
    list_filter = ("category", "is_active")
    search_fields = ("name", "category")


@admin.register(ProfilePhoto)
class ProfilePhotoAdmin(admin.ModelAdmin):
    list_display = ("profile", "ordering_index", "uploaded_at")
    list_filter = ("uploaded_at",)

