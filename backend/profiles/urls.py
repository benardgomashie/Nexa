from django.urls import path

from .views import (
    DiscoveryView,
    IntentTagListView,
    InterestTagListView,
    MyPhotoDetailView,
    MyPhotosListView,
    MyPreferencesView,
    MyProfileView,
)

app_name = "profiles"

urlpatterns = [
    # Profile endpoints
    path("me/", MyProfileView.as_view(), name="my-profile"),
    path("me/photos/", MyPhotosListView.as_view(), name="my-photos"),
    path("me/photos/<int:pk>/", MyPhotoDetailView.as_view(), name="my-photo-detail"),
    path("me/preferences/", MyPreferencesView.as_view(), name="my-preferences"),
    # Discovery endpoint
    path("discover/", DiscoveryView.as_view(), name="discover"),
    # Tags endpoints
    path("tags/intents/", IntentTagListView.as_view(), name="intent-tags"),
    path("tags/interests/", InterestTagListView.as_view(), name="interest-tags"),
]
