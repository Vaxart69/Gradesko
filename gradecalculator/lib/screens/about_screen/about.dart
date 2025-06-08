import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradecalculator/providers/auth_provider.dart';
import 'package:gradecalculator/screens/auth_screens/starting_page.dart';
import 'package:provider/provider.dart';
import 'package:gradecalculator/components/customsnackbar.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double height = size.height;
    final double width = size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height * 0.02),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: height * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      const TextSpan(text: "ABOUT "),
                      TextSpan(
                        text: "THE APP.",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6200EE),
                          fontWeight: FontWeight.bold,
                          fontSize: height * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
                _AboutContent(height),
                SizedBox(height: height * 0.03),
                _CustomPurpleButton(
                  text: "Logout",
                  onPressed: () async {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StartingPage(),
                        ),
                      );
                    }
                  },
                  width: size.width * 0.8,
                  height: size.height * 0.06,
                  backgroundColor: const Color(0xFF6200EE), 
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: height * 0.015),
                  child: Center(
                    child: Text(
                      "or",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: height * 0.018,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                _CustomPurpleButton(
                  text: "Delete Account",
                  onPressed: _showDeleteAccountDialog,
                  width: size.width * 0.8,
                  height: size.height * 0.06,
                  backgroundColor: const Color(0xFFCF6C79), 
                ),
                SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Delete Account',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete your account? This will permanently delete:\n\n'
              '• Your account and profile\n'
              '• All your courses\n'
              '• All components and records\n'
              '• All grading systems\n\n'
              'This action cannot be undone.',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: _handleDeleteAccount,
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    Navigator.of(context).pop(); 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await context.read<AuthProvider>().deleteAccount();

      if (mounted) {
        Navigator.of(context).pop(); 

        if (result == null) {
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StartingPage()),
            (route) => false,
          );
        } else {
         
          showCustomSnackbar(
            context,
            result,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); 
        showCustomSnackbar(
          context,
          'Error deleting account: $e',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}

Widget _AboutContent(double height) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: height * 0.02),
      Text(
        "Gradesko is a simple and intuitive grade calculator app that helps students manage their courses, define custom grading systems, and compute grades with ease. All data is securely stored online using cloud services, which means an internet connection is required to use the app.",
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: height * 0.018,
        ),
        textAlign: TextAlign.justify,
      ),
      SizedBox(height: height * 0.025),
      Text(
        "How to use Gradesko:",
        style: GoogleFonts.poppins(
          color: Color(0xFF6200EE),
          fontWeight: FontWeight.bold,
          fontSize: height * 0.022,
        ),
        textAlign: TextAlign.justify,
      ),
      SizedBox(height: height * 0.01),
      Text(
        "1. Press the add button to create a course\n"
        "2. Input the course information\n"
        "3. For failing grades (e.g., < 55), set the range from 0 to your cutoff. For this example, 0 to 54\n"
        "4. Add grading components (e.g., quizzes, exams) and assign their weights.\n"
        "5. Enter your scores for each component as you progress.\n"
        "6. The app will automatically compute your current grade based on your inputs.\n",
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: height * 0.018,
        ),
      ),
      Text(
        "Why do we have an authentication system?",
        style: GoogleFonts.poppins(
          color: Color(0xFF6200EE),
          fontWeight: FontWeight.bold,
          fontSize: height * 0.020,
        ),
      ),
      SizedBox(height: height * 0.01),
      Text(
        "Because my knowledge for backend development is limited, I used Firebase Authentication to allow users to save their courses and grades. This way, you can access your data across multiple devices without losing your data.",
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: height * 0.018,
        ),
      ),
      SizedBox(height: height * 0.02),

      Text(
        "- Russell Velasco, 2025",
        style: GoogleFonts.poppins(
          color: Colors.white38,
          fontSize: height * 0.016,
        ),
      ),
    ],
  );
}

Widget _CustomPurpleButton({
  required String text,
  required VoidCallback onPressed,
  required double width,
  required double height,
  Color backgroundColor = const Color(0xFF6200EE),
}) {
  return Center(
    child: SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: height * 0.33,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
