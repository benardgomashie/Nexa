from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode

User = get_user_model()


def send_verification_email(user, request=None):
    """Send email verification link to user."""
    token = default_token_generator.make_token(user)
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))

    # For development, print to console
    verification_url = f"norvi://verify-email?uidb64={uidb64}&token={token}"

    subject = "Verify your Norvi account"
    message = f"""
Hello {user.first_name or "there"},

Welcome to Norvi! Please verify your email address by clicking the link below:

{verification_url}

Or use these values in the app:
- uidb64: {uidb64}
- token: {token}

If you didn't create a Norvi account, you can ignore this email.

Best,
The Norvi Team
    """

    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )

    return {"uidb64": uidb64, "token": token}


def send_password_reset_email(user):
    """Send password reset link to user."""
    token = default_token_generator.make_token(user)
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))

    reset_url = f"norvi://reset-password?uidb64={uidb64}&token={token}"

    subject = "Reset your Norvi password"
    message = f"""
Hello {user.first_name or "there"},

You requested a password reset for your Norvi account. Click the link below:

{reset_url}

Or use these values in the app:
- uidb64: {uidb64}
- token: {token}

If you didn't request this, you can ignore this email.

Best,
The Norvi Team
    """

    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )

    return {"uidb64": uidb64, "token": token}
