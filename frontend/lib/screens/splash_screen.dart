import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';

/// Splash screen that checks authentication status
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.favorite_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            
            // App name
            Text(
              'Nexa',
              style: AppTheme.headline1.copyWith(
                color: Colors.white,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Human connection, simplified.',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
