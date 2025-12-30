import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _uidb64Controller = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;

  @override
  void dispose() {
    _uidb64Controller.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    try {
      final result = await ref.read(authProvider.notifier).verifyEmail(
        uidb64: _uidb64Controller.text.trim(),
        token: _tokenController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Redirecting to login...'),
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Navigate to login
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/auth/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Verification failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Check Your Email',
                  style: AppTheme.headline1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  'We\'ve sent a verification email. Check your email or enter the verification code below.',
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Development mode notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.developer_mode,
                            color: AppTheme.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Development Mode',
                            style: AppTheme.headline3.copyWith(
                              color: AppTheme.warning,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check the terminal/console for the verification email with uidb64 and token values.',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // uidb64 field
                TextFormField(
                  controller: _uidb64Controller,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'uidb64',
                    hintText: 'e.g., MQ',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter uidb64';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Token field
                TextFormField(
                  controller: _tokenController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleVerify(),
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    hintText: 'e.g., d1mf2q-05cbec8469...',
                    prefixIcon: Icon(Icons.password),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter token';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Verify button
                ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify Email'),
                ),
                const SizedBox(height: 16),
                
                // Back to login
                TextButton(
                  onPressed: () => context.go('/auth/login'),
                  child: const Text('Already verified? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
