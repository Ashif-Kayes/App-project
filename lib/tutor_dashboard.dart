import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'dart:async';

// IMPORTANT: Ensure this path is correct for your project
// Adjust 'flutter_application_1' and the sub-folder 'tutor/' if your file structure is different.
// For example, if tutor_profile_page.dart is directly in lib/, it might be 'package:flutter_application_1/tutor_profile_page.dart'
import 'tutor_profile.dart'; // Corrected import for TutorProfilePage
import 'student_info_for_tutor.dart'; // Assuming this file exists and is in the same directory or correctly imported

class TutorDashboardPage extends StatefulWidget {
  const TutorDashboardPage({Key? key}) : super(key: key);

  @override
  State<TutorDashboardPage> createState() => _TutorDashboardPageState();
}

class _TutorDashboardPageState extends State<TutorDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentTutorId;
  String _currentTutorName = 'Tutor'; // Default or fetched from profile
  StreamSubscription<User?>? _authStateChangesSubscription; // For listening to auth state

  @override
  void initState() {
    super.initState();
    print('TutorDashboardPage initState called.'); // Debug print

    // Listen for authentication state changes
    _authStateChangesSubscription = _auth.authStateChanges().listen((user) {
      if (user != null && _currentTutorId != user.uid) {
        // User logged in or switched
        setState(() {
          _currentTutorId = user.uid;
        });
        print('Auth State Changed: Tutor logged in, UID: $_currentTutorId');
        _fetchTutorName(); // Fetch name for the new UID
      } else if (user == null && _currentTutorId != null) {
        // User logged out
        setState(() {
          _currentTutorId = null;
          _currentTutorName = 'Tutor';
        });
        print('Auth State Changed: Tutor logged out.');
      }
      // If user is not null and _currentTutorId is already user.uid, no action needed
      // If user is null and _currentTutorId is already null, no action needed
    });

    // Check current user status on initial load
    final user = _auth.currentUser;
    if (user != null) {
      _currentTutorId = user.uid;
      print('initState: User already logged in, UID: $_currentTutorId');
      _fetchTutorName();
    } else {
      print('initState: No user currently logged in.');
    }
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel(); // Cancel the auth state listener
    super.dispose();
  }

  Future<void> _fetchTutorName() async {
    if (_currentTutorId == null) {
      print('No current tutor ID available to fetch name in _fetchTutorName.');
      return;
    }

    try {
      // CORRECTED: Using 'tutor_profiles' collection to fetch the tutor's name
      DocumentSnapshot tutorDoc = await FirebaseFirestore.instance
          .collection('tutor_profiles') // Corrected collection name
          .doc(_currentTutorId)
          .get();

      if (tutorDoc.exists && tutorDoc.data() != null) {
        setState(() {
          _currentTutorName = (tutorDoc.data() as Map<String, dynamic>)['name'] ?? 'Tutor';
        });
        print('Successfully fetched tutor name: $_currentTutorName');
      } else {
        print('Tutor profile not found for ID: $_currentTutorId. Setting name to "New Tutor".');
        setState(() {
          _currentTutorName = 'New Tutor';
        });
      }
    } catch (e) {
      print('Error fetching tutor name: $e');
      // Show snackbar for user feedback, but avoid excessive popups in case of persistent errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tutor profile name: $e')),
      );
    }
  }

  Future<void> _updateSessionStatus(String sessionId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session status updated to $newStatus!')),
      );
    } catch (e) {
      print('Error updating session status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update session status: $e')),
      );
    }
  }

  Future<void> _rescheduleSessionAsTutor(String sessionId, DateTime oldDateTime) async {
    DateTime? newDateTime;

    await showDialog(
      context: context,
      builder: (ctx) {
        DateTime? tempDate = oldDateTime;
        TimeOfDay tempTime = TimeOfDay(hour: oldDateTime.hour, minute: oldDateTime.minute);

        return AlertDialog(
          title: const Text('Propose Reschedule'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    child: Text(tempDate == null ? 'Pick Date' : DateFormat('yyyy-MM-dd').format(tempDate!)),
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
                  ElevatedButton(
                    child: Text(tempTime.format(context)),
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
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select new date and time')),
                  );
                }
              },
              child: const Text('Propose Reschedule'),
            ),
          ],
        );
      },
    );

    if (newDateTime != null) {
      try {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .update({'dateTime': Timestamp.fromDate(newDateTime!), 'status': 'rescheduled_by_tutor'});
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reschedule proposed. Student will be notified.')));
      } catch (e) {
        print('Error proposing reschedule: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to propose reschedule: $e')));
      }
    }
  }

  // Function to view student profile, now using StudentInfoForTutorPage
  void _viewStudentProfile(String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentInfoForTutorPage(studentId: studentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If _currentTutorId is null, it means the user is not logged in or data is still loading
    if (_currentTutorId == null) {
      print('Build method: _currentTutorId is null, showing login message or loader.');
      return Scaffold(
        appBar: AppBar(title: const Text('Tutor Dashboard')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              // Consider redirecting to login if this state persists or user is definitely logged out
              Text('Loading tutor data... Please ensure you are logged in.'),
            ],
          ),
        ),
      );
    }
    print('Build method: _currentTutorId is $_currentTutorId. Building dashboard.');

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_currentTutorName!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // CORRECTED: Navigate to the new TutorProfilePage without passing a tutorId
              // The TutorProfilePage now fetches the current user's profile automatically.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorProfilePage(), // Correctly call TutorProfilePage
                ),
              );
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // After logout, navigate back to the main/authentication page
              if (context.mounted) {
                // IMPORTANT: Ensure '/main' is a valid route in your MaterialApp's routes
                // or replace with your actual authentication/main entry point route.
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Session Requests:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('tutorId', isEqualTo: _currentTutorId)
                  .where('status', whereIn: ['pending', 'rescheduled', 'rescheduled_by_tutor'])
                  .orderBy('dateTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Pending Sessions Stream Error: ${snapshot.error}');
                  return Text('Error: ${snapshot.error}\n'
                      'Please check Firebase Console for required indexes.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('Pending Sessions: Still loading.');
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('Pending Sessions: No data found.');
                  return const Text('No pending session requests.');
                }

                print('Querying for tutorId (Pending): $_currentTutorId');
                print('Number of pending session docs found: ${snapshot.data!.docs.length}');

                final sessions = snapshot.data!.docs;

                return Column(
                  children: sessions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? ts = data['dateTime'] as Timestamp?;
                    final dateTime = ts?.toDate();
                    final String status = data['status'] ?? 'N/A';
                    final String studentId = data['studentId'] ?? '';
                    final String studentName = data['studentName'] ?? 'Unknown Student';


                    print('   - Session ID: ${doc.id}, Student: $studentName, Subject: ${data['subject']}, Status: $status');


                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.orange[50], // Hint for pending
                      child: ListTile(
                        title: Text('${data['subject'] ?? 'Subject'} session with $studentName'),
                        subtitle: Text(
                          'Date: ${dateTime != null ? DateFormat('MMM dd,EEEE h:mm a').format(dateTime.toLocal()) : 'N/A'}\n'
                              'Status: $status',
                        ),
                        trailing: (status == 'pending' || status == 'rescheduled' || status == 'rescheduled_by_tutor') && dateTime != null
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.person_search, color: Colors.purple),
                              onPressed: () {
                                if (studentId.isNotEmpty) {
                                  _viewStudentProfile(studentId);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Student ID not available.')),
                                  );
                                }
                              },
                              tooltip: 'View Student Profile',
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _updateSessionStatus(doc.id, 'accepted'),
                              tooltip: 'Accept Request',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _updateSessionStatus(doc.id, 'rejected'),
                              tooltip: 'Reject Request',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                              onPressed: () => _rescheduleSessionAsTutor(doc.id, dateTime),
                              tooltip: 'Propose Reschedule',
                            ),
                          ],
                        )
                            : null, // No actions for other statuses
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const Divider(height: 40),

            const Text('Confirmed Sessions:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('tutorId', isEqualTo: _currentTutorId)
                  .where('status', whereIn: ['accepted', 'booked'])
                  .orderBy('dateTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Confirmed Sessions Stream Error: ${snapshot.error}');
                  return Text('Error: ${snapshot.error}\n'
                      'Please check Firebase Console for required indexes.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('Confirmed Sessions: Still loading.');
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('Confirmed Sessions: No data found.');
                  return const Text('No confirmed sessions.');
                }

                print('Querying for tutorId (Confirmed): $_currentTutorId');
                print('Number of confirmed session docs found: ${snapshot.data!.docs.length}');

                final sessions = snapshot.data!.docs;

                return Column(
                  children: sessions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? ts = data['dateTime'] as Timestamp?;
                    final dateTime = ts?.toDate();
                    final String status = data['status'] ?? 'N/A';
                    final String studentId = data['studentId'] ?? '';
                    final String studentName = data['studentName'] ?? 'Unknown Student';


                    print('   - Confirmed Session ID: ${doc.id}, Student: $studentName, Subject: ${data['subject']}, Status: $status');


                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.lightGreen[50], // Hint for confirmed
                      child: ListTile(
                        title: Text('${data['subject'] ?? 'Subject'} session with $studentName'),
                        subtitle: Text(
                          'Date: ${dateTime != null ? DateFormat('MMM dd,EEEE h:mm a').format(dateTime.toLocal()) : 'N/A'}\n'
                              'Status: $status',
                        ),
                        trailing: (status == 'accepted' || status == 'booked') && dateTime != null
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.person_search, color: Colors.purple),
                              onPressed: () {
                                if (studentId.isNotEmpty) {
                                  _viewStudentProfile(studentId);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Student ID not available.')),
                                  );
                                }
                              },
                              tooltip: 'View Student Profile',
                            ),
                            IconButton(
                              icon: const Icon(Icons.done_all, color: Colors.blueGrey),
                              onPressed: () => _updateSessionStatus(doc.id, 'completed'),
                              tooltip: 'Mark as Completed',
                            ),
                          ],
                        )
                            : null, // No actions for other statuses
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const Divider(height: 40),

            const Text('Other Sessions (Completed/Cancelled/Rejected):', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('tutorId', isEqualTo: _currentTutorId)
                  .where('status', whereIn: ['completed', 'cancelled', 'rejected'])
                  .orderBy('dateTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                print('Number of other session docs found: ${snapshot.data!.docs.length}');

                final sessions = snapshot.data!.docs;
                if (sessions.isEmpty) return const Text('No past or inactive sessions.');

                return Column(
                  children: sessions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp? ts = data['dateTime'] as Timestamp?;
                    final dateTime = ts?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.grey[100], // Grey hint for past/inactive sessions
                      child: ListTile(
                        title: Text('${data['subject'] ?? 'Subject'} session with ${data['studentName'] ?? 'Unknown Student'}'),
                        subtitle: Text(
                          'Date: ${dateTime != null ? DateFormat('MMM dd,EEEE h:mm a').format(dateTime.toLocal()) : 'N/A'}\n'
                              'Status: ${data['status'] ?? 'N/A'}',
                        ),
                        trailing: (data['studentId'] ?? '').isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.person_search, color: Colors.purple),
                          onPressed: () => _viewStudentProfile(data['studentId']!),
                          tooltip: 'View Student Profile',
                        )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}