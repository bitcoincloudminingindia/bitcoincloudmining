import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../utils/number_formatter.dart';

class StorageUtils {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _userIdKey = 'userId';
  static const String _userDataKey = 'userData';
  static const String _tokenKey = 'token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _settingsKey = 'settings';
  static const String _walletBalanceKey = 'walletBalance';
  static const String _otpKey = 'otpData';
  static const String _adminIdKey = 'adminId';
  static const String _adminNameKey = 'adminName';
  static const String _adminEmailKey = 'adminEmail';

  static Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  // Secure storage methods for sensitive data
  static Future<void> saveToken(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token cannot be empty');
      }

      debugPrint('🔄 Saving token...');
      debugPrint('📝 Token structure validation');

      try {
        // Basic JWT structure validation
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid token structure');
        }

        // Try to decode the payload to verify it's valid base64
        final payloadData =
            const Base64Decoder().convert(base64.normalize(parts[1]));
        final payload = utf8.decode(payloadData);
        final decodedPayload = json.decode(payload);

        // Verify required claims
        if (decodedPayload['userId'] == null) {
          throw Exception('Token missing userId claim');
        }

        debugPrint('✅ Token validation passed');
      } catch (e) {
        debugPrint('❌ Token validation failed: $e');
        debugPrint('❌ Token validation failed: $e');
        throw Exception('Invalid token format: $e');
      }

      // Save token using secure storage when available
      if (!kIsWeb) {
        await _secureStorage.write(key: _tokenKey, value: token);
        debugPrint('✅ Token saved to secure storage');
      } else {
        // Fallback to shared preferences for web
        final prefs = await _getPrefs();
        await prefs.setString(_tokenKey, token);
        debugPrint('✅ Token saved to web storage');
      }

      // Update API config
      ApiConfig.setToken(token);

      // Verify token is saved correctly
      final verifiedToken = await getToken();
      if (verifiedToken != token) {
        debugPrint('❌ Token mismatch after save!');
        debugPrint(
            'Original length: ${token.length}, Saved length: ${verifiedToken?.length}');
      } else {
        debugPrint('✅ Token verified: matches original');
      }
      debugPrint('✅ Token updated in ApiConfig');

      // Verify token was saved
      final savedToken = await getToken();
      if (savedToken == null || savedToken != token) {
        throw Exception('Token was not saved successfully');
      }
      debugPrint('✅ Token verified in storage');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
      // Try to clean up if save failed
      try {
        await removeToken();
      } catch (cleanupError) {
        debugPrint(
            '⚠️ Error cleaning up after failed token save: $cleanupError');
      }
      throw Exception('Failed to save token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      debugPrint('🔍 Getting token from storage...');

      // Try secure storage first
      if (!kIsWeb) {
        final secureToken = await _secureStorage.read(key: _tokenKey);
        if (secureToken != null && secureToken.isNotEmpty) {
          debugPrint('✅ Token found in secure storage');
          return secureToken;
        }
      }

      // Try web storage if not in secure storage
      final prefs = await _getPrefs();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        debugPrint('✅ Token found in web storage');
        return token;
      }

      debugPrint('❌ No token found in any storage');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<void> removeToken() async {
    try {
      debugPrint('🔄 Removing token from storage...');

      // Remove from both storage types
      if (!kIsWeb) {
        await _secureStorage.delete(key: _tokenKey);
        debugPrint('✅ Token removed from secure storage');
      }
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
      debugPrint('✅ Token removed from web storage');

      // Clear API config
      ApiConfig.clear();
      debugPrint('✅ API config cleared');

      // Verify token was removed
      final remainingToken = await getToken();
      if (remainingToken != null) {
        throw Exception('Token was not removed successfully');
      }
      debugPrint('✅ Token removal verified');
    } catch (e) {
      debugPrint('❌ Error removing token: $e');
      rethrow;
    }
  }

  // User data methods
  static Future<void> saveUserId(String id) async {
    try {
      debugPrint('📝 Saving User ID: $id');

      // Save in secure storage
      await _secureStorage.write(key: _userIdKey, value: id);
      debugPrint('✅ User ID saved to secure storage');

      // Save in web storage
      final prefs = await _getPrefs();
      await prefs.setString(_userIdKey, id);
      debugPrint('✅ User ID saved to web storage');

      // Update API config
      ApiConfig.setUserId(id);
      debugPrint('✅ User ID updated in ApiConfig');
    } catch (e) {
      debugPrint('❌ Error saving user ID: $e');
      rethrow;
    }
  }

  static Future<String?> getUserId() async {
    try {
      // Try secure storage first
      if (!kIsWeb) {
        final secureId = await _secureStorage.read(key: _userIdKey);
        if (secureId != null && secureId.isNotEmpty) {
          debugPrint('✅ User ID found in secure storage');
          return secureId;
        }
      }

      // Try web storage
      final prefs = await _getPrefs();
      final id = prefs.getString(_userIdKey);
      debugPrint('📝 Retrieved User ID: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Saving user data...');
      debugPrint('📝 Raw user data: $data');

      // Ensure we're using MongoDB _id
      if (data['id'] != null && data['_id'] == null) {
        data['_id'] = data['id'];
      }

      await _secureStorage.write(
        key: _userDataKey,
        value: json.encode(data),
      );
      debugPrint('✅ User data saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      String? userDataStr;
      if (kIsWeb) {
        final prefs = await _getPrefs();
        userDataStr = prefs.getString(_userDataKey);
      } else {
        userDataStr = await _secureStorage.read(key: _userDataKey);
      }

      if (userDataStr == null) return null;
      return json.decode(userDataStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  // OTP related methods
  static Future<void> saveOtpData(
      String email, String otp, DateTime expiryTime) async {
    try {
      final otpData = {
        'email': email,
        'otp': otp,
        'expiryTime': expiryTime.toIso8601String(),
      };

      if (kIsWeb) {
        final prefs = await _getPrefs();
        prefs.setString(_otpKey, json.encode(otpData));
      } else {
        await _secureStorage.write(key: _otpKey, value: json.encode(otpData));
      }
    } catch (e) {
      debugPrint('Error saving OTP data: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getOtpData() async {
    try {
      String? otpDataStr;
      if (kIsWeb) {
        final prefs = await _getPrefs();
        otpDataStr = prefs.getString(_otpKey);
      } else {
        otpDataStr = await _secureStorage.read(key: _otpKey);
      }

      if (otpDataStr != null) {
        final otpData = json.decode(otpDataStr) as Map<String, dynamic>;
        final expiryTime = DateTime.parse(otpData['expiryTime']);
        if (DateTime.now().isBefore(expiryTime)) {
          return otpData;
        }
        await removeOtpData();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting OTP data: $e');
      return null;
    }
  }

  static Future<void> removeOtpData() async {
    try {
      if (kIsWeb) {
        final prefs = await _getPrefs();
        prefs.remove(_otpKey);
      } else {
        await _secureStorage.delete(key: _otpKey);
      }
    } catch (e) {
      debugPrint('Error removing OTP data: $e');
      rethrow;
    }
  }

  // Settings methods
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await _getPrefs();
      prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final prefs = await _getPrefs();
      final settingsStr = prefs.getString(_settingsKey);
      if (settingsStr != null) {
        return json.decode(settingsStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting settings: $e');
      return null;
    }
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    try {
      final prefs = await _getPrefs();
      await prefs.clear();
      if (!kIsWeb) {
        await _secureStorage.deleteAll();
      }
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      rethrow;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Generic storage methods
  static Future<void> setValue(String key, String value) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error setting value: $e');
      rethrow;
    }
  }

  static Future<String?> getValue(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting value: $e');
      return null;
    }
  }

  static Future<void> removeValue(String key) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error removing value: $e');
      rethrow;
    }
  }

  // Transaction storage methods
  static Future<List<Transaction>?> getStoredTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');

      if (transactionsJson == null) {
        return null;
      }

      final List<dynamic> decodedList = json.decode(transactionsJson);
      return decodedList
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting stored transactions: $e');
      return null;
    }
  }

  static Future<void> storeTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = json.encode(
        transactions.map((tx) => tx.toJson()).toList(),
      );
      await prefs.setString('transactions', transactionsJson);
    } catch (e) {
      debugPrint('Error storing transactions: $e');
    }
  }

  static Future<List<Transaction>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson == null) return [];

      final List<dynamic> decoded = json.decode(transactionsJson);
      return decoded
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting transactions: $e');
      return [];
    }
  }

  // Format balance to string with 18 decimal places
  static String formatBalanceString(String balance) {
    try {
      if (balance.isEmpty) return '0.000000000000000000';

      // Remove any existing formatting
      final cleanBalance = balance.replaceAll(RegExp(r'[^\d.-]'), '');

      // Parse as double
      final amount = double.tryParse(cleanBalance) ?? 0.0;

      // Format with exactly 18 decimal places
      return amount.toStringAsFixed(18);
    } catch (e) {
      debugPrint('❌ Error formatting balance: $e');
      return '0.000000000000000000';
    }
  }

  // Save wallet balance to storage
  static Future<void> saveWalletBalance(String balance) async {
    try {
      final prefs = await _getPrefs();
      final walletData = {
        'balance': balance,
        'lastUpdated': DateTime.now().toIso8601String()
      };
      await prefs.setString(_walletBalanceKey, json.encode(walletData));
    } catch (e) {
      debugPrint('❌ Error saving wallet balance: $e');
      throw Exception('Failed to save wallet balance: $e');
    }
  }

  // Get wallet balance from storage
  static Future<String?> getWalletBalance() async {
    try {
      final prefs = await _getPrefs();
      final walletJson = prefs.getString(_walletBalanceKey);
      if (walletJson != null) {
        final walletData = json.decode(walletJson);
        return walletData['balance'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error reading wallet balance: $e');
      return null;
    }
  }

  static Future<void> removeWalletBalance() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_walletBalanceKey);
      debugPrint('✅ Wallet balance removed from storage');
    } catch (e) {
      debugPrint('❌ Error removing wallet balance: $e');
    }
  }

  static Future<bool> refreshToken() async {
    try {
      debugPrint('🔄 Refreshing token...');
      final currentToken = await getToken();
      if (currentToken == null) {
        debugPrint('❌ No token found for refresh');
        return false;
      }

      final response = await ApiService.post(
        ApiConfig.refreshTokenEndpoint,
        {'token': currentToken},
      );

      if (response['success']) {
        final newToken = response['data']['token'];
        await saveToken(newToken);
        debugPrint('✅ Token refreshed successfully');
        return true;
      } else {
        debugPrint('❌ Token refresh failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      return false;
    }
  }

  static Future<void> saveAdminInfo({
    required String id,
    required String name,
    required String email,
  }) async {
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.setString(_adminIdKey, id),
      prefs.setString(_adminNameKey, name),
      prefs.setString(_adminEmailKey, email),
    ]);
  }

  static Future<void> clearAdminInfo() async {
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.remove(_adminIdKey),
      prefs.remove(_adminNameKey),
      prefs.remove(_adminEmailKey),
    ]);
  }

  static Future<void> saveClaimedTransactions(Set<String> transactions) async {
    try {
      await _secureStorage.write(
        key: 'claimed_transactions',
        value: jsonEncode(transactions.toList()),
      );
    } catch (e) {
      debugPrint('Error saving claimed transactions: $e');
      rethrow;
    }
  }

  static Future<Set<String>> getClaimedTransactions() async {
    try {
      final data = await _secureStorage.read(key: 'claimed_transactions');
      if (data == null) return {};
      return Set<String>.from(jsonDecode(data));
    } catch (e) {
      debugPrint('Error getting claimed transactions: $e');
      return {};
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Refresh token cannot be empty');
      }

      debugPrint('🔄 Saving refresh token...');
      debugPrint('📝 Refresh token to save: ${token.substring(0, 10)}...');

      // Save in both storage types for redundancy
      final prefs = await _getPrefs();
      await prefs.setString(_refreshTokenKey, token);
      debugPrint('✅ Refresh token saved to web storage');

      if (!kIsWeb) {
        await _secureStorage.write(key: _refreshTokenKey, value: token);
        debugPrint('✅ Refresh token saved to secure storage');
      }
    } catch (e) {
      debugPrint('❌ Error saving refresh token: $e');
      throw Exception('Failed to save refresh token: $e');
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      debugPrint('🔍 Getting refresh token from storage...');

      String? refreshToken;

      // First check web storage
      if (kIsWeb) {
        final prefs = await _getPrefs();
        refreshToken = prefs.getString(_refreshTokenKey);
        debugPrint(
            '📱 Refresh token from web storage: ${refreshToken != null ? 'Found' : 'Not found'}');
      } else {
        // Check secure storage
        refreshToken = await _secureStorage.read(key: _refreshTokenKey);
        debugPrint(
            '📱 Refresh token from secure storage: ${refreshToken != null ? 'Found' : 'Not found'}');

        // If not found in secure storage, check web storage
        if (refreshToken == null) {
          final prefs = await _getPrefs();
          refreshToken = prefs.getString(_refreshTokenKey);
          debugPrint(
              '📱 Refresh token from web storage: ${refreshToken != null ? 'Found' : 'Not found'}');
        }
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('⚠️ No refresh token found in storage');
        return null;
      }

      debugPrint('✅ Refresh token found: ${refreshToken.substring(0, 10)}...');
      return refreshToken;
    } catch (e) {
      debugPrint('❌ Error getting refresh token: $e');
      return null;
    }
  }

  static Future<void> removeRefreshToken() async {
    try {
      debugPrint('🗑️ Removing refresh token...');

      // Remove from both storage types
      final prefs = await _getPrefs();
      await prefs.remove(_refreshTokenKey);
      debugPrint('✅ Refresh token removed from web storage');

      if (!kIsWeb) {
        await _secureStorage.delete(key: _refreshTokenKey);
        debugPrint('✅ Refresh token removed from secure storage');
      }
    } catch (e) {
      debugPrint('❌ Error removing refresh token: $e');
      throw Exception('Failed to remove refresh token: $e');
    }
  }

  // Sync balance with server
  static Future<Map<String, dynamic>> syncWalletBalance(String balance) async {
    try {
      debugPrint('🔄 Syncing wallet balance with server...');

      // Get auth token
      debugPrint('🔍 Getting token from storage...');
      final token = await getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }
      debugPrint('✅ Token found in web storage');
      debugPrint('✅ Got auth token: ${token.substring(0, 10)}...');

      // Basic token validation
      final parts = token.split('.');
      debugPrint('🔐 Token parts: ${parts.length}');

      // Make API request
      const url = ' {ApiConfig.baseUrl}/api/wallet/sync-balance';
      debugPrint('📤 POST request to $url');

      final data = {'balance': balance};
      debugPrint('📦 Request data: $data');

      final response = await ApiService.postWithAuth(
        url,
        data,
        authToken: token,
      );

      final responseData = response['data'];
      final statusCode = response['statusCode'] as int;

      debugPrint('📥 Response status: $statusCode');
      debugPrint('📦 Response data: $responseData');

      // Handle successful sync
      if (statusCode == 200) {
        if (responseData['success'] == true) {
          // Check if it was a skipped sync
          if (responseData['message']?.contains('Sync skipped') == true) {
            debugPrint('ℹ️ Sync skipped: ${responseData['message']}');
            return {
              'success': true,
              'skipped': true,
              'message': responseData['message']
            };
          }

          debugPrint('✅ Balance synced successfully');
          if (responseData['data'] != null) {
            return {
              'success': true,
              'skipped': false,
              'data': responseData['data']
            };
          }
          return {'success': true, 'skipped': false};
        }
      }

      throw Exception(responseData['message'] ?? 'Failed to sync balance');
    } catch (e) {
      if (e.toString().contains('Sync skipped')) {
        debugPrint('ℹ️ ${e.toString()}');
        return {'success': true, 'skipped': true, 'message': e.toString()};
      }
      debugPrint('❌ Error syncing balance: $e');
      rethrow;
    }
  }

  // Update and sync wallet balance
  static Future<void> updateAndSyncBalance(String newBalance) async {
    try {
      debugPrint('🔄 Updating wallet balance...');
      debugPrint('💰 New balance: $newBalance');

      final currentBalance = await getWalletBalance() ?? '0.000000000000000000';
      debugPrint('📊 Current balance: $currentBalance');

      // Format balances to 18 decimal places
      final formattedNewBalance =
          NumberFormatter.formatBalanceString(newBalance);
      debugPrint('💫 Formatted balance: $formattedNewBalance');

      if (formattedNewBalance == currentBalance) {
        debugPrint('ℹ️ Balance unchanged');
        // Save the balance even if unchanged to update lastUpdated
        await saveWalletBalance(formattedNewBalance);
        debugPrint('✅ Wallet balance updated: $formattedNewBalance BTC');

        // Sync with server
        final syncResult = await syncWalletBalance(formattedNewBalance);
        if (syncResult['skipped'] == true) {
          debugPrint('ℹ️ Server sync skipped: ${syncResult['message']}');
        } else {
          debugPrint('✅ Server sync completed');
        }
      } else {
        debugPrint(
            '📈 Balance changed from $currentBalance to $formattedNewBalance');
        await saveWalletBalance(formattedNewBalance);
        debugPrint('✅ Wallet balance updated: $formattedNewBalance BTC');

        // Sync with server
        final syncResult = await syncWalletBalance(formattedNewBalance);
        if (syncResult['skipped'] == true) {
          debugPrint('ℹ️ Server sync skipped: ${syncResult['message']}');
        } else {
          debugPrint('✅ Server sync completed');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating balance: $e');
      throw Exception('Failed to update wallet balance: $e');
    }
  }
}
