import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradecalculator/components/custom_text_form_field.dart';
import 'package:gradecalculator/components/mainscaffold.dart';
import 'package:gradecalculator/models/components.dart';
import 'package:gradecalculator/models/course.dart';
import 'package:gradecalculator/models/grade_range.dart';
import 'package:gradecalculator/models/grading_system.dart';
import 'package:gradecalculator/providers/course_provider.dart';
import 'package:provider/provider.dart';
import 'package:gradecalculator/providers/auth_provider.dart';
import 'package:gradecalculator/components/customsnackbar.dart'; 
import 'package:dropdown_button2/dropdown_button2.dart'; 

class AddCourse extends StatefulWidget {
  final Course? courseToEdit; 

  const AddCourse({super.key, this.courseToEdit}); 

  @override
  State<AddCourse> createState() => _AddCourseState();
}

class _AddCourseState extends State<AddCourse> {
  // Constants
  static const List<String> _semesters = [
    '1st Semester',
    '2nd Semester',
    'Midyear',
  ];
  static const Duration _saveTimeout = Duration(seconds: 10);

  // Course form data
  String? selectedSemester;
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _unitsController = TextEditingController();
  final _instructorController = TextEditingController();

  // Grade range data
  final List<GradeRange> _gradeRanges = [];
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};
  final Map<String, TextEditingController> _gradeControllers = {};

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadExistingData();
    } else {
      _addGradeRange(); 
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    final controllers = [
      _courseCodeController,
      _courseNameController,
      _academicYearController,
      _unitsController,
      _instructorController,
      ..._minControllers.values,
      ..._maxControllers.values,
      ..._gradeControllers.values,
    ];

    for (final controller in controllers) {
      controller.dispose();
    }
  }

  void _printGradeRangesDebug() {
    print('--- Current Grade Ranges ---');
    for (var range in _gradeRanges) {
      final min = _minControllers[range.rangeId]?.text ?? '';
      final max = _maxControllers[range.rangeId]?.text ?? '';
      final grade = _gradeControllers[range.rangeId]?.text ?? '';
      print(
        'RangeId: ${range.rangeId} | Min: $min | Max: $max | Grade: $grade',
      );
    }
    print('----------------------------');
  }

  void _addGradeRange({String? gradingSystemId}) {
    setState(() {
      final rangeId = DateTime.now().millisecondsSinceEpoch.toString();
      final newRange = GradeRange(
        rangeId: rangeId,
        gradingSystemId: gradingSystemId ?? '',
        min: 0,
        max: 100,
        grade: 0.0,
      );

      _gradeRanges.add(newRange);
      _minControllers[rangeId] = TextEditingController();
      _maxControllers[rangeId] = TextEditingController();
      _gradeControllers[rangeId] = TextEditingController();
      _printGradeRangesDebug();
    });
  }

  void _removeGradeRange(int index) {
    setState(() {
      final rangeId = _gradeRanges[index].rangeId;

      // Dispose and remove controllers
      _minControllers[rangeId]?.dispose();
      _maxControllers[rangeId]?.dispose();
      _gradeControllers[rangeId]?.dispose();
      _minControllers.remove(rangeId);
      _maxControllers.remove(rangeId);
      _gradeControllers.remove(rangeId);

      _gradeRanges.removeAt(index);
      _printGradeRangesDebug();
    });
  }

  Course _createCourse(String courseId, String userId) {
    final updatedGradeRanges =
        _gradeRanges
            .map(
              (range) => GradeRange(
                rangeId: range.rangeId,
                gradingSystemId: courseId,
                min:
                    double.tryParse(
                      _minControllers[range.rangeId]?.text ?? '',
                    ) ??
                    0.0, 
                max:
                    double.tryParse(
                      _maxControllers[range.rangeId]?.text ?? '',
                    ) ??
                    0.0, 
                grade:
                    double.tryParse(
                      _gradeControllers[range.rangeId]?.text ?? '',
                    ) ??
                    0.0,
              ),
            )
            .toList();

    final gradingSystem = GradingSystem(
      gradingSystemId: courseId,
      courseId: courseId,
      gradeRanges: updatedGradeRanges,
    );

    return Course(
      courseId: courseId,
      userId: userId,
      courseName: _courseNameController.text,
      courseCode: _courseCodeController.text,
      units: _unitsController.text,
      instructor: _instructorController.text,
      academicYear: _academicYearController.text,
      semester: selectedSemester ?? '',
      gradingSystem: gradingSystem,
      components: [],
    );
  }

  bool get isEditMode => widget.courseToEdit != null; 

  
  void _loadExistingData() {
    final course = widget.courseToEdit!;

    _courseCodeController.text = course.courseCode;
    _courseNameController.text = course.courseName;
    _academicYearController.text = course.academicYear;
    _unitsController.text = course.units;
    _instructorController.text = course.instructor!;
    selectedSemester = course.semester;

    setState(() {
      _gradeRanges.clear();
      _minControllers.clear();
      _maxControllers.clear();
      _gradeControllers.clear();

      if (course.gradingSystem.gradeRanges.isEmpty) {
        _addGradeRange();
      } else {
        for (final range in course.gradingSystem.gradeRanges) {
          _gradeRanges.add(range);
          _minControllers[range.rangeId] = TextEditingController(
            text: range.min.toString(),
          );
          _maxControllers[range.rangeId] = TextEditingController(
            text: range.max.toString(),
          );
          _gradeControllers[range.rangeId] = TextEditingController(
            text: range.grade.toString(),
          );
        }
      }
    });
  }

  Future<void> _saveCourseToFirestore() async {
    try {
      if (isEditMode) {
        await _updateExistingCourse();
      } else {
        await _createNewCourse();
      }
    } catch (e) {
      print("Error saving course: $e");
    }
  }

  Future<void> _createNewCourse() async {
    final docRef = FirebaseFirestore.instance.collection('courses').doc();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.appUser?.userId ?? '';
    final course = _createCourse(docRef.id, userId);

    await docRef.set(course.toMap()).timeout(_saveTimeout);
    print("Course saved successfully online!");
  }

  Future<void> _updateExistingCourse() async {
    final existingCourse = widget.courseToEdit!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.appUser?.userId ?? '';
    final updatedCourse = _createCourse(existingCourse.courseId, userId);

    await FirebaseFirestore.instance
        .collection('courses')
        .doc(existingCourse.courseId)
        .update(updatedCourse.toMap())
        .timeout(_saveTimeout);
    
    
    await _recalculateGradesAfterEdit(existingCourse.courseId);
    
    print("Course updated successfully online!");
  }

  
  Future<void> _recalculateGradesAfterEdit(String courseId) async {
    try {
      
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      
      
      final updatedCourseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get()
          .timeout(_saveTimeout);
      
      if (updatedCourseDoc.exists) {
        final updatedCourse = Course.fromMap(updatedCourseDoc.data()!);
        
     
        final components = await courseProvider.loadCourseComponents(courseId);
        
      
        courseProvider.selectCourse(updatedCourse);
     
        await courseProvider.updateCourseGrade(components: components.cast<Component?>());
        
        print("Grades recalculated with updated grading system and ${components.length} components!");
      }
    } catch (e) {
      print("Error recalculating grades after course edit: $e");
    }
  }

  bool _validateGradingSystem() {
    bool isValid = true;
    for (var range in _gradeRanges) {
      final min = _minControllers[range.rangeId]?.text.trim() ?? '';
      final max = _maxControllers[range.rangeId]?.text.trim() ?? '';
      final grade = _gradeControllers[range.rangeId]?.text.trim() ?? '';
      if (min.isEmpty || max.isEmpty || grade.isEmpty) {
        isValid = false;
        break;
      }
    }
    return isValid && _gradeRanges.isNotEmpty;
  }

  Future<void> _handleSaveButton() async {
    final formValid = _formKey.currentState!.validate();
    final gradingValid = _validateGradingSystem();

    if (!formValid || !gradingValid) {
      if (!gradingValid) {
        showCustomSnackbar(
          context,
          'Please complete all grading system rows.',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }
    _showLoadingDialog();
    await _saveCourseToFirestore();
    if (mounted) {
      _dismissLoadingAndNavigate();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _dismissLoadingAndNavigate() {
    Navigator.of(context).pop(); 
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScaffold()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Form(
              key: _formKey, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(height),
                  SizedBox(height: height * 0.02),
                  _buildCourseFields(height),
                  SizedBox(height: height * 0.025),
                  _buildGradingSystem(height),
                  SizedBox(height: height * 0.015),
                  _buildSaveButton(size),
                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildTitle(double height) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: height * 0.04,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        children: [
          TextSpan(text: isEditMode ? "EDIT " : "ADD A  "),
          TextSpan(
            text: "COURSE.",
            style: GoogleFonts.poppins(
              color: const Color(0xFF6200EE),
              fontWeight: FontWeight.bold,
              fontSize: height * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseFields(double height) {
    return Column(
      children: [
        CustField(
          label: "Course Code",
          icon: Icons.article,
          hintText: "CMSC 23",
          controller: _courseCodeController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Course code is required';
            }
            return null;
          },
        ),
        SizedBox(height: height * 0.015),
        CustField(
          label: "Course Name (optional)",
          icon: Icons.menu_book,
          hintText: "Mobile Programming",
          controller: _courseNameController,
        ),
        SizedBox(height: height * 0.015),
        CustField(
          label: "Academic Year",
          icon: Icons.calendar_month,
          hintText: "2024-2025",
          controller: _academicYearController,
          keyboardType: TextInputType.number, 
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Academic year is required';
            }
            
            if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(value.trim())) {
              return 'Format: YYYY-YYYY';
            }
            return null;
          },
        ),
        SizedBox(height: height * 0.015),
        _buildSemesterDropdown(height),
        SizedBox(height: height * 0.015),
        CustField(
          label: "Units",
          icon: Icons.format_list_numbered,
          hintText: "3",
          controller: _unitsController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Units are required';
            }
            return null;
          },
        ),
        SizedBox(height: height * 0.015),
        CustField(
          label: "Instructor (optional)",
          icon: Icons.person,
          hintText: "Mx. Instructor",
          controller: _instructorController,
        ),
      ],
    );
  }

  Widget _buildSemesterDropdown(double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Semester",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: height * 0.02,
          ),
        ),
        SizedBox(height: height * 0.005),
        DropdownButtonFormField2<String>(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month, color: Colors.black54),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFF121212), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFFCF6C79), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFFCF6C79), width: 2),
            ),
            errorStyle: GoogleFonts.poppins(
              color: const Color(0xFFCF6C79),
              fontWeight: FontWeight.w600,
            ),
          ),
          value: selectedSemester,
          hint: Text(
            "1st Semester",
            style: GoogleFonts.poppins(
              color: Colors.black.withOpacity(0.3),
              fontWeight: FontWeight.w500,
              fontSize: height * 0.018,
            ),
          ),
          items:
              _semesters
                  .map(
                    (semester) => DropdownMenuItem<String>(
                      value: semester,
                      child: Text(
                        semester,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: height * 0.018,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) => setState(() => selectedSemester = newValue),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Semester is required';
            }
            return null;
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            maxHeight: 200,
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down),
            iconEnabledColor: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildGradingSystem(double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Grading System",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: height * 0.02,
          ),
        ),
        SizedBox(height: height * 0.01),
        _buildGradingTableHeader(height),
        _buildGradingTableRows(height),
      ],
    );
  }

  Widget _buildGradingTableHeader(double height) {
    const headers = ["From", "To", "Grade"];

    return Container(
      padding: EdgeInsets.all(height * 0.015),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          ...headers.map(
            (header) => Expanded(
              flex: 2,
              child: Text(
                header,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: height * 0.018,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: height * 0.05),
        ],
      ),
    );
  }

  Widget _buildGradingTableRows(double height) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          ..._gradeRanges.asMap().entries.map(
            (entry) => _buildGradeRangeRow(entry.value, entry.key, height),
          ),
          _buildAddButton(height),
        ],
      ),
    );
  }

  Widget _buildGradeRangeRow(GradeRange range, int index, double height) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.015,
        vertical: height * 0.01,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: _minControllers[range.rangeId]!,
              height: height,
            ),
          ),
          _buildSeparator("-", height),
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: _maxControllers[range.rangeId]!,
              height: height,
            ),
          ),
          _buildSeparator("=", height),
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: _gradeControllers[range.rangeId]!,
              height: height,
              isDecimal: true,
            ),
          ),
          SizedBox(width: height * 0.01),
          _buildDeleteButton(index, height),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required double height,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ), // allow decimal????
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(fontSize: height * 0.018),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: height * 0.01,
          vertical: height * 0.01,
        ),
      ),
    );
  }

  Widget _buildSeparator(String text, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: height * 0.01),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: height * 0.02,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(int index, double height) {
    return SizedBox(
      width: height * 0.05,
      child:
          _gradeRanges.length > 1
              ? IconButton(
                onPressed: () => _removeGradeRange(index),
                icon: Icon(
                  Icons.delete,
                  color: const Color(0xFFCF6C79),
                  size: height * 0.025,
                ),
              )
              : const SizedBox(),
    );
  }

  Widget _buildAddButton(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(height * 0.01),
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: _addGradeRange,
          icon: Icon(
            Icons.add_circle,
            color: const Color(0xFF6200EE),
            size: height * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Size size) {
    return Center(
      child: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.06,
        child: ElevatedButton(
          onPressed: _handleSaveButton,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6200EE),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: Text(
            isEditMode ? "Update Course" : "Add Course",
            style: GoogleFonts.poppins(
              fontSize: size.height * 0.020,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
