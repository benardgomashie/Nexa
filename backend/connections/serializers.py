from rest_framework import serializers

from profiles.serializers import PublicProfileSerializer

from .models import Connection


class ConnectionSerializer(serializers.ModelSerializer):
    """Serializer for Connection model with user profile details."""

    from_user_profile = PublicProfileSerializer(source="from_user.profile", read_only=True)
    to_user_profile = PublicProfileSerializer(source="to_user.profile", read_only=True)
    is_sender = serializers.SerializerMethodField()

    class Meta:
        model = Connection
        fields = (
            "id",
            "from_user",
            "to_user",
            "from_user_profile",
            "to_user_profile",
            "status",
            "created_at",
            "updated_at",
            "accepted_at",
            "is_sender",
        )
        read_only_fields = (
            "id",
            "from_user",
            "from_user_profile",
            "to_user_profile",
            "created_at",
            "updated_at",
            "accepted_at",
        )

    def get_is_sender(self, obj):
        """Check if the current user is the sender of this connection."""
        request = self.context.get("request")
        if request and request.user:
            return obj.from_user == request.user
        return False


class ConnectionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new connection request."""

    to_user = serializers.IntegerField(help_text="ID of the user to connect with")

    class Meta:
        model = Connection
        fields = ("to_user",)

    def validate_to_user(self, value):
        """Validate the to_user field."""
        from django.contrib.auth import get_user_model

        User = get_user_model()
        request = self.context.get("request")

        # Check if user exists
        try:
            to_user = User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("User does not exist.")

        # Prevent self-connection
        if to_user == request.user:
            raise serializers.ValidationError("You cannot connect with yourself.")

        # Check if users are blocked
        if Connection.is_blocked(request.user, to_user):
            raise serializers.ValidationError("This connection is not available.")

        # Check for existing connection
        existing_status, _ = Connection.get_connection_status(request.user, to_user)
        if existing_status:
            if existing_status == Connection.Status.PENDING:
                raise serializers.ValidationError("Connection request already pending.")
            elif existing_status == Connection.Status.ACCEPTED:
                raise serializers.ValidationError("You are already connected.")

        return value

    def create(self, validated_data):
        from django.contrib.auth import get_user_model

        User = get_user_model()
        request = self.context.get("request")
        to_user_id = validated_data["to_user"]

        to_user = User.objects.get(id=to_user_id)

        connection = Connection.objects.create(
            from_user=request.user,
            to_user=to_user,
            status=Connection.Status.PENDING,
        )

        return connection


class ConnectionUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating connection status (accept/reject/block)."""

    action = serializers.ChoiceField(
        choices=["accept", "reject", "block"],
        write_only=True,
        help_text="Action to perform: accept, reject, or block",
    )

    class Meta:
        model = Connection
        fields = ("action",)

    def update(self, instance, validated_data):
        action = validated_data.get("action")
        request = self.context.get("request")

        # Only to_user can accept/reject pending requests
        if action in ["accept", "reject"]:
            if instance.to_user != request.user:
                raise serializers.ValidationError("You can only respond to requests sent to you.")
            if instance.status != Connection.Status.PENDING:
                raise serializers.ValidationError("This request is no longer pending.")

            if action == "accept":
                success = instance.accept()
                
                # Auto-create chat thread when connection is accepted
                if success:
                    from chat.models import ChatThread
                    ChatThread.get_or_create_thread(instance.from_user, instance.to_user)
                    
            elif action == "reject":
                instance.reject()

        # Either user can block
        elif action == "block":
            instance.block()

        return instance
