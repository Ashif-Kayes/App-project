// File: lib/student_signup_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentSignUpPage extends StatefulWidget {
  const StudentSignUpPage({super.key});

  @override
  State<StudentSignUpPage> createState() => _StudentSignUpPageState();
}

class _StudentSignUpPageState extends State<StudentSignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _currentClassController = TextEditingController();
  final TextEditingController _studentWhatsappController = TextEditingController();
  final TextEditingController _parentsWhatsappController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _topTextAnimationController;
  late Animation<Offset> _topTextAnimation;

  late AnimationController _bottomTextAnimationController;
  late Animation<Offset> _bottomTextAnimation;

  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_loadingAnimationController);

    _topTextAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _topTextAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _topTextAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _bottomTextAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bottomTextAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bottomTextAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _topTextAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _bottomTextAnimationController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _currentClassController.dispose();
    _studentWhatsappController.dispose();
    _parentsWhatsappController.dispose();
    _topTextAnimationController.dispose();
    _bottomTextAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signUpStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _loadingAnimationController.forward();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User was not created by Firebase Auth.');
      }

      String uid = user.uid;
      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('user_profiles').doc(uid).set({
        'userId': uid,
        'userType': 'student',
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('students').doc(uid).set({
        'name': _nameController.text.trim(),
        'institution': _institutionController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'currentClass': _currentClassController.text.trim(),
        'studentWhatsapp': _studentWhatsappController.text.trim(),
        'parentsWhatsapp': _parentsWhatsappController.text.trim(),
        'registeredAt': FieldValue.serverTimestamp(),
        'isApproved': false,
        'isEmailVerified': user.emailVerified,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please verify your email and wait for admin approval.')),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verify_email');
      }

    } on FirebaseAuthException catch (e) {
      String message = 'An authentication error occurred: ${e.message}';
      if (e.code == 'weak-password') message = 'The password provided is too weak.';
      else if (e.code == 'email-already-in-use') message = 'The account already exists for that email.';
      else if (e.code == 'invalid-email') message = 'The email address is not valid.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      print('Firebase Auth Error (Student Sign Up): ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e')));
      print('General Error (Student Sign Up): $e');
    } finally {
      if (mounted) {
        _loadingAnimationController.reverse();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0E6F8), Color(0xFFC8A2C9)],
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    child: Image.asset(
                      'assets/student2_logo.png',
                      height: 120,
                    ),
                  ),

                  SlideTransition(
                    position: _topTextAnimation,
                    child: Text(
                      'Create your student account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SlideTransition(
                    position: _bottomTextAnimation,
                    child: Text(
                      'Join to find your perfect tutor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurpleAccent,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildTextFormField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _institutionController,
                    labelText: 'Current Institution',
                    validator: (value) => value!.isEmpty ? 'Please enter your institution' : null,
                    icon: Icons.school,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _addressController,
                    labelText: 'Address',
                    validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    icon: Icons.lock,
                    isPassword: true,
                    onSuffixPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    icon: Icons.lock,
                    isPassword: true,
                    onSuffixPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _ageController,
                    labelText: 'Age',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your age';
                      if (int.tryParse(value) == null) return 'Please enter a valid number for age';
                      return null;
                    },
                    icon: Icons.cake,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _currentClassController,
                    labelText: 'Current Class',
                    validator: (value) => value!.isEmpty ? 'Please enter your current class' : null,
                    icon: Icons.class_,
                  ),
                  const SizedBox(height: 16),
                  // Student WhatsApp Number (Optional)
                  _buildTextFormField(
                    controller: _studentWhatsappController,
                    labelText: 'Student WhatsApp No (Optional)',
                    keyboardType: TextInputType.phone,
                    icon: Icons.chat,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional field, so no error if empty
                      }
                      // Regex to match exactly 11 digits
                      if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                        return 'WhatsApp number must be 11 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Parent's WhatsApp Number (Required)
                  _buildTextFormField(
                    controller: _parentsWhatsappController,
                    labelText: 'Parent\'s WhatsApp No (Required)',
                    keyboardType: TextInputType.phone,
                    icon: Icons.chat,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter parent\'s WhatsApp number'; // Required field
                      }
                      // Regex to match exactly 11 digits
                      if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                        return 'WhatsApp number must be 11 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUpStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8A2C9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                          : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      if (!_isLoading) {
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                    child: const Text(
                      'Already have an account? Login',
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onSuffixPressed,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: 'Enter your $labelText',
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.deepPurple,
          ),
          onPressed: onSuffixPressed,
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(color: Colors.deepPurple),
        hintStyle: const TextStyle(color: Colors.grey),
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
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
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
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      validator: validator,
    );
  }
}