# Frontend Architecture Update

## ✅ Completed Migration

The Nexa frontend has been updated with a modern, production-ready architecture:

### Architecture Overview

**State Management**: Riverpod 2.6.1
- `authProvider` - Manages authentication state (user, profile, login, logout)
- `selectedIndexProvider` - Bottom navigation state
- Service providers for dependency injection

**Routing**: go_router 14.8.1
- Auth guards with automatic redirects
- Route protection based on authentication state
- Splash → Login/Register → Email Verification → Home flow

**HTTP Client**: Dio 5.9.0
- Automatic JWT token attachment
- Auto-refresh on 401 Unauthorized
- Secure token storage with flutter_secure_storage

### File Structure

```
lib/
├── config/
│   ├── app_config.dart        # API URLs, constants, settings
│   ├── theme.dart             # Design system & branding
│   └── router.dart            # go_router configuration
├── models/
│   ├── user.dart              # User model (matches backend)
│   ├── profile.dart           # Profile + ProfilePhoto
│   ├── connection.dart        # Connection status tracking
│   ├── chat.dart              # ChatThread + ChatMessage
│   ├── preferences.dart       # Matching & Location preferences
│   └── discover.dart          # Discovery API responses
├── services/
│   ├── api_client.dart        # Dio HTTP client with auth
│   └── auth_service.dart      # Auth API calls
├── providers/
│   ├── service_providers.dart # API & auth service providers
│   └── auth_provider.dart     # Auth state management
├── screens/
│   ├── splash_screen.dart     # Auth status check
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── email_verification_screen.dart
│   └── home_screen.dart       # Main app with bottom nav
└── main.dart                  # App entry with ProviderScope
```

### Key Features

**Authentication Flow**:
1. Splash screen checks auth state
2. Redirects to login if not authenticated
3. Register → Email verification → Login
4. JWT tokens stored securely
5. Auto-refresh on expiration
6. Logout clears all tokens

**Data Models**:
- All models match backend JSON schema exactly
- Full JSON serialization (fromJson/toJson)
- Helper methods (e.g., `isComplete`, `isPending`)
- Type-safe with nullable fields

**Theme System**:
- Nexa brand colors (purple #6C63FF, pink #FF6584)
- 6 text styles (headline1-3, body large/medium, caption)
- Material 3 theming for buttons, cards, inputs
- Consistent spacing and styling

**Home Screen**:
- Bottom navigation with 4 tabs
- Discover: Main feed (placeholder)
- Connections: Match requests (placeholder)
- Chats: Message threads (placeholder)
- Profile: User info, settings, logout

### Backend Integration

All models align with backend API responses:
- `User` → `accounts.User`
- `Profile` → `profiles.Profile`
- `Connection` → `connections.Connection`
- `ChatThread/ChatMessage` → `chat` models
- `MatchingPreference` → `profiles` preferences
- `DiscoveryProfile` → `matching.discover` response

API Base URL: `http://localhost:8000/api/v1`

### Running the App

1. Ensure backend is running on port 8000
2. Navigate to frontend directory:
   ```bash
   cd frontend
   ```
3. Install dependencies (if not already done):
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Next Steps

**Priority 1 - Complete Auth Flow**:
- [ ] Implement password reset screens
- [ ] Add email verification resend functionality
- [ ] Handle email verification callback

**Priority 2 - Profile Management**:
- [ ] Create ProfileEditScreen with photo upload
- [ ] Build PreferencesScreen for matching settings
- [ ] Add tag selection UI

**Priority 3 - Discovery**:
- [ ] Implement swipe UI for discovery
- [ ] Connect to `/matching/discover/` endpoint
- [ ] Add like/pass actions

**Priority 4 - Connections**:
- [ ] Create ConnectionsScreen with tabs
- [ ] Show received/sent/accepted connections
- [ ] Add accept/reject actions

**Priority 5 - Chat**:
- [ ] Build ChatListScreen with threads
- [ ] Create ChatDetailScreen with messages
- [ ] Implement real-time polling or WebSocket
- [ ] Add send message functionality

**Priority 6 - Safety**:
- [ ] Add block/report UI
- [ ] Create reason picker dialogs
- [ ] Integrate with moderation endpoints

### Migration Notes

**Replaced**:
- `flutter_login` → Custom auth screens
- `swipe_cards` → Will use custom swipe UI
- `http` package → Dio with interceptors
- Manual storage → flutter_secure_storage

**Dependencies Added**:
- flutter_riverpod: State management
- go_router: Routing with guards
- dio: HTTP client
- flutter_secure_storage: Secure JWT storage

**Breaking Changes**:
- Old `User` model replaced with backend-aligned model
- Old `api_service.dart` replaced with `api_client.dart`
- Navigation now uses go_router paths instead of Navigator
- All screens need to be ConsumerWidget for Riverpod

### Testing

To test the current implementation:

1. Start the backend server
2. Run the Flutter app
3. Register a new account
4. Check email for verification link (or check Django admin)
5. Verify the email
6. Login with credentials
7. Navigate between tabs in the home screen
8. Test logout functionality

The app should properly handle:
- Loading states during API calls
- Error messages for failed operations
- Token refresh on API errors
- Automatic redirect based on auth state

---

**Status**: Architecture complete, ready for feature implementation
**Last Updated**: January 2025
