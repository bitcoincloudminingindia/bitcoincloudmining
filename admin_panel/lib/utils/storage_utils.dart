import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageUtils {
  static final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _adminIdKey = 'admin_id';
  static const String _adminNameKey = 'admin_name';
  static const String _adminEmailKey = 'admin_email';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';

  // Token storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Admin information storage
  static Future<bool> saveAdminInfo(
      {required String id, required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminIdKey, id);
    await prefs.setString(_adminNameKey, name);
    return prefs.setString(_adminEmailKey, email);
  }

  static Future<Map<String, String?>> getAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_adminIdKey),
      'name': prefs.getString(_adminNameKey),
      'email': prefs.getString(_adminEmailKey),
    };
  }

  static Future<bool> clearAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminIdKey);
    await prefs.remove(_adminNameKey);
    return prefs.remove(_adminEmailKey);
  }

  // User data storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userDataKey);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  static Future<void> removeUserData() async {
    await _storage.delete(key: _userDataKey);
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Remember Me functionality
  static Future<void> saveRememberMeCredentials(
      String email, String password) async {
    await _storage.write(key: _savedEmailKey, value: email);
    await _storage.write(key: _savedPasswordKey, value: password);
    await _storage.write(key: _rememberMeKey, value: 'true');
  }

  static Future<void> clearRememberMeCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
    await _storage.delete(key: _rememberMeKey);
  }

  static Future<Map<String, String?>> getSavedCredentials() async {
    final isRememberMe = await _storage.read(key: _rememberMeKey);
    if (isRememberMe != 'true') {
      return {'email': null, 'password': null};
    }

    return {
      'email': await _storage.read(key: _savedEmailKey),
      'password': await _storage.read(key: _savedPasswordKey),
    };
  }
}
