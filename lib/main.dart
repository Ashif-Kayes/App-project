import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'tutor_signup.dart';
import 'tutor_login.dart';
import 'tutor_dashboard.dart';
import 'student_signup.dart';
import 'student_login.dart';
import 'student_dashboard.dart';
import 'firebase_options.dart';
import 'welcome.dart';
import 'theme_notifier.dart';
import 'verify_email_page.dart';
import 'pending_approval_page.dart';
import 'admin_dashboard_page.dart';
//import 'admin_signup_page.dart'; // Still commented out as per your request
import 'admin_login_page.dart';
import 'student_info.dart';
import 'teacher_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const TutorFinderApp(),
    ),
  );
}

class TutorFinderApp extends StatelessWidget {
  const TutorFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Tutor Finder',
      themeMode: themeNotifier.currentMode,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.purple),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.purple, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.purple),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
      darkTheme: ThemeData.dark(),
      home: const WelcomePage(),
      routes: {
        '/tutor_dashboard': (context) => const TutorDashboardPage(),
        '/student_dashboard': (context) => const StudentDashboardPage(),
        '/tutor_signup': (context) => const TutorSignUpPage(),
        '/student_signup': (context) => const StudentSignUpPage(),
        '/tutor_login': (context) => const TutorLoginPage(),
        '/student_login': (context) => const StudentLoginPage(),
        '/main': (context) => const AuthWrapper(),
        '/verify_email': (context) => const VerifyEmailPage(),
        '/pending_approval': (context) => const PendingApprovalPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        //'/admin_signup': (context) => const AdminSignUpPage(),
        '/admin_login': (context) => const AdminLoginPage(),
        '/student_info': (context) => const StudentInfoPage(),
        '/teacher_info': (context) => const TeacherInfoPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Error loading user data.')));
        }

        final user = snapshot.data;

        if (user != null) {
          if (!user.emailVerified) return const VerifyEmailPage();

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).get(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (profileSnapshot.hasError) {
                return const Scaffold(body: Center(child: Text('Error fetching profile. Please try again.')));
              }

              if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                final data = profileSnapshot.data!.data() as Map<String, dynamic>;
                final userType = data['userType'];
                final bool isApproved = data['isApproved'] ?? false;

                if (!isApproved) return const PendingApprovalPage();
                if (userType == 'student') return const StudentDashboardPage();
                if (userType == 'tutor') return const TutorDashboardPage();
                if (userType == 'admin') return const AdminDashboardPage();

                return const Scaffold(body: Center(child: Text('Unknown user type. Please contact support.')));
              }
              return const Scaffold(body: Center(child: Text('User profile data missing.')));
            },
          );
        } else {
          return const MainPage();
        }
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<String> slideImages = [
    'assets/images/slide1.jpg',
    'assets/images/slide2.jpg',
    'assets/images/slide3.jpg',
    'assets/images/slide4.jpg',
  ];

  final List<String> options = [
    'Tutor Sign Up',
    'Student Sign Up',
    'Tutor Login',
    'Student Login',
    //'Admin Sign Up',
    'Admin Login',
    'Back to Welcome Page',
  ];

  final List<String> routes = [
    '/tutor_signup',
    '/student_signup',
    '/tutor_login',
    '/student_login',
    //'/admin_signup',
    '/admin_login',
    'POP_TO_WELCOME',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Finder Home')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          ProfessionalImageSlider(
            images: slideImages,
            height: 220,
            viewportFraction: 0.7,
          ),
          const SizedBox(height: 16),
          const Text(
            "Choose Your Role",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                final label = options[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(label),
                    onPressed: () {
                      if (route == 'POP_TO_WELCOME') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomePage()),
                              (route) => false,
                        );
                      } else {
                        Navigator.pushNamed(context, route);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      minimumSize: const Size(double.infinity, 60),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfessionalImageSlider extends StatefulWidget {
  final List<String> images;
  final double height;
  final double viewportFraction;

  const ProfessionalImageSlider({
    super.key,
    required this.images,
    this.height = 120,
    this.viewportFraction = 0.7,
  });

  @override
  State<ProfessionalImageSlider> createState() => _ProfessionalImageSliderState();
}

class _ProfessionalImageSliderState extends State<ProfessionalImageSlider> {
  late final PageController _pageController;
  int currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction, initialPage: currentPage);
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentPage < widget.images.length - 1) {
        currentPage++;
      } else {
        currentPage = 0;
      }
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
              } else {
                value = index == 0 ? 1.0 : 0.7;
              }
              final scale = Curves.easeOut.transform(value);
              final opacity = value;

              return Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          widget.images[index],
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: widget.height,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}