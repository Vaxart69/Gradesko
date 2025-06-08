import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradecalculator/api/course_api.dart';
import 'package:gradecalculator/models/course.dart';
import 'package:gradecalculator/models/components.dart';
import 'package:gradecalculator/models/grade_range.dart';
import 'package:gradecalculator/models/records.dart';

class CourseProvider with ChangeNotifier {
  static const Duration _firestoreTimeout = Duration(seconds: 10);
  
  final CourseApi _courseApi = CourseApi();

  Course? _selectedCourse;

  Course? get selectedCourse => _selectedCourse;


  void selectCourse(Course course) {
   
    _selectedCourse = course;
    notifyListeners(); 

    
    _loadComponentsInBackground(course);
  }

  Future<void> _loadComponentsInBackground(Course course) async {
    try {
      // Load fresh components with timeout
      final components = await loadCourseComponents(course.courseId);

      // Only update if this course is still selected
      if (_selectedCourse?.courseId == course.courseId) {
        _selectedCourse = _createUpdatedCourse(course, components);
        notifyListeners(); // Update UI once components are loaded
      }
    } catch (e) {
      print("Failed to load components (offline?): $e");
      // Keep the course selected with empty components for offline mode
      if (_selectedCourse?.courseId == course.courseId) {
        _selectedCourse = _createUpdatedCourse(course, []);
        notifyListeners();
      }
    }
  }

  // Helper method to create updated course instance
  Course _createUpdatedCourse(Course originalCourse, List<Component> components, {
    double? newGrade,
    double? newNumericalGrade,
    bool? wasRounded,
  }) {
    return Course(
      courseId: originalCourse.courseId,
      userId: originalCourse.userId,
      courseName: originalCourse.courseName,
      courseCode: originalCourse.courseCode,
      units: originalCourse.units,
      instructor: originalCourse.instructor,
      academicYear: originalCourse.academicYear,
      semester: originalCourse.semester,
      gradingSystem: originalCourse.gradingSystem,
      components: components,
      grade: newGrade ?? originalCourse.grade,
      numericalGrade: newNumericalGrade ?? originalCourse.numericalGrade,
      wasRounded: wasRounded ?? originalCourse.wasRounded,
    );
  }

  // Clear selected course
  void clearSelectedCourse() {
    _selectedCourse = null;
    notifyListeners();
  }

  // Add course (existing functionality)
  Future<String?> addCourse(Course course) async {
    final result = await _courseApi.addCourse(course);
    notifyListeners();
    return result;
  }

  // Update selected course with new data (for when components are added/modified)
  void updateSelectedCourse(Course updatedCourse) {
    if (_selectedCourse?.courseId == updatedCourse.courseId) {
      _selectedCourse = updatedCourse;
      notifyListeners();
    }
  }

  
  Future<double> calculateCourseGrade({List<Component?>? components}) async {
    final courseComponents = components ?? _selectedCourse?.components ?? [];
    double totalGrade = 0.0;

    print("=== PROVIDER GRADE CALCULATION ===");
    print("Components found: ${courseComponents.length}");

    for (final component in courseComponents) {
      if (component == null) continue;

      final componentScore = await _calculateComponentScore(component);
      totalGrade += componentScore;
    }

    final finalGrade = double.parse(totalGrade.toStringAsFixed(2));
    print("\n=== FINAL GRADE ===");
    print("Total Course Grade: ${finalGrade.toStringAsFixed(2)}%");
    print("========================\n");

    return finalGrade;
  }

  // Helper method to calculate individual component score
  Future<double> _calculateComponentScore(Component component) async {
    // Get all records for this component from Firestore
    final recordsSnapshot = await FirebaseFirestore.instance
        .collection('records')
        .where('componentId', isEqualTo: component.componentId)
        .get()
        .timeout(_firestoreTimeout);

    double totalScore = 0.0;
    double totalPossible = 0.0;

    print("\n--- Component: ${component.componentName} ---");
    print("Weight: ${component.weight.toStringAsFixed(2)}%");
    print("Records found: ${recordsSnapshot.docs.length}");

    for (final doc in recordsSnapshot.docs) {
      final record = Records.fromMap(doc.data());
      totalScore += record.score;
      totalPossible += record.total;

      print("  ${record.name}: ${record.score.toStringAsFixed(2)}/${record.total.toStringAsFixed(2)}");
    }

    if (totalPossible <= 0) {
      print("No valid records found for this component");
      return 0.0;
    }

    final componentPercentage = (totalScore / totalPossible) * 100;
    final weightedScore = componentPercentage * (component.weight / 100);

    print("Total Score: ${totalScore.toStringAsFixed(2)}/${totalPossible.toStringAsFixed(2)} = ${componentPercentage.toStringAsFixed(2)}%");
    print("Weighted Score: ${componentPercentage.toStringAsFixed(2)}% × ${component.weight.toStringAsFixed(2)}% = ${weightedScore.toStringAsFixed(2)}");

    return weightedScore;
  }

