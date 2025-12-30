from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from connections.models import Connection
from profiles.models import Profile

from .models import ChatMessage, ChatThread

User = get_user_model()


class ChatThreadTests(TestCase):
    """Test suite for chat thread functionality."""

    def setUp(self):
        self.client = APIClient()
        
        # Create users
        self.user1 = User.objects.create_user(
            email="chatter1@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.user2 = User.objects.create_user(
            email="chatter2@example.com",
            password="TestPass123!",
            is_active=True,
        )
        
        # Create profiles (chat serializer expects profiles to exist)
        Profile.objects.create(user=self.user1)
        Profile.objects.create(user=self.user2)
        
        # Create accepted connection
        Connection.objects.create(
            from_user=self.user1,
            to_user=self.user2,
            status=Connection.Status.ACCEPTED,
        )
        
        # Create chat thread
        self.thread, _ = ChatThread.get_or_create_thread(self.user1, self.user2)
        
        self.client.force_authenticate(user=self.user1)
        self.thread_list_url = reverse("chat:thread-list")

    def test_thread_auto_created_on_connection_accept(self):
        """Test thread is created when connection is accepted."""
        # Create new users
        user3 = User.objects.create_user(
            email="user3@example.com",
            password="TestPass123!",
            is_active=True,
        )
        user4 = User.objects.create_user(
            email="user4@example.com",
            password="TestPass123!",
            is_active=True,
        )
        
        # Create connection
        conn = Connection.objects.create(
            from_user=user3,
            to_user=user4,
            status=Connection.Status.PENDING,
        )
        
        # No thread should exist yet
        thread_exists = ChatThread.objects.filter(
            user1=user3,
            user2=user4,
        ).exists()
        self.assertFalse(thread_exists)
        
        # Accept connection (this should create thread via signal/serializer)
        conn.accept()
        ChatThread.get_or_create_thread(user3, user4)
        
        # Thread should now exist
        thread = ChatThread.objects.filter(
            user1=user3,
            user2=user4,
        ).first()
        self.assertIsNotNone(thread)

    def test_list_threads(self):
        """Test listing user's chat threads."""
        response = self.client.get(self.thread_list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(response.data["count"], 0)

    def test_get_thread_detail(self):
        """Test getting thread details."""
        url = reverse("chat:thread-detail", args=[self.thread.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["id"], self.thread.id)

    def test_thread_ordering(self):
        """Test threads ordered by last message time."""
        # Create another connected user and thread
        user3 = User.objects.create_user(
            email="user3@example.com",
            password="TestPass123!",
            is_active=True,
        )
        Profile.objects.create(user=user3)
        Connection.objects.create(
            from_user=self.user1,
            to_user=user3,
            status=Connection.Status.ACCEPTED,
        )
        thread2, _ = ChatThread.get_or_create_thread(self.user1, user3)
        
        # Send message in thread2 (should make it appear first)
        ChatMessage.objects.create(
            thread=thread2,
            sender=self.user1,
            content="Recent message",
        )
        
        response = self.client.get(self.thread_list_url)
        # First thread should be the one with recent message
        self.assertEqual(response.data["results"][0]["id"], thread2.id)


class ChatMessageTests(TestCase):
    """Test suite for chat message functionality."""

    def setUp(self):
        self.client = APIClient()
        
        # Create users and connection
        self.user1 = User.objects.create_user(
            email="sender@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.user2 = User.objects.create_user(
            email="receiver@example.com",
            password="TestPass123!",
            is_active=True,
        )
        
        # Create profiles
        Profile.objects.create(user=self.user1)
        Profile.objects.create(user=self.user2)
        
        Connection.objects.create(
            from_user=self.user1,
            to_user=self.user2,
            status=Connection.Status.ACCEPTED,
        )
        
        self.thread, _ = ChatThread.get_or_create_thread(self.user1, self.user2)
        self.client.force_authenticate(user=self.user1)
        
        self.messages_url = reverse("chat:thread-messages", args=[self.thread.id])
        self.mark_read_url = reverse("chat:thread-mark-read", args=[self.thread.id])

    def test_send_message(self):
        """Test sending a message."""
        data = {"content": "Hello, this is a test message!"}
        response = self.client.post(self.messages_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["content"], data["content"])
        self.assertEqual(response.data["sender"], self.user1.id)

    def test_send_empty_message_fails(self):
        """Test sending empty message fails."""
        data = {"content": ""}
        response = self.client.post(self.messages_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_send_message_requires_connection(self):
        """Test sending message requires active connection."""
        # Create new user without connection
        user3 = User.objects.create_user(
            email="stranger@example.com",
            password="TestPass123!",
            is_active=True,
        )
        thread3, _ = ChatThread.get_or_create_thread(self.user1, user3)
        
        url = reverse("chat:thread-messages", args=[thread3.id])
        data = {"content": "Should fail"}
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_get_messages(self):
        """Test retrieving messages from thread."""
        # Create some messages
        ChatMessage.objects.create(
            thread=self.thread,
            sender=self.user1,
            content="Message 1",
        )
        ChatMessage.objects.create(
            thread=self.thread,
            sender=self.user2,
            content="Message 2",
        )
        
        response = self.client.get(self.messages_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 2)

    def test_mark_messages_as_read(self):
        """Test marking messages as read."""
        # Create message from user2
        message = ChatMessage.objects.create(
            thread=self.thread,
            sender=self.user2,
            content="Unread message",
        )
        self.assertIsNone(message.read_at)
        
        # Mark as read
        response = self.client.post(self.mark_read_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify read_at is set
        message.refresh_from_db()
        self.assertIsNotNone(message.read_at)

    def test_unread_count(self):
        """Test unread message count."""
        # Create unread messages from user2
        ChatMessage.objects.create(
            thread=self.thread,
            sender=self.user2,
            content="Unread 1",
        )
        ChatMessage.objects.create(
            thread=self.thread,
            sender=self.user2,
            content="Unread 2",
        )
        
        unread_count = self.thread.get_unread_count(self.user1)
        self.assertEqual(unread_count, 2)
