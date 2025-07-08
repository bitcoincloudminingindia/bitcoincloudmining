import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart'; // Added for BuildContext
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Added for Provider

import '../config/api_config.dart';
import '../providers/auth_provider.dart'
    as my_auth; // Added for AuthProvider with alias
import '../utils/storage_utils.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle(BuildContext context) async {
    try {
      // Step 1: Google account select karen
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google Sign-In cancelled by user',
          'error': 'SIGN_IN_CANCELLED'
        };
      }

      // Step 2: Auth details lein
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      // Step 3: Firebase credential banayein
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Step 4: Firebase me sign-in karein
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Firebase user not found',
          'error': 'FIREBASE_USER_NULL'
        };
      }

      // Step 5: Backend ko call karein
      final String? firebaseIdToken = await user.getIdToken();
      final backendResponse = await _sendToBackend(user, firebaseIdToken!);

      if (backendResponse['success']) {
        // Save token
        final token = backendResponse['data']['token'];
        print('Google sign-in ke baad backend se mila token: $token');
        await StorageUtils.saveToken(token);
        final verifiedToken = await StorageUtils.getToken();
        print('Verified token after save: $verifiedToken');
        // Save user data
        if (backendResponse['data']['user'] != null) {
          await StorageUtils.saveUserData(backendResponse['data']['user']);
          // Try to save userId from userId or id
          final userObj = backendResponse['data']['user'];
          if (userObj['userId'] != null) {
            await StorageUtils.saveUserId(userObj['userId']);
          } else if (userObj['id'] != null) {
            await StorageUtils.saveUserId(userObj['id']);
          }
          // AuthProvider update
          final authProvider =
              Provider.of<my_auth.AuthProvider>(context, listen: false);
          await authProvider.updateUserData(userObj);
        }

        return {
          'success': true,
          'message': 'Google Sign-In successful',
          'data': backendResponse['data']
        };
      } else {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message':
              backendResponse['message'] ?? 'Backend authentication failed',
          'error': 'BACKEND_AUTH_FAILED'
        };
      }
    } catch (e) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
        'error': 'GOOGLE_SIGN_IN_ERROR'
      };
    }
  }

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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await StorageUtils.clearAll();
    } catch (e) {}
  }

  bool get isSignedIn => _auth.currentUser != null;
  dynamic get currentUser => _auth.currentUser;
}
