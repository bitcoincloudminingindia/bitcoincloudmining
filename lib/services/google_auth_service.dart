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
import 'backend_failover_manager.dart'; // Import failover manager

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final BackendFailoverManager _failoverManager = BackendFailoverManager(); // Use failover manager

  /// Test backend connectivity and return detailed info
  Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      final backendUrl = await _failoverManager.getActiveBackendUrl();
      print('🔍 Testing backend connection to: $backendUrl');
      
      // Test health endpoint
      final healthUrl = Uri.parse('$backendUrl/health');
      final healthResponse = await http.get(
        healthUrl,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('🔍 Health endpoint status: ${healthResponse.statusCode}');
      print('🔍 Health response: ${healthResponse.body}');
      
      // Test Google signin endpoint existence (OPTIONS request)
      final authUrl = Uri.parse('$backendUrl/api/auth/google-signin');
      final optionsResponse = await http.head(authUrl).timeout(const Duration(seconds: 5));
      
      print('🔍 Auth endpoint reachable: ${optionsResponse.statusCode}');
      
      return {
        'backend_url': backendUrl,
        'health_status': healthResponse.statusCode,
        'health_response': healthResponse.body,
        'auth_endpoint_status': optionsResponse.statusCode,
        'is_healthy': healthResponse.statusCode == 200,
      };
    } catch (e) {
      print('🔍 Backend connection test failed: $e');
      return {
        'error': e.toString(),
        'is_healthy': false,
      };
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle(BuildContext context) async {
    try {
      // Step 0: Test backend connection first
      print('🔵 Testing backend connection before Google sign-in...');
      final connectionTest = await testBackendConnection();
      if (!connectionTest['is_healthy']) {
        print('🔴 Backend connection test failed: ${connectionTest['error']}');
        return {
          'success': false,
          'message': 'Service is temporarily unavailable. Please try again later.',
          'error': 'BACKEND_CONNECTION_FAILED',
          'debug_info': connectionTest
        };
      }
      print('🟢 Backend connection test passed');

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
        
        // If backend call failed, run connection test again for debugging
        if (backendResponse['error'] == 'SERVER_UNAVAILABLE' || 
            backendResponse['error'] == 'INVALID_JSON_RESPONSE') {
          print('🔍 Running connection test after backend failure...');
          final debugInfo = await testBackendConnection();
          backendResponse['debug_info'] = debugInfo;
        }
        
        return {
          'success': false,
          'message':
              backendResponse['message'] ?? 'Backend authentication failed',
          'error': 'BACKEND_AUTH_FAILED',
          'debug_info': backendResponse['debug_info']
        };
      }
    } catch (e) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      print('🔴 Google Sign-In failed with error: $e');
      
      // Run connection test for debugging
      print('🔍 Running connection test after sign-in failure...');
      final debugInfo = await testBackendConnection();
      
      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
        'error': 'GOOGLE_SIGN_IN_ERROR',
        'debug_info': debugInfo
      };
    }
  }

  Future<Map<String, dynamic>> _sendToBackend(User user, String idToken) async {
    try {
      print('🔵 Starting backend request with automatic failover...');
      
      // Use failover manager's makeRequest for automatic retry across backends
      final response = await _failoverManager.makeRequest(
        endpoint: '/api/auth/google-signin',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'firebaseUid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        }),
        timeout: const Duration(seconds: 30),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response headers: ${response.headers}');
      print('🔵 Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      // Check if response is HTML instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE html>') || 
          response.body.trim().startsWith('<html>')) {
        print('🔴 Server returned HTML instead of JSON - backend might be down');
        return {
          'success': false,
          'message': 'Server is temporarily unavailable. Please try again later.',
          'error': 'SERVER_UNAVAILABLE'
        };
      }

      // Check if response is empty
      if (response.body.trim().isEmpty) {
        print('🔴 Server returned empty response');
        return {
          'success': false,
          'message': 'Server error: Empty response. Please try again.',
          'error': 'EMPTY_RESPONSE'
        };
      }

      // Try to parse JSON
      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('🔴 JSON parse error: $e');
        print('🔴 Raw response: ${response.body}');
        return {
          'success': false,
          'message': 'Server response format error. Please try again later.',
          'error': 'INVALID_JSON_RESPONSE'
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🟢 Google signin successful via ${_failoverManager.getCachedBackendUrl()}');
        return {'success': true, 'data': responseData['data']};
      } else {
        print('🔴 Backend error: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Backend authentication failed',
          'error': 'BACKEND_ERROR'
        };
      }
    } catch (e) {
      print('🔴 Network error in Google signin: $e');
      
      // Get failover status for debugging
      final failoverStatus = _failoverManager.getStatus();
      print('🔍 Failover status: $failoverStatus');
      
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
