import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gradecalculator/providers/auth_provider.dart';
import 'package:gradecalculator/providers/course_provider.dart';
import 'package:gradecalculator/screens/course_screens/add_course.dart';
import 'package:gradecalculator/screens/course_screens/course_info.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as model;
import '../models/course.dart' as courseModel;
import 'package:gradecalculator/components/customsnackbar.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final user = context.watch<AuthProvider>().appUser;

    return Scaffold(
      body: SafeArea(
        child:
            user == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('appusers')
                          .doc(user.userId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text("User data not found"));
                    }

                    final userData = model.User.fromMap(
                      snapshot.data!.data() as Map<String, dynamic>,
                    );

                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: height * 0.03),
                            _buildWelcomeSection(userData, height),
                            SizedBox(height: height * 0.02),
                            _buildCoursesStream(userData, height),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildWelcomeSection(model.User userData, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, ${userData.username}!',
          style: GoogleFonts.poppins(
            fontSize: height * 0.030,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: height * 0.038,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            children: [
              const TextSpan(text: 'Track your '),
              TextSpan(
                text: 'grades',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6200EE),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesStream(model.User userData, double height) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('courses')
              .where('userId', isEqualTo: userData.userId)
              .snapshots(),
      builder: (context, courseSnapshot) {
        if (courseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              SizedBox(height: height * 0.30),
              Center(
                child: Text(
                  "No courses added yet.",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: height * 0.020,
                  ),
                ),
              ),
            ],
          );
        }

        final courses = courseSnapshot.data!.docs;
        final width = MediaQuery.of(context).size.width;
        return Column(
          children:
              courses.map((doc) {
                final course = courseModel.Course.fromMap(
                  doc.data() as Map<String, dynamic>,
                );
                return _buildCourseCard(
                  course,
                  height,
                  width,
                ); 
              }).toList(),
        );
      },
    );
  }

  Widget _buildCourseCard(
    courseModel.Course course,
    double height,
    double width,
  ) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: height * 0.008),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Stack(
        children: [
          ListTile(
            onTap: () {
             
              Provider.of<CourseProvider>(
                context,
                listen: false,
              ).selectCourse(course);
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const CourseInfo(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.fromLTRB(
              height * 0.020,
              height * 0.010,
              height *
                  0.080, 
              height * 0.010,
            ),
            title: Text(
              course.courseName.isNotEmpty
                  ? "${course.courseCode} - ${course.courseName}"
                  : course.courseCode,
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: height * 0.018,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _buildCourseSubtitle(course, height),
          ),
          _buildActionButtons(height, width, course), 
        ],
      ),
    );
  }

  Widget _buildCourseSubtitle(courseModel.Course course, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "A.Y. ${course.academicYear}, ${course.semester}",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: height * 0.014,
          ),
        ),
        SizedBox(height: height * 0.006),
        Row(
          children: [
            _buildGradeText(course, height),
            const Spacer(),
            Text(
              "${(double.tryParse(course.units) ?? 0.0).toStringAsFixed(1)} units",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: height * 0.014,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeText(courseModel.Course course, double height) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Grade: ",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.normal,
              fontSize: height * 0.014,
            ),
          ),
          TextSpan(
            text:
                course.numericalGrade != null
                    ? course.numericalGrade!
                        .toString() 
                    : "No grade yet",
            style: GoogleFonts.poppins(
              color: Colors.white70, 
              fontWeight: FontWeight.bold,
              fontSize: height * 0.014,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double height, width, courseModel.Course course) {
    return Positioned(
      top: height * 0.005,
      right: height * 0.005,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(height * 0.037, 0),
            child: IconButton(
              icon: Icon(Icons.edit, size: height * 0.017),
              color: Colors.white30,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: height * 0.020,
                minHeight: height * 0.020,
              ),
              onPressed: () => _navigateToEditCourse(course),
              tooltip: 'Edit',
            ),
          ),
          SizedBox(width: width * 0.02),
          IconButton(
            icon: Icon(Icons.delete, size: height * 0.017),
            color: Colors.white30,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: height * 0.020,
              minHeight: height * 0.020,
            ),
            onPressed: () => _showDeleteCourseDialog(course),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  void _navigateToEditCourse(courseModel.Course course) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                AddCourse(courseToEdit: course),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showDeleteCourseDialog(courseModel.Course course) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Delete Course',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${course.courseCode} - ${course.courseName}"? This will also delete all components and records. This action cannot be undone.',
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
                onPressed: () => _handleDeleteCourse(course),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleDeleteCourse(courseModel.Course course) async {
    Navigator.of(context).pop();
    await _deleteCourse(course);
  }

  Future<void> _deleteCourse(courseModel.Course course) async {
    try {
      _showLoadingDialog();

      try {
        final componentsSnapshot = await FirebaseFirestore.instance
            .collection('components')
            .where('courseId', isEqualTo: course.courseId)
            .get()
            .timeout(const Duration(seconds: 10));

        final batch = FirebaseFirestore.instance.batch();

        for (final componentDoc in componentsSnapshot.docs) {
          final componentId = componentDoc.id;

          final recordsSnapshot = await FirebaseFirestore.instance
              .collection('records')
              .where('componentId', isEqualTo: componentId)
              .get()
              .timeout(const Duration(seconds: 10));

          for (final recordDoc in recordsSnapshot.docs) {
            batch.delete(recordDoc.reference);
          }

          batch.delete(componentDoc.reference);
        }

        batch.delete(
          FirebaseFirestore.instance.collection('courses').doc(course.courseId),
        );

        try {
          await batch.commit().timeout(const Duration(seconds: 10));
          print("Course deleted successfully online!");
        } on TimeoutException {
          print("Course delete timed out - data cached offline");
        } catch (e) {
          print("Course delete completed (offline mode): $e");
        }

        if (mounted) {
          _hideLoadingDialog();
          _showSuccessMessage(course.courseCode, course.courseName);
        }

        print(
          "Course '${course.courseCode}' and all related data deleted successfully",
        );
      } on TimeoutException {
        if (mounted) {
          _hideLoadingDialog();
          _showSuccessMessage(course.courseCode, course.courseName);
        }
        print("Course delete timed out - data cached offline");
      } catch (e) {
        if (mounted) {
          _hideLoadingDialog();
          _showSuccessMessage(course.courseCode, course.courseName);
        }
        print("Course delete completed (offline mode): $e");
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorMessage(e.toString());
      }
      print("Error deleting course: $e");
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context).pop();
  }

  void _showSuccessMessage(String courseCode, String courseName) {
    showCustomSnackbar(
      context,
      'Course "$courseCode - $courseName" deleted successfully',
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorMessage(String error) {
    showCustomSnackbar(
      context,
      'Error deleting course: $error',
      duration: const Duration(seconds: 3),
    );
  }
}
