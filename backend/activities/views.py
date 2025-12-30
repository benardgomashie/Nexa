from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Q
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from math import radians, cos, sin, asin, sqrt

from .models import Activity, ActivityCategory, ActivityParticipant, ActivityChat, ActivityMessage
from .serializers import (
    ActivityCategorySerializer,
    ActivityListSerializer,
    ActivityDetailSerializer,
    ActivityCreateSerializer,
    JoinRequestSerializer,
    ParticipantResponseSerializer,
    ActivityMessageSerializer,
    ActivityMessageCreateSerializer,
    ActivityParticipantSerializer,
)


class ActivityCategoryListView(generics.ListAPIView):
    """GET /api/v1/activities/categories/ - List all activity categories."""

    queryset = ActivityCategory.objects.filter(is_active=True)
    serializer_class = ActivityCategorySerializer
    permission_classes = (IsAuthenticated,)


class ActivityListCreateView(APIView):
    """
    GET /api/v1/activities/ - List nearby activities
    POST /api/v1/activities/ - Create a new activity
    """

    permission_classes = (IsAuthenticated,)

    def get(self, request):
        """List nearby activities with filters."""
        from profiles.models import LocationPreference

        # Get user's location
        try:
            my_location = request.user.profile.location_preference
        except:
            return Response(
                {"error": "Please set your location first"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not my_location.latitude or not my_location.longitude:
            return Response(
                {"error": "Please set your location first"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Parse filters
        radius_km = int(request.query_params.get("radius_km", my_location.radius_km or 25))
        category_id = request.query_params.get("category")
        date_from = request.query_params.get("date_from")
        date_to = request.query_params.get("date_to")
        hosted_by_me = request.query_params.get("hosted_by_me") == "true"
        joined_by_me = request.query_params.get("joined_by_me") == "true"

        # Base queryset: open activities in the future
        activities = Activity.objects.filter(
            status=Activity.Status.OPEN,
            date__gte=timezone.now().date(),
        ).select_related("host", "category").prefetch_related("participants")

        # Filter by host
        if hosted_by_me:
            activities = Activity.objects.filter(host=request.user)
        elif joined_by_me:
            my_participations = ActivityParticipant.objects.filter(
                user=request.user,
                status__in=[ActivityParticipant.Status.PENDING, ActivityParticipant.Status.CONFIRMED],
            ).values_list("activity_id", flat=True)
            activities = Activity.objects.filter(id__in=my_participations)
        else:
            # For discovery, filter by visibility
            activities = activities.filter(
                Q(visibility=Activity.Visibility.PUBLIC) |
                Q(visibility=Activity.Visibility.CONNECTIONS, host__in=self._get_connections(request.user))
            )

        # Apply category filter
        if category_id:
            activities = activities.filter(category_id=category_id)

        # Apply date filters
        if date_from:
            activities = activities.filter(date__gte=date_from)
        if date_to:
            activities = activities.filter(date__lte=date_to)

        # Calculate distances and filter by radius
        def haversine(lon1, lat1, lon2, lat2):
            lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            return 6371 * c

        results = []
        for activity in activities:
            # Calculate distance if coordinates available
            distance = None
            if activity.latitude and activity.longitude:
                distance = haversine(
                    float(my_location.longitude),
                    float(my_location.latitude),
                    float(activity.longitude),
                    float(activity.latitude),
                )
                # Skip if outside radius (unless viewing own activities)
                if not hosted_by_me and not joined_by_me and distance > radius_km:
                    continue

            activity.distance_km = round(distance, 1) if distance else None
            results.append(activity)

        # Sort by date, then distance
        results.sort(key=lambda x: (x.date, x.distance_km or 9999))

        # Pagination
        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 20))
        start = (page - 1) * page_size
        end = start + page_size
        paginated = results[start:end]

        serializer = ActivityListSerializer(paginated, many=True, context={"request": request})
        return Response({
            "count": len(results),
            "page": page,
            "page_size": page_size,
            "results": serializer.data,
        })

    def post(self, request):
        """Create a new activity."""
        serializer = ActivityCreateSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            activity = serializer.save()
            return Response(
                ActivityDetailSerializer(activity, context={"request": request}).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def _get_connections(self, user):
        """Get list of connected user IDs."""
        from connections.models import Connection
        connections = Connection.objects.filter(
            Q(from_user=user) | Q(to_user=user),
            status=Connection.Status.ACCEPTED,
        )
        connected_ids = set()
        for conn in connections:
            connected_ids.add(conn.from_user_id if conn.to_user == user else conn.to_user_id)
        return connected_ids


class ActivityDetailView(APIView):
    """
    GET /api/v1/activities/<id>/ - Get activity details
    PUT /api/v1/activities/<id>/ - Update activity (host only)
    DELETE /api/v1/activities/<id>/ - Cancel activity (host only)
    """

    permission_classes = (IsAuthenticated,)

    def get(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)
        serializer = ActivityDetailSerializer(activity, context={"request": request})
        return Response(serializer.data)

    def put(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)
        if activity.host != request.user:
            return Response(
                {"error": "Only the host can update this activity"},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = ActivityCreateSerializer(
            activity, data=request.data, partial=True, context={"request": request}
        )
        if serializer.is_valid():
            serializer.save()
            return Response(
                ActivityDetailSerializer(activity, context={"request": request}).data
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)
        if activity.host != request.user:
            return Response(
                {"error": "Only the host can cancel this activity"},
                status=status.HTTP_403_FORBIDDEN,
            )
        activity.status = Activity.Status.CANCELLED
        activity.save()
        return Response({"message": "Activity cancelled"})


class ActivityJoinView(APIView):
    """
    POST /api/v1/activities/<id>/join/ - Request to join an activity
    DELETE /api/v1/activities/<id>/join/ - Cancel join request / leave activity
    """

    permission_classes = (IsAuthenticated,)

    def post(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)

        # Check if can join
        can_join, reason = activity.can_user_join(request.user)
        if not can_join:
            return Response({"error": reason}, status=status.HTTP_400_BAD_REQUEST)

        serializer = JoinRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Create participant record
        participant, created = ActivityParticipant.objects.get_or_create(
            activity=activity,
            user=request.user,
            defaults={
                "message": serializer.validated_data.get("message", ""),
                "status": ActivityParticipant.Status.PENDING,
            },
        )

        if not created:
            return Response(
                {"error": "You have already requested to join this activity"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            "message": "Join request sent",
            "status": participant.status,
        }, status=status.HTTP_201_CREATED)

    def delete(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)

        try:
            participant = ActivityParticipant.objects.get(
                activity=activity, user=request.user
            )
        except ActivityParticipant.DoesNotExist:
            return Response(
                {"error": "You are not a participant"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        participant.status = ActivityParticipant.Status.CANCELLED
        participant.save()
        return Response({"message": "Left activity"})


class ActivityParticipantsView(APIView):
    """
    GET /api/v1/activities/<id>/participants/ - List participants (host only sees pending)
    POST /api/v1/activities/<id>/participants/<user_id>/ - Approve/decline/remove participant
    """

    permission_classes = (IsAuthenticated,)

    def get(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)

        # Only host can see pending requests
        if activity.host == request.user:
            participants = activity.participants.all()
        else:
            participants = activity.participants.filter(
                status=ActivityParticipant.Status.CONFIRMED
            )

        serializer = ActivityParticipantSerializer(participants, many=True)
        return Response(serializer.data)


class ActivityParticipantActionView(APIView):
    """POST /api/v1/activities/<id>/participants/<user_id>/ - Approve/decline/remove."""

    permission_classes = (IsAuthenticated,)

    def post(self, request, activity_id, user_id):
        activity = get_object_or_404(Activity, id=activity_id)

        if activity.host != request.user:
            return Response(
                {"error": "Only the host can manage participants"},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            participant = ActivityParticipant.objects.get(
                activity=activity, user_id=user_id
            )
        except ActivityParticipant.DoesNotExist:
            return Response(
                {"error": "Participant not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = ParticipantResponseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data["action"]

        if action == "approve":
            if activity.is_full:
                return Response(
                    {"error": "Activity is full"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            participant.status = ActivityParticipant.Status.CONFIRMED
            participant.responded_at = timezone.now()
            participant.save()

            # Create chat if first participant confirmed
            if not hasattr(activity, "chat"):
                ActivityChat.objects.create(activity=activity)

            return Response({"message": "Participant approved"})

        elif action == "decline":
            participant.status = ActivityParticipant.Status.DECLINED
            participant.responded_at = timezone.now()
            participant.save()
            return Response({"message": "Participant declined"})

        elif action == "remove":
            participant.status = ActivityParticipant.Status.REMOVED
            participant.responded_at = timezone.now()
            participant.save()
            return Response({"message": "Participant removed"})


class ActivityChatView(APIView):
    """
    GET /api/v1/activities/<id>/chat/ - Get activity chat messages
    POST /api/v1/activities/<id>/chat/ - Send message to activity chat
    """

    permission_classes = (IsAuthenticated,)

    def get(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)

        # Check if user is host or confirmed participant
        is_host = activity.host == request.user
        is_participant = activity.participants.filter(
            user=request.user, status=ActivityParticipant.Status.CONFIRMED
        ).exists()

        if not is_host and not is_participant:
            return Response(
                {"error": "Only participants can view the chat"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Get or create chat
        chat, _ = ActivityChat.objects.get_or_create(activity=activity)

        # Get messages
        messages = chat.messages.all().order_by("-created_at")[:100]

        # Mark as read
        for msg in messages:
            msg.read_by.add(request.user)

        serializer = ActivityMessageSerializer(
            messages, many=True, context={"request": request}
        )
        return Response(serializer.data)

    def post(self, request, activity_id):
        activity = get_object_or_404(Activity, id=activity_id)

        # Check if user is host or confirmed participant
        is_host = activity.host == request.user
        is_participant = activity.participants.filter(
            user=request.user, status=ActivityParticipant.Status.CONFIRMED
        ).exists()

        if not is_host and not is_participant:
            return Response(
                {"error": "Only participants can send messages"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ActivityMessageCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Get or create chat
        chat, _ = ActivityChat.objects.get_or_create(activity=activity)

        # Create message
        message = ActivityMessage.objects.create(
            chat=chat,
            sender=request.user,
            content=serializer.validated_data["content"],
        )
        message.read_by.add(request.user)

        return Response(
            ActivityMessageSerializer(message, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )

