# Nexa – Product Specification (v1)

Human connection, simplified.

## 1. Problem & Vision

Most apps that connect people are optimized for dating or professional networking only. Nexa focuses on broader, non-romantic human connection: friends, collaborators, mentors, and activity partners. Users maintain control over how they are matched and who can see them.

**Vision:** Help people discover nearby, aligned humans for meaningful connection, with clear control over location, interests, intent, and boundaries.

## 2. Target Users

- People new to a city who want to meet friends.
- Makers, students, and professionals seeking collaborators or accountability partners.
- People who want to share hobbies (sports, gaming, co-learning, etc.).

## 3. Key Use Cases

- Discover people nearby who share interests and intent (e.g., coworking, learning, sports).
- Set how far you are willing to travel and when you are usually available.
- Request to connect and, upon mutual interest, chat to plan a meetup.
- Control visibility and block/report bad actors.

## 4. User Roles

- **User**
  - Create and manage profile.
  - Configure matching preferences.
  - Browse discovery feed.
  - Send and respond to connection requests.
  - Chat with accepted connections.
  - Block and report users.

- **Admin** (via internal tools)
  - Review reports and take action (warn, block, disable accounts).
  - View high-level metrics (user counts, active connections, reports).

## 5. Core Features (MVP)

### 5.1 Onboarding & Auth

- Sign up with email + password.
- Email verification (send confirmation link; user must verify before full access).
- Log in and log out securely.
- Password reset via email link.
- Store session with tokens on device (handled by Flutter client).

### 5.2 Profile

- Basic info: display name, short bio, pronouns.
- Age expressed as a bucket (e.g., 18–24, 25–34) rather than exact age.
- Languages: primary language + optional secondary languages.
- Interest tags: hobbies, skills, topics.
- Intent tags: friendship, networking, skill exchange, group activities.
- **Faith & Values** (optional):
  - Options: Christian, Muslim, Traditional/Spiritual, Other, Prefer not to say.
  - Default: **Hidden** — users choose whether to display or use as filter.
  - UI label: "Faith & Values" (softer, more inclusive than "Religion").
- Profile photos (1–3 images).

### 5.3 Preferences & Boundaries

- Location preference:
  - City/country or approximate coordinates.
  - Adjustable radius (e.g., 5–50 km).
  - Control over how precise location appears to others (city-level vs approximate).
- Matching preference:
  - Select which intents you are open to.
  - Choose interest tags that should matter most.
  - Configure preferred age buckets you want to connect with.
  - Availability windows: mornings / afternoons / evenings, weekdays vs weekends.
- **Faith & Values filter** (optional):
  - Same faith only.
  - Open to all faiths.
  - Exclude certain faiths (private — never shown to others).
  - This filter is **powerful combined with intent** (e.g., Friendship + Christian, Networking + Any faith).
- Visibility:
  - Toggle profile visibility on/off.
  - Optionally limit visibility to compatible-intent users.

### 5.4 Discovery & Matching

- Discovery feed of nearby users that satisfy mutual filters.
- Sort by relevance: distance, shared interests, shared intent, overlapping availability.
- Basic card design per user with name, age bucket, short bio, intents, interests, distance.
- Pagination / infinite scrolling.

### 5.5 Connections

- Send a connection request to a user from the discovery feed or profile.
- Pending connection states:
  - Sent (outgoing pending requests).
  - Received (incoming requests waiting for action).
- Receiver can accept or decline.
- Accepted connections appear in a "Connections" list.

### 5.6 Chat

- One-to-one chat threads between connected users.
- Message list with timestamps.
- Unread indicator per thread.
- Optional: typing indicator and online/offline status (can be added later).

### 5.7 Safety & Moderation

- Users can block others:
  - Blocked users cannot send new messages or connection requests.
- Users can report others with a reason:
  - Harassment
  - Spam
  - **Religious harassment / disrespect**
  - **Hate speech**
  - Inappropriate content
  - Fake profile
- **Community guidelines prohibit:**
  - Religious preaching or forced conversion attempts in chat.
  - Attacking or mocking others' beliefs.
  - Discriminatory language.
- Admin can:
  - See reports in an internal dashboard (Django admin).
  - Mark reports as handled and optionally add a note.
  - Deactivate or ban users as needed.

## 6. Non-Functional Requirements

- **Privacy-first**: Only store data necessary for the product. Never expose exact home addresses.
- **Performance**: Reasonable load times on mobile networks, API responses under ~300ms for typical queries.
- **Scalability**: Start small but keep backend stateless and ready to scale horizontally.
- **Security**: Strong password hashing, JWT-based auth, and basic rate limiting.

## 7. Success Metrics (Early)

- Number of verified profiles created.
- Ratio of users who send or accept at least one connection.
- Number of active chat threads.
- Reports per 1000 users (aim to minimize while maintaining safety).

## 8. Out of Scope (for initial MVP)

- Group chats and events.
- Matching algorithms based on ML / recommendations.
- OAuth social login (Google, Apple, etc.).
- Push notifications.
- In-app purchases or premium tiers.
- Detailed analytics dashboards.
- Web client.
- Image moderation (automated).
- Video/voice chat.

## 9. Cultural Context & Positioning (Ghana 🇬🇭)

Nexa is designed to be **culturally intelligent**, not a copy of Western apps.

### Why Faith Matters

- Religion is a major social reality in Ghana (Christian, Muslim, Traditional).
- Many people will not connect socially or romantically across faiths.
- Others are open — Nexa respects **both** choices.

### How Nexa Builds Trust

- Doesn't feel like a "hookup app."
- Respects church & mosque culture.
- Parents, pastors, and community leaders can endorse it.
- Youth groups and faith communities can recommend it.

### Public Messaging (Careful Wording)

❌ Don't say: "Faith-based matching app"

✅ Do say: "Connect with people who share your values — or discover new perspectives. You choose."

Subtle. Inclusive. Safe.

---

## 10. Future Considerations (Post-MVP)

- **Group activities:** Create or join local events/meetups.
- **Social login:** Sign in with Google, Apple, etc.
- **Push notifications:** Alerts for new connections, messages.
- **Premium features:** Expanded radius, advanced filters, read receipts.
- **ML-based matching:** Learn from user behavior to improve suggestions.
- **Web companion:** View messages and profile on desktop.
- **Expanded faith options:** More granular denominations if user demand exists.
- Detailed analytics dashboards.
- Web client.

This document is product-facing and serves as a guide for prioritizing features. Technical implementation details for Flutter and Django are described in `technical-spec.md`.