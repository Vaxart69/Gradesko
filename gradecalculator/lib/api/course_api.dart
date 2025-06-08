import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradecalculator/models/course.dart';

class CourseApi {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<String?> addCourse(Course course) async {
    try {
      final docRef = db.collection('courses').doc(); 
      final courseWithId = Course(
        courseId: docRef.id,
        userId: course.userId,
        courseName: course.courseName,
        courseCode: course.courseCode,
        units: course.units,
        instructor: course.instructor,
        academicYear: course.academicYear,
        semester: course.semester,
        gradingSystem: course.gradingSystem,
        components: course.components,
        grade: course.grade,
        numericalGrade: course.numericalGrade, 
      );
      await docRef.set(courseWithId.toMap());
      return null; // Success
    } catch (e) {
      return "Failed to add course: $e";
    }
  }
}