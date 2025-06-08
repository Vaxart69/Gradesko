import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/auth_api.dart';
import '../models/user.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthAPI _authApi = FirebaseAuthAPI();

  User? _firebaseUser;
  model.User? _appUser;

 
  User? get firebaseUser => _firebaseUser;
  model.User? get appUser => _appUser;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  
  AuthProvider() {
    _isLoading = true;
    _authApi.getUser().listen((user) async {
      _isLoading = true;
      notifyListeners();

      _firebaseUser = user; 

      if (user != null) {
        _appUser = await _authApi.getUserInfo(user.uid);
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> fetchUser() async {
    if (_firebaseUser != null) {
      _appUser = await _authApi.getUserInfo(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  // Sign in
  Future<String?> signIn(String email, String password) async {
    final result = await _authApi.signIn(email, password);
    if (result == null) {
      _firebaseUser = FirebaseAuth.instance.currentUser; // Add this line
      if (_firebaseUser != null) {
        _appUser = await _authApi.getUserInfo(_firebaseUser!.uid);
        notifyListeners();
      }
    }
    return result;
  }

  // Sign up
  Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final result = await _authApi.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      username: username,
    );
    if (result == null) {
      _firebaseUser = FirebaseAuth.instance.currentUser; // Add this line
      if (_firebaseUser != null) {
        _appUser = await _authApi.getUserInfo(_firebaseUser!.uid);
        notifyListeners();
      }
    }
    return result;
  }

  // Sign out
  Future<void> signOut() async {
    await _authApi.signOut();
    _firebaseUser = null;
    _appUser = null;
    notifyListeners();
  }

  // Update user info
  Future<String?> updateUserInfo(Map<String, dynamic> updatedData) async {
    if (_firebaseUser == null) return "No user signed in";
    final result = await _authApi.updateUserInfo(
      _firebaseUser!.uid,
      updatedData,
    );
    if (result == null) {
      _appUser = await _authApi.getUserInfo(_firebaseUser!.uid);
      notifyListeners();
    }
    return result;
  }

  // Delete account
  Future<String?> deleteAccount() async {
    if (_firebaseUser == null) return "No user signed in";

    try {
      final userId = _firebaseUser!.uid;

      // Delete all user-related data from Firestore
      await _deleteUserData(userId);

      // Delete the Firebase Auth user
      await _firebaseUser!.delete();

      // Clear local state
      _firebaseUser = null;
      _appUser = null;
      notifyListeners();

      return null; // Success
    } catch (e) {
      return "Error deleting account: $e";
    }
  }

  Future<void> _deleteUserData(String userId) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      // Step 1: Get all courses for this user
      final coursesSnapshot =
          await FirebaseFirestore.instance
              .collection('courses')
              .where('userId', isEqualTo: userId)
              .get();

      // Step 2: For each course, delete components and records
      for (final courseDoc in coursesSnapshot.docs) {
        final courseId = courseDoc.id;

        // Get all components for this course
        final componentsSnapshot =
            await FirebaseFirestore.instance
                .collection('components')
                .where('courseId', isEqualTo: courseId)
                .get();

        // For each component, delete all its records
        for (final componentDoc in componentsSnapshot.docs) {
          final componentId = componentDoc.id;

          // Get all records for this component
          final recordsSnapshot =
              await FirebaseFirestore.instance
                  .collection('records')
                  .where('componentId', isEqualTo: componentId)
                  .get();

          // Delete all records
          for (final recordDoc in recordsSnapshot.docs) {
            batch.delete(recordDoc.reference);
          }

          // Delete the component
          batch.delete(componentDoc.reference);
        }

        // Delete the course
        batch.delete(courseDoc.reference);
      }

      // Step 3: Delete the user document
      batch.delete(
        FirebaseFirestore.instance.collection('appusers').doc(userId),
      );

      // Execute all deletes
      await batch.commit();
    } catch (e) {
      print("Error deleting user data: $e");
      rethrow;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Force account selection by signing out first
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return "Sign-in cancelled by user";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      _firebaseUser = userCredential.user;

      if (_firebaseUser != null) {
        // Check if user exists in Firestore, if not create one
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appusers')
                .doc(_firebaseUser!.uid)
                .get();

        if (!userDoc.exists) {
          // Create new user document
          final newUser = model.User(
            userId: _firebaseUser!.uid,
            email: _firebaseUser!.email!,
            firstname: _firebaseUser!.displayName?.split(' ').first ?? 'User',
            lastname: _firebaseUser!.displayName?.split(' ').last ?? '',
            username: _firebaseUser!.email!.split('@').first,
            courses: const [],
          );

          await FirebaseFirestore.instance
              .collection('appusers')
              .doc(_firebaseUser!.uid)
              .set(newUser.toMap());

          _appUser = newUser;
        } else {
          _appUser = model.User.fromMap(userDoc.data()!);
        }

        notifyListeners();
        return null; // Success
      }

      return "Failed to sign in with Google";
    } catch (e) {
      return "Error: $e";
    }
  }
}