  // CALCULATE NUMERICAL GRADE FROM PERCENTAGE (TWO-PASS ALGORITHM)
  (double?, bool) calculateNumericalGradeWithRounding(double percentage, List<GradeRange> gradeRanges) {
    print("=== NUMERICAL GRADE CALCULATION ===");
    print("Original Percentage: ${percentage.toStringAsFixed(2)}%");
    print("Available grade ranges: ${gradeRanges.length}");

    // FIRST PASS
    final exactMatch = _findGradeInRanges(percentage, gradeRanges, "First Pass: Checking exact percentage");
    if (exactMatch != null) return (exactMatch, false); // Not rounded

    // SECOND PASS
    final rounded = (percentage % 1 >= 0.5) ? percentage.ceil() : percentage.floor();
    print("\n--- Second Pass: Checking rounded percentage ---");
    print("Rounded Percentage: $rounded%");
    
    final roundedMatch = _findGradeInRanges(rounded.toDouble(), gradeRanges, "Second Pass: Checking rounded percentage");
    if (roundedMatch != null) return (roundedMatch, true); // Was rounded

    print("No grade range found for ${percentage.toStringAsFixed(2)}% (exact) or $rounded% (rounded)");
    print("===================================\n");
    return (null, false); 
  }

  
  double? calculateNumericalGrade(double percentage, List<GradeRange> gradeRanges) {
    final (grade, _) = calculateNumericalGradeWithRounding(percentage, gradeRanges);
    return grade;
  }

  
  double? _findGradeInRanges(double value, List<GradeRange> gradeRanges, String passDescription) {
    print("\n--- $passDescription ---");
    
    for (final range in gradeRanges) {
      print("Checking range: ${range.min}-${range.max} = ${range.grade}");
      
      if (value >= range.min && value <= range.max) {
        print("✓ Match found! ${value.toStringAsFixed(2)}% falls in range ${range.min}-${range.max}");
        print("Numerical Grade: ${range.grade}");
        print("===================================\n");
        return range.grade;
      } else {
        print("✗ No match: ${value.toStringAsFixed(2)}% not in ${range.min}-${range.max}");
      }
    }
    return null;
  }

  // UPDATE COURSE GRADE IN FIREBASE AND PROVIDER (Modified)
  Future<void> updateCourseGrade({List<Component?>? components}) async {
    if (_selectedCourse == null) return;

    try {
      // Calculate new percentage grade
      final newPercentageGrade = await calculateCourseGrade(components: components);

      // Calculate numerical grade from percentage WITH rounding tracking
      final (numericalGrade, wasRounded) = calculateNumericalGradeWithRounding(
        newPercentageGrade,
        _selectedCourse!.gradingSystem.gradeRanges,
      );

      // Debug print
      print("=== GRADE UPDATE SUMMARY ===");
      print("Percentage Grade: ${newPercentageGrade.toStringAsFixed(2)}%");
      print("Numerical Grade: ${numericalGrade ?? 'No matching range'}");
      print("Was Rounded: $wasRounded");
      print("============================\n");

      // Update in Firebase (include wasRounded)
      await _updateCourseInFirebase(newPercentageGrade, numericalGrade, wasRounded);

      // Update local state
      _selectedCourse = _createUpdatedCourse(
        _selectedCourse!,
        components?.cast<Component>() ?? _selectedCourse!.components.cast<Component>(),
        newGrade: newPercentageGrade,
        newNumericalGrade: numericalGrade,
        wasRounded: wasRounded,
      );

      notifyListeners();
      print("Course grades updated - Percentage: ${newPercentageGrade.toStringAsFixed(2)}%, Numerical: ${numericalGrade ?? 'None'}, Rounded: $wasRounded");
    } catch (e) {
      print("Error updating course grade: $e");
    }
  }

