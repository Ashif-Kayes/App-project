// File: lib/student_info_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentInfoPage extends StatefulWidget {
  const StudentInfoPage({super.key});

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // State variable to hold the current search query

  @override
  void initState() {
    super.initState();
    // Listen for changes in the search text field
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase(); // Update search query and convert to lowercase
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Student Details'), // Updated title for clarity
        backgroundColor: Colors.purple, // Consistent app bar color
        foregroundColor: Colors.white,
      ),
      body: Column( // Use Column to arrange search bar and student list
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple), // Search icon
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, // No border lines
                ),
                filled: true,
                fillColor: Colors.grey[200], // Light grey background for the search bar
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
              style: const TextStyle(color: Colors.black87), // Text color for input
            ),
          ),
          Expanded( // Expanded widget ensures the ListView takes the remaining space
            child: StreamBuilder<QuerySnapshot>(
              // *** IMPORTANT CHANGE STARTS HERE ***
              stream: FirebaseFirestore.instance
                  .collection('students') // Changed from 'approved_students' to 'students'
                  .where('isApproved', isEqualTo: true) // Added filter for approved students
                  .snapshots(),
              // *** IMPORTANT CHANGE ENDS HERE ***
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // Display if no approved students at all
                  return const Center(child: Text('No approved students found.'));
                }

                // Filter students based on the search query
                final allStudents = snapshot.data!.docs;
                final filteredStudents = allStudents.where((student) {
                  final name = student['name']?.toLowerCase() ?? ''; // Get name and convert to lowercase
                  return name.contains(_searchQuery); // Check if name contains the search query
                }).toList();

                if (filteredStudents.isEmpty && _searchQuery.isNotEmpty) {
                  // Display if no students match the current search
                  return const Center(child: Text('No matching students found.'));
                }

                return ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final studentData = student.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 5, // Increased elevation for a more prominent card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Slightly more rounded corners
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${studentData['name'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Email: ${studentData['email'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Age: ${studentData['age']?.toString() ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Current Class: ${studentData['currentClass'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Institution: ${studentData['institution'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Address: ${studentData['address'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Student WhatsApp: ${studentData['studentWhatsapp'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Parent\'s WhatsApp: ${studentData['parentsWhatsapp'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}