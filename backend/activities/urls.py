from django.urls import path
from . import views

app_name = "activities"

urlpatterns = [
    # Categories
    path("categories/", views.ActivityCategoryListView.as_view(), name="activity-categories"),
    
    # Activities
    path("", views.ActivityListCreateView.as_view(), name="activity-list-create"),
    path("<int:activity_id>/", views.ActivityDetailView.as_view(), name="activity-detail"),
    
    # Join/Leave
    path("<int:activity_id>/join/", views.ActivityJoinView.as_view(), name="activity-join"),
    
    # Participants management
    path("<int:activity_id>/participants/", views.ActivityParticipantsView.as_view(), name="activity-participants"),
    path("<int:activity_id>/participants/<int:user_id>/", views.ActivityParticipantActionView.as_view(), name="activity-participant-action"),
    
    # Chat
    path("<int:activity_id>/chat/", views.ActivityChatView.as_view(), name="activity-chat"),
]
