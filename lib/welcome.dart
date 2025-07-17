import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'developers_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation; // Animation for the text

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Duration for all animations
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Text animation: directly from off-screen left (-300) to center (0)
    _textAnimation = Tween<double>(begin: -300, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic), // Start later, end before logo, use a smoother curve
      ),
    );

    // Start the animation when the widget is initialized
    _controller.forward(); // Play once

    // Add a listener to stop the controller once it completes, stopping all animations
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateToMainPage() {
    Navigator.pushNamed(context, '/main');
  }

  void navigateToDevelopersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DevelopersPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Color> lightGradientColors = [
      Colors.white,
      Colors.purple,
    ];

    final List<Color> darkGradientColors = [
      Colors.grey.shade900,
      Colors.blueGrey.shade900,
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? darkGradientColors : lightGradientColors,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: Icon(
                                Provider.of<ThemeNotifier>(context).isDark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              onPressed: () {
                                Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
                              },
                              tooltip: 'Toggle Theme',
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _logoAnimation.value),
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/logo.png',
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: 80),

                          Text(
                            "Welcome to Tutor Finder",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // এই SizedBox এর height আরও কমিয়েছি, প্রায় শূন্য
                          const SizedBox(height: 2), // Reduced from 5 to 2
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_textAnimation.value, 0),
                                child: child,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                "Are you facing problems to find a proper tutor for you? Don't worry! Find your perfect tutor easily by this app. Our platform connects students with verified tutors. ",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),

                          Padding(
                            // horizontal padding আরও বাড়িয়েছি বাটনগুলো আরও ছোট করার জন্য
                            padding: const EdgeInsets.symmetric(horizontal: 100.0), // Increased from 80 to 100
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: navigateToDevelopersPage,
                                    style: ElevatedButton.styleFrom(
                                      // vertical padding আরও কমিয়েছি বাটনগুলোর height কমানোর জন্য
                                      padding: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      backgroundColor: isDarkMode ? Colors.blueGrey.shade700 : Colors.deepPurpleAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: (isDarkMode ? Colors.blueGrey.shade700 : Colors.deepPurpleAccent).withOpacity(0.4),
                                    ),
                                    child: const Text(
                                      "About Developers",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: navigateToMainPage,
                                    style: ElevatedButton.styleFrom(
                                      // vertical padding আরও কমিয়েছি
                                      padding: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                                    ),
                                    child: const Text(
                                      "Get Started",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}