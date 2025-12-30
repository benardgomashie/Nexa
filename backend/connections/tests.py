from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from .models import Connection

User = get_user_model()


class ConnectionTests(TestCase):
    """Test suite for connection functionality."""

    def setUp(self):
        self.client = APIClient()
        
        # Create users
        self.user1 = User.objects.create_user(
            email="user1@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com",
            password="TestPass123!",
            is_active=True,
        )
        
        self.client.force_authenticate(user=self.user1)
        self.connection_list_url = reverse("connections:connection-list")
        self.connection_create_url = reverse("connections:connection-create")

    def test_send_connection_request(self):
        """Test sending a connection request."""
        data = {"to_user": self.user2.id}
        response = self.client.post(self.connection_create_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify connection created
        connection = Connection.objects.filter(
            from_user=self.user1,
            to_user=self.user2,
        ).first()
        self.assertIsNotNone(connection)
        self.assertEqual(connection.status, Connection.Status.PENDING)

    def test_prevent_duplicate_connection_request(self):
        """Test duplicate connection requests are prevented."""
        data = {"to_user": self.user2.id}
        
        # Send first request
        self.client.post(self.connection_create_url, data)
        
        # Try to send duplicate
        response = self.client.post(self.connection_create_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_prevent_self_connection(self):
        """Test users cannot connect with themselves."""
        data = {"to_user": self.user1.id}
        response = self.client.post(self.connection_create_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_accept_connection_request(self):
        """Test accepting a connection request."""
        # Create pending connection
        connection = Connection.objects.create(
            from_user=self.user2,
            to_user=self.user1,
            status=Connection.Status.PENDING,
        )
        
        # Accept as user1 (recipient)
        url = reverse("connections:connection-detail", args=[connection.id])
        response = self.client.patch(url, {"action": "accept"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify status changed
        connection.refresh_from_db()
        self.assertEqual(connection.status, Connection.Status.ACCEPTED)
        self.assertIsNotNone(connection.accepted_at)

    def test_reject_connection_request(self):
        """Test rejecting a connection request."""
        # Create pending connection
        connection = Connection.objects.create(
            from_user=self.user2,
            to_user=self.user1,
            status=Connection.Status.PENDING,
        )
        
        # Reject as user1 (recipient)
        url = reverse("connections:connection-detail", args=[connection.id])
        response = self.client.patch(url, {"action": "reject"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify status changed
        connection.refresh_from_db()
        self.assertEqual(connection.status, Connection.Status.REJECTED)

    def test_block_user(self):
        """Test blocking a user."""
        # Create pending connection
        connection = Connection.objects.create(
            from_user=self.user2,
            to_user=self.user1,
            status=Connection.Status.PENDING,
        )
        
        # Block as user1
        url = reverse("connections:connection-detail", args=[connection.id])
        response = self.client.patch(url, {"action": "block"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify status changed
        connection.refresh_from_db()
        self.assertEqual(connection.status, Connection.Status.BLOCKED)

    def test_list_pending_sent_connections(self):
        """Test listing pending sent connection requests."""
        # Create pending connection from user1 to user2
        Connection.objects.create(
            from_user=self.user1,
            to_user=self.user2,
            status=Connection.Status.PENDING,
        )
        
        response = self.client.get(self.connection_list_url, {"status": "pending_sent"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)

    def test_list_pending_received_connections(self):
        """Test listing pending received connection requests."""
        # Create pending connection from user2 to user1
        Connection.objects.create(
            from_user=self.user2,
            to_user=self.user1,
            status=Connection.Status.PENDING,
        )
        
        response = self.client.get(self.connection_list_url, {"status": "pending_received"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)

    def test_connection_creates_chat_thread(self):
        """Test accepting connection creates chat thread."""
        from chat.models import ChatThread
        
        # Create and accept connection
        connection = Connection.objects.create(
            from_user=self.user2,
            to_user=self.user1,
            status=Connection.Status.PENDING,
        )
        
        # No thread exists yet
        self.assertFalse(ChatThread.objects.filter(
            user1=self.user1,
            user2=self.user2,
        ).exists())
        
        # Accept connection
        url = reverse("connections:connection-detail", args=[connection.id])
        self.client.patch(url, {"action": "accept"})
        
        # Thread should now exist
        thread = ChatThread.objects.filter(
            user1=self.user1,
            user2=self.user2,
        ).first()
        self.assertIsNotNone(thread)
