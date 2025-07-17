import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TutorSignUpPage extends StatefulWidget {
  const TutorSignUpPage({super.key});

  @override
  State<TutorSignUpPage> createState() => _TutorSignUpPageState();
}

class _TutorSignUpPageState extends State<TutorSignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _subjectsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _monthlySalaryController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _whatsappNumberController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _subjectsController.dispose();
    _experienceController.dispose();
    _monthlySalaryController.dispose();
    _institutionController.dispose();
    _addressController.dispose();
    _whatsappNumberController.dispose();
    _topTextAnimationController.dispose();
    _bottomTextAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signUpTutor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _loadingAnimationController.forward();

    try {
      // 1. Create the user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get the user
      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User was not created.');
      }

      // 2. Send email verification
      await user.sendEmailVerification();

      // 3. Store user data in 'user_profiles' collection (for general user info and role)
      await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).set({
        'userId': user.uid,
        'userType': 'tutor', // Explicitly set user type here
        'email': _emailController.text.trim(),
        'isApproved': false, // Approval is pending for new tutors
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Store detailed tutor profile data in 'tutor_profiles' collection
      //    (This replaces the 'tutors' collection logic)

      // --- ONLY CHANGE HERE: Store subjects as a single string directly ---
      String subjectsString = _subjectsController.text.trim();

      await FirebaseFirestore.instance.collection('tutor_profiles').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'subjects': subjectsString, // NOW SAVED AS A SINGLE STRING
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'monthlySalary': double.tryParse(_monthlySalaryController.text.trim()) ?? 0.0, // Renamed to monthlySalary for consistency
        'institution': _institutionController.text.trim(),
        'address': _addressController.text.trim(),
        'whatsappNumber': _whatsappNumberController.text.trim(),
        'educationBackground': '',
        'availability': '',
        'isApproved': false,
        'registeredAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'numberOfRatings': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please verify your email and await admin approval.')),
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
      print('Firebase Auth Error (Tutor Sign Up): ${e.code} - ${e.message}');
    } catch (e) {
      print('Error during sign up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
                      'assets/tutor_logo.png',
                      height: 120,
                    ),
                  ),

                  SlideTransition(
                    position: _topTextAnimation,
                    child: Text(
                      'Create your tutor account',
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
                      'Join to find tuitions',
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
                    controller: _institutionController,
                    labelText: 'Institution',
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
                    controller: _whatsappNumberController,
                    labelText: 'WhatsApp Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'Please enter your WhatsApp number' : null,
                    icon: Icons.chat,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _subjectsController,
                    labelText: 'Subjects (comma-separated)',
                    validator: (value) => value!.isEmpty ? 'Please enter the subjects you teach' : null,
                    icon: Icons.book,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _experienceController,
                    labelText: 'Experience (years)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your experience';
                      if (int.tryParse(value) == null) return 'Enter a valid number for experience';
                      return null;
                    },
                    icon: Icons.star,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _monthlySalaryController,
                    labelText: 'Monthly Salary (in Tk)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your desired monthly salary';
                      if (double.tryParse(value) == null) return 'Enter a valid number for salary';
                      return null;
                    },
                    icon: Icons.money_outlined,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUpTutor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
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
                        'Sign Up as Tutor',
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