  // Helper method to update course in Firebase
  Future<void> _updateCourseInFirebase(double grade, double? numericalGrade, bool wasRounded) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(_selectedCourse!.courseId)
        .update({
          'grade': grade,
          'numericalGrade': numericalGrade,
          'wasRounded': wasRounded,
        })
        .timeout(_firestoreTimeout);
  }

  // ADD COMPONENT AND UPDATE GRADE
  Future<void> addComponentAndUpdateGrade(Component component) async {
    if (_selectedCourse == null) return;

    final updatedComponents = List<Component?>.from(_selectedCourse!.components)..add(component);
    await updateCourseGrade(components: updatedComponents);
  }

  // REMOVE COMPONENT AND UPDATE GRADE (Updated)
  Future<void> removeComponentAndUpdateGrade(String componentId) async {
    if (_selectedCourse == null) return;

    try {
      // Remove component from local state
      final updatedComponents = _selectedCourse!.components
          .where((comp) => comp?.componentId != componentId)
          .toList();

      // Calculate new percentage grade with remaining components
      final newPercentageGrade = await calculateCourseGrade(components: updatedComponents);

      // Calculate numerical grade from percentage WITH rounding tracking
      final (numericalGrade, wasRounded) = calculateNumericalGradeWithRounding(
        newPercentageGrade,
        _selectedCourse!.gradingSystem.gradeRanges,
      );

      // Debug print
      print("=== DELETE GRADE UPDATE SUMMARY ===");
      print("Percentage Grade: ${newPercentageGrade.toStringAsFixed(2)}%");
      print("Numerical Grade: ${numericalGrade ?? 'No matching range'}");
      print("Was Rounded: $wasRounded");
      print("===================================\n");

      // Update in Firebase
      await _updateCourseInFirebase(newPercentageGrade, numericalGrade, wasRounded);

      // Update local state
      _selectedCourse = _createUpdatedCourse(
        _selectedCourse!,
        updatedComponents.cast<Component>(),
        newGrade: newPercentageGrade,
        newNumericalGrade: numericalGrade,
        wasRounded: wasRounded,
      );

      notifyListeners();
      print("Component removed and grades updated - Percentage: ${newPercentageGrade.toStringAsFixed(2)}%, Numerical: ${numericalGrade ?? 'None'}, Rounded: $wasRounded");
    } catch (e) {
      print("Error removing component and updating grade: $e");
    }
  }

  // ADD COMPONENT WITH RECORDS (moved from AddComponent)
  Future<void> createComponentWithRecords({
    required String componentName,
    required double weight,
    required List<Map<String, dynamic>> recordsData, // [{name, score, total}, ...]
  }) async {
    if (_selectedCourse == null) return;

    try {
      final componentDocRef = FirebaseFirestore.instance.collection('components').doc();
      final componentId = componentDocRef.id;

      // Create component
      final component = Component(
        componentId: componentId,
        componentName: componentName,
        weight: weight,
        courseId: _selectedCourse!.courseId,
      );

      // Create records with default numbering
      final records = recordsData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final name = (data['name'] as String).trim();
        
        return Records(
          recordId: DateTime.now().millisecondsSinceEpoch.toString() + '_$index',
          componentId: componentId,
          name: name.isEmpty ? (index + 1).toString() : name, // Default to counter
          score: data['score'] as double,
          total: data['total'] as double,
        );
      }).toList();

      // Save component to Firebase
      await componentDocRef.set(component.toMap());

      // Save records
      final batch = FirebaseFirestore.instance.batch();
      for (final record in records) {
        final recordDocRef = FirebaseFirestore.instance
            .collection('records')
            .doc(record.recordId);
        batch.set(recordDocRef, record.toMap());
      }
      await batch.commit();

      // Update grade
      await addComponentAndUpdateGrade(component);

      print("Component created successfully!");
    } catch (e) {
      print("Error creating component: $e");
      rethrow;
    }
  }

  // UPDATE COMPONENT WITH RECORDS (moved from AddComponent)
  Future<void> updateComponentWithRecords({
    required String componentId,
    required String componentName,
    required double weight,
    required List<Map<String, dynamic>> recordsData, // [{name, score, total}, ...]
  }) async {
    if (_selectedCourse == null) return;

    try {
      // Update component
      final updatedComponent = Component(
        componentId: componentId,
        componentName: componentName,
        weight: weight,
        courseId: _selectedCourse!.courseId,
      );

      // Update component in Firebase
      await FirebaseFirestore.instance
          .collection('components')
          .doc(componentId)
          .update(updatedComponent.toMap());

      // Delete all existing records for this component
      final existingRecordsSnapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('componentId', isEqualTo: componentId)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      // Delete old records
      for (final doc in existingRecordsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Create new records with default numbering
      final records = recordsData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final name = (data['name'] as String).trim();
        
        return Records(
          recordId: DateTime.now().millisecondsSinceEpoch.toString() + '_$index',
          componentId: componentId,
          name: name.isEmpty ? (index + 1).toString() : name, // Default to counter
          score: data['score'] as double,
          total: data['total'] as double,
        );
      }).toList();

      // Add new records
      for (final record in records) {
        final recordDocRef = FirebaseFirestore.instance
            .collection('records')
            .doc(record.recordId);
        batch.set(recordDocRef, record.toMap());
      }

      await batch.commit();

      // Update grade
      await updateCourseGrade();

      print("Component updated successfully!");
    } catch (e) {
      print("Error updating component: $e");
      rethrow;
    }
  }

  // Add method to load components from Firestore
  Future<List<Component>> loadCourseComponents(String courseId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('components')
          .where('courseId', isEqualTo: courseId)
          .get()
          .timeout(_firestoreTimeout);

      return snapshot.docs.map((doc) => Component.fromMap(doc.data())).toList();
    } on TimeoutException {
      print("Loading components timed out - returning empty list");
      return [];
    } catch (e) {
      print("Error loading components (offline?): $e");
      return [];
    }
  }

  // Add this method to clear course when user navigates away completely
  void clearSelectedCourseOnNavigation() {
    // This can be called when user navigates to different main tabs
    _selectedCourse = null;
    notifyListeners();
  }
}
