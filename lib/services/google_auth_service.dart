import 'package:firebase_auth/firebase_auth.dart';

import '../utils/storage_utils.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Google Sign-In process (temporarily disabled due to package issues)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // TODO: Fix Google Sign-In package issues
      // For now, return error message
      return {
        'success': false,
        'message':
            'Google Sign-In is temporarily unavailable. Please use email/password login.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
      };
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await StorageUtils.clearAll();
    } catch (e) {
      // Handle sign out error
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get current Firebase user
  dynamic get currentUser => _auth.currentUser;
}
