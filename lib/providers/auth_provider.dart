import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bitcoin_cloud_mining/models/user.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
// wallet_service.dart file does not exist, so it has been removed
import 'package:bitcoin_cloud_mining/utils/constants.dart';
import 'package:bitcoin_cloud_mining/utils/error_handler.dart';
import 'package:bitcoin_cloud_mining/utils/number_formatter.dart';
import 'package:bitcoin_cloud_mining/utils/storage_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Type definition for API responses
typedef ApiResponse = Map<String, dynamic>;

/// Standard response structure
/// {
///   'success': bool,
///   'message': String,
///   'data': Map<String, dynamic>?,
///   'error': String?,
///   'token': String?,
/// }

class AuthProvider extends ChangeNotifier {
  final _client = http.Client();
  final String baseUrl = ApiConfig.baseUrl;

  // Keys and constants
  static const String _usersKey = 'users';

  // Use these keys in StorageUtils
  static const String settingsKey = 'user_settings';
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  // Initialization state
  bool _isInitializing = false;
  bool _isInitialized = false;

  // User state
  String? _userId;
  String? _fullName;
  String? _userName;
  String? _email;
  String? _profileImagePath;
  bool _is2FAEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isNotificationsEnabled = true;
  bool _isSecurityAlertsEnabled = true;
  String? _password;
  double _walletBalance = 0.0;
  String? _referralCode;
  String? _referredBy;
  int _referralCount = 0;
  bool _isLoggedIn = false;
  String? _token;
  String? _refreshToken;

  // Add the missing _userData field
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  // Add missing fields
  double? _referralEarnings;

  // Cache for referral code validation
  final Map<String, bool> _referralCodeCache = {};
  Timer? _cacheCleanupTimer;

  // User model instance
  User? _user;
  User? get user => _user;

  // Getters
  String? get userId => _userId;
  String? get fullName => _fullName;
  String? get userName => _userName;
  String? get email => _email;
  String? get profileImagePath => _profileImagePath;
  bool get is2FAEnabled => _is2FAEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isSecurityAlertsEnabled => _isSecurityAlertsEnabled;
  double get walletBalance => _walletBalance;
  String get referralCode => _referralCode ?? '';
  String? get referredBy => _referredBy;
  int get referralCount => _referralCount;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  bool get isAuthenticated => _isLoggedIn && _token != null;
  double get totalReferralEarnings => _referralEarnings ?? 0.0;

  AuthProvider() {
    _initializeCacheCleanup();
  }

