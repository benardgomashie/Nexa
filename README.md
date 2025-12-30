# Nexa

**Human connection, simplified.**

> Version: 1.0.0-beta  
> Status: v1 Core - 85% Complete

Nexa is a mobile-first app that helps people **meet people near them**, safely and intentionally. It uses a Flutter frontend and a Django REST backend.

## Vision

Open your phone and see the right people around you, on your terms. Nexa focuses on intentional connections — friendship, dating, networking, and activity partners — with user-controlled matching and cultural awareness.

## Tech Stack

| Layer       | Technology                          |
|-------------|-------------------------------------|
| Frontend    | Flutter 3.29.3 (Android/iOS)        |
| Backend     | Django 5.2.4 + Django REST Framework|
| Database    | SQLite (dev) / PostgreSQL (prod)    |
| Auth        | JWT (djangorestframework-simplejwt) |
| State Mgmt  | Riverpod                            |
| Navigation  | GoRouter                            |

---

## Nexa v1 Features (Core Product)

### ✅ Implemented

**Account & Identity**
- Email/password registration with verification
- JWT token-based authentication
- Profile: Name, photos (1-3), age bucket, bio, pronouns

**Intent Selection**
- Friendship, Dating, Networking, Activity Partner
- Visible on profile, filterable in discovery

**Faith & Values (Ghana-Aware)**
- Optional: Christian, Muslim, Traditional, Other, Prefer not to say
- Visibility control (hidden by default)
- Can be used as private filter

**Discovery**
- Swipeable card interface
- Distance-based sorting
- Filter by intent, interests, age, faith
- Pass/Connect actions

**Connections (Consent-First)**
- Send connection requests
- Mutual acceptance required
- View sent/received/accepted connections

**1-to-1 Chat**
- Text messaging between connections
- Read receipts
- Message threads

**Safety & Trust**
- Block users
- Report users (7 categories including religious harassment)
- Blocked users management

### 🔴 In Progress (v1 Gaps)

| Feature | Priority | Status |
|---------|----------|--------|
| Location radius control (1km/3km/5km/10km) | High | Not built |
| Pause visibility | High | Backend ready, UI needed |
| Delete account | High | Not built |
| Phone signup + OTP | Medium | Not built |
| Gender field | Medium | Not built |
| Dedicated filter UI | Medium | Not built |
| Password reset UI | Medium | Backend ready |

### ❌ NOT in v1

- Group events
- Feeds/Stories
- Public posts
- Payments
- AI matching

---

## Nexa v1.5 Features (Future)

> **After v1 is stable**: Help users do things with people they already trust.

- **Activities/Plans**: Home hangouts, football matches, study groups
- **Activity Creation**: Title, date, location, max people, filters
- **Join Flow**: Request → Host approval → Location shared
- **Activity Safety**: Max limits, leave anytime, report

---

## Getting Started

### Prerequisites

- Python 3.11+
- Flutter 3.29+
- Android Studio / Xcode

### Backend Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # macOS/Linux

pip install -r requirements.txt
python manage.py migrate
python manage.py seed_tags
python manage.py runserver 0.0.0.0:8000
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

### Physical Device Testing

```bash
# Enable ADB port forwarding
adb reverse tcp:8000 tcp:8000

# Run on device
flutter run -d <device_id>
```

---

## Project Structure

```
Nexa/
├── README.md
├── IMPLEMENTATION_STATUS.md    # Detailed feature tracking
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

---

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

---

## Roadmap

### v1 (Current)
- [x] Email authentication
- [x] User profiles with photos
- [x] Intent & interest tags
- [x] Discovery with filtering
- [x] Connection requests
- [x] 1-to-1 chat
- [x] Block & report
- [ ] Location radius control
- [ ] Pause/delete account
- [ ] Phone signup

### v1.5 (Future)
- [ ] Activities/Plans system
- [ ] Activity creation & filters
- [ ] Join flow with approval
- [ ] Activity safety features

### v2 (Future)
- [ ] Real-time chat (WebSocket)
- [ ] Push notifications
- [ ] Circles (recurring groups)
- [ ] Profile verification

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

MIT License - see LICENSE file for details
