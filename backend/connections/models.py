from django.conf import settings
from django.db import models
from django.utils import timezone


class Connection(models.Model):
    """
    Represents a connection request or established connection between two users.
    
    States:
    - pending: from_user sent request, to_user hasn't responded
    - accepted: to_user accepted, both can chat
    - rejected: to_user declined (soft delete - keep for history)
    - blocked: from_user blocked to_user (hard block - hide from discovery)
    """

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"
        BLOCKED = "blocked", "Blocked"

    from_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="connections_sent",
        help_text="User who initiated the connection",
    )
    to_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="connections_received",
        help_text="User who received the connection request",
    )
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PENDING,
    )
    
    # Optional intro message when sending connection request
    intro_message = models.TextField(
        max_length=200,
        blank=True,
        help_text="Optional intro message sent with connection request",
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    accepted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the connection was accepted",
    )

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["from_user", "to_user"],
                name="unique_connection_pair",
            ),
            models.CheckConstraint(
                check=~models.Q(from_user=models.F("to_user")),
                name="no_self_connection",
            ),
        ]
        indexes = [
            models.Index(fields=["from_user", "status"]),
            models.Index(fields=["to_user", "status"]),
            models.Index(fields=["status", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.from_user.email} → {self.to_user.email} ({self.status})"

    def accept(self):
        """Accept a pending connection request."""
        if self.status == self.Status.PENDING:
            self.status = self.Status.ACCEPTED
            self.accepted_at = timezone.now()
            self.save()
            return True
        return False

    def reject(self):
        """Reject a pending connection request."""
        if self.status == self.Status.PENDING:
            self.status = self.Status.REJECTED
            self.save()
            return True
        return False

    def block(self):
        """Block the connection (hard block)."""
        self.status = self.Status.BLOCKED
        self.save()
        return True

    @staticmethod
    def get_connection_status(user1, user2):
        """
        Get the connection status between two users.
        Returns: (status, connection_obj) or (None, None) if no connection exists.
        """
        # Check both directions
        connection = Connection.objects.filter(
            models.Q(from_user=user1, to_user=user2) | models.Q(from_user=user2, to_user=user1)
        ).first()
        
        if connection:
            return connection.status, connection
        return None, None

    @staticmethod
    def is_blocked(user1, user2):
        """Check if either user has blocked the other."""
        return Connection.objects.filter(
            models.Q(from_user=user1, to_user=user2, status=Connection.Status.BLOCKED)
            | models.Q(from_user=user2, to_user=user1, status=Connection.Status.BLOCKED)
        ).exists()

    @staticmethod
    def are_connected(user1, user2):
        """Check if two users have an accepted connection."""
        return Connection.objects.filter(
            models.Q(from_user=user1, to_user=user2, status=Connection.Status.ACCEPTED)
            | models.Q(from_user=user2, to_user=user1, status=Connection.Status.ACCEPTED)
        ).exists()

