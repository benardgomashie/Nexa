from django.conf import settings
from django.db import models


class Report(models.Model):
    """
    Represents a user report for harassment, spam, or policy violations.
    """

    class ReportReason(models.TextChoices):
        HARASSMENT = "harassment", "Harassment"
        SPAM = "spam", "Spam"
        RELIGIOUS_HARASSMENT = "religious_harassment", "Religious Harassment / Disrespect"
        HATE_SPEECH = "hate_speech", "Hate Speech"
        INAPPROPRIATE_CONTENT = "inappropriate_content", "Inappropriate Content"
        FAKE_PROFILE = "fake_profile", "Fake Profile"
        OTHER = "other", "Other"

    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reports_made",
        help_text="User who submitted the report",
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reports_received",
        help_text="User being reported",
    )
    reason = models.CharField(
        max_length=30,
        choices=ReportReason.choices,
    )
    description = models.TextField(
        max_length=1000,
        blank=True,
        help_text="Additional details about the report (optional)",
    )
    
    # Moderation
    handled = models.BooleanField(
        default=False,
        help_text="Whether this report has been reviewed by a moderator",
    )
    handled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reports_handled",
        help_text="Moderator who handled this report",
    )
    handled_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the report was handled",
    )
    moderator_notes = models.TextField(
        blank=True,
        help_text="Internal notes from the moderator",
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["reporter", "-created_at"]),
            models.Index(fields=["reported_user", "-created_at"]),
            models.Index(fields=["handled", "-created_at"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        return f"Report: {self.reporter.email} → {self.reported_user.email} ({self.reason})"

    def mark_handled(self, moderator, notes=""):
        """Mark report as handled by a moderator."""
        from django.utils import timezone
        
        self.handled = True
        self.handled_by = moderator
        self.handled_at = timezone.now()
        if notes:
            self.moderator_notes = notes
        self.save()

