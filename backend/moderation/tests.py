from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from datetime import timedelta
from rest_framework import status
from rest_framework.test import APIClient

from .models import Report

User = get_user_model()


class ReportTests(TestCase):
    """Test suite for report functionality."""

    def setUp(self):
        self.client = APIClient()
        
        # Create users
        self.reporter = User.objects.create_user(
            email="reporter@example.com",
            password="TestPass123!",
            is_active=True,
        )
        self.reported_user = User.objects.create_user(
            email="badactor@example.com",
            password="TestPass123!",
            is_active=True,
        )
        
        self.client.force_authenticate(user=self.reporter)
        self.report_url = reverse("moderation:report-create")
        self.my_reports_url = reverse("moderation:my-reports")

    def test_submit_report(self):
        """Test submitting a report."""
        data = {
            "reported_user": self.reported_user.id,
            "reason": "harassment",
            "description": "This user was harassing me.",
        }
        response = self.client.post(self.report_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify report created
        report = Report.objects.filter(
            reporter=self.reporter,
            reported_user=self.reported_user,
        ).first()
        self.assertIsNotNone(report)
        self.assertEqual(report.reason, "harassment")
        self.assertFalse(report.handled)

    def test_prevent_self_report(self):
        """Test users cannot report themselves."""
        data = {
            "reported_user": self.reporter.id,
            "reason": "spam",
        }
        response = self.client.post(self.report_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_prevent_duplicate_recent_reports(self):
        """Test duplicate reports within 24 hours are prevented."""
        data = {
            "reported_user": self.reported_user.id,
            "reason": "spam",
        }
        
        # Submit first report
        self.client.post(self.report_url, data)
        
        # Try to submit duplicate
        response = self.client.post(self.report_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_allow_report_after_24_hours(self):
        """Test users can report same user after 24 hours."""
        # Create old report (25 hours ago)
        old_report = Report.objects.create(
            reporter=self.reporter,
            reported_user=self.reported_user,
            reason="spam",
        )
        old_report.created_at = timezone.now() - timedelta(hours=25)
        old_report.save()
        
        # Try to submit new report
        data = {
            "reported_user": self.reported_user.id,
            "reason": "harassment",
        }
        response = self.client.post(self.report_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_list_my_reports(self):
        """Test listing user's submitted reports."""
        # Create reports
        Report.objects.create(
            reporter=self.reporter,
            reported_user=self.reported_user,
            reason="spam",
        )
        
        response = self.client.get(self.my_reports_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_report_reasons(self):
        """Test all report reason types work."""
        reasons = [
            "harassment",
            "spam",
            "religious_harassment",
            "hate_speech",
            "inappropriate_content",
            "fake_profile",
            "other",
        ]
        
        for reason in reasons:
            # Create unique user for each report
            user = User.objects.create_user(
                email=f"{reason}@example.com",
                password="TestPass123!",
                is_active=True,
            )
            
            data = {
                "reported_user": user.id,
                "reason": reason,
            }
            response = self.client.post(self.report_url, data)
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_mark_report_handled(self):
        """Test marking report as handled."""
        report = Report.objects.create(
            reporter=self.reporter,
            reported_user=self.reported_user,
            reason="spam",
        )
        
        # Create moderator
        moderator = User.objects.create_user(
            email="mod@example.com",
            password="TestPass123!",
            is_active=True,
            is_staff=True,
        )
        
        # Mark as handled
        report.mark_handled(moderator, "Reviewed and warned user.")
        
        self.assertTrue(report.handled)
        self.assertEqual(report.handled_by, moderator)
        self.assertIsNotNone(report.handled_at)
        self.assertEqual(report.moderator_notes, "Reviewed and warned user.")
