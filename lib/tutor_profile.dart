// lib/tutor_profile_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({Key? key}) : super(key: key);

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectsController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _monthlySalaryController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _whatsappNumberController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  String? _currentTutorId;

  late AnimationController _animationController;

  // Define individual animations for each field or group of fields
  late Animation<Offset> _profileHeaderSlideAnimation;
  late Animation<double> _profileHeaderFadeAnimation;

  late List<Animation<Offset>> _fieldSlideAnimations;
  late List<Animation<double>> _fieldFadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Slightly longer duration for all staggered animations
    );

    // Main header animations
    _profileHeaderSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut), // Header animates in first 50%
    ));

    _profileHeaderFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn), // Header fades in first 40%
    ));

    // Initialize lists for field animations
    _fieldSlideAnimations = [];
    _fieldFadeAnimations = [];

    // Define staggered animations for each field
    // You'll need to create a pair of animations (slide and fade) for each field.
    // The delay intervals will determine the stagger effect.
    final int numberOfFields = 10; // Adjust based on your actual number of fields
    final int staggerDuration = 100; // Milliseconds between each field's animation start
    final int fieldAnimDuration = 500; // Duration for each field's slide/fade

    for (int i = 0; i < numberOfFields; i++) {
      final double startInterval = (500 + i * staggerDuration) / _animationController.duration!.inMilliseconds;
      final double endSlideInterval = (500 + i * staggerDuration + fieldAnimDuration) / _animationController.duration!.inMilliseconds;
      final double endFadeInterval = (500 + i * staggerDuration + (fieldAnimDuration * 0.6).toInt()) / _animationController.duration!.inMilliseconds;

      _fieldSlideAnimations.add(Tween<Offset>(
        begin: const Offset(0, 0.5), // Start from slightly below
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(startInterval, endSlideInterval, curve: Curves.easeOutCubic),
      )));

      _fieldFadeAnimations.add(Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(startInterval, endFadeInterval, curve: Curves.easeIn),
      )));
    }

    _getCurrentTutorIdAndFetchProfile();
  }

  Future<void> _getCurrentTutorIdAndFetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentTutorId = user.uid;
      await _fetchTutorProfile();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view your profile.')),
      );
    }
  }

  Future<void> _fetchTutorProfile() async {
    if (_currentTutorId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot tutorDoc = await FirebaseFirestore.instance
          .collection('tutor_profiles')
          .doc(_currentTutorId)
          .get();

      if (tutorDoc.exists && tutorDoc.data() != null) {
        final tutorData = tutorDoc.data() as Map<String, dynamic>;

        _nameController.text = tutorData['name'] ?? '';
        _emailController.text = tutorData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

        final dynamic subjectsFromFirestore = tutorData['subjects'];
        if (subjectsFromFirestore is List) {
          _subjectsController.text = (subjectsFromFirestore as List<dynamic>).map((e) => e.toString()).join(', ');
        } else if (subjectsFromFirestore is String) {
          _subjectsController.text = subjectsFromFirestore;
        } else {
          _subjectsController.text = '';
        }

        _educationController.text = tutorData['educationBackground'] ?? '';
        _experienceController.text = tutorData['experience']?.toString() ?? '';
        _monthlySalaryController.text = tutorData['monthlySalary']?.toString() ?? '';
        _institutionController.text = tutorData['institution'] ?? '';
        _addressController.text = tutorData['address'] ?? '';
        _whatsappNumberController.text = tutorData['whatsappNumber'] ?? '';
        _availabilityController.text = tutorData['availability'] ?? '';
      } else {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _emailController.text = currentUser.email ?? '';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No complete profile found. Please fill in details.')),
        );
      }
    } catch (e) {
      print('Error fetching tutor profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward(); // Start animation once data is loaded
    }
  }

  Future<void> _updateTutorProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentTutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Cannot update profile.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String subjectsString = _subjectsController.text.trim();

      Map<String, dynamic> profileUpdateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'subjects': subjectsString,
        'educationBackground': _educationController.text.trim(),
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'monthlySalary': double.tryParse(_monthlySalaryController.text.trim()) ?? 0.0,
        'institution': _institutionController.text.trim(),
        'address': _addressController.text.trim(),
        'whatsappNumber': _whatsappNumberController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'isApproved': true,
      };

      await FirebaseFirestore.instance
          .collection('tutor_profiles')
          .doc(_currentTutorId)
          .set(profileUpdateData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      print('Error updating tutor profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectsController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _monthlySalaryController.dispose();
    _institutionController.dispose();
    _addressController.dispose();
    _whatsappNumberController.dispose();
    _availabilityController.dispose();
    _animationController.dispose(); // Ensure this is always disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showNoDataMessage = !_isLoading && !_isEditing && _nameController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tutor Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel_rounded : Icons.edit_rounded),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _fetchTutorProfile();
                }
              });
            },
            tooltip: _isEditing ? 'Cancel Editing' : 'Edit Profile',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : showNoDataMessage
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No profile data available. Please complete your profile to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        )
            : SingleChildScrollView( // No direct animation on SingleChildScrollView
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Avatar, Name, Email) with its own animation
                FadeTransition(
                  opacity: _profileHeaderFadeAnimation,
                  child: SlideTransition(
                    position: _profileHeaderSlideAnimation,
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 3,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                              child: Icon(
                                Icons.person_rounded,
                                size: 70,
                                color: Theme.of(context).colorScheme.onSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : 'Tutor Name',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _emailController.text.isNotEmpty ? _emailController.text : 'tutor@example.com',
                            style: TextStyle(
                              fontSize: 17,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Profile fields, now correctly using the pre-defined staggered animations
                _buildAnimatedProfileField(
                  fieldIndex: 0, // Pass index to get correct animation pair
                  child: _buildEditableProfileField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    isEditable: _isEditing,
                    validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 1,
                  child: _buildEditableProfileField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    isEditable: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 2,
                  child: _buildEditableProfileField(
                    controller: _institutionController,
                    label: 'Institution',
                    icon: Icons.school_outlined,
                    isEditable: _isEditing,
                    validator: (value) => value!.isEmpty ? 'Institution cannot be empty' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 3,
                  child: _buildEditableProfileField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    isEditable: _isEditing,
                    validator: (value) => value!.isEmpty ? 'Address cannot be empty' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 4,
                  child: _buildEditableProfileField(
                    controller: _whatsappNumberController,
                    label: 'WhatsApp Number',
                    icon: Icons.chat_outlined,
                    isEditable: _isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'WhatsApp number cannot be empty' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 5,
                  child: _buildEditableProfileField(
                    controller: _subjectsController,
                    label: 'Subjects (comma-separated)',
                    icon: Icons.bookmark_border_outlined,
                    isEditable: _isEditing,
                    validator: (value) => value!.isEmpty ? 'Subjects cannot be empty' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 6,
                  child: _buildEditableProfileField(
                    controller: _experienceController,
                    label: 'Experience (years)',
                    icon: Icons.work_outline,
                    isEditable: _isEditing,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your experience';
                      if (int.tryParse(value) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 7,
                  child: _buildEditableProfileField(
                    controller: _monthlySalaryController,
                    label: 'Monthly Salary (in Tk)',
                    icon: Icons.payments_outlined,
                    isEditable: _isEditing,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your monthly salary';
                      if (double.tryParse(value) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 8,
                  child: _buildEditableProfileField(
                    controller: _educationController,
                    label: 'Education Background',
                    icon: Icons.school_outlined,
                    isEditable: _isEditing,
                    maxLines: 2,
                    validator: (value) => value!.isEmpty ? 'Education background cannot be empty' : null,
                  ),
                ),
                _buildAnimatedProfileField(
                  fieldIndex: 9,
                  child: _buildEditableProfileField(
                    controller: _availabilityController,
                    label: 'Availability',
                    icon: Icons.calendar_today_outlined,
                    isEditable: _isEditing,
                    maxLines: 2,
                    validator: (value) => value!.isEmpty ? 'Availability cannot be empty' : null,
                  ),
                ),
                const SizedBox(height: 40),
                if (_isEditing)
                // The save button can also have a simple animation
                  FadeTransition(
                    opacity: _fieldFadeAnimations.last, // Use the last field's fade for the button or create a separate one
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Icon(Icons.save_rounded, size: 24),
                          label: Text(_isLoading ? 'Saving...' : 'Save Changes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          onPressed: _isLoading ? null : _updateTutorProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simplified _buildAnimatedProfileField to use pre-defined animations
  Widget _buildAnimatedProfileField({required Widget child, required int fieldIndex}) {
    if (fieldIndex >= _fieldSlideAnimations.length || fieldIndex >= _fieldFadeAnimations.length) {
      // Fallback for safety if index is out of bounds (shouldn't happen with correct numberOfFields)
      return child;
    }
    return FadeTransition(
      opacity: _fieldFadeAnimations[fieldIndex],
      child: SlideTransition(
        position: _fieldSlideAnimations[fieldIndex],
        child: child,
      ),
    );
  }

  Widget _buildEditableProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditable,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: isEditable
                  ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), fontSize: 16),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), width: 1.5),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.5),
                  ),
                  contentPadding: const EdgeInsets.only(bottom: 5),
                ),
                keyboardType: keyboardType,
                maxLines: maxLines,
                validator: validator,
                readOnly: !isEditable,
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.text.isNotEmpty ? controller.text : 'Not provided',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}