import 'package:gradecalculator/models/components.dart';
import 'package:gradecalculator/models/grading_system.dart';

class Course {
  final String courseId;
  final String userId; 
  final String courseName;
  final String courseCode;
  final String units;
  final String? instructor;
  final String academicYear; 
  final String semester; 
  final GradingSystem gradingSystem; 
  final List<Component?> components;
  final double? grade;
  final double? numericalGrade; 
  final bool? wasRounded; 

  Course({
    required this.courseId,
    required this.userId,
    required this.courseName,
    required this.courseCode,
    required this.units,
    this.instructor,
    required this.academicYear,
    required this.semester,
    required this.gradingSystem,
    this.components = const [],
    this.grade = 0.0,
    this.numericalGrade,
    this.wasRounded, 
  });

  factory Course.fromMap(Map<String, dynamic> map) => Course(
        courseId: map['courseId'] ?? '',
        userId: map['userId'] ?? '',
        courseName: map['courseName'] ?? '',
        courseCode: map['courseCode'] ?? '',
        units: map['units'] ?? '',
        instructor: map['instructor'],
        academicYear: map['academicYear'] ?? '',
        semester: map['semester'] ?? '',
        gradingSystem: map['gradingSystem'] != null
            ? GradingSystem.fromMap(Map<String, dynamic>.from(map['gradingSystem']))
            : GradingSystem(
                gradingSystemId: '', 
                courseId: map['courseId'] ?? '',
                gradeRanges: [],
              ),
        components: map['components'] != null
            ? List<Component?>.from(
                (map['components'] as List)
                    .map((e) => e == null ? null : Component.fromMap(Map<String, dynamic>.from(e))))
            : [],
        grade: map['grade'] != null
            ? (map['grade'] is int
                ? (map['grade'] as int).toDouble()
                : map['grade'] as double)
            : null, // <-- Add this line
        numericalGrade: map['numericalGrade'] != null 
            ? (map['numericalGrade'] is int
                ? (map['numericalGrade'] as int).toDouble()
                : map['numericalGrade'] as double)
            : null,
        wasRounded: map['wasRounded'] as bool?, 
      );

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'userId': userId,
        'courseName': courseName,
        'courseCode': courseCode,
        'units': units,
        'instructor': instructor,
        'academicYear': academicYear,
        'semester': semester,
        'gradingSystem': gradingSystem.toMap(),
        'components': components.map((e) => e?.toMap()).toList(),
        'grade': grade, 
        'numericalGrade': numericalGrade, 
        'wasRounded': wasRounded, 
      };
}