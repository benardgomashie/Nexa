from django.conf import settings
from django.db import models


class ActivityCategory(models.Model):
    """Categories for activities (e.g., Sports, Coffee, Study, etc.)."""

    name = models.CharField(max_length=50, unique=True)
    icon = models.CharField(max_length=50, blank=True)  # Icon name for frontend
    description = models.CharField(max_length=200, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Activity Categories"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Activity(models.Model):
    """
    An activity that users can create and join.
    Examples: Coffee chat, hiking trip, study session, networking event.
    """

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        OPEN = "open", "Open for Joining"
        FULL = "full", "Full"
        CANCELLED = "cancelled", "Cancelled"
        COMPLETED = "completed", "Completed"

    class Visibility(models.TextChoices):
        PUBLIC = "public", "Public (Anyone nearby)"
        CONNECTIONS = "connections", "Connections Only"
        INVITE = "invite", "Invite Only"

    # Basic info
    host = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="hosted_activities",
    )
    title = models.CharField(max_length=100)
    description = models.TextField(max_length=500, blank=True)
    category = models.ForeignKey(
        ActivityCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="activities",
    )

    # When
    date = models.DateField()
    time = models.TimeField(null=True, blank=True)
    duration_minutes = models.PositiveIntegerField(
        null=True, blank=True, help_text="Approximate duration in minutes"
    )

    # Where
    location_name = models.CharField(max_length=200)  # Human-readable location
    location_address = models.CharField(max_length=300, blank=True)
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )

    # Capacity
    max_participants = models.PositiveIntegerField(
        default=4, help_text="Maximum number of participants including host"
    )
    min_participants = models.PositiveIntegerField(
        default=2, help_text="Minimum participants for activity to happen"
    )

    # Visibility & Filters
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.OPEN
    )
    visibility = models.CharField(
        max_length=20, choices=Visibility.choices, default=Visibility.PUBLIC
    )

    # Optional filters (host can restrict who can join)
    gender_filter = models.JSONField(
        default=list,
        blank=True,
        help_text="List of allowed genders, empty means all",
    )
    age_filter = models.JSONField(
        default=list,
        blank=True,
        help_text="List of allowed age buckets, empty means all",
    )
    intent_filter = models.ManyToManyField(
        "profiles.IntentTag",
        blank=True,
        help_text="Required intents, empty means all",
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["date", "time"]
        verbose_name_plural = "Activities"

    def __str__(self):
        return f"{self.title} by {self.host.email} on {self.date}"

    @property
    def current_participant_count(self):
        """Count of confirmed participants including host."""
        return self.participants.filter(status=ActivityParticipant.Status.CONFIRMED).count() + 1

    @property
    def spots_available(self):
        """Number of spots still available."""
        return max(0, self.max_participants - self.current_participant_count)

    @property
    def is_full(self):
        """Check if activity is at capacity."""
        return self.spots_available == 0

    def can_user_join(self, user):
        """Check if a user can join this activity."""
        # Can't join own activity
        if user == self.host:
            return False, "You are the host of this activity"

        # Check if already participant
        if self.participants.filter(user=user).exists():
            return False, "You are already a participant"

        # Check capacity
        if self.is_full:
            return False, "Activity is full"

        # Check status
        if self.status != self.Status.OPEN:
            return False, "Activity is not open for joining"

        # Check visibility
        if self.visibility == self.Visibility.CONNECTIONS:
            from connections.models import Connection
            if not Connection.are_connected(user, self.host):
                return False, "This activity is for connections only"

        if self.visibility == self.Visibility.INVITE:
            return False, "This activity is invite only"

        # Check filters
        try:
            profile = user.profile
        except:
            return False, "Please complete your profile first"

        if self.gender_filter and profile.gender not in self.gender_filter:
            return False, "Activity has gender restrictions"

        if self.age_filter and profile.age_bucket not in self.age_filter:
            return False, "Activity has age restrictions"

        if self.intent_filter.exists():
            user_intents = set(profile.intents.values_list("id", flat=True))
            required_intents = set(self.intent_filter.values_list("id", flat=True))
            if not user_intents.intersection(required_intents):
                return False, "Activity requires specific intents"

        return True, "OK"


class ActivityParticipant(models.Model):
    """
    Tracks users who have requested to join or are confirmed for an activity.
    """

    class Status(models.TextChoices):
        PENDING = "pending", "Pending Approval"
        CONFIRMED = "confirmed", "Confirmed"
        DECLINED = "declined", "Declined"
        CANCELLED = "cancelled", "Cancelled by User"
        REMOVED = "removed", "Removed by Host"

    activity = models.ForeignKey(
        Activity, on_delete=models.CASCADE, related_name="participants"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="activity_participations",
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    message = models.TextField(
        max_length=300, blank=True, help_text="Message from user when requesting to join"
    )

    # Timestamps
    requested_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ["activity", "user"]
        ordering = ["requested_at"]

    def __str__(self):
        return f"{self.user.email} - {self.activity.title} ({self.status})"


class ActivityChat(models.Model):
    """
    Group chat for an activity. Created when activity has confirmed participants.
    """

    activity = models.OneToOneField(
        Activity, on_delete=models.CASCADE, related_name="chat"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Chat for {self.activity.title}"


class ActivityMessage(models.Model):
    """
    Messages in an activity chat.
    """

    chat = models.ForeignKey(
        ActivityChat, on_delete=models.CASCADE, related_name="messages"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="activity_messages",
    )
    content = models.TextField(max_length=1000)
    created_at = models.DateTimeField(auto_now_add=True)

    # Read tracking
    read_by = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="read_activity_messages",
        blank=True,
    )

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.sender.email}: {self.content[:50]}"
