from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from .models import IntentTag, InterestTag, Profile

User = get_user_model()


class ProfileTests(TestCase):
    """Test suite for profile functionality."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="profile@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.client.force_authenticate(user=self.user)
        self.profile_url = reverse("profiles:my-profile")
        
        # Create test tags
        self.intent = IntentTag.objects.create(name="Coffee Meetup", is_active=True)
        self.interest = InterestTag.objects.create(name="Technology", is_active=True)

    def test_profile_auto_created(self):
        """Test profile is auto-created on user creation."""
        self.assertTrue(hasattr(self.user, "profile"))
        self.assertIsNotNone(self.user.profile)

    def test_get_profile(self):
        """Test retrieving user profile."""
        response = self.client.get(self.profile_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["user"], self.user.id)

    def test_update_profile(self):
        """Test updating profile information."""
        update_data = {
            "display_name": "Test User",
            "bio": "This is my bio",
            "age_bucket": "25-30",
            "pronouns": "they/them",
            "faith": "Christian",
            "faith_visible": True,
        }
        response = self.client.put(self.profile_url, update_data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["display_name"], "Test User")
        self.assertEqual(response.data["bio"], "This is my bio")

    def test_profile_add_tags(self):
        """Test adding intents and interests to profile."""
        update_data = {
            "display_name": "Test User",
            "intents": [self.intent.id],
            "interests": [self.interest.id],
        }
        response = self.client.put(self.profile_url, update_data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(self.intent.id, response.data["intents"])
        self.assertIn(self.interest.id, response.data["interests"])

    def test_profile_completeness(self):
        """Test profile completeness flag."""
        # Initially incomplete
        self.assertFalse(self.user.profile.is_complete)
        
        # Complete the profile
        update_data = {
            "display_name": "Test User",
            "bio": "Bio",
            "age_bucket": "25-30",
            "intents": [self.intent.id],
        }
        response = self.client.put(self.profile_url, update_data)
        
        # Refresh profile
        self.user.profile.refresh_from_db()
        self.assertTrue(self.user.profile.is_complete)


class DiscoveryTests(TestCase):
    """Test suite for discovery/matching functionality."""

    def setUp(self):
        self.client = APIClient()
        
        # Create main user
        self.user = User.objects.create_user(
            email="discover@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.client.force_authenticate(user=self.user)
        
        # Complete profile
        self.user.profile.display_name = "Discoverer"
        self.user.profile.bio = "Looking to connect"
        self.user.profile.age_bucket = "25-30"
        self.user.profile.save()
        
        # Create intent
        self.intent = IntentTag.objects.create(name="Coffee Meetup", is_active=True)
        self.user.profile.intents.add(self.intent)
        
        # Create location preference
        from profiles.models import LocationPreference, MatchingPreference
        LocationPreference.objects.create(
            profile=self.user.profile,
            latitude=5.6037,
            longitude=-0.1870,
            city="Accra",
            country="Ghana",
        )
        MatchingPreference.objects.create(
            profile=self.user.profile,
            visible=True,
        )
        
        # Create other users
        self.other_user = User.objects.create_user(
            email="other@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.other_user.profile.display_name = "Other User"
        self.other_user.profile.bio = "Also looking"
        self.other_user.profile.age_bucket = "25-30"
        self.other_user.profile.save()
        self.other_user.profile.intents.add(self.intent)
        
        LocationPreference.objects.create(
            profile=self.other_user.profile,
            latitude=5.6050,
            longitude=-0.1880,
            city="Accra",
            country="Ghana",
        )
        MatchingPreference.objects.create(
            profile=self.other_user.profile,
            visible=True,
        )
        
        self.discover_url = reverse("profiles:discover")

    def test_discover_requires_complete_profile(self):
        """Test discovery requires complete profile."""
        # Create user with incomplete profile
        incomplete_user = User.objects.create_user(
            email="incomplete@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.client.force_authenticate(user=incomplete_user)
        
        response = self.client.get(self.discover_url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_discover_returns_nearby_users(self):
        """Test discovery returns nearby compatible users."""
        response = self.client.get(self.discover_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(response.data["count"], 0)
        self.assertIn("results", response.data)

    def test_discover_excludes_self(self):
        """Test discovery doesn't return current user."""
        response = self.client.get(self.discover_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        for result in response.data["results"]:
            self.assertNotEqual(result["id"], self.user.profile.id)
