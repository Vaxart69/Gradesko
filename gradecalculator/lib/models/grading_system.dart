import 'package:gradecalculator/models/grade_range.dart';

class GradingSystem {
  final String gradingSystemId;
  final String courseId;
  final List<GradeRange> gradeRanges;

  GradingSystem({
    required this.gradingSystemId,
    required this.courseId,
    required this.gradeRanges,
  });

  factory GradingSystem.fromMap(Map<String, dynamic> map) => GradingSystem(
        gradingSystemId: map['gradingSystemId'] ?? '',
        courseId: map['courseId'] ?? '',
        gradeRanges: map['gradeRanges'] != null
            ? List<GradeRange>.from(
                (map['gradeRanges'] as List)
                    .where((e) => e != null)
                    .map((e) => GradeRange.fromMap(Map<String, dynamic>.from(e))))
            : [],
      );

  Map<String, dynamic> toMap() => {
        'gradingSystemId': gradingSystemId,
        'courseId': courseId,
        'gradeRanges': gradeRanges.map((e) => e.toMap()).toList(),
      };
}