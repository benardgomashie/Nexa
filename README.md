# Nexa

**Human connection, simplified.**

> Version: 1.0.0-dev  
> Status: Documentation & Planning Phase

Nexa is a mobile-first app that helps people form meaningful, non-romantic connections based on location and user-controlled factors like interests, intent, and availability. It uses a Flutter frontend and a Django REST backend.

## Vision

Open your phone and see the right people around you, on your terms. Nexa focuses on friendship, collaboration, and community building rather than dating.

## Tech Stack

| Layer       | Technology                          |
|-------------|-------------------------------------|
| Frontend    | Flutter (Android first, iOS later)  |
| Backend     | Django 5.x + Django REST Framework  |
| Database    | PostgreSQL 15+                      |
| Auth        | JWT (djangorestframework-simplejwt) |
| Real-time   | Django Channels + Redis (Phase 2)   |

## High-Level Features

- User registration and authentication
- Rich user profiles (bio, age bucket, pronouns, interests, faith & values)
- User-controlled matching preferences (location radius, intent, interests, availability, faith)
- Discovery of nearby people based on preferences
- Connection requests and acceptance flow
- 1:1 chat between connected users
- Safety tools: block, report, basic moderation
- **Culturally intelligent**: Respects local values without forcing them

## Documentation

More detailed documents are in the `docs/` folder:

- `docs/product-spec.md` – Product vision, user stories, and feature breakdown
- `docs/technical-spec.md` – System architecture, data model, and API design
- `docs/implementation-plan.md` – **V1 roadmap with phases, tasks, and checklists**

These documents guide the implementation of the Flutter frontend and Django backend.

## Getting Started

> **Note:** Project scaffolding not yet created. See documentation above for planned structure.

Once scaffolded:

```bash
# Backend (Django)
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver

# Frontend (Flutter)
cd frontend
flutter pub get
flutter run
```

## Project Structure (Planned)

```
Nexa/
├── README.md
├── docs/
│   ├── product-spec.md
│   └── technical-spec.md
├── backend/               # Django project
│   ├── manage.py
│   ├── config/            # Django settings
│   ├── accounts/          # User auth
│   ├── profiles/          # User profiles
│   ├── matching/          # Discovery logic
│   ├── connections/       # Connection requests
│   ├── chat/              # Messaging
│   └── moderation/        # Reports, blocking
└── frontend/              # Flutter app
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   ├── models/
    │   ├── services/
    │   └── widgets/
    └── pubspec.yaml
```

## Contributing

This project is in early development. Contribution guidelines will be added once the initial scaffold is complete.

## License

TBD