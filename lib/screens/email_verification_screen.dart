import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  Future<void> _sendVerificationEmail(BuildContext context) async {
    final authService = context.read<AuthService>();
    authService.isSendingVerification = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if user signed in with Google (Google users are automatically verified)
        final isGoogleUser = user.providerData.any((provider) => provider.providerId == 'google.com');
        
        if (isGoogleUser) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google accounts are automatically verified. Please refresh to continue.')),
            );
          }
          return;
        }
        
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email is already verified!')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'Failed to send verification email';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please wait before requesting another verification email.';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled.';
              break;
            case 'user-not-found':
              errorMessage = 'User account not found.';
              break;
            default:
              errorMessage = 'Failed to send verification email: ${e.message}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (context.mounted) {
        authService.isSendingVerification = false;
      }
    }
  }

  Future<void> _checkEmailVerification(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if user signed in with Google (Google users are automatically verified)
      final isGoogleUser = user.providerData.any((provider) => provider.providerId == 'google.com');
      
      if (isGoogleUser) {
        // For Google users, mark as verified and continue
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google account verified successfully!')),
          );
          // The AuthWrapper will handle navigation
        }
        return;
      }
      
      await user.reload();
      if (user.emailVerified) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully!')),
          );
          // Don't navigate manually - let AuthWrapper handle it
          // The AuthWrapper will automatically redirect to dashboard
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1C1C23) : const Color(0xFFF4F5F7);
    final cardColor = isDarkMode ? const Color(0xFF2A2A35) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a verification email to your inbox. Please click the link in the email to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'your email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Didn\'t receive the email?',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authService.isSendingVerification ? null : () => _sendVerificationEmail(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: authService.isSendingVerification
                            ? const CircularProgressIndicator()
                            : const Text('Resend Verification Email'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _checkEmailVerification(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('I\'ve Verified My Email'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    // Don't navigate manually - let AuthWrapper handle it
                    // The AuthWrapper will automatically redirect to welcome screen
                  },
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
