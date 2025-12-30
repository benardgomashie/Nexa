from rest_framework import serializers

from .models import Report


class ReportSerializer(serializers.ModelSerializer):
    """Serializer for viewing reports (admin/moderator use)."""

    reporter_email = serializers.EmailField(source="reporter.email", read_only=True)
    reported_user_email = serializers.EmailField(source="reported_user.email", read_only=True)

    class Meta:
        model = Report
        fields = (
            "id",
            "reporter",
            "reporter_email",
            "reported_user",
            "reported_user_email",
            "reason",
            "description",
            "handled",
            "handled_by",
            "handled_at",
            "moderator_notes",
            "created_at",
        )
        read_only_fields = (
            "id",
            "reporter",
            "reporter_email",
            "reported_user_email",
            "handled",
            "handled_by",
            "handled_at",
            "moderator_notes",
            "created_at",
        )


class ReportCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new report."""

    reported_user = serializers.IntegerField(help_text="ID of the user to report")

    class Meta:
        model = Report
        fields = ("reported_user", "reason", "description")

    def validate_reported_user(self, value):
        """Validate the reported_user field."""
        from django.contrib.auth import get_user_model

        User = get_user_model()
        request = self.context.get("request")

        # Check if user exists
        try:
            reported_user = User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("User does not exist.")

        # Prevent self-reporting
        if reported_user == request.user:
            raise serializers.ValidationError("You cannot report yourself.")

        # Check for duplicate recent reports (within 24 hours)
        from django.utils import timezone
        from datetime import timedelta

        recent_cutoff = timezone.now() - timedelta(hours=24)
        duplicate_report = Report.objects.filter(
            reporter=request.user,
            reported_user=reported_user,
            created_at__gte=recent_cutoff,
        ).exists()

        if duplicate_report:
            raise serializers.ValidationError(
                "You have already reported this user recently. Please wait 24 hours before reporting again."
            )

        return value

    def validate_description(self, value):
        """Validate description length."""
        if value and len(value) > 1000:
            raise serializers.ValidationError("Description too long (max 1000 characters).")
        return value

    def create(self, validated_data):
        from django.contrib.auth import get_user_model

        User = get_user_model()
        request = self.context.get("request")
        reported_user_id = validated_data.pop("reported_user")

        reported_user = User.objects.get(id=reported_user_id)

        report = Report.objects.create(
            reporter=request.user,
            reported_user=reported_user,
            reason=validated_data.get("reason"),
            description=validated_data.get("description", ""),
        )

        return report
