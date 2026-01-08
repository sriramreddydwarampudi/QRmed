import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_storage_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut(BuildContext context) async {
    await _firebaseAuth.signOut();
    // Clear saved login credentials
    await AuthStorageService.clearSavedCredentials();
    // Navigate to the login screen and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