  void _initializeCacheCleanup() {
    // Clean cache every 5 minutes
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _referralCodeCache.clear();
    });
  }

  @override
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _client.close();
    super.dispose();
  }

  Future<void> _updateUserState(Map<String, dynamic> userData) async {
    try {
      debugPrint('🔄 Updating user state with data: $userData');

      // Update wallet balance
      if (userData['walletBalance'] != null) {
        final balance = userData['walletBalance'].toString();
        debugPrint('💰 Wallet balance updated: $balance BTC');
      }

      // Update user ID
      if (userData['userId'] != null) {
        _userId = userData['userId'];
        ApiConfig.setUserId(_userId!);
        debugPrint('👤 UserId updated in ApiConfig: Set');
      }

      // Update token
      if (userData['token'] != null) {
        _token = userData['token'];
        ApiConfig.setToken(_token!);
        debugPrint('🔑 Token updated in ApiConfig: Set');
      }

      // Update user object
      _user = User.fromJson(userData);
      _isLoggedIn = true;

      debugPrint('✅ User state updated successfully');
      debugPrint('🔍 User ID after update: $_userId');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating user state: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String userName,
    required String userEmail,
    required String password,
    String? referredByCode,
  }) async {
    try {
      debugPrint('📤 Sending signup request');
      debugPrint('📝 User data: $fullName, $userName, $userEmail');

      // Check connectivity first
      if (!await checkConnectivity()) {
        return {
          'success': false,
          'message': 'No internet connection',
          'error': 'NETWORK_ERROR'
        };
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.baseUrl + ApiConfig.register),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'fullName': fullName,
              'userName': userName,
              'userEmail': userEmail,
              'password': password,
              if (referredByCode != null && referredByCode.isNotEmpty)
                'referredByCode': referredByCode,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📝 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['data']?['token'];
        final user = data['data']?['user'];
        if (token != null) {
          await _saveToken(token);
          await _updateUserState(user);
        }
        return {'success': true, 'data': data};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Signup failed',
          'error': errorData['error'] ?? 'UNKNOWN_ERROR'
        };
      }
    } catch (e) {
      debugPrint('❌ Signup error: $e');
      return {
        'success': false,
        'message': 'An error occurred during signup',
        'error': e.toString()
      };
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      debugPrint('💾 Saving token to storage');
      await StorageUtils.saveToken(token);
      _token = token;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting login for email: $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('📥 Login response: ${response.statusCode}');

      if (response.statusCode == 200 && data['success'] == true) {
        // Extract token and user data
        final token = data['data']['token'];
        final userData = data['data']['user'];

        if (token == null || userData == null) {
          throw ApiError('Invalid response format');
        }

        // Save token to storage and update API config
        await StorageUtils.saveToken(token);
        _token = token;
        ApiConfig.setToken(token);
        debugPrint('✅ Token saved and configured');

        // Save user ID
        final userId = userData['userId'] ?? userData['_id'];
        if (userId != null) {
          await StorageUtils.saveUserId(userId);
          ApiConfig.setUserId(userId);
          debugPrint('✅ User ID saved: $userId');
        }

        // Update user state
        await _updateUserState(userData);
        _isLoggedIn = true;
        notifyListeners();

        return {
          'success': true,
          'message': 'Login successful',
          'data': userData,
        };
      } else {
        throw ApiError(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  Future<bool> validateReferralCode(String code) async {
    if (code.isEmpty) return false;

    try {
      final result = await ApiService.post('/referral/validate', {
        'code': code,
      });

      return result['success'] == true && result['data'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<String> generateReferralCode() async {
    // Generate a random 8-character alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final code =
        List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
    return code;
  }

  Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> usersMap = {};

    final existingUsers = prefs.getString(_usersKey);
    if (existingUsers != null) usersMap = json.decode(existingUsers);

    usersMap[userData['userId']] = userData;
    await prefs.setString(_usersKey, json.encode(usersMap));
  }

  Future<void> saveUserData({
    required String userName,
    required String email,
    String? fullName,
    String? profileImagePath,
  }) async {
    try {
      // First update on server
      final result = await ApiService.post(
        ApiConfig.userProfile,
        {
          'username': userName,
          'email': email,
          if (fullName != null) 'fullName': fullName,
          if (profileImagePath != null) 'profileImage': profileImagePath,
        },
      );

      if (result['success']) {
        // If server update successful, update local state
        _userName = userName;
        _email = email;
        if (fullName != null) _fullName = fullName;
        if (profileImagePath != null) {
          _profileImagePath = profileImagePath;
        }

        // Update local storage
        final userData = {
          'userId': _userId,
          'fullName': _fullName,
          'userName': _userName,
          'email': _email,
          'profileImagePath': _profileImagePath,
          'password': _password,
          'walletBalance': _walletBalance,
          'referralCode': _referralCode,
          'referredBy': _referredBy,
          'referralCount': _referralCount,
          'token': _token,
        };

        await _saveUser(userData);
        notifyListeners();
      } else {
        throw Exception(result['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      print('Save user data error: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  void clearUserData() {
    _userId = null;
    _fullName = null;
    _userName = null;
    _email = null;
    _profileImagePath = null;
    _password = null;
    _walletBalance = 0.0;
    _referralCode = null;
    _referredBy = null;
    _referralCount = 0;
    _token = null;
    notifyListeners();
  }

  Future<void> setUserData({
    required String userId,
    required String userName,
    required String email,
    required String token,
    String? fullName,
    String? profileImagePath,
    double? walletBalance,
    String? referralCode,
    String? referredBy,
    int? referralCount,
  }) async {
    final Map<String, dynamic> userData = {
      'userId': userId,
      'userName': userName,
      'email': email,
      'token': token,
      if (fullName != null) 'fullName': fullName,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
      if (walletBalance != null) 'walletBalance': walletBalance,
      if (referralCode != null) 'referralCode': referralCode,
      if (referredBy != null) 'referredBy': referredBy,
      if (referralCount != null) 'referralCount': referralCount,
    };

    await _updateUserState(userData);

    await StorageUtils.saveToken(token);
    await StorageUtils.saveUserData(userData);

    notifyListeners();
  }

  Future<void> logout() async {
    try {
      debugPrint('🚪 Logging out...');
      final token = await StorageUtils.getToken();
      final userId = _userId;

      if (token != null && userId != null) {
        try {
          // Get current wallet balance
          final walletBalance =
              _user?.walletBalance.toString() ?? '0.000000000000000000';
          debugPrint('💰 Current wallet balance: $walletBalance');

          // Format balance to 18 decimal places
          final formattedBalance =
              NumberFormatter.formatBTCAmount(double.parse(walletBalance));
          debugPrint('💰 Formatted balance for logout: $formattedBalance');

          // Attempt server logout
          final response = await http
              .post(
                Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'userId': userId,
                  'walletBalance': formattedBalance,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode != 200) {
            final errorData = jsonDecode(response.body);
            debugPrint('⚠️ Server logout failed: ${errorData['message']}');
          }
        } catch (e) {
          debugPrint('⚠️ Server logout failed: $e');
        }
      }

      // Clear local storage
      await Future.wait([
        StorageUtils.removeToken(),
        StorageUtils.removeRefreshToken(),
        StorageUtils.clearAll(),
      ]);

      // Clear ApiConfig
      ApiConfig.clear();

      // Reset all state
      _token = null;
      _refreshToken = null;
      _userId = null;
      _user = null;
      _isLoggedIn = false;
      _userData = null;
      _isInitialized = false; // Reset initialization state
      _isInitializing = false;

      debugPrint('✅ Logged out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/users/update-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        await StorageUtils.saveUserData({
          'userId': _userId,
          'userName': _userName,
          'email': _email,
          'profileImagePath': _profileImagePath,
        });
      } else {
        throw json.decode(response.body)['message'] ?? 'Password update failed';
      }
    } catch (e) {
      throw 'Password update failed: $e';
    }
  }

  Future<void> toggle2FA(bool value) async {
    _is2FAEnabled = value;
    await updateSettings();
  }

  Future<void> toggleBiometric(bool value) async {
    _isBiometricEnabled = value;
    await updateSettings();
  }

  Future<void> toggleNotifications(bool value) async {
    _isNotificationsEnabled = value;
    await updateSettings();
  }

  Future<void> toggleSecurityAlerts(bool value) async {
    _isSecurityAlertsEnabled = value;
    await updateSettings();
  }

  // Helper method to format balance to 18 decimal places
  String _formatBalance(double balance) {
    return balance.toStringAsFixed(18);
  }

  // Helper method to parse balance from string to double
  double _parseBalance(String balance) {
    return double.parse(balance);
  }

  Future<void> updateWalletBalance(double newBalance) async {
    try {
      // Format balance to 18 decimal places
      final formattedBalance = _formatBalance(newBalance);
      _walletBalance = _parseBalance(formattedBalance);

      // Save formatted balance
      await StorageUtils.saveWalletBalance(formattedBalance);

      // Update user data with formatted balance
      final userData = await StorageUtils.getUserData() ?? {};
      userData['walletBalance'] = formattedBalance;
      await StorageUtils.saveUserData(userData);

      notifyListeners();
      print('✅ Wallet balance updated: $formattedBalance BTC');
    } catch (e) {
      print('❌ Balance sync error: $e');
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (data['user'] != null) {
        final userData = data['user'];
        _userId = userData['userId'] as String?;
        _fullName = userData['fullName'] as String?;
        _userName = userData['userName'] as String?;
        _email = userData['userEmail'] as String?; // Updated to use userEmail
        _profileImagePath = userData['profilePicture'] as String?;
        _referralCode = userData['referralCode'] as String?;
        _referralCount = userData['referralCount'] as int? ?? 0;
        _referralEarnings =
            (userData['referralEarnings'] as num?)?.toDouble() ?? 0.0;
        _userData = userData;

        if (userData['wallet'] != null) {
          final walletData = userData['wallet'];
          _walletBalance =
              double.tryParse(walletData['balance']?.toString() ?? '0') ?? 0.0;
        }

        notifyListeners();
        await StorageUtils.saveUserData(userData);
      }
    } catch (e) {
      debugPrint('❌ Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> _loadUserProfileFromServer() async {
    try {
      final response = await ApiService.get(ApiConfig.profile);
      debugPrint('📥 Profile response: $response');

      if (response['status'] == 'success' && response['data'] != null) {
        debugPrint('🔄 Saving user data...');
        debugPrint('📝 Raw user data: ${response['data']}');
        await updateUserData(response['data']);
        debugPrint('✅ User data saved successfully');
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
      rethrow;
    }
  }

  Future<void> updateSettings() async {
    try {
      final result = await ApiService.post(
        ApiConfig.userProfile,
        {
          'username': _userName,
          'email': _email,
          if (_fullName != null) 'fullName': _fullName,
          if (_profileImagePath != null) 'profileImage': _profileImagePath,
        },
      );

      if (result['success']) {
        notifyListeners();
      } else {
        throw Exception(result['message'] ?? 'Settings update failed');
      }
    } catch (e) {
      print('Update settings error: $e');
      rethrow;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      if (email.isEmpty || otp.isEmpty) {
        throw ValidationError('Email and OTP are required');
      }

      final response = await ApiService.post(
        ApiConfig.verifyOtp,
        {
          'email': email,
          'otp': otp,
        },
      );

      if (response['success'] == true) {
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }

      throw AuthenticationError(
          response['message'] ?? 'OTP verification failed');
    } catch (e) {
      print('OTP verification error: $e');
      rethrow;
    }
  }

  Future<bool> initializeAuth() async {
    // Prevent concurrent initialization
    if (_isInitializing) {
      print('⚠️ Auth initialization already in progress, waiting...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized && _isLoggedIn;
    }

    // Return cached state if already initialized
    if (_isInitialized) {
      print('✅ Auth already initialized, returning cached state');
      return _isLoggedIn;
    }

    try {
      _isInitializing = true;
      print('🔄 Starting auth initialization...');

      // Get token from storage
      final token = await StorageUtils.getToken();
      print('🔑 Token from storage: ${token != null ? 'Found' : 'Not found'}');

      if (token == null) {
        print('❌ No token found, auth initialization failed');
        _isLoggedIn = false;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      // Update token state
      _token = token;
      ApiConfig.setToken(token);

      // Get user data from storage
      final userData = await StorageUtils.getUserData();
      print(
          '📱 User data from storage: ${userData != null ? 'Found' : 'Not found'}');

      // If no user data but we have token, try to fetch from server
      if (userData == null) {
        print('⚠️ No user data in storage, trying to fetch from server...');
        try {
          final apiService = ApiService();
          final response = await apiService.getUserProfile();
          if (response['status'] == 'success' && response['data'] != null) {
            print('✅ Got user data from server');
            final serverData = response['data'];

            // Save server data
            await StorageUtils.saveUserData(serverData);

            // Update state
            await _updateUserState(serverData);
            _isLoggedIn = true;
            _isInitialized = true;
            notifyListeners();
            return true;
          }
        } catch (e) {
          print('❌ Error fetching user data from server: $e');
          // Don't logout on network error
          if (e.toString().contains('SocketException') ||
              e.toString().contains('TimeoutException')) {
            print('⚠️ Network error, keeping login state');
            _isInitialized = true;
            return true;
          }
        }

        // Only logout if we couldn't get data from server
        print('❌ Could not get user data from server');
        await logout();
        _isInitialized = true;
        return false;
      }

      try {
        // First validate token
        print('🔍 Validating token...');
        final response = await ApiService.post(
          ApiConfig.validateToken,
          {'token': token},
        );

        if (response['success'] == true || response['status'] == 'success') {
          print('✅ Token is valid');

          // Update state with stored data
          await _updateUserState(userData);
          _isLoggedIn = true;
          _isInitialized = true;

          notifyListeners();
          return true;
        }

        // If token is not valid, try to refresh
        print('⚠️ Token invalid, attempting refresh...');
        final refreshResponse = await refreshToken();
        if (refreshResponse) {
          print('✅ Token refreshed successfully');

          // Update state with stored data
          await _updateUserState(userData);
          _isLoggedIn = true;
          _isInitialized = true;

          notifyListeners();
          return true;
        }

        // If refresh also fails, then logout
        print('❌ Token validation and refresh failed');
        await logout();
        _isInitialized = true;
        return false;
      } catch (e) {
        print('❌ Token validation error: $e');

        // Network error condition, keep login state if we have valid data
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException')) {
          print('⚠️ Network error, keeping login state');
          await _updateUserState(userData);
          _isLoggedIn = true;
          _isInitialized = true;
          notifyListeners();
          return true;
        }

        // For other errors, logout
        await logout();
        _isInitialized = true;
        return false;
      }
    } catch (e) {
      print('❌ Auth initialization error: $e');

      // Critical error condition, logout
      if (e.toString().contains('FormatException') ||
          e.toString().contains('TypeError')) {
        await logout();
      }
      _isInitialized = true;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> validateCurrentToken() async {
    try {
      print('🔍 Checking token validation...');
      final token = await getToken();
      if (token == null) {
        print('❌ No token found for validation');
        return false;
      }

      final result = await ApiService.post(
        ApiConfig.validateToken,
        {'token': token},
      );

      if (result['success'] == true) {
        print('✅ Token is valid');
        return true;
      }

      // If token is expired, try to refresh
      if (result['status'] == 401) {
        print('⚠️ Token expired, attempting refresh...');
        return await refreshToken();
      }

      print('❌ Token validation failed: ${result['message']}');
      return false;
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await ApiService.post(
        ApiConfig.checkEmail,
        {'email': email},
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendLoginOtp(String email) async {
    try {
      final response = await ApiService.post(
        '/auth/send-login-otp',
        {'email': email},
      );
      return response['success'] ?? false;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await StorageUtils.getRefreshToken();
      if (refreshToken == null) {
        print('No refresh token found');
        return false;
      }

      final response = await ApiService.post(
        ApiConfig.refreshTokenEndpoint,
        {'token': refreshToken},
      );

      if (response['success'] == true) {
        _token = response['data']['token'];
        _refreshToken = response['data']['refreshToken'];

        // Save new tokens
        await StorageUtils.saveToken(_token!);
        await StorageUtils.saveRefreshToken(_refreshToken!);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  Future<void> maintainAuthState() async {
    // Skip if not initialized or initializing
    if (!_isInitialized || _isInitializing) return;

    // Skip if not logged in or no token
    if (!_isLoggedIn || _token == null) return;

    try {
      final isValid = await validateCurrentToken();
      if (!isValid) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await logout();
        }
      }
    } catch (e) {
      print('Auth state maintenance error: $e');
      await logout();
    }
  }

  Future<void> loadUserProfile() async {
    // Skip if not initialized
    if (!_isInitialized) {
      debugPrint('⚠️ Auth not initialized, initializing first...');
      final initialized = await initializeAuth();
      if (!initialized) {
        throw Exception('Auth initialization failed');
      }
      return;
    }

    try {
      debugPrint('🔄 Loading user profile...');

      // Try to load from server first
      try {
        await _loadUserProfileFromServer();
        return;
      } catch (e) {
        debugPrint('⚠️ Failed to load from server: $e');
        // Continue to try loading from storage
      }

      // If server load fails, try to load from storage
      final userData = await StorageUtils.getUserData();
      if (userData != null) {
        await updateUserData({'user': userData});
        debugPrint('✅ Loaded user data from storage');
        return;
      }

      throw Exception('Could not load user profile from server or storage');
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      rethrow;
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await ApiService().checkUsername(username);
      return response['success'] == true && response['available'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> validateToken() async {
    // If not initialized, perform initialization first
    if (!_isInitialized) {
      debugPrint('⚠️ Auth not initialized, initializing first...');
      final initialized = await initializeAuth();
      if (!initialized) {
        return {'success': false, 'message': 'Auth initialization failed'};
      }
    }

    try {
      if (_token == null) {
        return {'success': false, 'message': 'No token available'};
      }

      final response = await ApiService.post(
        ApiConfig.validateToken,
        {'token': _token},
      );

      if (response['success'] == true || response['status'] == 'success') {
        _isLoggedIn = true;
        _isInitialized = true;
        notifyListeners();
      } else {
        _token = null;
        _userId = null;
        _isLoggedIn = false;
        notifyListeners();
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      print('🔄 Updating profile...');
      print('📝 Profile data: $data');

      // Validate required fields are not null
      if (data['fullName'] == null) {
        throw 'Full name is required';
      }

      // Clean up the data by removing null values
      data.removeWhere((key, value) => value == null);

      final response = await ApiService.post(
        ApiConfig.updateProfile,
        data,
      );

      if (response['success']) {
        print('✅ Profile updated successfully');
        // Update local user data if needed
        if (response['data'] != null && response['data']['user'] != null) {
          _userData = {...?_userData, ...response['data']['user']};
          notifyListeners();
        }
        return response;
      } else {
        print('❌ Profile update failed: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.resetPassword,
        {
          'userId': _userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> requestPasswordResetUser(String email) async {
    try {
      if (email.isEmpty) {
        throw ValidationError('Email is required');
      }

      final response = await ApiService.post(
        ApiConfig.requestPasswordReset,
        {'email': email},
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Password reset link has been sent'
        };
      }

      throw ApiError(response['message'] ?? 'Password reset failed');
    } catch (e) {
      print('Password reset request error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyResetOtpUser({
    required String email,
    required String otp,
  }) async {
    try {
      if (email.isEmpty || otp.isEmpty) {
        throw ValidationError('Email and OTP are required');
      }

      final response = await ApiService.post(
        ApiConfig.verifyResetOtp,
        {
          'email': email,
          'otp': otp,
        },
      );

      if (response['success'] == true) {
        return {'success': true, 'message': 'OTP verification successful'};
      }

      throw AuthenticationError(
          response['message'] ?? 'OTP verification failed');
    } catch (e) {
      print('Reset OTP verification error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
        throw ValidationError('All fields are required');
      }

      // First verify OTP to get token
      final verifyResponse = await ApiService.post(
        '/auth/verify-reset-otp',
        {
          'email': email,
          'otp': otp,
        },
      );

      if (!verifyResponse['success']) {
        throw ApiError(verifyResponse['message'] ?? 'OTP verification failed');
      }

      final resetToken = verifyResponse['resetToken'];
      if (resetToken == null) {
        throw ApiError('Reset token not received');
      }

      // Now reset password with token
      final response = await ApiService.post(
        '/auth/reset-password',
        {
          'email': email,
          'token': resetToken,
          'password': newPassword,
        },
      );

      if (response['success']) {
        return {'success': true, 'message': 'Password reset successful'};
      }

      throw ApiError(response['message'] ?? 'Password reset failed');
    } catch (e) {
      print('Password reset error: $e');
      if (e is ApiError) {
        return {'success': false, 'message': e.message, 'error': 'API_ERROR'};
      }
      return {
        'success': false,
        'message': e.toString(),
        'error': 'UNKNOWN_ERROR'
      };
    }
  }

  Future<Map<String, dynamic>> resetPasswordUser({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
        throw ValidationError('All fields are required');
      }

      final response = await ApiService.post(
        ApiConfig.resetPassword,
        {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (response['success'] == true) {
        return {'success': true, 'message': 'Password changed successfully'};
      }

      throw ApiError(response['message'] ?? 'Password reset failed');
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await ApiService.post(
        ApiConfig.requestPasswordReset,
        {'email': email},
      );
      return response['success'] == true;
    } catch (e) {
      print('Error requesting password reset: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    try {
      final response = await ApiService.post(
        '/auth/verify-reset-otp',
        {
          'email': email,
          'otp': otp,
        },
      );
      return response;
    } catch (e) {
      print('Error verifying reset OTP: $e');
      return {'success': false, 'message': e.toString(), 'error': 'API_ERROR'};
    }
  }

  Future<bool> resetPasswordWithToken({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        '/auth/reset-password',
        {
          'email': email,
          'token': token,
          'password': password,
        },
      );
      return response['success'] == true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  Future<void> loadReferralEarnings() async {
    try {
      final response = await ApiService.get('/api/referral/earnings');
      if (response['success'] == true) {
        _referralEarnings = double.tryParse(
                response['totalEarnings'] ?? '0.000000000000000000') ??
            0.0;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading referral earnings: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<List<dynamic>> getReferredUsers() async {
    try {
      final response = await ApiService.get('/api/referral/users');
      if (response['success'] == true) {
        return response['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Error getting referred users: $e');
      return [];
    }
  }

  Future<bool> claimReferralBonus() async {
    try {
      final result = await ApiService.post('/referral/claim-bonus', {});

      if (result['success'] == true) {
        // Update local state
        _referralEarnings = 0.0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to claim referral bonus: ${e.toString()}');
    }
  }

  Future<String?> getToken() async {
    try {
      if (_token != null) {
        return _token;
      }
      final token = await StorageUtils.getToken();
      if (token != null) {
        _token = token;
        notifyListeners();
      }
      return token;
    } catch (e) {
      print('❌ Token retrieval error: $e');
      return null;
    }
  }

  Future<void> setToken(String token) async {
    try {
      debugPrint('🔄 Saving token...');
      debugPrint('📝 Token to save: ${token.substring(0, 20)}...');

      // Save token to storage
      await StorageUtils.saveToken(token);
      debugPrint('✅ Token saved to web storage');

      // Update token in ApiConfig
      ApiConfig.setToken(token);
      debugPrint('🔑 Token updated in ApiConfig: Set');
      debugPrint('✅ Token updated in ApiConfig');

      _token = token;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
      rethrow;
    }
  }

  Future<void> clearToken() async {
    try {
      _token = null;
      ApiConfig.clear();
      await StorageUtils.removeToken();
      notifyListeners();
    } catch (e) {
      print('❌ Token clearing error: $e');
      rethrow;
    }
  }

  Future<void> setUserId(String id) async {
    try {
      print('🔄 Setting user ID: $id');

      if (id.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      _userId = id;

      // Save to secure storage
      await StorageUtils.saveUserId(id);

      // Update API config
      ApiConfig.setUserId(id);

      print('✅ User ID set successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error setting user ID: $e');
      rethrow;
    }
  }

  // Get user's referrals
  Future<Map<String, dynamic>> getUserReferrals() async {
    try {
      final response = await ApiService.get('/referrals');
      return response;
    } catch (e) {
      print('Error getting referrals: $e');
      rethrow;
    }
  }

  // Generate new referral code
  Future<Map<String, dynamic>> generateNewReferralCode() async {
    try {
      final response =
          await ApiService.post('/referrals/generate', {'method': 'POST'});
      if (response['success']) {
        _referralCode = response['data']['referralCode'];
        notifyListeners();
      }
      return response;
    } catch (e) {
      print('Error generating referral code: $e');
      rethrow;
    }
  }

  // Check referral code validity
  Future<Map<String, dynamic>> checkReferralCode(String code) async {
    try {
      final response =
          await ApiService.post('/referrals/validate', {'code': code});
      return response;
    } catch (e) {
      print('Error validating referral code: $e');
      rethrow;
    }
  }

  Future<String?> getUserId() async {
    try {
      return _userId ?? await StorageUtils.getToken();
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  // Remove this unused method since updateUserData handles this functionality

  Future<void> sendVerificationEmail() async {
    try {
      print('📧 Sending verification email');

      final response = await ApiService.post(
        '/auth/send-verification',
        {'email': _email},
      );

      if (response['success']) {
        print('✅ Verification email sent successfully');
      } else {
        throw Exception(
            response['message'] ?? 'Failed to send verification email');
      }
    } catch (e) {
      print('❌ Error sending verification email: $e');
      rethrow;
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      print('🔍 Verifying email with token');

      final response = await ApiService.post(
        '/auth/verify-email',
        {'token': token},
      );

      if (response['success']) {
        print('✅ Email verified successfully');
        // Update user state
        if (_user != null) {
          _user = _user!.copyWith(isVerified: true);
          notifyListeners();
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Email verification failed');
      }
    } catch (e) {
      print('❌ Error verifying email: $e');
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      print('📧 Resending verification email');

      final response = await ApiService.post(
        '/auth/resend-verification',
        {'email': _email},
      );

      if (response['success']) {
        print('✅ Verification email resent successfully');
      } else {
        throw Exception(
            response['message'] ?? 'Failed to resend verification email');
      }
    } catch (e) {
      print('❌ Error resending verification email: $e');
      rethrow;
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ Connectivity check error: $e');
      return false;
    }
  }
}
