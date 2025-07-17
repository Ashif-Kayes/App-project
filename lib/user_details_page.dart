import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String userType;
  final Function(String userId, String userType) onApprove;
  final Function(String userId, String userType) onReject;

  const UserDetailsPage({
    super.key,
    required this.userId,
    required this.userType,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      DocumentSnapshot doc;
      // Fetch data from the correct collection based on user type
      if (widget.userType == 'student') {
        doc = await FirebaseFirestore.instance.collection('students').doc(widget.userId).get();
      } else { // tutor
        doc = await FirebaseFirestore.instance.collection('tutor_profiles').doc(widget.userId).get();
      }

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User data not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch data: $e';
        _isLoading = false;
      });
      print('Error fetching user details: $e');
    }
  }

  // Called when the Approve button is pressed
  void _onApprovePressed() async {
    await widget.onApprove(widget.userId, widget.userType);
    if (mounted) {
      Navigator.pop(context); // Go back from the details page
    }
  }

  // Called when the Reject button is pressed
  void _onRejectPressed() async {
    await widget.onReject(widget.userId, widget.userType);
    if (mounted) {
      Navigator.pop(context); // Go back from the details page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userType == 'student' ? 'Student' : 'Tutor'} Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              title: 'General Information',
              details: {
                'Name': _userData!['name'] ?? 'N/A',
                'Email': _userData!['email'] ?? 'N/A',
                'Address': _userData!['address'] ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),
            if (widget.userType == 'student')
              _buildDetailCard(
                title: 'Student Information',
                details: {
                  'Institution': _userData!['institution'] ?? 'N/A',
                  'Age': _userData!['age']?.toString() ?? 'N/A',
                  'Current Class': _userData!['currentClass'] ?? 'N/A',
                  'Student WhatsApp': _userData!['studentWhatsapp'] ?? 'N/A',
                  'Parents WhatsApp': _userData!['parentsWhatsapp'] ?? 'N/A',
                  // NEW: Display Subjects of Interest for Students
                  'Subjects of Interest': (_userData!['subjectsOfInterest'] as List<dynamic>?)?.join(', ') ?? 'N/A',
                },
              ),
            if (widget.userType == 'tutor')
              _buildDetailCard(
                title: 'Tutor Information',
                details: {
                  'Institution': _userData!['institution'] ?? 'N/A',
                  'WhatsApp Number': _userData!['whatsappNumber'] ?? 'N/A',
                  // CORRECTED: Display Subjects as a single string
                  'Subjects': (_userData!['subjects'] as String?) ?? 'N/A',
                  'Experience (Years)': _userData!['experience']?.toString() ?? 'N/A',
                  // Using 'monthlySalary' as per TutorSignUpPage (previously 'monthlyIncome')
                  'Monthly Salary (Tk)': _userData!['monthlySalary']?.toString() ?? 'N/A',
                },
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _onApprovePressed,
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _onRejectPressed,
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required Map<String, String> details}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const Divider(height: 20, thickness: 1),
            ...details.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(entry.value),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}