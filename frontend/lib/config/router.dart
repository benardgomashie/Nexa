import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import '../screens/settings/discovery_settings_screen.dart';

/// Router configuration with authentication guards
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      
      print('[ROUTER] Redirect check - path: ${state.matchedLocation}');
      print('[ROUTER] isLoading: $isLoading, isAuthenticated: $isAuthenticated');
      
      // Show splash while checking auth
      if (isLoading) {
        print('[ROUTER] Still loading, staying on splash');
        return '/';
      }
      
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/';
      
      // Redirect authenticated users from splash to home
      if (isAuthenticated && isSplash) {
        print('[ROUTER] Authenticated user on splash, redirecting to /home');
        return '/home';
      }
      
      // Redirect to login if not authenticated and on splash (after loading completes)
      if (!isAuthenticated && isSplash) {
        print('[ROUTER] Not authenticated and on splash, redirecting to /auth/login');
        return '/auth/login';
      }
      
      // Redirect to home if authenticated and trying to access auth routes
      if (isAuthenticated && isAuthRoute) {
        print('[ROUTER] Authenticated user on auth route, redirecting to /home');
        return '/home';
      }
      
      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthRoute && !isSplash) {
        print('[ROUTER] Unauthenticated user on protected route, redirecting to /auth/login');
        return '/auth/login';
      }
      
      print('[ROUTER] No redirect needed');
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (context, state) {
          final threadId = int.parse(state.pathParameters['threadId']!);
          return ChatDetailScreen(threadId: threadId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/settings/discovery',
        builder: (context, state) => const DiscoverySettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
