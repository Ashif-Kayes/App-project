// File: lib/student_profile_display_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProfileDisplayPage extends StatefulWidget {
  final String studentId;

  const StudentProfileDisplayPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentProfileDisplayPage> createState() => _StudentProfileDisplayPageState();
}

class _StudentProfileDisplayPageState extends State<StudentProfileDisplayPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _currentClassController = TextEditingController();
  final TextEditingController _studentWhatsappController = TextEditingController();
  final TextEditingController _parentsWhatsappController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Fetch student profile and then start the animation
    _fetchStudentProfile().then((_) {
      _animationController.forward();
    });
  }

  Future<void> _fetchStudentProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists && studentDoc.data() != null) {
        final studentData = studentDoc.data() as Map<String, dynamic>;

        _nameController.text = studentData['name'] ?? '';
        _emailController.text = studentData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
        _studentWhatsappController.text = studentData['studentWhatsapp'] ?? '';
        _parentsWhatsappController.text = studentData['parentsWhatsapp'] ?? '';
        _addressController.text = studentData['address'] ?? '';
        _ageController.text = studentData['age']?.toString() ?? '';
        _currentClassController.text = studentData['currentClass'] ?? '';
        _institutionController.text = studentData['institution'] ?? '';
      } else {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == widget.studentId) {
          _emailController.text = currentUser.email ?? '';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile not found. Please complete your profile.')),
        );
      }
    } catch (e) {
      print('Error fetching student profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStudentProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> profileUpdateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'studentWhatsapp': _studentWhatsappController.text.trim(),
        'parentsWhatsapp': _parentsWhatsappController.text.trim(),
        'address': _addressController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'currentClass': _currentClassController.text.trim(),
        'institution': _institutionController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .set(profileUpdateData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      print('Error updating student profile: $e');
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
    _studentWhatsappController.dispose();
    _parentsWhatsappController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _currentClassController.dispose();
    _institutionController.dispose();
    _animationController.dispose(); // Ensure this is called
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showNoDataMessage = !_isLoading && !_isEditing && _nameController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Student Profile'),
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
                  _fetchStudentProfile(); // Reload data if exiting edit mode without saving
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
            : FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
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
                            _nameController.text.isNotEmpty ? _nameController.text : 'Student Name',
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
                            _emailController.text.isNotEmpty ? _emailController.text : 'student@example.com',
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
                    const SizedBox(height: 40),

                    // Profile fields - NOT wrapped with _buildAnimatedProfileField anymore
                    _buildEditableProfileField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      isEditable: _isEditing,
                      validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                    ),
                    _buildEditableProfileField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      isEditable: false, // Email is generally read-only
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                    ),
                    _buildEditableProfileField(
                      controller: _institutionController,
                      label: 'Current Institution',
                      icon: Icons.school_outlined,
                      isEditable: _isEditing,
                      validator: (value) => value!.isEmpty ? 'Institution cannot be empty' : null,
                    ),
                    _buildEditableProfileField(
                      controller: _studentWhatsappController,
                      label: 'Student WhatsApp Number (Optional)',
                      icon: Icons.chat_outlined,
                      isEditable: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildEditableProfileField(
                      controller: _parentsWhatsappController,
                      label: 'Parent\'s WhatsApp Number (Required)',
                      icon: Icons.chat_outlined,
                      isEditable: _isEditing,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Parent\'s WhatsApp number cannot be empty' : null,
                    ),
                    _buildEditableProfileField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      isEditable: _isEditing,
                      maxLines: 2,
                      validator: (value) => value!.isEmpty ? 'Address cannot be empty' : null,
                    ),
                    _buildEditableProfileField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      isEditable: _isEditing,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your age';
                        if (int.tryParse(value) == null) return 'Enter a valid number for age';
                        return null;
                      },
                    ),
                    _buildEditableProfileField(
                      controller: _currentClassController,
                      label: 'Current Class',
                      icon: Icons.class_outlined,
                      isEditable: _isEditing,
                      validator: (value) => value!.isEmpty ? 'Current class cannot be empty' : null,
                    ),
                    const SizedBox(height: 40),
                    if (_isEditing)
                      Center(
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
                            onPressed: _isLoading ? null : _updateStudentProfile,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Removed _buildAnimatedProfileField completely.

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