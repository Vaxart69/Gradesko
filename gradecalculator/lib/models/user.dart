import 'package:gradecalculator/models/course.dart';

class User {
  final String userId;
  final String username;
  final String firstname;
  final String lastname;
  final String email;
  final List<Course> courses;

  User({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.courses = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
        userId: map['userId'] ?? '',
        username: map['username'] ?? '',
        firstname: map['firstname'] ?? '',
        lastname: map['lastname'] ?? '',
        email: map['email'] ?? '',
        courses: map['courses'] != null
            ? List<Course>.from(
                (map['courses'] as List)
                    .where((e) => e != null)
                    .map((e) => Course.fromMap(Map<String, dynamic>.from(e))))
            : [],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'courses': courses.map((e) => e.toMap()).toList(),
      };
}