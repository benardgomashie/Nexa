from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

User = get_user_model()


class AuthenticationTests(TestCase):
    """Test suite for authentication endpoints."""

    def setUp(self):
        self.client = APIClient()
        self.register_url = reverse("accounts:register")
        self.login_url = reverse("accounts:login")
        self.verify_url = reverse("accounts:verify-email")
        self.password_reset_url = reverse("accounts:password-reset")
        self.password_reset_confirm_url = reverse("accounts:password-reset-confirm")

        self.user_data = {
            "email": "test@example.com",
            "password": "TestPass123!",
            "password_confirm": "TestPass123!",
        }

    def test_user_registration_success(self):
        """Test successful user registration."""
        response = self.client.post(self.register_url, self.user_data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("user", response.data)
        self.assertIn("message", response.data)
        self.assertEqual(response.data["user"]["email"], self.user_data["email"])

        # Verify user was created but is inactive
        user = User.objects.get(email=self.user_data["email"])
        self.assertFalse(user.is_active)

    def test_user_registration_duplicate_email(self):
        """Test registration with duplicate email fails."""
        # Create first user
        self.client.post(self.register_url, self.user_data)
        # Try to create duplicate
        response = self.client.post(self.register_url, self.user_data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_user_registration_password_mismatch(self):
        """Test registration with mismatched passwords fails."""
        data = self.user_data.copy()
        data["password_confirm"] = "DifferentPass123!"
        response = self.client.post(self.register_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_inactive_user(self):
        """Test login with inactive (unverified) user fails."""
        # Register user (inactive by default)
        self.client.post(self.register_url, self.user_data)

        # Try to login
        login_data = {
            "email": self.user_data["email"],
            "password": self.user_data["password"],
        }
        response = self.client.post(self.login_url, login_data)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_active_user_success(self):
        """Test login with active user succeeds."""
        # Create active user
        user = User.objects.create_user(
            email=self.user_data["email"],
            password=self.user_data["password"],
            is_active=True,
        )

        # Login
        login_data = {
            "email": self.user_data["email"],
            "password": self.user_data["password"],
        }
        response = self.client.post(self.login_url, login_data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_login_wrong_password(self):
        """Test login with wrong password fails."""
        # Create active user
        User.objects.create_user(
            email=self.user_data["email"],
            password=self.user_data["password"],
            is_active=True,
        )

        # Try login with wrong password
        login_data = {
            "email": self.user_data["email"],
            "password": "WrongPassword123!",
        }
        response = self.client.post(self.login_url, login_data)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TokenTests(TestCase):
    """Test suite for JWT token functionality."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="token@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.login_url = reverse("accounts:login")
        self.refresh_url = reverse("accounts:token-refresh")
        self.logout_url = reverse("accounts:logout")

    def test_token_refresh(self):
        """Test token refresh works."""
        # Login to get tokens
        login_data = {"email": "token@example.com", "password": "TestPass123!"}
        response = self.client.post(self.login_url, login_data)
        refresh_token = response.data["refresh"]

        # Refresh token
        refresh_data = {"refresh": refresh_token}
        response = self.client.post(self.refresh_url, refresh_data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)

    def test_logout_blacklists_token(self):
        """Test logout blacklists refresh token."""
        # Login
        login_data = {"email": "token@example.com", "password": "TestPass123!"}
        response = self.client.post(self.login_url, login_data)
        refresh_token = response.data["refresh"]

        # Logout
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {response.data["access"]}')
        logout_data = {"refresh": refresh_token}
        response = self.client.post(self.logout_url, logout_data)
        self.assertEqual(response.status_code, status.HTTP_205_RESET_CONTENT)

        # Try to use the refresh token again (should fail)
        refresh_data = {"refresh": refresh_token}
        response = self.client.post(self.refresh_url, refresh_data)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
