from django.core.management.base import BaseCommand

from profiles.models import IntentTag, InterestTag


class Command(BaseCommand):
    help = "Seed the database with initial intent and interest tags"

    def handle(self, *args, **options):
        self.stdout.write("Seeding tags...")

        # Intent tags (from product spec)
        intents = [
            {"name": "Friendship", "description": "Looking to make new friends"},
            {"name": "Networking", "description": "Professional connections and career growth"},
            {"name": "Skill Exchange", "description": "Teach or learn skills from others"},
            {"name": "Activity Partners", "description": "Find people to do activities with"},
            {"name": "Study Buddies", "description": "Accountability partners for learning"},
            {"name": "Mentorship", "description": "Seek or offer mentorship"},
        ]

        for intent_data in intents:
            obj, created = IntentTag.objects.get_or_create(
                name=intent_data["name"],
                defaults={"description": intent_data["description"]},
            )
            status = "Created" if created else "Exists"
            self.stdout.write(f"  {status}: Intent '{obj.name}'")

        # Interest tags (categorized, Ghana-relevant)
        interests = [
            # Sports & Fitness
            {"name": "Football", "category": "Sports"},
            {"name": "Basketball", "category": "Sports"},
            {"name": "Running", "category": "Sports"},
            {"name": "Gym & Fitness", "category": "Sports"},
            {"name": "Swimming", "category": "Sports"},
            {"name": "Tennis", "category": "Sports"},
            {"name": "Hiking", "category": "Sports"},
            # Tech & Career
            {"name": "Software Development", "category": "Tech"},
            {"name": "Design", "category": "Tech"},
            {"name": "Data Science", "category": "Tech"},
            {"name": "Startups", "category": "Tech"},
            {"name": "Business", "category": "Tech"},
            {"name": "Marketing", "category": "Tech"},
            {"name": "Finance", "category": "Tech"},
            # Arts & Creative
            {"name": "Music", "category": "Arts"},
            {"name": "Photography", "category": "Arts"},
            {"name": "Writing", "category": "Arts"},
            {"name": "Film & Movies", "category": "Arts"},
            {"name": "Art & Painting", "category": "Arts"},
            {"name": "Fashion", "category": "Arts"},
            # Lifestyle
            {"name": "Cooking", "category": "Lifestyle"},
            {"name": "Travel", "category": "Lifestyle"},
            {"name": "Reading", "category": "Lifestyle"},
            {"name": "Gaming", "category": "Lifestyle"},
            {"name": "Volunteering", "category": "Lifestyle"},
            {"name": "Coffee & Tea", "category": "Lifestyle"},
            # Learning
            {"name": "Languages", "category": "Learning"},
            {"name": "Personal Development", "category": "Learning"},
            {"name": "Public Speaking", "category": "Learning"},
            {"name": "Leadership", "category": "Learning"},
            # Social
            {"name": "Board Games", "category": "Social"},
            {"name": "Nightlife", "category": "Social"},
            {"name": "Food & Dining", "category": "Social"},
            {"name": "Community Events", "category": "Social"},
        ]

        for interest_data in interests:
            obj, created = InterestTag.objects.get_or_create(
                name=interest_data["name"],
                defaults={"category": interest_data["category"]},
            )
            status = "Created" if created else "Exists"
            self.stdout.write(f"  {status}: Interest '{obj.name}' ({obj.category})")

        self.stdout.write(
            self.style.SUCCESS(
                f"Done! {IntentTag.objects.count()} intents, {InterestTag.objects.count()} interests."
            )
        )
