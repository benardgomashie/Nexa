# Nexa – V1 Implementation Plan

This document outlines the phased development plan for Nexa MVP, targeting a Flutter frontend and Django backend.

---

## Overview

| Phase | Focus | Duration (Est.) | Outcome |
|-------|-------|-----------------|---------|
| 0 | Project Setup | 1 week | Scaffolding, dev environment, CI basics |
| 1 | Auth & Profiles | 2 weeks | Users can register, login, create profiles |
| 2 | Preferences & Discovery | 2 weeks | Users can set preferences and see matches |
| 3 | Connections | 1 week | Users can send/accept connection requests |
| 4 | Chat | 2 weeks | Connected users can message each other |
| 5 | Safety & Polish | 1–2 weeks | Block, report, moderation, bug fixes |
| 6 | Testing & Launch Prep | 1–2 weeks | QA, beta testing, Play Store submission |

**Total estimated time: 10–12 weeks** (for a solo dev or small team)

---

## Phase 0: Project Setup (Week 1) ✅ COMPLETE

### Backend (Django)
- [x] Create Django project with recommended app structure:
  - `config/` (settings, urls, wsgi)
  - `accounts/`
  - `profiles/`
  - `matching/`
  - `connections/`
  - `chat/`
  - `moderation/`
- [x] Configure PostgreSQL database connection (SQLite for dev)
- [x] Set up Django REST Framework
- [x] Set up JWT auth (`djangorestframework-simplejwt`)
- [x] Create base User model (email-based auth)
- [x] Set up environment variables (`.env`)
- [x] Create `requirements.txt`
- [x] Add basic health check endpoint (`GET /api/health/`)

### Frontend (Flutter)
- [ ] Create Flutter project
- [ ] Set up folder structure:
  - `lib/screens/`
  - `lib/models/`
  - `lib/services/`
  - `lib/widgets/`
  - `lib/providers/` (or `lib/blocs/`)
- [ ] Choose and configure state management (Riverpod recommended)
- [ ] Set up routing (`go_router`)
- [ ] Create `ApiClient` service with base URL config
- [ ] Set up secure storage for tokens (`flutter_secure_storage`)
- [ ] Create basic theme (colors, typography)

### DevOps
- [ ] Initialize Git repository
- [ ] Create `.gitignore` for Django + Flutter
- [ ] (Optional) Set up GitHub Actions for basic lint/test

**Milestone:** Both projects run locally; backend serves health check; Flutter app launches.

---

## Phase 1: Auth & Profiles (Weeks 2–3) ✅ COMPLETE

### Backend
- [x] Implement registration endpoint (`POST /api/v1/auth/register/`)
  - Email + password
  - Create User + empty Profile
  - Send verification email (use console backend for dev)
- [x] Implement email verification (`POST /api/v1/auth/verify-email/`)
- [x] Implement login (`POST /api/v1/auth/login/`)
- [x] Implement token refresh (`POST /api/v1/auth/token-refresh/`)
- [x] Implement logout with token blacklist (`POST /api/v1/auth/logout/`)
- [x] Implement password reset flow:
  - `POST /api/v1/auth/password-reset/`
  - `POST /api/v1/auth/password-reset/confirm/`
- [x] Create Profile model with fields:
  - `display_name`, `bio`, `pronouns`, `age_bucket`
  - `primary_language`, `faith`, `faith_visible`
- [x] Implement profile endpoints:
  - `GET /api/v1/me/`
  - `PUT /api/v1/me/`
- [x] Create ProfilePhoto model
- [x] Implement photo upload endpoints:
  - `GET /api/v1/me/photos/`
  - `POST /api/v1/me/photos/`
  - `DELETE /api/v1/me/photos/{id}/`
- [x] Create InterestTag and IntentTag models + seed data
- [x] Implement tag endpoints:
  - `GET /api/v1/tags/interests/`
  - `GET /api/v1/tags/intents/`

### Frontend
- [ ] Build Splash screen (check for existing token, validate)
- [ ] Build Login screen
- [ ] Build Register screen
- [ ] Build Email Verification info screen
- [ ] Implement auth service (register, login, logout, refresh)
- [ ] Implement token storage and auto-attach to API calls
- [ ] Build Profile Edit screen:
  - Display name, bio, pronouns, age bucket
  - Faith & values (with visibility toggle)
  - Interest tags picker
  - Intent tags picker
  - Photo upload (1–3 images)
