# Nexa – Technical Specification (Flutter + Django)

This document describes the architecture, data model, and API for the Nexa app using a Flutter frontend and Django backend.

## 1. High-Level Architecture

- **Client:** Flutter mobile app (Android first, iOS later)
  - Handles UI, navigation, local state, and communication with the backend.
  - Stores JWT tokens securely for authenticated API calls.
- **Backend:** Django + Django REST Framework
  - Exposes RESTful API endpoints for auth, profiles, discovery, connections, and chat.
  - Optional: Django Channels for real-time chat (can be added later).
- **Database:** PostgreSQL
  - Stores users, profiles, preferences, connections, chat messages, and reports.

Data flow:

1. Flutter sends HTTPS requests with JWT auth headers to Django REST API.
2. Django validates the request, reads/writes to Postgres, and returns JSON responses.
3. For chat (if using WebSockets), Flutter connects to Django Channels endpoints.

## 2. Backend Structure (Django)

### 2.1 Django Apps

Recommended project layout:

- `accounts` – User model, registration, login, JWT integration.
- `profiles` – Profile, photos, interests, intents, preferences.
- `matching` – Discovery logic and endpoints.
- `connections` – Connection requests and state transitions.
- `chat` – Threads and messages (and WebSocket consumers if enabled).
- `moderation` – Reports, blocking, admin utilities.

### 2.2 Key Dependencies

- `Django`
- `djangorestframework`
- `djangorestframework-simplejwt` (or similar) for JWT auth
- `psycopg2` or `psycopg2-binary` for PostgreSQL
- `Pillow` or storage SDK (e.g., S3 client) for image uploads
- Optional: `django-channels` + Redis for real-time chat

## 3. Data Model (Conceptual)

Below is a conceptual schema; actual Django models will follow this structure.

### 3.1 Accounts & Profiles

- **User**
  - `id`
  - `email` (unique)
  - `password` (hashed)
  - `is_active`
  - `is_staff` / `is_superuser`
  - `date_joined`, `last_login`

- **Profile** (OneToOne with User)
  - `user`
  - `display_name`
  - `bio`
  - `pronouns`
  - `age_bucket` (enum e.g., `18_24`, `25_34`, `35_44`, `45_plus`)
  - `primary_language`
  - (Optional) `other_languages` (separate table if needed)
  - `faith` (enum: `CHRISTIAN`, `MUSLIM`, `TRADITIONAL`, `OTHER`, `PREFER_NOT_TO_SAY`, `NULL`)
  - `faith_visible` (bool, default `false`) — whether to show faith on profile

- **ProfilePhoto**
  - `id`
  - `user`
  - `image_url` (or storage path)
  - `ordering_index`

- **InterestTag**
  - `id`
  - `name` (e.g., "Hiking", "Design", "Gaming")

- **IntentTag**
  - `id`
  - `name` (e.g., "Friendship", "Networking")

### 3.2 Preferences & Matching

- **LocationPreference**
  - `user`
  - `latitude` (nullable)
  - `longitude` (nullable)
  - `city`
  - `country`
  - `radius_km` (int)
  - `share_precision` (enum: `CITY_ONLY`, `APPROX`, `NEARBY`)

- **MatchingPreference**
  - `user`
  - Many-to-many to `IntentTag`
  - Many-to-many to `InterestTag`
  - Preferred age buckets (e.g., JSON field or join table)
  - `available_mornings` (bool)
  - `available_afternoons` (bool)
  - `available_evenings` (bool)
  - `visible` (bool)
  - `faith_filter` (enum: `SAME_ONLY`, `OPEN_TO_ALL`, `CUSTOM`)
  - `faith_exclude` (JSON array, private — e.g., `["MUSLIM"]`) — never exposed to other users

### 3.3 Connections & Chat

- **Connection**
  - `id`
  - `from_user`
  - `to_user`
  - `status` (enum: `PENDING`, `ACCEPTED`, `REJECTED`, `BLOCKED`)
  - `created_at`, `updated_at`

- **ChatThread**
  - `id`
  - `user1`
  - `user2`
  - `created_at`

