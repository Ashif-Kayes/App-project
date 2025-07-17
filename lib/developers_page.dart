import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart'; // Make sure this path is correct

class DevelopersPage extends StatelessWidget {
  const DevelopersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define the new gradient colors to match the screenshot's background
    final List<Color> screenshotBackgroundColors = [
      Color(0xFFE0F7FA), // A very light cyan/teal
      Color(0xFFB2EBF2), // A slightly deeper light cyan/teal
    ];

    // Your existing gradients (can be kept for other pages if needed, but not used here)
    final List<Color> lightGradientColors = [
      Colors.white,
      Colors.purple,
    ];

    final List<Color> darkGradientColors = [
      Colors.grey.shade900,
      Colors.blueGrey.shade900,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Developers'),
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0, // Remove shadow
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // Use the new screenshot background colors for the App Bar
              colors: screenshotBackgroundColors,
            ),
          ),
        ),
        // Adjust text color for app bar title and back button based on global theme
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Use the new screenshot background colors for the Body
            colors: screenshotBackgroundColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Optional: Theme toggle button if you want it on this page too
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
                  const SizedBox(height: 30),
                  Text(
                    "Meet the Team",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      // Text color still adapts to the global theme
                      color: isDarkMode ? Colors.white : Colors.deepPurple, // Changed to a specific color for contrast
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildDeveloperInfo(
                    context,
                    imagePath: 'assets/kayes.jpg', // <--- Add developer image path here
                    name: "Md. Ashif Mahmud Kayes",
                    email: "ashifsarkar28@gmail.com",
                    details: "A passionate Flutter developer with expertise in UI/UX design and frontend integration.",
                    isDarkMode: isDarkMode,
                  ),
                  // Commented out Tabassum Kabir's details



                  // Commented out Swapon Chandra Ray's details

                  const SizedBox(height: 20),
                  _buildDeveloperInfo(
                    context,
                    imagePath: 'assets/swapon.jpg', // <--- Add developer image path here
                    name: "Swapon Chandra Ray",
                    email: "swaponbarman44@gmail.com",
                    details: "Passionate about crafting high-quality code and designing future-proof application architecture.",
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 20),
                  _buildDeveloperInfo(
                    context,
                    imagePath: 'assets/tabassum.jpg', // <--- Add developer image path here
                    name: "Tabassum Kabir",
                    email: "sanjidaakter2310@gmail.com",
                    details: "Specializes in database management and API development for seamless data flow.",
                    isDarkMode: isDarkMode,
                  ),

                  // Commented out Akash Biswas's details

                  const SizedBox(height: 20),
                  _buildDeveloperInfo(
                    context,
                    imagePath: 'assets/akash.jpg', // <--- Add developer image path here
                    name: "Akash Biswas",
                    email: "ts8870110@gmail.com",
                    details: "Contributed to the design and user experience.",
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous page
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: isDarkMode ? Colors.blueGrey.shade700 : Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: (isDarkMode ? Colors.blueGrey.shade700 : Colors.deepPurpleAccent).withOpacity(0.4),
                    ),
                    child: const Text(
                      "Back to Welcome",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(BuildContext context, {
    required String imagePath, // <--- New parameter for image path
    required String name,
    required String email,
    required String details,
    required bool isDarkMode
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withOpacity(0.7) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Conditionally display CircleAvatar with image or icon
          CircleAvatar(
            radius: 100, // Radius increased to 100 for a much larger image
            backgroundColor: isDarkMode ? Colors.blueGrey.shade600 : Colors.deepPurple.shade100, // Background if image not full circle
            // Check if imagePath is not empty to attempt loading the image
            backgroundImage: imagePath.isNotEmpty ? AssetImage(imagePath) : null,
            child: imagePath.isEmpty
                ? Icon(
              Icons.person,
              size: 120, // Icon size adjusted to match the larger circle
              color: isDarkMode ? Colors.white70 : Colors.deepPurple.shade400,
            )
                : null, // If imagePath is not empty, no child icon is needed
          ),
          const SizedBox(height: 10), // Space between image/icon and name
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.blueGrey[300] : Colors.blueGrey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}