- [ ] Build Profile View screen (own profile)

**Milestone:** Users can register, verify email, login, and complete their profile.

---

## Phase 2: Preferences & Discovery (Weeks 4–5) ✅ COMPLETE

### Backend
- [x] Create LocationPreference model
- [x] Create MatchingPreference model (intents, interests, age buckets, availability, faith filter)
- [x] Implement preferences endpoints:
  - `GET /api/v1/me/preferences/`
  - `PUT /api/v1/me/preferences/`
- [x] Implement discovery endpoint (`GET /api/v1/discover/`):
  - Filter by: distance, intent overlap, age bucket, faith compatibility, visibility
  - Sort by relevance score
  - Paginate results
  - Return: id, display_name, age_bucket, bio, intents, interests, faith (if visible), distance_km, mutual_interest_count
- [x] Add distance calculation (haversine formula)
- [x] Write unit tests for matching logic

### Frontend
- [ ] Build Preferences screen:
  - Location input (city picker or GPS)
  - Radius slider (5–50 km)
  - Intent selection
  - Interest tag selection
  - Age bucket preferences
  - Availability checkboxes (morning/afternoon/evening, weekday/weekend)
  - Faith filter (same only / open to all)
  - Visibility toggle
- [ ] Build Discover screen:
  - Card-based UI showing nearby users
  - Pull-to-refresh
  - Infinite scroll / pagination
  - Tap card to view profile detail
- [ ] Build User Profile Detail screen (other users)
- [ ] Implement location permission handling

**Milestone:** Users can set preferences and browse a feed of compatible people nearby.

---

## Phase 3: Connections (Week 6) ✅ COMPLETE

### Backend
- [x] Create Connection model (from_user, to_user, status)
- [x] Implement connection endpoints:
  - `GET /api/v1/connections/` (list: pending sent, pending received, accepted)
  - `POST /api/v1/connections/` (send request)
  - `PATCH /api/v1/connections/{id}/` (accept / reject / block)
- [x] Add connection status to discovery response
- [x] Prevent duplicate connection requests
- [x] Handle blocked users (hide from discovery, prevent messaging)

### Frontend
- [ ] Add "Connect" button to user profile detail screen
- [ ] Build Connections screen with tabs:
  - Received requests (accept / decline)
  - Sent requests (pending)
  - Accepted connections (list)
- [ ] Show connection status on Discover cards
- [ ] Add pull-to-refresh on Connections screen

**Milestone:** Users can send, accept, and manage connection requests.

---

## Phase 4: Chat (Weeks 7–8) ✅ COMPLETE

### Backend
- [x] Create ChatThread model (user1, user2)
- [x] Create ChatMessage model (thread, sender, content, sent_at, read_at)
- [x] Auto-create thread when connection accepted
- [x] Implement chat endpoints:
  - `GET /api/v1/chat/threads/` (list threads with last message preview, unread count)
  - `GET /api/v1/chat/threads/{id}/messages/` (paginated messages)
  - `POST /api/v1/chat/threads/{id}/messages/` (send message)
  - `POST /api/v1/chat/threads/{id}/read/` (mark messages as read)
- [ ] (Future) Add Django Channels for real-time WebSocket:
  - `/ws/chat/{thread_id}/`
  - Send/receive messages in real-time

### Frontend
- [ ] Build Chat List screen:
  - List of threads with other user's name, last message, timestamp
  - Unread indicator (badge or bold)
- [ ] Build Chat Detail screen:
  - Message bubbles (sent vs received)
  - Text input + send button
  - Scroll to bottom on new message
  - Load older messages on scroll up
- [ ] Implement polling for new messages (or WebSocket if backend supports)
- [ ] Navigate to chat from Connections screen

**Milestone:** Connected users can chat with each other.

---

## Phase 5: Safety & Polish (Weeks 9–10) ✅ BACKEND COMPLETE

### Backend
- [x] Create Report model (reporter, reported_user, reason, handled)
- [x] Implement report endpoint:
  - `POST /api/v1/moderation/reports/`
