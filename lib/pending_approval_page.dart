import 'package:flutter/material.dart';
import 'auth_service.dart'; // Adjust path if needed

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // Instantiate AuthService

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending Approval'),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.pending_actions, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Your account is currently under review.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'An administrator needs to approve your registration before you can access your dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'We will notify you by email once your account has been approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Log out the user and return to the main page
                await authService.signOut();
                if (context.mounted) {
                  // Use `pushNamedAndRemoveUntil()` to remove all previous routes and go to the main route
                  Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Go Back to Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Optionally provide a way to contact support
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please contact support@tutorfinder.com for assistance.')),
                );
              },
              child: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }
}
