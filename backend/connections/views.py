from django.db.models import Q
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Connection
from .serializers import (
    ConnectionCreateSerializer,
    ConnectionSerializer,
    ConnectionUpdateSerializer,
)


class ConnectionListView(APIView):
    """
    GET /api/v1/connections/ - List connections by status
    Query params:
      - status: 'pending_sent', 'pending_received', 'accepted', 'all'
    """

    permission_classes = (IsAuthenticated,)
    default_status_filter = "all"

    def get(self, request):
        status_filter = request.query_params.get("status", self.default_status_filter)
        user = request.user

        # Base queryset
        queryset = Connection.objects.select_related(
            "from_user", "to_user", "from_user__profile", "to_user__profile"
        ).prefetch_related(
            "from_user__profile__photos",
            "to_user__profile__photos",
            "from_user__profile__intents",
            "to_user__profile__intents",
            "from_user__profile__interests",
            "to_user__profile__interests",
        )

        if status_filter == "pending_sent":
            # Requests I sent that are pending
            queryset = queryset.filter(from_user=user, status=Connection.Status.PENDING)
        elif status_filter == "pending_received":
            # Requests sent to me that are pending
            queryset = queryset.filter(to_user=user, status=Connection.Status.PENDING)
        elif status_filter == "accepted":
            # All accepted connections
            queryset = queryset.filter(
                Q(from_user=user, status=Connection.Status.ACCEPTED)
                | Q(to_user=user, status=Connection.Status.ACCEPTED)
            )
        else:
            # All connections (exclude blocked)
            queryset = queryset.filter(
                Q(from_user=user) | Q(to_user=user)
            ).exclude(status=Connection.Status.BLOCKED)

        # Serialize
        serializer = ConnectionSerializer(queryset, many=True, context={"request": request})

        return Response({
            "count": queryset.count(),
            "status_filter": status_filter,
            "results": serializer.data,
        })


class ConnectionSentListView(ConnectionListView):
    """GET /api/v1/connections/sent/ - List sent connection requests"""
    default_status_filter = "pending_sent"


class ConnectionReceivedListView(ConnectionListView):
    """GET /api/v1/connections/received/ - List received connection requests"""
    default_status_filter = "pending_received"


class ConnectionCreateView(generics.CreateAPIView):
    """
    POST /api/v1/connections/ - Send a connection request
    Body: {"to_user": <user_id>}
    """

    permission_classes = (IsAuthenticated,)
    serializer_class = ConnectionCreateSerializer

    def perform_create(self, serializer):
        serializer.save()


class ConnectionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/v1/connections/{id}/ - Get connection details
    PATCH /api/v1/connections/{id}/ - Update connection (accept/reject/block)
    DELETE /api/v1/connections/{id}/ - Delete/cancel connection request
    """

    permission_classes = (IsAuthenticated,)
    queryset = Connection.objects.select_related("from_user", "to_user")

    def get_serializer_class(self):
        if self.request.method in ["PUT", "PATCH"]:
            return ConnectionUpdateSerializer
        return ConnectionSerializer

    def get_queryset(self):
        # User can only access connections they're part of
        user = self.request.user
        return Connection.objects.filter(
            Q(from_user=user) | Q(to_user=user)
        ).exclude(status=Connection.Status.BLOCKED)

    def perform_destroy(self, instance):
        """Delete/cancel a connection."""
        from rest_framework import serializers
        
        user = self.request.user

        # Only sender can cancel pending requests
        if instance.status == Connection.Status.PENDING and instance.from_user != user:
            raise serializers.ValidationError("You can only cancel requests you sent.")

        # Either user can delete accepted connections (disconnect)
        instance.delete()