- [x] Expand block functionality:
  - Blocked user cannot see blocker in discovery
  - Blocked user cannot send connection request or message
- [x] Set up Django Admin for moderation:
  - View reports, mark handled, add notes
  - Deactivate/ban users
- [x] Add rate limiting on sensitive endpoints (register, login, report)
- [x] Review and harden security (CORS, HTTPS ready)

### Frontend
- [ ] Add Block button to user profile / chat
- [ ] Add Report button with reason picker:
  - Harassment
  - Spam
  - Religious harassment / disrespect
  - Hate speech
  - Inappropriate content
  - Fake profile
- [ ] Show confirmation after report submitted
- [ ] Handle blocked user states gracefully (hide from UI)
- [ ] UI polish:
  - Loading states
  - Error messages
  - Empty states (no matches, no connections, no messages)
  - Pull-to-refresh everywhere
- [ ] Accessibility pass (contrast, font sizes, screen reader labels)

**Milestone:** App is safe, stable, and ready for real users.

---

## Phase 6: Testing & Launch Prep (Weeks 11–12)

### Backend Testing ✅ COMPLETE
- [x] Backend unit tests (auth, matching logic, connections, chat) - **45 tests**
- [x] API integration tests
- [x] Test coverage documentation (TEST_SUMMARY.md)
- [x] All tests passing

### Frontend (Flutter) - 🔄 IN PROGRESS

**Current Status:** Backend MVP complete with 45 comprehensive tests. Ready to begin Flutter implementation.

### Launch Prep
- [ ] Set up production environment:
  - Deploy Django to cloud (Railway, Render, AWS, etc.)
  - Set up managed PostgreSQL
  - Configure production environment variables
  - Set up file storage for photos (S3 or similar)
  - Enable HTTPS
- [ ] Build release APK / App Bundle
- [ ] Create Play Store listing:
  - App name: Nexa
  - Short description: "Human connection, simplified."
  - Screenshots, feature graphic
  - Privacy policy URL
- [ ] Submit to Google Play for review
- [ ] (Optional) Prepare TestFlight build for iOS beta

**Milestone:** Nexa v1 is live on Google Play Store! 🚀

---

## Post-Launch (Ongoing)

- Monitor crash reports and analytics
- Respond to user feedback
- Plan Phase 2 features:
  - Push notifications
  - Group activities / events
  - Social login (Google, Apple)
  - iOS App Store release
  - Web companion

---

## Dependencies & Tools Summary

### Backend
| Tool | Purpose |
|------|---------|
| Django 5.x | Web framework |
| Django REST Framework | API layer |
| djangorestframework-simplejwt | JWT authentication |
| psycopg2-binary | PostgreSQL driver |
| Pillow | Image handling |
| python-decouple | Environment variables |
| django-cors-headers | CORS for mobile clients |

### Frontend
| Tool | Purpose |
|------|---------|
| Flutter 3.x | UI framework |
| Riverpod / Provider | State management |
| go_router | Navigation |
| dio | HTTP client |
| flutter_secure_storage | Secure token storage |
| image_picker | Photo selection |
| geolocator | Location services |

---

## Checklist View (Copy to Issue Tracker)

```
## Phase 0: Setup
- [ ] Django project scaffold
- [ ] Flutter project scaffold
- [ ] Git repo + .gitignore

## Phase 1: Auth & Profiles
- [ ] Registration + email verification
- [ ] Login / logout / refresh
- [ ] Password reset
- [ ] Profile CRUD
- [ ] Photo upload
- [ ] Tags endpoints

## Phase 2: Preferences & Discovery
- [ ] Preferences model + API
- [ ] Discovery endpoint with filtering
- [ ] Discover screen UI
- [ ] Location handling

## Phase 3: Connections
- [ ] Connection model + API
- [ ] Connections screen UI

## Phase 4: Chat
- [ ] Chat models + API
- [ ] Chat UI

## Phase 5: Safety & Polish
- [ ] Block + report
- [ ] Django admin moderation
- [ ] UI polish + error states

## Phase 6: Launch
- [ ] Testing
- [ ] Production deploy
- [ ] Play Store submission
```

---

This plan is a living document. Adjust timelines based on team size and availability.
