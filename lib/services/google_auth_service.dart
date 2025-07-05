import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/storage_utils.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Google Sign-In process (Mobile compatible)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Step 1: Create Google Auth Provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Step 2: Sign in with Firebase (platform specific)
      UserCredential userCredential;

      if (Platform.isAndroid || Platform.isIOS) {
        // Use signInWithRedirect for mobile
        await _auth.signInWithRedirect(googleProvider);

        // Get the result from redirect
        userCredential = await _auth.getRedirectResult();
      } else {
        // Use popup for web
        userCredential = await _auth.signInWithPopup(googleProvider);
      }

      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Failed to get user from Firebase',
          'error': 'FIREBASE_USER_NULL'
        };
      }

      // Step 3: Get ID token for backend verification
      final String? idToken = await user.getIdToken();

      if (idToken == null) {
        return {
          'success': false,
          'message': 'Failed to get ID token from Firebase',
          'error': 'ID_TOKEN_NULL'
        };
      }

      // Step 4: Send to backend for user creation/verification
      final backendResponse = await _sendToBackend(user, idToken);

      if (backendResponse['success']) {
        // Store tokens
        await StorageUtils.saveToken(backendResponse['data']['token']);

        return {
          'success': true,
          'message': 'Google Sign-In successful',
          'data': backendResponse['data']
        };
      } else {
        // Sign out from Firebase if backend fails
        await _auth.signOut();

        return {
          'success': false,
          'message':
              backendResponse['message'] ?? 'Backend authentication failed',
          'error': 'BACKEND_AUTH_FAILED'
        };
      }
    } catch (e) {
      // Clean up on error
      try {
        await _auth.signOut();
      } catch (cleanupError) {
        // Ignore cleanup errors
      }

      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
        'error': 'GOOGLE_SIGN_IN_ERROR'
      };
    }
  }

  /// Send user data to backend for authentication
  Future<Map<String, dynamic>> _sendToBackend(User user, String idToken) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/google-signin');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'firebaseUid': user.uid,
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Backend authentication failed',
          'error': 'BACKEND_ERROR'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NETWORK_ERROR'
      };
    }
  }

  /// Sign out from Firebase
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
