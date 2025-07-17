import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // Corrected import path

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isSending = false;
  bool _isChecking = false;
  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  void initState() {
    super.initState();
    _sendVerificationEmailOnLoad(); // Automatically send email when page loads
  }

  Future<void> _sendVerificationEmailOnLoad() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await _sendVerificationEmail();
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent! Please check your inbox/spam.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: ${e.message}')),
      );
      print('Error sending verification email: ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
      print('General error sending verification email: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Reload the user to get the latest email verification status
      await _authService.reloadUser();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        // If email is verified, navigate to AuthWrapper to re-evaluate state
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully! Redirecting...')),
        );
        if (mounted) {
          // PushReplacementNamed to root will trigger AuthWrapper to re-evaluate
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is still not verified. Check your inbox.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking verification: ${e.toString()}')),
      );
      print('Error checking email verification: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.email_outlined, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            Text(
              'A verification email has been sent to ${user?.email ?? 'your email address'}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please check your inbox (and spam folder) and click the link to verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendVerificationEmail,
              icon: _isSending
                  ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Resend Email'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isChecking ? null : _checkEmailVerified,
              icon: _isChecking
                  ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(_isChecking ? 'Checking...' : 'I\'ve Verified My Email'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                await _authService.signOut(); // Log out if user wants to start over
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/main_page'); // Go back to main page
                }
              },
              child: const Text('Go Back to Login/Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}