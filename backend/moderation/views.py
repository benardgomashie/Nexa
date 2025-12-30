from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Report
from .serializers import ReportCreateSerializer, ReportSerializer


@method_decorator(ratelimit(key='user', rate='10/d', method='POST'), name='dispatch')
class ReportCreateView(generics.CreateAPIView):
    """
    POST /api/v1/reports/ - Submit a new report
    Body: {"reported_user": <user_id>, "reason": "<reason>", "description": "..."}
    Rate limited to 10 reports per user per day.
    """

    permission_classes = (IsAuthenticated,)
    serializer_class = ReportCreateSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"status": "Report submitted successfully. Thank you for helping keep Nexa safe."},
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MyReportsListView(generics.ListAPIView):
    """
    GET /api/v1/reports/my/ - List reports submitted by current user
    """

    permission_classes = (IsAuthenticated,)
    serializer_class = ReportSerializer

    def get_queryset(self):
        return Report.objects.filter(reporter=self.request.user)

