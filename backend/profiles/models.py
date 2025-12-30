from django.conf import settings
from django.db import models


class IntentTag(models.Model):
    """Tags representing user intentions (friendship, networking, etc.)."""

    name = models.CharField(max_length=50, unique=True)
    description = models.CharField(max_length=200, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class InterestTag(models.Model):
    """Tags representing hobbies, skills, topics."""

    name = models.CharField(max_length=50, unique=True)
    category = models.CharField(max_length=50, blank=True)  # e.g., Sports, Tech, Arts
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["category", "name"]

    def __str__(self):
        return self.name


class Profile(models.Model):
    """Extended user profile with personal info and preferences."""

    class AgeBucket(models.TextChoices):
        AGE_18_24 = "18_24", "18–24"
        AGE_25_34 = "25_34", "25–34"
        AGE_35_44 = "35_44", "35–44"
        AGE_45_54 = "45_54", "45–54"
        AGE_55_PLUS = "55_plus", "55+"

    class Faith(models.TextChoices):
        CHRISTIAN = "christian", "Christian"
        MUSLIM = "muslim", "Muslim"
        TRADITIONAL = "traditional", "Traditional / Spiritual"
        OTHER = "other", "Other"
        PREFER_NOT_TO_SAY = "prefer_not_to_say", "Prefer not to say"

    class Pronouns(models.TextChoices):
        HE_HIM = "he_him", "He/Him"
        SHE_HER = "she_her", "She/Her"
        THEY_THEM = "they_them", "They/Them"
        OTHER = "other", "Other"
        PREFER_NOT_TO_SAY = "prefer_not_to_say", "Prefer not to say"

    class Gender(models.TextChoices):
        MALE = "male", "Male"
        FEMALE = "female", "Female"
        NON_BINARY = "non_binary", "Non-binary"
        OTHER = "other", "Other"
        PREFER_NOT_TO_SAY = "prefer_not_to_say", "Prefer not to say"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    display_name = models.CharField(max_length=100, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    pronouns = models.CharField(
        max_length=20,
        choices=Pronouns.choices,
        blank=True,
    )
    gender = models.CharField(
        max_length=20,
        choices=Gender.choices,
        blank=True,
    )
    gender_visible = models.BooleanField(default=False)
    age_bucket = models.CharField(
        max_length=10,
        choices=AgeBucket.choices,
        blank=True,
    )
    primary_language = models.CharField(max_length=50, default="English")
    other_languages = models.JSONField(default=list, blank=True)  # e.g., ["French", "Twi"]

    # Faith & Values
    faith = models.CharField(
        max_length=20,
        choices=Faith.choices,
        blank=True,
    )
    faith_visible = models.BooleanField(default=False)

    # Many-to-many relationships for tags
    interests = models.ManyToManyField(InterestTag, blank=True, related_name="profiles")
    intents = models.ManyToManyField(IntentTag, blank=True, related_name="profiles")

    # Profile completion tracking
    is_complete = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.display_name or self.user.email}'s profile"

    def check_completion(self):
        """Check if profile has minimum required fields."""
        required = [self.display_name, self.age_bucket]
        has_intent = self.intents.exists()
        self.is_complete = all(required) and has_intent
        return self.is_complete


class ProfilePhoto(models.Model):
    """Profile photos (1-3 per user)."""

    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name="photos",
    )
    image = models.ImageField(upload_to="profile_photos/%Y/%m/")
    ordering_index = models.PositiveSmallIntegerField(default=0)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["ordering_index"]
        constraints = [
            models.UniqueConstraint(
                fields=["profile", "ordering_index"],
                name="unique_photo_order_per_profile",
            )
        ]

    def __str__(self):
        return f"Photo {self.ordering_index} for {self.profile}"


class LocationPreference(models.Model):
    """User's location and radius preferences for matching."""

    class SharePrecision(models.TextChoices):
        CITY_ONLY = "city_only", "City Only"
        APPROX = "approx", "Approximate"
        NEARBY = "nearby", "Nearby Area"

    profile = models.OneToOneField(
        Profile,
        on_delete=models.CASCADE,
        related_name="location_preference",
    )
    # Coordinates (nullable for privacy or city-only mode)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    # City/country (always required)
    city = models.CharField(max_length=100)
    country = models.CharField(max_length=100, default="Ghana")

    # Matching radius in kilometers
    radius_km = models.PositiveSmallIntegerField(default=25, help_text="Search radius in km (5-50)")

    # Privacy setting for location sharing
    share_precision = models.CharField(
        max_length=20,
        choices=SharePrecision.choices,
        default=SharePrecision.APPROX,
    )

    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.profile.display_name}'s location ({self.city})"

    class Meta:
        verbose_name = "Location Preference"
        verbose_name_plural = "Location Preferences"


class MatchingPreference(models.Model):
    """User's matching criteria and filters."""

    class FaithFilter(models.TextChoices):
        SAME_ONLY = "same_only", "Same faith only"
        OPEN_TO_ALL = "open_to_all", "Open to all faiths"
        CUSTOM = "custom", "Custom (exclude specific)"

    profile = models.OneToOneField(
        Profile,
        on_delete=models.CASCADE,
        related_name="matching_preference",
    )

    # Preferred age buckets (JSON array, e.g., ["18_24", "25_34"])
    preferred_age_buckets = models.JSONField(default=list, blank=True)

    # Availability windows
    available_mornings = models.BooleanField(default=False)
    available_afternoons = models.BooleanField(default=False)
    available_evenings = models.BooleanField(default=False)
    available_weekdays = models.BooleanField(default=True)
    available_weekends = models.BooleanField(default=True)

    # Faith/values matching
    faith_filter = models.CharField(
        max_length=20,
        choices=FaithFilter.choices,
        default=FaithFilter.OPEN_TO_ALL,
    )
    # Private field: faiths to exclude (never shown to others)
    faith_exclude = models.JSONField(default=list, blank=True)

    # Visibility toggle
    visible = models.BooleanField(default=True, help_text="Show my profile in discovery")

    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.profile.display_name}'s matching preferences"

    class Meta:
        verbose_name = "Matching Preference"
        verbose_name_plural = "Matching Preferences"


