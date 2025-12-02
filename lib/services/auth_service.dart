import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut(BuildContext context) async {
    await _firebaseAuth.signOut();
    // Navigate to the login screen and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
