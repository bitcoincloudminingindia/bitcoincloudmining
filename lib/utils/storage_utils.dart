import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

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

      print('🔄 Saving token...');
      print('📝 Token structure validation');

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

        print('✅ Token validation passed');
      } catch (e) {
        print('❌ Token validation failed: $e');
        throw Exception('Invalid token format: $e');
      }

      // Save token using secure storage when available
      if (!kIsWeb) {
        await _secureStorage.write(key: _tokenKey, value: token);
        print('✅ Token saved to secure storage');
      } else {
        // Fallback to shared preferences for web
        final prefs = await _getPrefs();
        await prefs.setString(_tokenKey, token);
        print('✅ Token saved to web storage');
      }

      // Update API config
      ApiConfig.setToken(token);

      // Verify token is saved correctly
      final verifiedToken = await getToken();
      if (verifiedToken != token) {
        print('❌ Token mismatch after save!');
        print(
            'Original length: ${token.length}, Saved length: ${verifiedToken?.length}');
      } else {
        print('✅ Token verified: matches original');
      }
      print('✅ Token updated in ApiConfig');

      // Verify token was saved
      final savedToken = await getToken();
      if (savedToken == null || savedToken != token) {
        throw Exception('Token was not saved successfully');
      }
      print('✅ Token verified in storage');
    } catch (e) {
      print('❌ Error saving token: $e');
      // Try to clean up if save failed
      try {
        await removeToken();
      } catch (cleanupError) {
        print('⚠️ Error cleaning up after failed token save: $cleanupError');
      }
      throw Exception('Failed to save token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      print('🔍 Getting token from storage...');

      // Try secure storage first
      if (!kIsWeb) {
        final secureToken = await _secureStorage.read(key: _tokenKey);
        if (secureToken != null && secureToken.isNotEmpty) {
          print('✅ Token found in secure storage');
          return secureToken;
        }
      }

      // Try web storage if not in secure storage
      final prefs = await _getPrefs();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        print('✅ Token found in web storage');
        return token;
      }

      print('❌ No token found in any storage');
      return null;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<void> removeToken() async {
    try {
      print('🔄 Removing token from storage...');

      // Remove from both storage types
      if (!kIsWeb) {
        await _secureStorage.delete(key: _tokenKey);
        print('✅ Token removed from secure storage');
      }
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
      print('✅ Token removed from web storage');

      // Clear API config
      ApiConfig.clear();
      print('✅ API config cleared');

      // Verify token was removed
      final remainingToken = await getToken();
      if (remainingToken != null) {
        throw Exception('Token was not removed successfully');
      }
      print('✅ Token removal verified');
    } catch (e) {
      print('❌ Error removing token: $e');
      rethrow;
    }
  }

  // User data methods
  static Future<void> saveUserId(String id) async {
    try {
      print('📝 Saving User ID: $id');

      // Save in secure storage
      await _secureStorage.write(key: _userIdKey, value: id);
      print('✅ User ID saved to secure storage');

      // Save in web storage
      final prefs = await _getPrefs();
      await prefs.setString(_userIdKey, id);
      print('✅ User ID saved to web storage');

      // Update API config
      ApiConfig.setUserId(id);
      print('✅ User ID updated in ApiConfig');
    } catch (e) {
      print('❌ Error saving user ID: $e');
      rethrow;
    }
  }

  static Future<String?> getUserId() async {
    try {
      // Try secure storage first
      if (!kIsWeb) {
        final secureId = await _secureStorage.read(key: _userIdKey);
        if (secureId != null && secureId.isNotEmpty) {
          print('✅ User ID found in secure storage');
          return secureId;
        }
      }

      // Try web storage
      final prefs = await _getPrefs();
      final id = prefs.getString(_userIdKey);
      print('📝 Retrieved User ID: $id');
      return id;
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      print('🔄 Saving user data...');
      print('📝 Raw user data: $data');

      // Ensure we're using MongoDB _id
      if (data['id'] != null && data['_id'] == null) {
        data['_id'] = data['id'];
      }

      await _secureStorage.write(
        key: _userDataKey,
        value: json.encode(data),
      );
      print('✅ User data saved successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
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
      print('❌ Error getting user data: $e');
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
      print('Error saving OTP data: $e');
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
      print('Error getting OTP data: $e');
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
      print('Error removing OTP data: $e');
      rethrow;
    }
  }

  // Settings methods
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await _getPrefs();
      prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      print('Error saving settings: $e');
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
      print('Error getting settings: $e');
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
      print('❌ Error clearing data: $e');
      rethrow;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Generic storage methods
  static Future<void> setValue(String key, String value) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } catch (e) {
      print('Error setting value: $e');
      rethrow;
    }
  }

  static Future<String?> getValue(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } catch (e) {
      print('Error getting value: $e');
      return null;
    }
  }

  static Future<void> removeValue(String key) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } catch (e) {
      print('Error removing value: $e');
      rethrow;
    }
  }

  // Wallet balance methods
  static Future<void> saveWalletBalance(double balance) async {
    try {
      // Format balance to 18 decimal places
      final formattedBalance = balance.toStringAsFixed(18);
      print('💰 Formatted balance for storage: $formattedBalance');

      final prefs = await _getPrefs();
      await prefs.setString(_walletBalanceKey, formattedBalance);
      print('💾 Balance saved to storage: $formattedBalance');
    } catch (e) {
      print('❌ Error saving wallet balance: $e');
      rethrow;
    }
  }

  static Future<double?> getWalletBalance() async {
    try {
      final prefs = await _getPrefs();
      final balanceStr = prefs.getString(_walletBalanceKey);

      if (balanceStr != null) {
        // Convert string to double
        final balance = double.tryParse(balanceStr);
        if (balance != null) {
          print('💰 Retrieved balance from storage: $balance');
          return balance;
        }
      }

      // If no balance found or invalid format, return 0
      print('💰 No valid balance found in storage, returning 0');
      return 0.0;
    } catch (e) {
      print('❌ Error getting wallet balance: $e');
      return 0.0;
    }
  }

  static Future<void> removeWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walletBalanceKey);
  }

  static Future<bool> refreshToken() async {
    try {
      print('🔄 Refreshing token...');
      final currentToken = await getToken();
      if (currentToken == null) {
        print('❌ No token found for refresh');
        return false;
      }

      final response = await ApiService.post(
        ApiConfig.refreshTokenEndpoint,
        {'token': currentToken},
      );

      if (response['success']) {
        final newToken = response['data']['token'];
        await saveToken(newToken);
        print('✅ Token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
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

  static Future<List<Transaction>?> getStoredTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');

      if (transactionsJson == null) {
        return null;
      }

      final List<dynamic> decodedList = json.decode(transactionsJson);
      return decodedList.map(Transaction.fromJson).toList();
    } catch (e) {
      print('Error getting stored transactions: $e');
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
      print('Error storing transactions: $e');
    }
  }

  static Future<void> updateWalletBalance(double balance) async {
    try {
      print('🔄 Updating wallet balance: $balance');

      // Format balance to 18 decimal places
      final formattedBalance = balance.toStringAsFixed(18);
      print('💰 Formatted balance: $formattedBalance');

      // Get current user data
      final userData = await getUserData();
      if (userData != null) {
        // Update balance in user data
        userData['walletBalance'] = balance;
        userData['balance'] = balance;

        // Save updated user data
        await saveUserData(userData);
        print('✅ Wallet balance updated in user data');
      }

      // Save to SharedPreferences
      final prefs = await _getPrefs();
      await prefs.setDouble(_walletBalanceKey, balance);
      print('✅ Wallet balance saved to storage');
    } catch (e) {
      print('❌ Error updating wallet balance: $e');
      rethrow;
    }
  }

  static Future<void> playRewardSound() async {
    try {
      print('🎵 Playing reward sound...');
      // Sound playback temporarily disabled
    } catch (e) {
      print('⚠️ Error playing reward sound: $e');
      // Continue without sound if there's an error
    }
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = transactions.map((tx) => tx.toJson()).toList();
      await prefs.setString('transactions', json.encode(transactionsJson));
    } catch (e) {
      print('❌ Error saving transactions: $e');
    }
  }

  static Future<List<Transaction>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson == null) return [];

      final List<dynamic> decoded = json.decode(transactionsJson);
      return decoded.map(Transaction.fromJson).toList();
    } catch (e) {
      print('❌ Error getting transactions: $e');
      return [];
    }
  }

  static Future<void> saveClaimedTransactions(Set<String> transactions) async {
    try {
      await _secureStorage.write(
        key: 'claimed_transactions',
        value: jsonEncode(transactions.toList()),
      );
    } catch (e) {
      print('Error saving claimed transactions: $e');
      rethrow;
    }
  }

  static Future<Set<String>> getClaimedTransactions() async {
    try {
      final data = await _secureStorage.read(key: 'claimed_transactions');
      if (data == null) return {};
      return Set<String>.from(jsonDecode(data));
    } catch (e) {
      print('Error getting claimed transactions: $e');
      return {};
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Refresh token cannot be empty');
      }

      print('🔄 Saving refresh token...');
      print('📝 Refresh token to save: ${token.substring(0, 10)}...');

      // Save in both storage types for redundancy
      final prefs = await _getPrefs();
      await prefs.setString(_refreshTokenKey, token);
      print('✅ Refresh token saved to web storage');

      if (!kIsWeb) {
        await _secureStorage.write(key: _refreshTokenKey, value: token);
        print('✅ Refresh token saved to secure storage');
      }
    } catch (e) {
      print('❌ Error saving refresh token: $e');
      throw Exception('Failed to save refresh token: $e');
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      print('🔍 Getting refresh token from storage...');

      String? refreshToken;

      // First check web storage
      if (kIsWeb) {
        final prefs = await _getPrefs();
        refreshToken = prefs.getString(_refreshTokenKey);
        print(
            '📱 Refresh token from web storage: ${refreshToken != null ? 'Found' : 'Not found'}');
      } else {
        // Check secure storage
        refreshToken = await _secureStorage.read(key: _refreshTokenKey);
        print(
            '📱 Refresh token from secure storage: ${refreshToken != null ? 'Found' : 'Not found'}');

        // If not found in secure storage, check web storage
        if (refreshToken == null) {
          final prefs = await _getPrefs();
          refreshToken = prefs.getString(_refreshTokenKey);
          print(
              '📱 Refresh token from web storage: ${refreshToken != null ? 'Found' : 'Not found'}');
        }
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token found in storage');
        return null;
      }

      print('✅ Refresh token found: ${refreshToken.substring(0, 10)}...');
      return refreshToken;
    } catch (e) {
      print('❌ Error getting refresh token: $e');
      return null;
    }
  }

  static Future<void> removeRefreshToken() async {
    try {
      print('🗑️ Removing refresh token...');

      // Remove from both storage types
      final prefs = await _getPrefs();
      await prefs.remove(_refreshTokenKey);
      print('✅ Refresh token removed from web storage');

      if (!kIsWeb) {
        await _secureStorage.delete(key: _refreshTokenKey);
        print('✅ Refresh token removed from secure storage');
      }
    } catch (e) {
      print('❌ Error removing refresh token: $e');
      throw Exception('Failed to remove refresh token: $e');
    }
  }

  // Format balance to 18 decimal places
  static String formatBalance(String balance) {
    try {
      if (balance.isEmpty) return '0.000000000000000000';

      // Remove any existing formatting
      final cleanBalance = balance.replaceAll(RegExp(r'[^\d.-]'), '');

      // Parse as double
      final amount = double.tryParse(cleanBalance) ?? 0.0;

      // Format with exactly 18 decimal places
      return amount.toStringAsFixed(18);
    } catch (e) {
      print('❌ Error formatting balance: $e');
      return '0.000000000000000000';
    }
  }

  // Save wallet balance to storage
  static Future<void> _saveWalletBalance(String balance) async {
    try {
      final prefs = await _getPrefs();
      final walletData = {
        'balance': balance,
        'lastUpdated': DateTime.now().toIso8601String()
      };
      await prefs.setString(_walletBalanceKey, json.encode(walletData));
    } catch (e) {
      print('❌ Error saving wallet balance: $e');
      throw Exception('Failed to save wallet balance: $e');
    }
  }

  // Retrieve wallet balance from storage
  static Future<String?> readWalletBalance() async {
    try {
      final prefs = await _getPrefs();
      final walletJson = prefs.getString(_walletBalanceKey);
      if (walletJson != null) {
        final walletData = json.decode(walletJson);
        return walletData['balance'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error reading wallet balance: $e');
      return null;
    }
  }

  // Sync balance with server
  static Future<Map<String, dynamic>> syncWalletBalance(String balance) async {
    try {
      print('🔄 Syncing wallet balance with server...');

      // Get auth token
      print('🔍 Getting token from storage...');
      final token = await getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }
      print('✅ Token found in web storage');
      print('✅ Got auth token: ${token.substring(0, 10)}...');

      // Basic token validation
      final parts = token.split('.');
      print('🔐 Token parts: ${parts.length}');

      // Make API request
      const url = '${ApiConfig.baseUrl}/api/wallet/sync-balance';
      print('📤 POST request to $url');

      final data = {'balance': balance};
      print('📦 Request data: $data');

      final response = await ApiService.postWithAuth(
        url,
        data,
        authToken: token,
      );

      final responseData = response['data'];
      final statusCode = response['statusCode'] as int;

      print('📥 Response status: $statusCode');
      print('📦 Response data: $responseData');

      // Handle successful sync
      if (statusCode == 200) {
        if (responseData['success'] == true) {
          // Check if it was a skipped sync
          if (responseData['message']?.contains('Sync skipped') == true) {
            print('ℹ️ Sync skipped: ${responseData['message']}');
            return {
              'success': true,
              'skipped': true,
              'message': responseData['message']
            };
          }

          print('✅ Balance synced successfully');
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
        print('ℹ️ ${e.toString()}');
        return {'success': true, 'skipped': true, 'message': e.toString()};
      }
      print('❌ Error syncing balance: $e');
      rethrow;
    }
  }

  // Update and sync wallet balance
  static Future<void> updateAndSyncBalance(String newBalance) async {
    try {
      print('🔄 Updating wallet balance...');
      print('💰 New balance: $newBalance');

      final currentBalance =
          await readWalletBalance() ?? '0.000000000000000000';
      print('📊 Current balance: $currentBalance');

      // Format balances to 18 decimal places
      final formattedNewBalance = formatBalance(newBalance);
      print('💫 Formatted balance: $formattedNewBalance');

      if (formattedNewBalance == currentBalance) {
        print('ℹ️ Balance unchanged');
        // Save the balance even if unchanged to update lastUpdated
        await _saveWalletBalance(formattedNewBalance);
        print('✅ Wallet balance updated: $formattedNewBalance BTC');

        // Sync with server
        final syncResult = await syncWalletBalance(formattedNewBalance);
        if (syncResult['skipped'] == true) {
          print('ℹ️ Server sync skipped: ${syncResult['message']}');
        } else {
          print('✅ Server sync completed');
        }
      } else {
        print(
            '📈 Balance changed from $currentBalance to $formattedNewBalance');
        await _saveWalletBalance(formattedNewBalance);
        print('✅ Wallet balance updated: $formattedNewBalance BTC');

        // Sync with server
        final syncResult = await syncWalletBalance(formattedNewBalance);
        if (syncResult['skipped'] == true) {
          print('ℹ️ Server sync skipped: ${syncResult['message']}');
        } else {
          print('✅ Server sync completed');
        }
      }
    } catch (e) {
      print('❌ Error updating balance: $e');
      throw Exception('Failed to update wallet balance: $e');
    }
  }
}
