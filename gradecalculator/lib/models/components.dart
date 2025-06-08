import 'package:gradecalculator/models/records.dart';

// this is the component model. every component has an id and 

class Component {
  final String componentId;
  final String componentName;
  final double weight;
  final String courseId;

  Component({
    required this.componentId,
    required this.componentName,
    required this.weight,
    required this.courseId,
  });

  factory Component.fromMap(Map<String, dynamic> map) => Component(
        componentId: map['componentId'] ?? '',
        componentName: map['componentName'] ?? '',
        weight:
            (map['weight'] is int)
                ? (map['weight'] as int).toDouble()
                : (map['weight'] ?? 0.0),
        courseId: map['courseId'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'componentId': componentId,
        'componentName': componentName,
        'weight': weight,
        'courseId': courseId,
      };
}
