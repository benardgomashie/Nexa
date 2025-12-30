from django.db import models
from rest_framework import generics, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import IntentTag, InterestTag, LocationPreference, MatchingPreference, Profile, ProfilePhoto
from .serializers import (
    IntentTagSerializer,
    InterestTagSerializer,
    PreferencesSerializer,
    ProfilePhotoSerializer,
    ProfilePhotoUploadSerializer,
    ProfileSerializer,
    PublicProfileSerializer,
)


class MyProfileView(generics.RetrieveUpdateAPIView):
    """
    GET /api/v1/me/ - Retrieve current user's profile
    PUT/PATCH /api/v1/me/ - Update current user's profile
    """

    permission_classes = (IsAuthenticated,)
    serializer_class = ProfileSerializer

    def get_object(self):
        profile, _ = Profile.objects.get_or_create(user=self.request.user)
        return profile


class MyPhotosListView(APIView):
    """
    GET /api/v1/me/photos/ - List current user's photos
    POST /api/v1/me/photos/ - Upload a new photo
    """

    permission_classes = (IsAuthenticated,)
    parser_classes = (MultiPartParser, FormParser)

    def get(self, request):
        profile, _ = Profile.objects.get_or_create(user=request.user)
        photos = profile.photos.all()
        serializer = ProfilePhotoSerializer(photos, many=True)
        return Response(serializer.data)

    def post(self, request):
        profile, _ = Profile.objects.get_or_create(user=request.user)
        serializer = ProfilePhotoUploadSerializer(
            data=request.data,
            context={"profile": profile},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MyPhotoDetailView(APIView):
    """
    DELETE /api/v1/me/photos/{id}/ - Delete a specific photo
    """

    permission_classes = (IsAuthenticated,)

    def delete(self, request, pk):
        profile, _ = Profile.objects.get_or_create(user=request.user)
        try:
            photo = profile.photos.get(pk=pk)
        except ProfilePhoto.DoesNotExist:
            return Response(
                {"error": "Photo not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        photo.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class IntentTagListView(generics.ListAPIView):
    """
    GET /api/v1/tags/intents/ - List all active intent tags
    """

    permission_classes = (AllowAny,)
    serializer_class = IntentTagSerializer
    queryset = IntentTag.objects.filter(is_active=True)
    pagination_class = None  # Return all tags without pagination


class InterestTagListView(generics.ListAPIView):
    """
    GET /api/v1/tags/interests/ - List all active interest tags
    """

    permission_classes = (AllowAny,)
    serializer_class = InterestTagSerializer
    queryset = InterestTag.objects.filter(is_active=True)
    pagination_class = None  # Return all tags without pagination


class MyPreferencesView(generics.RetrieveUpdateAPIView):
    """
    GET /api/v1/me/preferences/ - Get current user's preferences
    PUT/PATCH /api/v1/me/preferences/ - Update preferences
    """

    permission_classes = (IsAuthenticated,)
    serializer_class = PreferencesSerializer

    def get_object(self):
        profile, _ = Profile.objects.get_or_create(user=self.request.user)
        return profile


class DiscoveryView(APIView):
    """
    GET /api/v1/discover/ - Discover nearby compatible users
    Query params:
      - radius_km: Override default radius
      - intent: Filter by intent name
      - interest: Filter by interest name
      - faith: 'same' or 'all'
      - page, page_size: Pagination
    """

    permission_classes = (IsAuthenticated,)

    def get(self, request):
        from django.db.models import Count, Q
        from math import radians, cos, sin, asin, sqrt

        # Get current user's profile and preferences
        try:
            my_profile = request.user.profile
        except Profile.DoesNotExist:
            return Response(
                {"error": "Please complete your profile first."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check if profile is complete
        if not my_profile.is_complete:
            return Response(
                {"error": "Please complete your profile before discovering others."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get or create preferences
        my_location, _ = LocationPreference.objects.get_or_create(profile=my_profile)
        my_matching, _ = MatchingPreference.objects.get_or_create(profile=my_profile)

        # Parse query params
        radius_override = request.query_params.get("radius_km")
        intent_filter = request.query_params.get("intent")
        interest_filter = request.query_params.get("interest")
        faith_param = request.query_params.get("faith")

        # Determine search radius
        search_radius = int(radius_override) if radius_override else my_location.radius_km

        # Start with base queryset: visible, complete, active profiles (exclude self)
        candidates = Profile.objects.filter(
            is_complete=True,
            user__is_active=True,
        ).exclude(user=request.user).select_related(
            "user", "location_preference", "matching_preference"
        ).prefetch_related("interests", "intents", "photos")

        # Filter by visibility
        candidates = candidates.filter(matching_preference__visible=True)

        # Filter by intent overlap
        if intent_filter:
            candidates = candidates.filter(intents__name=intent_filter)
        elif my_profile.intents.exists():
            # Must have at least one shared intent
            my_intent_ids = my_profile.intents.values_list("id", flat=True)
            candidates = candidates.filter(intents__id__in=my_intent_ids)

        # Filter by interest
        if interest_filter:
            candidates = candidates.filter(interests__name=interest_filter)

        # Filter by age bucket compatibility
        if my_matching.preferred_age_buckets:
            candidates = candidates.filter(age_bucket__in=my_matching.preferred_age_buckets)

        # Filter by faith compatibility
        faith_filter_mode = faith_param or my_matching.faith_filter
        if faith_filter_mode == "same_only" or faith_param == "same":
            if my_profile.faith:
                candidates = candidates.filter(faith=my_profile.faith)
        elif faith_filter_mode == "custom":
            if my_matching.faith_exclude:
                candidates = candidates.exclude(faith__in=my_matching.faith_exclude)

        # Exclude blocked users
        from connections.models import Connection
        blocked_user_ids = Connection.objects.filter(
            models.Q(from_user=request.user, status=Connection.Status.BLOCKED)
            | models.Q(to_user=request.user, status=Connection.Status.BLOCKED)
        ).values_list("from_user_id", "to_user_id")
        
        # Flatten the list of tuples and exclude current user
        blocked_ids = set()
        for from_id, to_id in blocked_user_ids:
            if from_id != request.user.id:
                blocked_ids.add(from_id)
            if to_id != request.user.id:
                blocked_ids.add(to_id)
        
        if blocked_ids:
            candidates = candidates.exclude(user__id__in=blocked_ids)

        # Haversine distance calculation function
        def haversine(lon1, lat1, lon2, lat2):
            """Calculate distance in km between two points."""
            lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            km = 6371 * c
            return km

        # Filter by distance and annotate with distance + match score
        results = []
        for candidate in candidates:
            try:
                candidate_location = candidate.location_preference
            except LocationPreference.DoesNotExist:
                continue

            # Skip if no coordinates
            if not my_location.latitude or not candidate_location.latitude:
                # For city-only matching, could add city comparison here
                continue

            # Calculate distance
            distance = haversine(
                float(my_location.longitude),
                float(my_location.latitude),
                float(candidate_location.longitude),
                float(candidate_location.latitude),
            )

            # Check if within radius
            if distance > search_radius:
                continue

            # Calculate match score
            shared_interests = set(my_profile.interests.values_list("id", flat=True)) & set(
                candidate.interests.values_list("id", flat=True)
            )
            shared_intents = set(my_profile.intents.values_list("id", flat=True)) & set(
                candidate.intents.values_list("id", flat=True)
            )

            # Simple scoring (can be enhanced)
            score = 0
            score += (50 - distance) / 50 * 30  # Distance score (max 30)
            score += len(shared_interests) * 5  # Interest score (5 per match)
            score += len(shared_intents) * 15  # Intent score (15 per match)

            # Faith match bonus
            if my_profile.faith and candidate.faith == my_profile.faith:
                score += 10

            results.append({
                "profile": candidate,
                "distance_km": round(distance, 1),
                "mutual_interest_count": len(shared_interests),
                "score": score,
            })

        # Sort by score descending
        results.sort(key=lambda x: x["score"], reverse=True)

        # Pagination
        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 20))
        start = (page - 1) * page_size
        end = start + page_size
        paginated = results[start:end]

        # Serialize results
        data = []
        for item in paginated:
            profile_data = PublicProfileSerializer(item["profile"]).data
            profile_data["distance_km"] = item["distance_km"]
            profile_data["mutual_interest_count"] = item["mutual_interest_count"]
            
            # Add connection status
            from connections.models import Connection
            connection_status, connection_obj = Connection.get_connection_status(
                request.user, item["profile"].user
            )
            profile_data["connection_status"] = connection_status
            profile_data["is_connection_pending"] = (
                connection_status == Connection.Status.PENDING if connection_status else False
            )
            
            data.append(profile_data)

        return Response({
            "count": len(results),
            "page": page,
            "page_size": page_size,
            "results": data,
        })


