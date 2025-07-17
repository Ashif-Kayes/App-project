import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore correctly
import 'auth_service.dart'; // Import your AuthService

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the user is an admin
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch the user's profile from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;

          // Check if the user is an admin
          if (userData['userType'] == 'admin' && userData['isApproved'] == true) {
            // Admin is verified and approved
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            // Redirect to the appropriate page (e.g., student dashboard) if the user is not an admin
            Navigator.pushReplacementNamed(context, '/student_dashboard');
          }
        } else {
          throw Exception('User profile not found');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Login error: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      print('Firebase Auth Error (Admin Login): ${e.code} - ${e.message}');
    } on EmailNotVerifiedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email address first.')),
        );
        Navigator.pushReplacementNamed(context, '/verify_email');
      }
    } on AccountNotApprovedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account is pending admin approval.')),
        );
        Navigator.pushReplacementNamed(context, '/pending_approval');
      }
    } on UserProfileNotFoundException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found. Please contact support.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      }
      print('General Error (Admin Login): $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _loginAdmin,
                child: const Text('Login as Admin'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/admin_signup'),
                child: const Text('Don\'t have an admin account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
