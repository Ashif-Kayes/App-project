import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom Exceptions for better error handling
class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException([this.message = 'Your email address is not verified.']);
  @override
  String toString() => 'EmailNotVerifiedException: $message';
}

class AccountNotApprovedException implements Exception {
  final String message;
  AccountNotApprovedException([this.message = 'Your account is pending admin approval.']);
  @override
  String toString() => 'AccountNotApprovedException: $message';
}

class UserProfileNotFoundException implements Exception {
  final String message;
  UserProfileNotFoundException([this.message = 'User profile not found.']);
  @override
  String toString() => 'UserProfileNotFoundException: $message';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Common Sign-In Method ---
  Future<void> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 1. Check if email is verified
        if (!user.emailVerified) {
          throw EmailNotVerifiedException();
        }

        // 2. Fetch user profile to check approval status and user type
        DocumentSnapshot userProfileDoc =
            await _firestore.collection('user_profiles').doc(user.uid).get();

        if (!userProfileDoc.exists) {
          // This should ideally not happen if signup process is robust
          throw UserProfileNotFoundException();
        }

        final data = userProfileDoc.data() as Map<String, dynamic>;
        final bool isApproved = data['isApproved'] ?? false; // Default to false if not present

        if (!isApproved) {
          throw AccountNotApprovedException();
        }
        // If execution reaches here, user is authenticated, email is verified, and account is approved.
      }
    } on FirebaseAuthException catch (e) {
      rethrow; // Rethrow FirebaseAuthException to be caught by UI layer
    } on EmailNotVerifiedException {
      rethrow; // Rethrow custom exception
    } on AccountNotApprovedException {
      rethrow; // Rethrow custom exception
    } on UserProfileNotFoundException {
      rethrow; // Rethrow custom exception
    } catch (e) {
      print('AuthService SignIn Error: $e');
      rethrow; // Rethrow any other unexpected errors
    }
  }

  // --- Student Sign-Up ---
  Future<void> signUpStudent({
    required String name,
    required String email,
    required String password,
    required String institution, // Corrected from studentId
    required String address,     // Added from student_signup_page
    required String age,         // Added from student_signup_page
    required String parentsMobile, // Added from student_signup_page
    required String currentClass, // Added from student_signup_page
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Store user profile (common for all user types)
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'userId': user.uid,
          'userType': 'student',
          'email': email,
          'name': name,
          'isApproved': false, // Initially false, requires admin approval
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Store student-specific profile
        await _firestore.collection('students').doc(user.uid).set({
          'name': name,
          'email': email,
          'institution': institution,
          'address': address,
          'age': age,
          'parentsMobile': parentsMobile,
          'currentClass': currentClass,
          'registeredAt': FieldValue.serverTimestamp(),
          'isApproved': false, // Duplicate for clarity, but user_profiles is primary
        });
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print('AuthService SignUpStudent Error: $e');
      rethrow;
    }
  }

  // --- Tutor Sign-Up ---
  Future<void> signUpTutor({
    required String name,
    required String email,
    required String password,
    required List<String> subjects,
    required String educationBackground,
    required double experience,
    required double ratePerHour,
    required String availability,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Store user profile (common for all user types)
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'userId': user.uid,
          'userType': 'tutor',
          'email': email,
          'name': name,
          'isApproved': false, // Initially false, requires admin approval
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Store tutor-specific profile
        await _firestore.collection('tutors').doc(user.uid).set({
          'name': name,
          'email': email,
          'subjects': subjects,
          'educationBackground': educationBackground,
          'experience': experience,
          'ratePerHour': ratePerHour,
          'availability': availability,
          'rating': 0.0, // Initial rating
          'registeredAt': FieldValue.serverTimestamp(),
          'isApproved': false, // Duplicate for clarity, but user_profiles is primary
        });
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print('AuthService SignUpTutor Error: $e');
      rethrow;
    }
  }

  // --- NEW: Admin Sign-Up ---
  Future<void> signUpAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send email verification (optional for admin, but good practice)
        await user.sendEmailVerification();

        // Store user profile (common for all user types)
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'userId': user.uid,
          'userType': 'admin',
          'email': email,
          'name': name,
          'isApproved': true, // Admins are automatically approved
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Optionally, create a separate 'admins' collection for specific admin data or roles
        await _firestore.collection('admins').doc(user.uid).set({
          'name': name,
          'email': email,
          'registeredAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print('AuthService SignUpAdmin Error: $e');
      rethrow;
    }
  }

  // --- Send Password Reset Email ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print('AuthService SendPasswordResetEmail Error: $e');
      rethrow;
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- Stream for Auth State Changes ---
  Stream<User?> get user => _auth.authStateChanges();

  // --- Reload User for Email Verification Check ---
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}