import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Class name changed to StudentInfoForTutorPage
class StudentInfoForTutorPage extends StatelessWidget {
  final String studentId; // Added studentId to the constructor

  const StudentInfoForTutorPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: Theme.of(context).colorScheme.primary, // Use theme color
        foregroundColor: Colors.white,
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
        child: FutureBuilder<DocumentSnapshot>( // Changed to FutureBuilder for single document fetch
          future: FirebaseFirestore.instance.collection('students').doc(studentId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Student profile not found.'));
            }

            final studentData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
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
                          studentData['name'] ?? 'Student Name',
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
                          studentData['email'] ?? 'student@example.com',
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
                  _buildInfoField(
                    context,
                    label: 'Institution',
                    value: studentData['institution'] ?? 'N/A',
                    icon: Icons.school_outlined,
                  ),
                  _buildInfoField(
                    context,
                    label: 'Address',
                    value: studentData['address'] ?? 'N/A',
                    icon: Icons.location_on_outlined,
                  ),
                  _buildInfoField(
                    context,
                    label: 'Age',
                    value: studentData['age']?.toString() ?? 'N/A',
                    icon: Icons.cake_outlined,
                  ),
                  _buildInfoField(
                    context,
                    label: 'Current Class',
                    value: studentData['currentClass'] ?? 'N/A',
                    icon: Icons.class_outlined,
                  ),
                  _buildInfoField(
                    context,
                    label: 'Student WhatsApp',
                    value: studentData['studentWhatsapp'] ?? 'N/A',
                    icon: Icons.chat_outlined,
                  ),
                  _buildInfoField(
                    context,
                    label: 'Parents WhatsApp',
                    value: studentData['parentsWhatsapp'] ?? 'N/A',
                    icon: Icons.family_restroom_outlined, // More appropriate icon
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper function to build a display-only info field
  Widget _buildInfoField(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
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
              child: Column(
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
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
