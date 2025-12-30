from django.db.models import Q
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from connections.models import Connection

from .models import ChatMessage, ChatThread
from .serializers import (
    ChatMessageCreateSerializer,
    ChatMessageSerializer,
    ChatThreadSerializer,
)


class ChatThreadListView(APIView):
    """
    GET /api/v1/threads/ - List all chat threads for the current user
    """

    permission_classes = (IsAuthenticated,)

    def get(self, request):
        user = request.user

        # Get all threads where user is either user1 or user2
        threads = ChatThread.objects.filter(
            Q(user1=user) | Q(user2=user)
        ).select_related("user1", "user2", "user1__profile", "user2__profile").prefetch_related(
            "user1__profile__photos",
            "user2__profile__photos",
            "messages",
        )

        serializer = ChatThreadSerializer(threads, many=True, context={"request": request})

        return Response({
            "count": threads.count(),
            "results": serializer.data,
        })


class ChatThreadDetailView(generics.RetrieveAPIView):
    """
    GET /api/v1/threads/{id}/ - Get thread details
    """

    permission_classes = (IsAuthenticated,)
    serializer_class = ChatThreadSerializer

    def get_queryset(self):
        user = self.request.user
        return ChatThread.objects.filter(Q(user1=user) | Q(user2=user))


class ChatThreadMessagesView(APIView):
    """
    GET /api/v1/threads/{thread_id}/messages/ - Get messages in a thread (paginated)
    POST /api/v1/threads/{thread_id}/messages/ - Send a new message
    """

    permission_classes = (IsAuthenticated,)

    def get_thread(self, thread_id):
        """Get thread and verify user is a participant."""
        try:
            thread = ChatThread.objects.get(
                Q(id=thread_id),
                Q(user1=self.request.user) | Q(user2=self.request.user),
            )
            return thread
        except ChatThread.DoesNotExist:
            return None

    def get(self, request, thread_id):
        """Get messages in the thread (oldest first, paginated)."""
        thread = self.get_thread(thread_id)
        if not thread:
            return Response(
                {"error": "Thread not found or access denied."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Get messages with pagination
        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 50))

        messages = thread.messages.select_related("sender").order_by("sent_at")
        total_count = messages.count()

        # Calculate pagination
        start = (page - 1) * page_size
        end = start + page_size
        paginated_messages = messages[start:end]

        serializer = ChatMessageSerializer(paginated_messages, many=True, context={"request": request})

        return Response({
            "count": total_count,
            "page": page,
            "page_size": page_size,
            "results": serializer.data,
        })

    def post(self, request, thread_id):
        """Send a new message in the thread."""
        thread = self.get_thread(thread_id)
        if not thread:
            return Response(
                {"error": "Thread not found or access denied."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Verify users are still connected
        other_user = thread.get_other_user(request.user)
        if not Connection.are_connected(request.user, other_user):
            return Response(
                {"error": "You must be connected to send messages."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Verify not blocked
        if Connection.is_blocked(request.user, other_user):
            return Response(
                {"error": "Cannot send messages to this user."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Create message
        serializer = ChatMessageCreateSerializer(data=request.data)
        if serializer.is_valid():
            message = serializer.save(thread=thread, sender=request.user)
            response_serializer = ChatMessageSerializer(message, context={"request": request})
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChatThreadMarkReadView(APIView):
    """
    POST /api/v1/threads/{thread_id}/read/ - Mark all messages in thread as read
    """

    permission_classes = (IsAuthenticated,)

    def post(self, request, thread_id):
        """Mark all messages from the other user as read."""
        try:
            thread = ChatThread.objects.get(
                Q(id=thread_id),
                Q(user1=request.user) | Q(user2=request.user),
            )
        except ChatThread.DoesNotExist:
            return Response(
                {"error": "Thread not found or access denied."},
                status=status.HTTP_404_NOT_FOUND,
            )

        thread.mark_as_read(request.user)

        return Response({"status": "Messages marked as read."}, status=status.HTTP_200_OK)

