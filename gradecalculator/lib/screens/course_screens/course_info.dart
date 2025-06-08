import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradecalculator/components/customsnackbar.dart';
import 'package:gradecalculator/providers/course_provider.dart';
import 'package:provider/provider.dart';
import 'package:gradecalculator/screens/component_screen/add_component.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradecalculator/models/components.dart';
import 'package:gradecalculator/models/records.dart';

class CourseInfo extends StatefulWidget {
  const CourseInfo({super.key});

  @override
  State<CourseInfo> createState() => _CourseInfoState();
}

class _CourseInfoState extends State<CourseInfo> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final course = courseProvider.selectedCourse;

        return Scaffold(
          backgroundColor: const Color(0xFF121212), 
          appBar: _buildAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourseHeader(course, height),
                    SizedBox(height: height * 0.03),
                    _buildComponentsSection(course, height, width),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          
          Navigator.of(context).pop();
        },
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context).push(_createSlideRoute()),
      backgroundColor: const Color(0xFF6200EE),
      tooltip: 'Add Component',
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  PageRouteBuilder _createSlideRoute() {
    return PageRouteBuilder(
      pageBuilder:
          (context, animation, secondaryAnimation) => const AddComponent(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Widget _buildCourseHeader(dynamic course, double height) {
    if (course == null) return const SizedBox.shrink();

    String gradeDisplay;
    if (course.numericalGrade != null && course.grade != null) {
      final actual = course.grade!;
      
      if (course.wasRounded == true) {
        // show rounded value only if found in the second pass
        final rounded = (actual % 1 >= 0.5) ? actual.ceil() : actual.floor();
        gradeDisplay = "${course.numericalGrade} (${actual.toStringAsFixed(2)}% → ${rounded}%)";
      } else {
        
        gradeDisplay = "${course.numericalGrade} (${actual.toStringAsFixed(2)}%)";
      }
    } else if (course.grade != null) {
      gradeDisplay = "${course.grade!.toStringAsFixed(2)}%";
    } else {
      gradeDisplay = "No grade yet";
    }

    final headerItems = [
      (
        course.courseCode,
        height * 0.04,
        FontWeight.w800,
        const Color(0xFF6200EE),
      ),
      (course.courseName, height * 0.024, FontWeight.normal, Colors.white70),
      (course.instructor, height * 0.018, FontWeight.normal, Colors.white70),
      (
        gradeDisplay,
        height * 0.018,
        FontWeight.normal,
        Colors.white70,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          headerItems
              .map(
                (item) => Text(
                  item.$1.toString(),
                  style: GoogleFonts.poppins(
                    color: item.$4,
                    fontWeight: item.$3,
                    fontSize: item.$2,
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildComponentsSection(dynamic course, double height, double width) {
    if (course == null) {
      return const Center(child: Text("No course selected"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.001),
        _buildComponentsStream(course.courseId, height, width),
      ],
    );
  }

  Widget _buildComponentsStream(String courseId, double height, double width) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('components')
              .where('courseId', isEqualTo: courseId)
              .snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Column(
            children: [
              SizedBox(height: height * 0.15),
              const Center(child: CircularProgressIndicator()),
              SizedBox(height: height * 0.02),
              Center(
                child: Text(
                  "Loading components...",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: height * 0.016,
                  ),
                ),
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(height);
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                final component = Component.fromMap(
                  doc.data() as Map<String, dynamic>,
                );
                return _buildComponentCard(component, height, width);
              }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(double height) {
    return Column(
      children: [
        SizedBox(height: height * 0.18), 
        Center(
          child: Text(
            "No components added yet.",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: height * 0.020,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentCard(Component component, double height, double width) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: height * 0.008),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Stack(
        children: [
         
          ListTile(
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.fromLTRB(
              height * 0.020,
              height * 0.010,
              height * 0.020, 
              height * 0.010,
            ),
            title: Text(
              "${component.componentName} (${component.weight.toStringAsFixed(2)}%)",
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: height * 0.018,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _buildRecordsList(component, height),
          ),
          
          _buildComponentActionButtons(component, height, width),
        ],
      ),
    );
  }

  Widget _buildRecordsList(Component component, double height) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('records')
              .where('componentId', isEqualTo: component.componentId)
              .snapshots(),
      builder: (context, snapshot) {
     
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingText(height);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoRecordsText(height);
        }

        final recordsList =
            snapshot.data!.docs
                .map(
                  (doc) => Records.fromMap(doc.data() as Map<String, dynamic>),
                )
                .toList();

        final (totalScore, totalPossible) = _calculateTotals(recordsList);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...recordsList.map((record) => _buildRecordRow(record, height)),
            if (recordsList.isNotEmpty)
              _buildTotalSection(totalScore, totalPossible, height, component),
          ],
        );
      },
    );
  }

  Widget _buildLoadingText(double height) {
    return Text(
      "Loading records...",
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: height * 0.014,
      ),
    );
  }

  Widget _buildNoRecordsText(double height) {
    return Text(
      "No records yet",
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: height * 0.014,
      ),
    );
  }

  (double, double) _calculateTotals(List<Records> records) {
    double totalScore = 0;
    double totalPossible = 0;

    for (final record in records) {
      totalScore += record.score;
      totalPossible += record.total;
    }

    return (totalScore, totalPossible);
  }

  Widget _buildTotalSection(
    double totalScore,
    double totalPossible,
    double height,
    Component component,
  ) {
   
    final componentPercentage =
        totalPossible > 0 ? (totalScore / totalPossible) * 100 : 0.0;


    final normalizedScore = componentPercentage * (component.weight / 100);

    return Column(
      children: [
        SizedBox(height: height * 0.008),
        Container(
          height: 1,
          color: Colors.white30,
          margin: EdgeInsets.symmetric(vertical: height * 0.004),
        ),
        Padding(
          padding: EdgeInsets.only(top: height * 0.004),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            
              Text(
                "${totalScore.toStringAsFixed(2)}/${totalPossible.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: height * 0.014,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: height * 0.012), 
              
              Text(
                "(${normalizedScore.toStringAsFixed(2)}%)",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: height * 0.014,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordRow(Records record, double height) {
    return Padding(
      padding: EdgeInsets.only(top: height * 0.004),
      child: Row(
        children: [
          Expanded(
            child: Text(
              record.name,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: height * 0.014,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "${record.score.toStringAsFixed(2)}/${record.total.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: height * 0.014,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    double height,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Transform.translate(
      offset: icon == Icons.edit ? Offset(height * 0.037, 0) : Offset.zero,
      child: IconButton(
        icon: Icon(icon, size: height * 0.017),
        color: Colors.white30,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: height * 0.020,
          minHeight: height * 0.020,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildComponentActionButtons(
    Component component,
    double height,
    double width,
  ) {
    return Positioned(
      top: height * 0.005,
      right: height * 0.005,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            Icons.edit,
            height,
            'Edit Component',
            () => _navigateToEditComponent(component), 
          ),
          SizedBox(width: width * 0.02),
          _buildActionButton(
            Icons.delete,
            height,
            'Delete Component',
            () => _showDeleteComponentDialog(component),
          ),
        ],
      ),
    );
  }


  void _navigateToEditComponent(Component component) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => AddComponent(
              componentToEdit: component, 
            ),
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

  void _showDeleteComponentDialog(Component component) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Delete Component',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${component.componentName}"? This action cannot be undone.',
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
                onPressed: () => _handleDeleteComponent(component),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleDeleteComponent(Component component) async {
    Navigator.of(context).pop();
    await _deleteComponent(component);
  }

  Future<void> _deleteComponent(Component component) async {
    try {
      _showLoadingDialog();

      final batch = FirebaseFirestore.instance.batch();

      
      final recordsQuery =
          await FirebaseFirestore.instance
              .collection('records')
              .where('componentId', isEqualTo: component.componentId)
              .get();

      for (final doc in recordsQuery.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(
        FirebaseFirestore.instance
            .collection('components')
            .doc(component.componentId),
      );

      await batch.commit();

      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );

      await courseProvider.removeComponentAndUpdateGrade(component.componentId);

      if (mounted) {
        _hideLoadingDialog();
        _showSuccessMessage(component.componentName);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorMessage(e.toString());
      }
      print("Error deleting component: $e");
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

  void _showSuccessMessage(String componentName) {
    showCustomSnackbar(
      context,
      'Component "$componentName" deleted successfully',
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorMessage(String error) {
    showCustomSnackbar(
      context,
      'Error deleting component: $error',
      duration: const Duration(seconds: 2),
    );
  }
}
