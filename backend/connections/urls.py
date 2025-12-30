from django.urls import path

from .views import (
    ConnectionCreateView,
    ConnectionDetailView,
    ConnectionListView,
    ConnectionReceivedListView,
    ConnectionSentListView,
)

app_name = "connections"

urlpatterns = [
    path("", ConnectionListView.as_view(), name="connection-list"),
    path("received/", ConnectionReceivedListView.as_view(), name="connection-received"),
    path("sent/", ConnectionSentListView.as_view(), name="connection-sent"),
    path("create/", ConnectionCreateView.as_view(), name="connection-create"),
    path("<int:pk>/", ConnectionDetailView.as_view(), name="connection-detail"),
]
