from django.urls import path

from .views import (
    ChatThreadDetailView,
    ChatThreadListView,
    ChatThreadMarkReadView,
    ChatThreadMessagesView,
)

app_name = "chat"

urlpatterns = [
    path("", ChatThreadListView.as_view(), name="thread-list"),
    path("<int:pk>/", ChatThreadDetailView.as_view(), name="thread-detail"),
    path("<int:thread_id>/messages/", ChatThreadMessagesView.as_view(), name="thread-messages"),
    path("<int:thread_id>/read/", ChatThreadMarkReadView.as_view(), name="thread-mark-read"),
]