- **ChatMessage**
  - `id`
  - `thread`
  - `sender`
  - `content`
  - `sent_at`
  - `read_at` (nullable)

### 3.4 Moderation

- **Report**
  - `id`
  - `reporter`
  - `reported_user`
  - `reason` (text or enum)
  - `created_at`
  - `handled` (bool)
  - `handled_by` (admin user, nullable)
  - `note` (admin note, optional)

## 4. API Design (REST)

Base path: `/api/v1/`

### 4.1 Auth

- `POST /auth/register/`
  - Request: `{ "email", "password", "display_name" }`
  - Response: `{ "user": {...}, "message": "Verification email sent" }`
  - Sends email with verification link.

- `POST /auth/verify-email/`
  - Request: `{ "token": "<verification_token>" }`
  - Response: `{ "message": "Email verified" }`

- `POST /auth/login/`
  - Request: `{ "email", "password" }`
  - Response: `{ "access": "<jwt>", "refresh": "<jwt>", "user": {...} }`
  - Returns 403 if email not verified.

- `POST /auth/refresh/`
  - Request: `{ "refresh": "<token>" }`
  - Response: `{ "access": "<new_jwt>" }`

- `POST /auth/logout/`
  - Request: `{ "refresh": "<token>" }`
  - Blacklists the refresh token server-side.

- `POST /auth/password-reset/`
  - Request: `{ "email" }`
  - Response: `{ "message": "Reset email sent" }` (always 200 to avoid email enumeration).

- `POST /auth/password-reset/confirm/`
  - Request: `{ "token": "<reset_token>", "new_password" }`
  - Response: `{ "message": "Password updated" }`

### 4.2 Profile & Preferences

- `GET /me/`
  - Returns: user + profile + preferences bundled.

- `PUT /me/`
  - Update profile fields.

- `GET /me/photos/`, `POST /me/photos/`, `DELETE /me/photos/{id}/`
  - Manage profile photos.

- `GET /me/preferences/`
  - Returns: location and matching preferences.

- `PUT /me/preferences/`
  - Update location radius, visibility, intents, interests, availability, etc.

- `GET /tags/intents/`
- `GET /tags/interests/`
  - For populating client pickers.

### 4.3 Discovery & Matching

- `GET /discover/`
  - Query params:
    - `radius_km` (optional override)
    - `intent` (filter by intent name/key)
    - `interest` (filter by interest tag)
    - `faith` (filter: `same`, `all`, or omit to use preference)
    - `page` / `page_size`
  - Returns a paginated list of user summaries with:
    - `id`, `display_name`, `age_bucket`, `bio`
    - `intents`, `interests`
    - `faith` (only if user has set `faith_visible = true`, else `null`)
    - approximate `distance_km`
    - `mutual_interest_count`
    - `is_connection_pending`

### 4.4 Connections

- `GET /connections/`
  - List of user connections (accepted and pending).

- `POST /connections/`
  - Request: `to_user_id`.
  - Creates a pending connection.

- `PATCH /connections/{id}/`
  - Request: `{ "action": "accept" | "reject" | "block" }`.

### 4.5 Chat

- `GET /threads/`
  - List of chat threads for the current user.

- `GET /threads/{id}/messages/`
  - Paginated list of messages.

- `POST /threads/{id}/messages/`
  - Request: `content`.

If using WebSockets with Django Channels:

- WebSocket URL: `/ws/chat/{thread_id}/`
  - Auth via JWT in query/string header or subprotocol.

## 5. Matching Logic (Backend)

### 5.1 Filtering

Given a current user `U`:

1. Filter users by:
   - Other user's visibility = true.
   - Both users are active.
   - Distance between `U` and candidate <= both users' radius preferences (or at least `U`'s, for MVP).
   - Shared intents (intersection not empty).
   - Age bucket compatibility (if configured).
   - **Faith compatibility:**
     - If `U.faith_filter = SAME_ONLY`: candidate must have same `faith` value.
     - If `U.faith_filter = OPEN_TO_ALL`: no faith filtering.
     - If `U.faith_filter = CUSTOM`: exclude candidates in `U.faith_exclude` list.
     - Note: `faith_exclude` is **never exposed** to other users (privacy-sensitive).

