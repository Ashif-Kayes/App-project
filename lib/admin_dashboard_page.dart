// File: lib/admin_dashboard_page.dart (or wherever your admin dashboard is located)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Imported for kDebugMode
import 'auth_service.dart'; // Ensure your AuthService file is correct

// Import the new UserDetailsPage
import 'user_details_page.dart'; // This file will be created later

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AuthService _authService = AuthService();

  // Function to logout
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main'); // Redirect to main page
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  // Function to approve a user (student or teacher)
  // This function will be passed as a callback to UserDetailsPage
  Future<void> _approveUser(String userId, String userType) async {
    try {
      // Update 'isApproved' status in 'user_profiles' (general user type management)
      await FirebaseFirestore.instance.collection('user_profiles').doc(userId).update({'isApproved': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userType approved successfully!')));
      }

      // If it's a tutor, update 'isApproved' in the 'tutor_profiles' collection
      // We no longer move to 'approved_tutors' or delete from 'tutors'.
      // We just update the status in 'tutor_profiles'.
      if (userType == 'tutor') {
        await FirebaseFirestore.instance.collection('tutor_profiles').doc(userId).update({'isApproved': true});
      }
      // If it's a student, update their approval status in the 'students' collection
      else if (userType == 'student') {
        // --- START OF CHANGE ---
        await FirebaseFirestore.instance.collection('students').doc(userId).update({'isApproved': true}); // Changed from 'student_profiles' to 'students'
        // --- END OF CHANGE ---
        // You might also remove from a 'pending_students' if you have such a collection and structure
        // Or if you were moving them previously, you might just update their status in their main profile.
      }
    } catch (e) {
      print('Failed to approve $userType: $e'); // Add print for debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve $userType: $e')));
      }
    }
  }

  // Function to reject a user (student or teacher)
  // This function will be passed as a callback to UserDetailsPage
  Future<void> _rejectUser(String userId, String userType) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Rejection'),
            content: Text('Are you sure you want to reject and delete this $userType? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        // Delete user data from user_profiles
        await FirebaseFirestore.instance.collection('user_profiles').doc(userId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userType rejected and deleted.')));
        }

        // If it's a tutor, delete from 'tutor_profiles'
        // We no longer delete from 'tutors' or 'approved_tutors'
        if (userType == 'tutor') {
          await FirebaseFirestore.instance.collection('tutor_profiles').doc(userId).delete();
        }
        // If it's a student, delete from 'students'
        else if (userType == 'student') {
          await FirebaseFirestore.instance.collection('students').doc(userId).delete();
        }

        // IMPORTANT: Also delete the user from Firebase Authentication if you reject them.
        // This requires Admin SDK on a backend (Cloud Functions).
        // Direct client-side deletion of other users is not allowed for security reasons.
        // If you reject a user, their Firebase Auth account will remain unless deleted via Admin SDK.
        // Consider this for your full backend implementation.
      }
    } catch (e) {
      print('Failed to reject $userType: $e'); // Add print for debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reject $userType: $e')));
      }
    }
  }

  // Function to view detailed user information
  void _viewUserDetails(String userId, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsPage(
          userId: userId,
          userType: userType,
          onApprove: _approveUser, // Pass the approve function
          onReject: _rejectUser, // Pass the reject function
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Pending Students
              const Text(
                'Pending Students',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                // Assuming students are also stored in a 'students' collection or 'user_profiles'
                // If student profiles are in 'student_profiles' similar to tutors, adjust here too.
                stream: FirebaseFirestore.instance
                    .collection('students') // This is already correct
                    .where('isApproved', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('Pending Students Stream Error: ${snapshot.error}'); // Debug print
                    return Text('Error: ${snapshot.error}');
                  }

                  final students = snapshot.data!.docs;

                  if (students.isEmpty) {
                    return const Text('No pending students.');
                  }

                  return Column(
                    children: students.map((student) {
                      var studentData = student.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(studentData['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(studentData['email'] ?? 'N/A'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.blue),
                                onPressed: () => _viewUserDetails(student.id, 'student'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _approveUser(student.id, 'student'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectUser(student.id, 'student'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Display Pending Teachers
              const Text(
                'Pending Teachers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tutor_profiles') // This is consistent with 'tutor_profiles'
                    .where('isApproved', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('Pending Teachers Stream Error: ${snapshot.error}'); // Debug print
                    return Text('Error: ${snapshot.error}');
                  }

                  final tutors = snapshot.data!.docs;

                  if (tutors.isEmpty) {
                    return const Text('No pending teachers.');
                  }

                  return Column(
                    children: tutors.map((tutor) {
                      var tutorData = tutor.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(tutorData['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(tutorData['email'] ?? 'N/A'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.blue),
                                onPressed: () => _viewUserDetails(tutor.id, 'tutor'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _approveUser(tutor.id, 'tutor'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectUser(tutor.id, 'tutor'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Buttons to view student and teacher details (keep as is if they navigate to other pages)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/student_info');
                  },
                  child: const Text('View Student Details'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/teacher_info');
                  },
                  child: const Text('View Teacher Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}