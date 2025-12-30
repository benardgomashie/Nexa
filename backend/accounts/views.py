from django.contrib.auth import get_user_model
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .emails import send_password_reset_email, send_verification_email
from .serializers import (
    EmailVerificationSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserSerializer,
)

User = get_user_model()


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = "email"


@method_decorator(ratelimit(key='ip', rate='5/h', method='POST'), name='dispatch')
class EmailTokenObtainPairView(TokenObtainPairView):
    permission_classes = (AllowAny,)
    serializer_class = EmailTokenObtainPairSerializer


@method_decorator(ratelimit(key='ip', rate='3/h', method='POST'), name='dispatch')
class RegisterView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Send verification email
        try:
            email_data = send_verification_email(user, request)
        except Exception:
            email_data = None

        data = {
            "user": UserSerializer(user).data,
            "message": "Account created. Please check your email to verify your account.",
        }
        # Include tokens in dev mode for testing (remove in production)
        if email_data:
            data["_dev_verification"] = email_data

        return Response(data, status=status.HTTP_201_CREATED)


class VerifyEmailView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        serializer = EmailVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]
        user.is_active = True
        user.save()

        # Generate tokens for immediate login
        refresh = RefreshToken.for_user(user)
        data = {
            "user": UserSerializer(user).data,
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            },
            "message": "Email verified successfully.",
        }
        return Response(data, status=status.HTTP_200_OK)


@method_decorator(ratelimit(key='ip', rate='5/h', method='POST'), name='dispatch')
class ResendVerificationView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get("email", "").lower()
        if not email:
            return Response({"error": "Email is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email__iexact=email, is_active=False)
            send_verification_email(user, request)
        except User.DoesNotExist:
            pass  # Don't reveal if email exists

        return Response(
            {"message": "If an unverified account exists, a verification email has been sent."},
            status=status.HTTP_200_OK,
        )


@method_decorator(ratelimit(key='ip', rate='5/h', method='POST'), name='dispatch')
class PasswordResetRequestView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"]
        try:
            user = User.objects.get(email__iexact=email, is_active=True)
            send_password_reset_email(user)
        except User.DoesNotExist:
            pass  # Don't reveal if email exists

        return Response(
            {"message": "If an account exists with this email, a password reset link has been sent."},
            status=status.HTTP_200_OK,
        )


class PasswordResetConfirmView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]
        user.set_password(serializer.validated_data["new_password"])
        user.save()

        return Response({"message": "Password has been reset successfully."}, status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response({"error": "Refresh token is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except Exception:  # broad to avoid leaking token errors
            return Response({"error": "Invalid or expired refresh token."}, status=status.HTTP_400_BAD_REQUEST)

        return Response({"message": "Logged out successfully."}, status=status.HTTP_205_RESET_CONTENT)


class DeleteAccountView(APIView):
    """Delete the authenticated user's account permanently."""
    permission_classes = (IsAuthenticated,)

    def delete(self, request):
        user = request.user
        
        # Optional: Require password confirmation for extra security
        password = request.data.get("password")
        if password:
            if not user.check_password(password):
                return Response(
                    {"error": "Incorrect password."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Delete the user account
        user.delete()
        
        return Response(
            {"message": "Account deleted successfully."},
            status=status.HTTP_200_OK
        )
