import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // For Timer

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isEmailVerified = false;
  bool _canResendEmail = true; // To prevent rapid resending
  Timer? _timer; // Timer for periodic check
  int _countdownSeconds = 60; // Countdown for resend button
  bool _isResending = false; // Loading state for resend button

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      // Send verification email automatically when user lands on this page
      // but only if it hasn't been sent recently or if it's the first time.
      // We'll rely on the signup page to send the first one, this is for resend.
      // _sendVerificationEmail(); // Consider if you want to auto-resend here

      // Start a timer to periodically check email verification status
      _timer = Timer.periodic(
        const Duration(seconds: 3), // Check every 3 seconds
            (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Function to check if email is verified
  Future<void> checkEmailVerified() async {
    // Reload the user to get the latest email verification status
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      _timer?.cancel(); // Stop the timer if email is verified
      if (mounted) {
        // Navigate to the main authentication wrapper to determine the correct dashboard
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  // Function to send verification email
  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail || _isResending) return; // Prevent multiple clicks

    setState(() {
      _isResending = true;
      _canResendEmail = false; // Disable button immediately
      _countdownSeconds = 60; // Reset countdown
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent! Please check your inbox (and spam).')),
        );
      }
      // Start countdown for resend button
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _countdownSeconds--;
          });
          if (_countdownSeconds <= 0) {
            timer.cancel();
            setState(() {
              _canResendEmail = true;
              _isResending = false;
            });
          }
        } else {
          timer.cancel(); // Cancel if widget is unmounted
        }
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: ${e.message}')),
        );
      }
      print('Error sending verification email: ${e.code} - ${e.message}');
      setState(() {
        _canResendEmail = true; // Re-enable if error
        _isResending = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
      print('General Error sending verification email: $e');
      setState(() {
        _canResendEmail = true; // Re-enable if error
        _isResending = false;
      });
    }
  }

  // Function to log out the user
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate back to the main entry point, which will lead to WelcomePage
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 100,
                color: Colors.purple,
              ),
              const SizedBox(height: 30),
              const Text(
                'Verify Your Email Address',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'A verification email has been sent to ${FirebaseAuth.instance.currentUser?.email ?? 'your email address'}. Please check your inbox and spam folder.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isEmailVerified ? null : checkEmailVerified, // Disable if already verified
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('I have verified my email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _canResendEmail ? _sendVerificationEmail : null,
                icon: _isResending
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _canResendEmail
                      ? 'Resend Verification Email'
                      : 'Resend in $_countdownSeconds s',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}