import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // Import your AuthService

class TutorLoginPage extends StatefulWidget {
  const TutorLoginPage({super.key});

  @override
  State<TutorLoginPage> createState() => _TutorLoginPageState();
}

class _TutorLoginPageState extends State<TutorLoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  final AuthService _authService = AuthService(); // Instantiate AuthService

  // Animation for the loading indicator (fade)
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingFadeAnimation;

  // Animation for the "Access your tutor account" text (slide from left)
  late AnimationController _textSlideAnimationController; // Correct variable name
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize loading animation
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_loadingAnimationController);

    // Initialize text slide animation
    _textSlideAnimationController = AnimationController( // Correct variable name
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Adjust duration for desired speed
    );
    // Start from off-screen left (-1.0 means 100% of the widget's width to the left)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero, // End at its original position
    ).animate(CurvedAnimation(
      parent: _textSlideAnimationController, // Correct variable name
      curve: Curves.easeOutCubic, // A smooth easing curve
    ));

    // Start the text slide animation when the page loads
    _textSlideAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loadingAnimationController.dispose(); // Dispose loading animation controller
    _textSlideAnimationController.dispose(); // CORRECTED: Dispose text slide animation controller
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });
    _loadingAnimationController.forward(); // Start fade-in animation for loading indicator

    try {
      // Use the AuthService for login, which now includes email verification and approval checks
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // After successful login, check email verification and route accordingly
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;

        // Check if the tutor's email is verified
        if (user != null && user.emailVerified) {
          Navigator.pushReplacementNamed(context, '/tutor_dashboard'); // Go to Tutor Dashboard
        } else {
          Navigator.pushReplacementNamed(context, '/verify_email'); // Go to email verification page
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor login successful! Redirecting...')),
      );

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password. Please check your credentials.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many login attempts. Please try again later.';
      } else if (e.code == 'email-not-verified') {
        message = 'Please verify your email address to log in.';
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/verify_email');
          return; // Exit function after navigation
        }
      } else if (e.code == 'account-not-approved') {
        message = 'Your account is pending admin approval.';
      } else {
        message = 'An authentication error occurred: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      print('Firebase Auth Error (Tutor Login): ${e.code} - ${e.message}'); // Log error for debugging
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      }
      print('General Error (Tutor Login): $e'); // Log error for debugging
    } finally {
      if (mounted) {
        _loadingAnimationController.reverse(); // Start fade-out animation for loading indicator
        setState(() {
          _isLoading = false; // Hide loading indicator regardless of success or failure
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password.')),
      );
      return;
    }
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    _loadingAnimationController.forward(); // Start fade-in animation for loading indicator

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email! Check your inbox/spam folder.')),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No tutor found for that email address.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Error sending reset email: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      print('Password Reset Error (Tutor): ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
      print('Password Reset General Error (Tutor): $e');
    } finally {
      _loadingAnimationController.reverse(); // Start fade-out animation for loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        // Gradient background with new colors from Screenshot (466).png
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC100C0), Color(0xFFFFAF86)], // New gradient: Deep Pink/Purple to Light Orange/Peach
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your Logo (graduation_cap_logo.png)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20), // Spacing below the logo
                    child: Image.asset(
                      'assets/images/graduation_cap_logo.png', // Ensure this path is correct
                      height: 100, // Adjust the height as needed
                      // If your logo is a single color and you want to tint it (e.g., white for better contrast):
                      // color: Colors.white,
                      // colorBlendMode: BlendMode.srcIn,
                    ),
                  ),

                  // Animated "Access your tutor account" text
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 40), // Spacing between text and email field
                      child: Text(
                        'Access your tutor account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.05, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text color for contrast with the new gradient
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Email Input Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3), // Slightly transparent white fill
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3), // Slightly transparent white fill
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your password' : null,
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    width: double.infinity, // Make button full width
                    height: 55, // Fixed height for consistency
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Button background
                        foregroundColor: const Color(0xFFC100C0), // Text color (matches darker new gradient start)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8, // Add shadow
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? FadeTransition(
                        opacity: _loadingFadeAnimation,
                        child: const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC100C0)), // Matches button text
                          ),
                        ),
                      )
                          : const Text(
                        'Login as Tutor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Forgot Password Button
                  TextButton(
                    onPressed: _isLoading ? null : _sendPasswordResetEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sign Up Button
                  TextButton(
                    onPressed: () {
                      if (!_isLoading) {
                        Navigator.pushNamed(context, '/tutor_signup');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}