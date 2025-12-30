# Nexa

**Human connection, simplified.**

> Version: 1.0.0-mvp  
> Status: MVP Complete - Testing Phase

Nexa is a mobile-first app that helps people form meaningful connections based on location and user-controlled factors like interests, intent, and availability. It uses a Flutter frontend and a Django REST backend.

## Vision

Open your phone and see the right people around you, on your terms. Nexa focuses on friendship, collaboration, community building, and dating - letting users define their intent.

## Tech Stack

| Layer       | Technology                          |
|-------------|-------------------------------------|
| Frontend    | Flutter 3.29.3 (Android/iOS)        |
| Backend     | Django 5.2.4 + Django REST Framework|
| Database    | SQLite (dev) / PostgreSQL (prod)    |
| Auth        | JWT (djangorestframework-simplejwt) |
| State Mgmt  | Riverpod                            |
| Navigation  | GoRouter                            |

## Features

### ✅ Implemented (MVP)

- **Authentication**
  - Email/password registration with verification
  - JWT token-based authentication
  - Secure token storage

- **User Profiles**
  - Photo upload with ordering
  - Display name, bio, pronouns
  - Age bucket, faith preferences
  - Intent tags (Friendship, Dating, Networking, etc.)
  - Interest tags (Music, Sports, Travel, etc.)

- **Discovery**
  - Swipeable card interface
  - Filter by intent, interests, age, faith
  - Pass/Connect actions

- **Connections**
  - Send connection requests
  - Accept/reject incoming requests
  - View sent/received/accepted connections

- **Chat**
  - 1:1 messaging between connected users
  - Message threads list
  - Real-time message display

- **Safety**
  - Block users
  - Report users with reason categories
  - View and unblock blocked users

## Getting Started

### Prerequisites

- Python 3.11+
- Flutter 3.29+
- Android Studio / Xcode (for mobile development)

### Backend Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # macOS/Linux

pip install -r requirements.txt
python manage.py migrate
python manage.py seed_tags  # Seed intent/interest tags
python manage.py runserver 0.0.0.0:8000
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

### Testing on Physical Device

```bash
# Enable ADB port forwarding for API access
adb reverse tcp:8000 tcp:8000

# Run on connected device
flutter run -d <device_id>
```

## Project Structure

```
Nexa/
├── README.md
├── docs/
│   ├── product-spec.md
│   ├── technical-spec.md
│   └── implementation-plan.md
├── backend/
│   ├── manage.py
│   ├── config/            # Django settings & URLs
│   ├── accounts/          # User auth & registration
│   ├── profiles/          # User profiles & discovery
│   ├── connections/       # Connection requests
│   ├── chat/              # Messaging
│   └── moderation/        # Reports & blocking
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── config/        # Theme, router, app config
    │   ├── models/        # Data models
    │   ├── providers/     # Riverpod state management
    │   ├── screens/       # UI screens
    │   ├── services/      # API services
    │   └── widgets/       # Reusable components
    └── pubspec.yaml
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register/` - Register new user
- `POST /api/v1/auth/login/` - Login
- `POST /api/v1/auth/verify-email/` - Verify email
- `POST /api/v1/auth/token/refresh/` - Refresh JWT token

### Profiles
- `GET/PATCH /api/v1/me/` - Current user profile
- `GET/POST /api/v1/me/photos/` - Profile photos
- `GET/PATCH /api/v1/me/preferences/` - Matching preferences
- `GET /api/v1/discover/` - Discover profiles

### Connections
- `POST /api/v1/connections/` - Send connection request
- `GET /api/v1/connections/sent/` - Sent requests
- `GET /api/v1/connections/received/` - Received requests
- `POST /api/v1/connections/{id}/accept/` - Accept request
- `POST /api/v1/connections/{id}/reject/` - Reject request

### Chat
- `GET /api/v1/chat/threads/` - Message threads
- `GET/POST /api/v1/chat/threads/{id}/messages/` - Thread messages

### Safety
- `POST /api/v1/connections/{id}/block/` - Block user
- `POST /api/v1/reports/` - Report user

## Environment Configuration

### Frontend (lib/config/app_config.dart)
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

### Backend (config/settings.py)
```python
ALLOWED_HOSTS = ['*']  # Configure for production
CORS_ALLOW_ALL_ORIGINS = True  # Configure for production
```

## Roadmap

- [x] MVP Features
- [ ] Real-time chat with WebSockets
- [ ] Push notifications
- [ ] Profile verification
- [ ] Advanced matching algorithm
- [ ] Group activities/events
- [ ] iOS App Store release
- [ ] Android Play Store release

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details