### 5.2 Scoring (Simplified)

Define a score:

- `distance_score` – higher for closer distances.
- `shared_interest_score` – number of shared interest tags.
- `intent_score` – 1.0 if overlapping intents, 0 if not.
- `availability_score` – 1.0 if overlapping availability windows, else 0.
- `faith_match_score` – 1.0 if same faith (when user cares), 0.5 if open, 0 if excluded.

Example formula:

`score = w1 * distance_score + w2 * shared_interest_score + w3 * intent_score + w4 * availability_score + w5 * faith_match_score`

Return candidates ordered by `score` descending.

## 6. Flutter Client Overview

### 6.1 Architecture

- State management: Riverpod / Provider / Bloc (choose one and keep consistent).
- Networking: `dio` or `http` for REST calls.
- Secure storage: `flutter_secure_storage` for JWT tokens.
- Routing: `go_router` or similar.

### 6.2 Main Screens

- **Auth flow:**
  - Splash (check stored tokens, validate with backend).
  - Login / Register screens.

- **Main app (after login):**
  - Discover screen – list/cards of suggested users.
  - Connections screen – accepted + pending connections.
  - Chat screen – list of threads, message view.
  - Profile screen – profile details and preferences editor.

### 6.3 API Integration

- Use a central `ApiClient` class:
  - Attaches `Authorization: Bearer <token>` header on authenticated calls.
  - Handles token refresh when needed.

- Error handling:
  - Graceful messages for network errors and validation errors.

## 7. Security & Privacy

- **Passwords:**
  - Use Django's built-in password hashing.

- **Tokens:**
  - JWT access + refresh tokens; short-lived access token.
  - Store tokens securely in Flutter (e.g., `flutter_secure_storage`).

- **Transport:**
  - Enforce HTTPS for all communications.

- **Data minimization:**
  - Do not expose exact coordinates in responses; only distance and approximate area.

## 8. API Error Responses

All error responses follow a consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": { "field_name": ["error1", "error2"] }
  }
}
```

Common HTTP status codes:
- `200` – Success
- `201` – Created
- `400` – Bad request / validation error
- `401` – Unauthorized (missing or invalid token)
- `403` – Forbidden (e.g., email not verified, blocked user)
- `404` – Not found
- `429` – Rate limited
- `500` – Server error

## 9. Environment Variables (Backend)

Required environment variables for Django:

| Variable              | Description                          |
|-----------------------|--------------------------------------|
| `SECRET_KEY`          | Django secret key                    |
| `DEBUG`               | `True` for dev, `False` for prod     |
| `DATABASE_URL`        | PostgreSQL connection string         |
| `ALLOWED_HOSTS`       | Comma-separated allowed hostnames    |
| `CORS_ALLOWED_ORIGINS`| Frontend URLs allowed for CORS       |
| `EMAIL_HOST`          | SMTP server for sending emails       |
| `EMAIL_PORT`          | SMTP port                            |
| `EMAIL_HOST_USER`     | SMTP username                        |
| `EMAIL_HOST_PASSWORD` | SMTP password                        |
| `AWS_S3_BUCKET`       | (Optional) S3 bucket for photo uploads |

## 10. Deployment (High Level)

- **Backend:**
  - Containerized Django app (Docker) behind a reverse proxy (e.g., Nginx).
  - PostgreSQL managed service (e.g., AWS RDS, Supabase) or self-hosted.
  - Redis for caching and Channels (if real-time chat enabled).
  - CORS configured to allow Flutter app origins.

- **Mobile:**
  - Flutter app built and distributed via Play Store / TestFlight.
  - API base URL configurable per environment (dev, staging, prod).

## 11. Development Workflow

1. **Backend first:** Set up Django models, migrations, and core API endpoints.
2. **API testing:** Use Postman or Django REST Framework browsable API.
3. **Flutter integration:** Build screens that consume the API.
4. **Iterate:** Add features per roadmap phases.

This technical spec is the reference for implementing the Django backend and Flutter frontend. It should be kept in sync with any future API or data model changes.