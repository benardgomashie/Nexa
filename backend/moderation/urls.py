from django.urls import path

from .views import MyReportsListView, ReportCreateView

app_name = "moderation"

urlpatterns = [
    path("", ReportCreateView.as_view(), name="report-create"),
    path("my/", MyReportsListView.as_view(), name="my-reports"),
]
