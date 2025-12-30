from rest_framework import serializers
from django.utils import timezone
from .models import Activity, ActivityCategory, ActivityParticipant, ActivityChat, ActivityMessage
from profiles.serializers import PublicProfileSerializer


class ActivityCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ActivityCategory
        fields = ("id", "name", "icon", "description")


class ActivityParticipantSerializer(serializers.ModelSerializer):
    user_profile = serializers.SerializerMethodField()

    class Meta:
        model = ActivityParticipant
        fields = (
            "id",
            "user",
            "user_profile",
            "status",
            "message",
            "requested_at",
            "responded_at",
        )
        read_only_fields = ("id", "user", "user_profile", "requested_at", "responded_at")

    def get_user_profile(self, obj):
        try:
            return PublicProfileSerializer(obj.user.profile).data
        except:
            return None


class ActivityListSerializer(serializers.ModelSerializer):
    """Serializer for listing activities (minimal data)."""

    host_profile = serializers.SerializerMethodField()
    category_name = serializers.CharField(source="category.name", read_only=True)
    participant_count = serializers.SerializerMethodField()
    spots_available = serializers.IntegerField(read_only=True)
    distance_km = serializers.FloatField(read_only=True, required=False)

    class Meta:
        model = Activity
        fields = (
            "id",
            "title",
            "description",
            "category",
            "category_name",
            "date",
            "time",
            "duration_minutes",
            "location_name",
            "max_participants",
            "participant_count",
            "spots_available",
            "status",
            "visibility",
            "host_profile",
            "distance_km",
            "created_at",
        )

    def get_host_profile(self, obj):
        try:
            return {
                "user_id": obj.host.id,
                "display_name": obj.host.profile.display_name,
                "photo": obj.host.profile.photos.first().image.url if obj.host.profile.photos.exists() else None,
            }
        except:
            return None

    def get_participant_count(self, obj):
        return obj.current_participant_count


class ActivityDetailSerializer(serializers.ModelSerializer):
    """Serializer for activity detail view."""

    host_profile = serializers.SerializerMethodField()
    category_data = ActivityCategorySerializer(source="category", read_only=True)
    participants = serializers.SerializerMethodField()
    participant_count = serializers.SerializerMethodField()
    spots_available = serializers.IntegerField(read_only=True)
    can_join = serializers.SerializerMethodField()
    is_host = serializers.SerializerMethodField()
    user_status = serializers.SerializerMethodField()

    class Meta:
        model = Activity
        fields = (
            "id",
            "title",
            "description",
            "category",
            "category_data",
            "date",
            "time",
            "duration_minutes",
            "location_name",
            "location_address",
            "latitude",
            "longitude",
            "max_participants",
            "min_participants",
            "participant_count",
            "spots_available",
            "status",
            "visibility",
            "host_profile",
            "participants",
            "can_join",
            "is_host",
            "user_status",
            "created_at",
            "updated_at",
        )

    def get_host_profile(self, obj):
        try:
            return PublicProfileSerializer(obj.host.profile).data
        except:
            return None

    def get_participants(self, obj):
        confirmed = obj.participants.filter(status=ActivityParticipant.Status.CONFIRMED)
        return ActivityParticipantSerializer(confirmed, many=True).data

    def get_participant_count(self, obj):
        return obj.current_participant_count

    def get_can_join(self, obj):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return {"allowed": False, "reason": "Please login"}
        can_join, reason = obj.can_user_join(request.user)
        return {"allowed": can_join, "reason": reason}

    def get_is_host(self, obj):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False
        return obj.host == request.user

    def get_user_status(self, obj):
        """Get current user's participation status."""
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return None
        if obj.host == request.user:
            return "host"
        try:
            participant = obj.participants.get(user=request.user)
            return participant.status
        except ActivityParticipant.DoesNotExist:
            return None


class ActivityCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating activities."""

    class Meta:
        model = Activity
        fields = (
            "title",
            "description",
            "category",
            "date",
            "time",
            "duration_minutes",
            "location_name",
            "location_address",
            "latitude",
            "longitude",
            "max_participants",
            "min_participants",
            "visibility",
            "gender_filter",
            "age_filter",
            "intent_filter",
        )

    def validate_date(self, value):
        if value < timezone.now().date():
            raise serializers.ValidationError("Activity date cannot be in the past")
        return value

    def validate_max_participants(self, value):
        if value < 2:
            raise serializers.ValidationError("Must have at least 2 participants")
        if value > 20:
            raise serializers.ValidationError("Maximum 20 participants allowed")
        return value

    def validate(self, data):
        min_p = data.get("min_participants", 2)
        max_p = data.get("max_participants", 4)
        if min_p > max_p:
            raise serializers.ValidationError(
                "Minimum participants cannot exceed maximum"
            )
        return data

    def create(self, validated_data):
        intent_filter = validated_data.pop("intent_filter", [])
        validated_data["host"] = self.context["request"].user
        activity = Activity.objects.create(**validated_data)
        if intent_filter:
            activity.intent_filter.set(intent_filter)
        return activity


class JoinRequestSerializer(serializers.Serializer):
    """Serializer for join requests."""

    message = serializers.CharField(max_length=300, required=False, allow_blank=True)


class ParticipantResponseSerializer(serializers.Serializer):
    """Serializer for host responding to join requests."""

    action = serializers.ChoiceField(choices=["approve", "decline", "remove"])


class ActivityMessageSerializer(serializers.ModelSerializer):
    """Serializer for activity chat messages."""

    sender_profile = serializers.SerializerMethodField()
    is_read = serializers.SerializerMethodField()

    class Meta:
        model = ActivityMessage
        fields = (
            "id",
            "sender",
            "sender_profile",
            "content",
            "created_at",
            "is_read",
        )
        read_only_fields = ("id", "sender", "sender_profile", "created_at", "is_read")

    def get_sender_profile(self, obj):
        try:
            return {
                "user_id": obj.sender.id,
                "display_name": obj.sender.profile.display_name,
                "photo": obj.sender.profile.photos.first().image.url if obj.sender.profile.photos.exists() else None,
            }
        except:
            return None

    def get_is_read(self, obj):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False
        return obj.read_by.filter(id=request.user.id).exists()


class ActivityMessageCreateSerializer(serializers.Serializer):
    """Serializer for creating activity messages."""

    content = serializers.CharField(max_length=1000)
