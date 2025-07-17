// File: lib/teacher_info_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherInfoPage extends StatefulWidget {
  const TeacherInfoPage({super.key});

  @override
  State<TeacherInfoPage> createState() => _TeacherInfoPageState();
}

class _TeacherInfoPageState extends State<TeacherInfoPage> {
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
        title: const Text('Approved Teacher Details'), // Title indicating approved teachers
        backgroundColor: Colors.purple, // Consistent app bar color
        foregroundColor: Colors.white,
      ),
      body: Column( // Use Column to arrange search bar and teacher list
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by teacher name...',
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
              stream: FirebaseFirestore.instance
                  .collection('tutor_profiles')
                  .where('isApproved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No approved teachers found.'));
                }

                final allTeachers = snapshot.data!.docs;
                final filteredTeachers = allTeachers.where((teacher) {
                  final name = teacher['name']?.toLowerCase() ?? '';
                  // You might also want to search by subjects here if needed,
                  // but for now, it's just by name as requested by the search bar's hint.
                  // If you search by subjects, remember it's a string, so use .contains().
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredTeachers.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text('No matching teachers found.'));
                }

                return ListView.builder(
                  itemCount: filteredTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = filteredTeachers[index];
                    final teacherData = teacher.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${teacherData['name'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Email: ${teacherData['email'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            // *** CORRECTED LINE FOR SUBJECTS DISPLAY ***
                            Text(
                              'Subjects: ${teacherData['subjects'] ?? 'N/A'}', // Directly display as string
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Experience: ${teacherData['experience']?.toString() ?? 'N/A'} years',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Monthly Salary: Tk ${teacherData['monthlySalary']?.toStringAsFixed(2) ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Institution: ${teacherData['institution'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Address: ${teacherData['address'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'WhatsApp: ${teacherData['whatsappNumber'] ?? 'N/A'}',
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