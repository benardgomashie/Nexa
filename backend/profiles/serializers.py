from django.db.models import Max
from rest_framework import serializers

from .models import (
    IntentTag,
    InterestTag,
    LocationPreference,
    MatchingPreference,
    Profile,
    ProfilePhoto,
)


class IntentTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = IntentTag
        fields = ("id", "name", "description")


class InterestTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = InterestTag
        fields = ("id", "name", "category")


class ProfilePhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfilePhoto
        fields = ("id", "image", "ordering_index", "uploaded_at")
        read_only_fields = ("id", "uploaded_at")


class ProfileSerializer(serializers.ModelSerializer):
    interests = InterestTagSerializer(many=True, read_only=True)
    intents = IntentTagSerializer(many=True, read_only=True)
    photos = ProfilePhotoSerializer(many=True, read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)

    # Write-only fields for updating many-to-many (support both IDs and names)
    interest_ids = serializers.PrimaryKeyRelatedField(
        queryset=InterestTag.objects.filter(is_active=True),
        many=True,
        write_only=True,
        required=False,
    )
    intent_ids = serializers.PrimaryKeyRelatedField(
        queryset=IntentTag.objects.filter(is_active=True),
        many=True,
        write_only=True,
        required=False,
    )
    interest_tags = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False,
    )
    intent_tags = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False,
    )

    class Meta:
        model = Profile
        fields = (
            "id",
            "email",
            "display_name",
            "bio",
            "pronouns",
            "gender",
            "gender_visible",
            "age_bucket",
            "primary_language",
            "other_languages",
            "faith",
            "faith_visible",
            "interests",
            "intents",
            "interest_ids",
            "intent_ids",
            "interest_tags",
            "intent_tags",
            "photos",
            "is_complete",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "is_complete", "created_at", "updated_at")

    def update(self, instance, validated_data):
        # Handle many-to-many updates
        interest_ids = validated_data.pop("interest_ids", None)
        intent_ids = validated_data.pop("intent_ids", None)
        interest_tags = validated_data.pop("interest_tags", None)
        intent_tags = validated_data.pop("intent_tags", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Handle interest tags by name
        if interest_tags is not None:
            interests = InterestTag.objects.filter(name__in=interest_tags, is_active=True)
            instance.interests.set(interests)
        elif interest_ids is not None:
            instance.interests.set(interest_ids)
            
        # Handle intent tags by name
        if intent_tags is not None:
            intents = IntentTag.objects.filter(name__in=intent_tags, is_active=True)
            instance.intents.set(intents)
        elif intent_ids is not None:
            instance.intents.set(intent_ids)

        # Update completion status
        instance.check_completion()
        instance.save(update_fields=["is_complete"])

        return instance


class ProfilePhotoUploadSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfilePhoto
        fields = ("id", "image", "ordering_index")

    def validate(self, attrs):
        profile = self.context["profile"]
        # Check max photos limit (3)
        current_count = profile.photos.count()
        if current_count >= 3:
            raise serializers.ValidationError("Maximum of 3 photos allowed per profile.")
        return attrs

    def create(self, validated_data):
        profile = self.context["profile"]
        # Always auto-assign the next ordering_index
        max_index = profile.photos.aggregate(max_idx=Max("ordering_index"))["max_idx"]
        validated_data["ordering_index"] = (max_index if max_index is not None else -1) + 1
        return ProfilePhoto.objects.create(profile=profile, **validated_data)


class PublicProfileSerializer(serializers.ModelSerializer):
    """Serializer for viewing other users' profiles (limited fields)."""

    interests = InterestTagSerializer(many=True, read_only=True)
    intents = IntentTagSerializer(many=True, read_only=True)
    photos = ProfilePhotoSerializer(many=True, read_only=True)
    faith = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = (
            "id",
            "display_name",
            "bio",
            "pronouns",
            "age_bucket",
            "primary_language",
            "faith",
            "interests",
            "intents",
            "photos",
        )

    def get_faith(self, obj):
        """Only return faith if user has set it visible."""
        if obj.faith_visible:
            return obj.faith
        return None


class LocationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = LocationPreference
        fields = (
            "id",
            "latitude",
            "longitude",
            "city",
            "country",
            "radius_km",
            "share_precision",
            "updated_at",
        )
        read_only_fields = ("id", "updated_at")

    def validate_radius_km(self, value):
        if value < 5 or value > 50:
            raise serializers.ValidationError("Radius must be between 5 and 50 km.")
        return value


class MatchingPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = MatchingPreference
        fields = (
            "id",
            "preferred_age_buckets",
            "available_mornings",
            "available_afternoons",
            "available_evenings",
            "available_weekdays",
            "available_weekends",
            "faith_filter",
            "faith_exclude",
            "visible",
            "updated_at",
        )
        read_only_fields = ("id", "updated_at")


class PreferencesSerializer(serializers.Serializer):
    """Combined serializer for location and matching preferences."""

    location = LocationPreferenceSerializer()
    matching = MatchingPreferenceSerializer()

    def update(self, instance, validated_data):
        # instance is the Profile
        location_data = validated_data.get("location")
        matching_data = validated_data.get("matching")

        if location_data:
            location_pref, _ = LocationPreference.objects.get_or_create(profile=instance)
            for attr, value in location_data.items():
                setattr(location_pref, attr, value)
            location_pref.save()

        if matching_data:
            matching_pref, _ = MatchingPreference.objects.get_or_create(profile=instance)
            for attr, value in matching_data.items():
                setattr(matching_pref, attr, value)
            matching_pref.save()

        return instance

    def to_representation(self, instance):
        # instance is the Profile
        location_pref, _ = LocationPreference.objects.get_or_create(profile=instance)
        matching_pref, _ = MatchingPreference.objects.get_or_create(profile=instance)

        return {
            "location": LocationPreferenceSerializer(location_pref).data,
            "matching": MatchingPreferenceSerializer(matching_pref).data,
        }
