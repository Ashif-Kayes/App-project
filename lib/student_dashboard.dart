// File: lib/student_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter

// Import your comprehensive student profile display page (assuming it's in the same directory)
import 'student_profile_display_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({Key? key}) : super(key: key);

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  // Use a nullable double for maximum salary search, initialized to null
  double? _maxMonthlySalarySearchValue; // Changed to maximum salary search
  // String for subject search, initialized to empty
  String _subjectSearchValue = '';

  final TextEditingController _maxSalarySearchController = TextEditingController(); // Changed controller name
  final TextEditingController _subjectSearchController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _currentStudentId;
  String _currentStudentName = 'Student'; // Default or fetched from profile

  @override
  void initState() {
    super.initState();
    // Safely add listeners to the search text fields
    _maxSalarySearchController.addListener(_onMaxSalarySearchTextChanged); // Updated listener
    _subjectSearchController.addListener(_onSubjectSearchTextChanged);

    // Set up Firebase Auth state listener
    _auth.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _currentStudentId = user?.uid;
        });
        if (_currentStudentId != null) {
          _fetchStudentName(); // Fetch name once student ID is confirmed
        } else {
          _currentStudentName = 'Student'; // Reset if user logs out
        }
      }
    });

    // Handle the case where the user is already logged in when the page initializes
    _currentUser = _auth.currentUser;
    _currentStudentId = _currentUser?.uid;
    // print('Initial Current Student ID from initState: $_currentStudentId'); // DEBUG
    if (_currentStudentId != null) {
      _fetchStudentName(); // Fetch name for already logged-in users
    }
  }

  // Handles changes in the maximum salary search text field to update the filter value
  void _onMaxSalarySearchTextChanged() {
    if (mounted) {
      setState(() {
        _maxMonthlySalarySearchValue = double.tryParse(_maxSalarySearchController.text.trim());
        // print('Max Salary search text updated: "${_maxSalarySearchController.text.trim()}" -> _maxMonthlySalarySearchValue: $_maxMonthlySalarySearchValue'); // DEBUG
      });
    }
  }

  // Handles changes in the subject search text field
  void _onSubjectSearchTextChanged() {
    if (mounted) {
      setState(() {
        // Store in lowercase for case-insensitive matching
        _subjectSearchValue = _subjectSearchController.text.trim().toLowerCase();
        // print('Subject search text updated: "${_subjectSearchController.text.trim()}" -> _subjectSearchValue: $_subjectSearchValue'); // DEBUG
      });
    }
  }

  // Fetches the current student's name from Firestore
  Future<void> _fetchStudentName() async {
    if (_currentStudentId == null) {
      // print('Current Student ID is null, cannot fetch name.'); // DEBUG
      return;
    }

    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(_currentStudentId)
          .get();

      if (studentDoc.exists && studentDoc.data() != null) {
        setState(() {
          _currentStudentName = (studentDoc.data() as Map<String, dynamic>)['name'] ?? 'Student';
          // print('Fetched student name: $_currentStudentName'); // DEBUG
        });
      } else {
        // If profile doesn't exist, prompt the user to complete it
        // print('Student profile document not found for ID: $_currentStudentId in students collection'); // DEBUG
        setState(() {
          _currentStudentName = 'New Student';
        });
        // Optionally show a SnackBar or dialog here to prompt profile completion
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete your profile to get full access.')),
          );
        }
      }
    } catch (e) {
      // print('Error fetching student name: $e'); // DEBUG
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student name: $e')),
        );
      }
    }
  }

  // Formats the subject data for display.
  // Handles both List and String types for subjects.
  String _formatSubjects(dynamic subjects) {
    if (subjects is List) {
      // If it's a list, join them with commas
      return subjects.map((s) => s.toString()).join(', ');
    } else if (subjects is String && subjects.isNotEmpty) {
      // If it's a non-empty string, just return it
      return subjects;
    }
    return 'N/A'; // Default for null or empty/invalid data
  }

  @override
  void dispose() {
    _maxSalarySearchController.removeListener(_onMaxSalarySearchTextChanged); // Updated
    _maxSalarySearchController.dispose(); // Updated
    _subjectSearchController.removeListener(_onSubjectSearchTextChanged);
    _subjectSearchController.dispose();
    super.dispose();
  }

  // Builds the Firebase query for approved tutors
  Query _buildTutorQuery() {
    Query q = FirebaseFirestore.instance.collection('tutor_profiles');
    // print('Starting new tutor query...'); // DEBUG

    // Essential: Only fetch approved tutors
    q = q.where('isApproved', isEqualTo: true);
    // print('Applied isApproved filter: true'); // DEBUG

    // Ordering by 'name' is good for presentation and can help with indexes
    q = q.orderBy('name', descending: false);
    // print('Applied order by name'); // DEBUG

    return q;
  }

  // Function to send a session request to a tutor
  void _sendSessionRequest(String tutorId, String tutorName, String subject) async {
    if (_currentStudentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to request a session.')),
        );
      }
      return;
    }
    // print('Attempting to send session request for Tutor: $tutorName ($tutorId), Subject: $subject'); // DEBUG

    DateTime? chosenDateTime;

    await showDialog(
      context: context,
      builder: (ctx) {
        // Initialize date/time for the dialog with reasonable defaults
        DateTime initialDate = DateTime.now().add(const Duration(days: 1));
        TimeOfDay initialTime = const TimeOfDay(hour: 17, minute: 0);

        DateTime? tempDate = initialDate;
        TimeOfDay? tempTime = initialTime;

        return AlertDialog(
          title: Text('Request Session with $tutorName'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date Picker Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(tempDate == null ? 'Pick Date' : DateFormat('yyyy-MM-dd').format(tempDate!)),
                    onPressed: () async {
                      DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? initialDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => tempDate = d);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Time Picker Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(tempTime == null ? 'Pick Time' : tempTime!.format(context)),
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(
                        context: context,
                        initialTime: tempTime ?? initialTime,
                        useRootNavigator: false, // Prevents fullscreen dialog on iPad
                      );
                      if (t != null) setState(() => tempTime = t);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (tempDate != null && tempTime != null) {
                  chosenDateTime = DateTime(
                    tempDate!.year,
                    tempDate!.month,
                    tempDate!.day,
                    tempTime!.hour,
                    tempTime!.minute,
                  );
                  Navigator.pop(ctx); // Close dialog
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please pick both date and time')),
                    );
                  }
                }
              },
              child: const Text('Confirm Request'),
            )
          ],
        );
      },
    );

    // Proceed only if a date and time were chosen from the dialog
    if (chosenDateTime != null) {
      // print('Chosen DateTime for session: $chosenDateTime'); // DEBUG
      try {
        await FirebaseFirestore.instance.collection('sessions').add({
          'studentId': _currentStudentId,
          'studentName': _currentStudentName,
          'tutorId': tutorId,
          'tutorName': tutorName,
          'subject': subject,
          'dateTime': Timestamp.fromDate(chosenDateTime!),
          'status': 'pending', // Initial status
          'requestedAt': FieldValue.serverTimestamp(), // Timestamp of request
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session request sent successfully!')),
          );
        }
        // print('Session request successfully added to Firestore.'); // DEBUG
      } catch (e) {
        // print('Error sending session request: $e'); // DEBUG
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send session request: $e')),
          );
        }
      }
    } else {
      // print('No date/time chosen, session request cancelled by user.'); // DEBUG
    }
  }

  // Function to cancel a session
  Future<void> _cancelSession(String sessionId) async {
    // print('Attempting to cancel session: $sessionId'); // DEBUG
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .update({'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Session cancelled')));
      }
      // print('Session $sessionId cancelled successfully.'); // DEBUG
    } catch (e) {
      // print('Error cancelling session $sessionId: $e'); // DEBUG
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to cancel session: $e')));
      }
    }
  }

  // Function to reschedule a session
  Future<void> _rescheduleSession(String sessionId, DateTime oldDateTime) async {
    // print('Attempting to reschedule session: $sessionId from $oldDateTime'); // DEBUG
    DateTime? newDateTime;

    await showDialog(
      context: context,
      builder: (ctx) {
        DateTime? tempDate = oldDateTime; // Start with old date
        TimeOfDay tempTime = TimeOfDay(hour: oldDateTime.hour, minute: oldDateTime.minute); // Start with old time

        return AlertDialog(
          title: const Text('Reschedule Session'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('yyyy-MM-dd').format(tempDate!)),
                    onPressed: () async {
                      DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: tempDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => tempDate = d);
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(tempTime.format(context)),
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(
                        context: context,
                        initialTime: tempTime,
                        useRootNavigator: false,
                      );
                      if (t != null) setState(() => tempTime = t);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (tempDate != null && tempTime != null) {
                  newDateTime = DateTime(
                    tempDate!.year,
                    tempDate!.month,
                    tempDate!.day,
                    tempTime.hour,
                    tempTime.minute,
                  );
                  Navigator.pop(ctx); // Close dialog
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select new date and time')),
                    );
                  }
                }
              },
              child: const Text('Reschedule'),
            ),
          ],
        );
      },
    );

    if (newDateTime != null) {
      // print('New DateTime for session $sessionId: $newDateTime'); // DEBUG
      try {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .update({'dateTime': Timestamp.fromDate(newDateTime!), 'status': 'pending'}); // Reset status to pending
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Session rescheduled')));
        }
        // print('Session $sessionId rescheduled successfully.'); // DEBUG
      } catch (e) {
        // print('Error rescheduling session $sessionId: $e'); // DEBUG
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to reschedule session: $e')));
        }
      }
    } else {
      // print('Reschedule cancelled by user for session $sessionId.'); // DEBUG
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return a loading spinner or login prompt if user ID isn't available yet
    if (_currentStudentId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Dashboard')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final tutorQuery = _buildTutorQuery(); // Build the base tutor query

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_currentStudentName!'),
        automaticallyImplyLeading: false, // Don't show back button by default
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                // Pass the current student's ID to the profile page
                MaterialPageRoute(builder: (context) => StudentProfileDisplayPage(studentId: _currentStudentId!)),
              ).then((_) {
                // Re-fetch the student's name when returning from the profile page
                _fetchStudentName();
              });
            },
            tooltip: 'View/Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // Navigate to the main login/signup route and remove all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully!')),
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Increased overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Tutors Section ---
            Text('Search Tutors', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            // Max Monthly Salary Search Bar
            TextField(
              controller: _maxSalarySearchController, // Changed controller
              decoration: InputDecoration(
                labelText: 'Maximum Monthly Salary (e.g., 10000)', // Changed label
                hintText: 'Enter maximum salary to filter tutors', // Changed hint text
                prefixIcon: const Icon(Icons.currency_pound), // Or your local currency icon
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _maxSalarySearchController.clear(); // Clear search text
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Allow digits and up to 2 decimal places
              ],
            ),
            const SizedBox(height: 15), // Spacing between search bars

            // New: Subject Search Bar
            TextField(
              controller: _subjectSearchController,
              decoration: InputDecoration(
                labelText: 'Search by Subject (e.g., Math)',
                hintText: 'Enter subject to filter tutors',
                prefixIcon: const Icon(Icons.menu_book),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _subjectSearchController.clear(); // Clear search text
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words, // Capitalize words for better UX
            ),

            const SizedBox(height: 25), // Increased spacing after search bars

            const Divider(height: 40), // Visual separator

            // --- All Tutors Display Section ---
            Text('Available Tutors:', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: tutorQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // print('Tutor Stream Error: ${snapshot.error}'); // DEBUG
                  return Center(child: Text('Error loading tutors: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No approved tutors found.'));
                }

                // Client-side filtering based on _maxMonthlySalarySearchValue AND _subjectSearchValue
                final tutors = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final double tutorMonthlySalary = (data['monthlySalary'] as num?)?.toDouble() ?? 0.0;

                  // --- Robust Subject Handling for Filtering ---
                  String subjectsToFilter = '';
                  if (data['subjects'] is List) {
                    // If it's a list, join them into a single string for searching
                    subjectsToFilter = (data['subjects'] as List)
                        .map((s) => s.toString())
                        .join(' ') // Join with space for better searching (e.g., "Math Physics")
                        .toLowerCase();
                  } else if (data['subjects'] is String) {
                    // If it's a single string, use it directly
                    subjectsToFilter = (data['subjects'] as String).toLowerCase();
                  }
                  // Default to empty string if neither a List nor a String, so it doesn't cause an error


                  // Salary criteria (Changed for maximum salary)
                  final bool meetsSalaryCriteria = _maxMonthlySalarySearchValue == null || tutorMonthlySalary <= _maxMonthlySalarySearchValue!;

                  // Subject criteria (case-insensitive, checks if the processed subject string contains the search string)
                  final bool meetsSubjectCriteria = _subjectSearchValue.isEmpty ||
                      subjectsToFilter.contains(_subjectSearchValue);


                  // print('Filtering tutor ${data['name'] ?? 'N/A'}: Salary ${tutorMonthlySalary} vs Max Search ${_maxMonthlySalarySearchValue}. Meets salary: $meetsSalaryCriteria. Subjects processed for filter: $subjectsToFilter vs Search $_subjectSearchValue. Meets subject: $meetsSubjectCriteria'); // DEBUG
                  return meetsSalaryCriteria && meetsSubjectCriteria; // Both must be true
                }).toList();

                if (tutors.isEmpty) {
                  return const Center(child: Text('No tutors found matching your criteria.'));
                }

                return ListView.builder(
                  shrinkWrap: true, // Important for nested ListViews/Columns
                  physics: const NeverScrollableScrollPhysics(), // Prevent inner scrolling
                  itemCount: tutors.length,
                  itemBuilder: (context, index) {
                    final doc = tutors[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Handle subjects for display, ensuring a clean string
                    String subjectsDisplay = _formatSubjects(data['subjects']);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? 'No Name', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 5),
                            Text('Subjects: $subjectsDisplay', style: Theme.of(context).textTheme.bodyMedium),
                            Text('Experience: ${(data['experience'] as num?)?.toStringAsFixed(0) ?? 'N/A'} years', style: Theme.of(context).textTheme.bodyMedium),
                            Text('Monthly Salary: Tk${(data['monthlySalary'] as num?)?.toStringAsFixed(0) ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                            Text('Availability: ${data['availability'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.bookmark_add),
                                label: const Text('Book Session'),
                                onPressed: () {
                                  _sendSessionRequest(doc.id, data['name'] ?? 'Tutor', subjectsDisplay);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const Divider(height: 40), // Visual separator

            // --- Your Requested Sessions Chamber ---
            Text('Your Requested Sessions:', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('studentId', isEqualTo: _currentStudentId)
                  .where('status', whereIn: ['pending', 'rescheduled'])
                  .orderBy('dateTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // print('Requested Sessions Stream Error: ${snapshot.error}'); // DEBUG
                  return Center(child: Text('Error loading requests: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No pending session requests.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? ts = data['dateTime'] as Timestamp?;
                    final dateTime = ts?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      color: Colors.blue.shade50, // Light blue for pending
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text('${data['subject'] ?? 'Subject'} session with ${data['tutorName'] ?? 'Unknown Tutor'}'),
                        subtitle: Text(
                          'Date: ${dateTime != null ? DateFormat('MMM dd, yyyy, EEEE h:mm a').format(dateTime.toLocal()) : 'N/A'}\n'
                              'Status: ${data['status'] ?? 'N/A'}',
                        ),
                        trailing: dateTime != null
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _cancelSession(doc.id),
                              tooltip: 'Cancel Request',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _rescheduleSession(doc.id, dateTime),
                              tooltip: 'Reschedule Request',
                            ),
                          ],
                        )
                            : null, // No actions if dateTime is null
                      ),
                    );
                  },
                );
              },
            ),

            const Divider(height: 40), // Visual separator

            // --- Your Confirmed Sessions Chamber ---
            Text('Your Confirmed Sessions:', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('studentId', isEqualTo: _currentStudentId)
                  .where('status', whereIn: ['accepted', 'booked'])
                  .orderBy('dateTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // print('Confirmed Sessions Stream Error: ${snapshot.error}'); // DEBUG
                  return Center(child: Text('Error loading confirmed sessions: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No confirmed sessions.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? ts = data['dateTime'] as Timestamp?;
                    final dateTime = ts?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      color: Colors.green.shade50, // Light green for confirmed
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text('${data['subject'] ?? 'Subject'} session with ${data['tutorName'] ?? 'Unknown Tutor'}'),
                        subtitle: Text(
                          'Date: ${dateTime != null ? DateFormat('MMM dd, yyyy, EEEE h:mm a').format(dateTime.toLocal()) : 'N/A'}\n'
                              'Status: ${data['status'] ?? 'N/A'}',
                        ),
                        trailing: dateTime != null
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _cancelSession(doc.id),
                            ),
                          ],
                        )
                            : null, // No actions if dateTime is null
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}