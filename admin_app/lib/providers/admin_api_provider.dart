import 'dart:async'; // Added for Timer
import 'dart:convert'; // Added for jsonDecode

import 'package:flutter/material.dart';
// Optional shared_preferences import
import 'package:shared_preferences/shared_preferences.dart' as prefs;

import '../services/api_service.dart';

class AdminApiProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  bool _isLoading = false;
  String? _error;
  List<dynamic> _users = [];
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _pendingWithdrawals = [];
  Map<String, dynamic> _withdrawalStats = {};
  List<dynamic> _referralList = [];
  Map<String, dynamic> _referralStats = {};
  Map<String, dynamic> _adStats = {};
  List<dynamic> _adList = [];
  List<dynamic> _notifications = [];
  List<dynamic> _auditLogs = [];
  int _activeUserCount = 0;
  int _totalWithdrawals = 0;
  List<dynamic> _latestWithdrawals = [];
  Map<String, dynamic> _dashboardAnalytics = {};
  int _totalUserCount = 0;
  List<int> _userActiveHours = List.filled(24, 0);
  List<int> _platformUserActiveHours = List.filled(24, 0);
  List<int> get platformUserActiveHours => _platformUserActiveHours;

  // Wallet related properties
  final List<dynamic> _wallets = [];
  final List<dynamic> _walletTransactions = [];
  final Map<String, dynamic> _walletStats = {};
  int _totalWallets = 0;
  double _totalWalletBalance = 0.0;
  double _dailyWalletGrowth = 0.0;
  int _totalTransactions = 0;

  // Session management
  bool _isInitialized = false;
  DateTime? _lastActivity;
  Timer? _sessionTimer;
  bool _usePersistence = true; // Flag to track if persistence is available

  // In-memory fallback storage
  String? _inMemoryToken;
  DateTime? _inMemoryLastActivity;

  // Market rates
  Map<String, double> _marketRates = {'BTC': 1.0, 'USD': 0.0, 'INR': 0.0};
  String _selectedCurrency = 'BTC';

  // Referral settings
  Map<String, dynamic> _referralSettings = {
    'referralDailyPercent': 1.0,
    'referralEarningDays': 30,
  };
  Map<String, dynamic> get referralSettings => _referralSettings;

  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _token != null;
  List<dynamic> get users => _users;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<dynamic> get pendingWithdrawalsList => _pendingWithdrawals;
  Map<String, dynamic> get withdrawalStats => _withdrawalStats;
  List<dynamic> get referralList => _referralList;
  Map<String, dynamic> get referralStats => _referralStats;
  Map<String, dynamic> get adStats => _adStats;
  List<dynamic> get adList => _adList;
  List<dynamic> get notifications => _notifications;
  List<dynamic> get auditLogs => _auditLogs;
  int get activeUserCount => _activeUserCount;
  int get totalWithdrawals => _totalWithdrawals;
  List<dynamic> get latestWithdrawals => _latestWithdrawals;
  Map<String, dynamic> get dashboardAnalytics => _dashboardAnalytics;
  int get totalUserCount => _totalUserCount;
  List<int> get userActiveHours => _userActiveHours;

  // Wallet getters
  List<dynamic> get wallets => _wallets;
  List<dynamic> get walletTransactions => _walletTransactions;
  Map<String, dynamic> get walletStats => _walletStats;
  int get totalWallets => _totalWallets;
  double get totalWalletBalance => _totalWalletBalance;
  double get dailyWalletGrowth => _dailyWalletGrowth;
  int get totalTransactions => _totalTransactions;

  // Withdrawal getters
  int get pendingWithdrawals {
    final val = _withdrawalStats['pending'];
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  int get completedWithdrawals {
    final val = _withdrawalStats['completed'];
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  int get rejectedWithdrawals {
    final val = _withdrawalStats['rejected'];
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  double get totalWithdrawalAmount {
    final val = _withdrawalStats['totalAmount'];
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  List<dynamic> get withdrawals => _pendingWithdrawals;

  // Market rates getters
  Map<String, double> get marketRates => _marketRates;
  String get selectedCurrency => _selectedCurrency;

  // Initialize provider and load saved token
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefsInstance = await prefs.SharedPreferences.getInstance();
      final savedToken = prefsInstance.getString('admin_token');
      final lastActivity = prefsInstance.getString('last_activity');

      if (savedToken != null && lastActivity != null) {
        final lastActivityTime = DateTime.parse(lastActivity);
        final now = DateTime.now();

        // Check if session is still valid (24 hours)
        if (now.difference(lastActivityTime).inHours < 24) {
          _token = savedToken;
          _apiService.setToken(savedToken);
          _lastActivity = lastActivityTime;
          _startSessionTimer();
          print('Token restored from storage: ${_token?.substring(0, 20)}...');
        } else {
          // Session expired, clear saved data
          await _clearSavedData();
        }
      }
    } catch (e) {
      print('Error initializing provider: $e');
      // Don't fail initialization if shared_preferences is not available
      // Just continue without persistent storage
      if (e.toString().contains('MissingPluginException')) {
        print(
          'SharedPreferences plugin not available, continuing without persistence',
        );
        _usePersistence = false;

        // Try to restore from in-memory storage
        if (_inMemoryToken != null && _inMemoryLastActivity != null) {
          final now = DateTime.now();
          if (now.difference(_inMemoryLastActivity!).inHours < 24) {
            _token = _inMemoryToken;
            _apiService.setToken(_inMemoryToken!);
            _lastActivity = _inMemoryLastActivity;
            _startSessionTimer();
            print('Token restored from memory: ${_token?.substring(0, 20)}...');
          }
        }
      } else {
        await _clearSavedData();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Start session timer for auto-logout
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkSessionTimeout();
    });
  }

  // Check if session is about to timeout
  void _checkSessionTimeout() {
    if (_lastActivity == null) return;

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);

    // Warn 5 minutes before session expires (23 hours)
    if (timeSinceLastActivity.inHours >= 23) {
      print(
        'Session timeout warning: ${timeSinceLastActivity.inHours} hours since last activity',
      );
      // You can show a dialog here to warn the user
    }

    // Auto logout after 24 hours
    if (timeSinceLastActivity.inHours >= 24) {
      print('Session expired, auto logging out...');
      logout();
    }
  }

  // Save token to persistent storage
  Future<void> _saveToken(String token) async {
    // Always save to in-memory storage
    _inMemoryToken = token;
    _inMemoryLastActivity = DateTime.now();

    if (!_usePersistence) {
      _lastActivity = DateTime.now();
      _startSessionTimer();
      return;
    }

    try {
      final prefsInstance = await prefs.SharedPreferences.getInstance();
      await prefsInstance.setString('admin_token', token);
      await prefsInstance.setString(
        'last_activity',
        DateTime.now().toIso8601String(),
      );
      _lastActivity = DateTime.now();
      _startSessionTimer();
      print('Token saved to storage');
    } catch (e) {
      print('Error saving token: $e');
      // Continue without persistence if plugin is not available
      if (e.toString().contains('MissingPluginException')) {
        _usePersistence = false;
      }
      _lastActivity = DateTime.now();
      _startSessionTimer();
    }
  }

  // Clear saved data
  Future<void> _clearSavedData() async {
    // Always clear in-memory storage
    _inMemoryToken = null;
    _inMemoryLastActivity = null;

    if (!_usePersistence) {
      _sessionTimer?.cancel();
      return;
    }

    try {
      final prefsInstance = await prefs.SharedPreferences.getInstance();
      await prefsInstance.remove('admin_token');
      await prefsInstance.remove('last_activity');
      _sessionTimer?.cancel();
      print('Saved data cleared');
    } catch (e) {
      print('Error clearing saved data: $e');
      // Continue even if clearing fails
      _sessionTimer?.cancel();
      if (e.toString().contains('MissingPluginException')) {
        _usePersistence = false;
      }
    }
  }

  // Update last activity
  Future<void> _updateLastActivity() async {
    // Always update in-memory storage
    _inMemoryLastActivity = DateTime.now();

    if (!_usePersistence) {
      _lastActivity = DateTime.now();
      return;
    }

    try {
      final prefsInstance = await prefs.SharedPreferences.getInstance();
      await prefsInstance.setString(
        'last_activity',
        DateTime.now().toIso8601String(),
      );
      _lastActivity = DateTime.now();
    } catch (e) {
      print('Error updating last activity: $e');
      // Continue without persistence if plugin is not available
      if (e.toString().contains('MissingPluginException')) {
        _usePersistence = false;
      }
      _lastActivity = DateTime.now();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting login for email: $email');
      final response = await _apiService.post('/admin/login', {
        'email': email,
        'password': password,
      });

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        print(
          'Parsed token: ${token != null ? token.substring(0, 20) + "..." : "null"}',
        );

        if (token != null) {
          _token = token;
          _apiService.setToken(token);
          await _saveToken(token);
          await _updateLastActivity();
          print('Login successful! Token set in ApiService');
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print('Token not found in login response!');
          _error = 'Server error: Token not received';
        }
      } else if (response.statusCode == 401) {
        print('Login failed: Invalid credentials');
        _error = 'Invalid email or password';
      } else {
        print('Login failed: HTTP ${response.statusCode}');
        _error = 'Server error: HTTP ${response.statusCode}';
      }
    } catch (e) {
      print('Login exception: $e');

      // Better error messages for different types of errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        _error =
            'Network error: Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        _error =
            'Connection timeout: Server is taking too long to respond. Please try again.';
      } else if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        _error = 'Invalid email or password';
      } else if (e.toString().contains('Server error: HTTP 503')) {
        _error = 'Server temporarily unavailable. Trying backup server...';
        // Trigger UI update to show server switch
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
      } else {
        _error = 'Login failed: ${e.toString().replaceAll('Exception: ', '')}';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _token = null;
    _apiService.setToken(null);
    _users = [];
    _dashboardStats = {};
    _pendingWithdrawals = [];
    _withdrawalStats = {};
    _referralList = [];
    _referralStats = {};
    _adStats = {};
    _adList = [];
    _notifications = [];
    _auditLogs = [];
    _wallets.clear();
    _walletTransactions.clear();
    _walletStats.clear();
    _clearSavedData();
    notifyListeners();
  }

  // Helper: Ensure ApiService has token before any API call
  void _ensureToken() {
    if (_token != null && _apiService.token != _token) {
      _apiService.setToken(_token);
    }
  }

  // Enhanced error handling for API calls
  Future<T?> _handleApiCall<T>(Future<T> Function() apiCall) async {
    if (!_isInitialized) {
      await initialize();
    }

    _ensureToken();
    await _updateLastActivity();

    try {
      return await apiCall();
    } catch (e) {
      print('API call error: $e');

      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('Token expired')) {
        print('Authentication error detected, logging out...');
        logout();
        _error = 'Session expired. Please login again.';
      } else {
        _error = 'Request failed: $e';
      }

      notifyListeners();
      return null;
    }
  }

  // Users
  Future<void> fetchUsers() async {
    final users = await _handleApiCall(() => _apiService.fetchUsers());
    if (users != null) {
      _users = users;
      _totalUserCount = users.length; // Update total user count from users list
      print(
        'Users fetched: ${users.length}, Total user count: $_totalUserCount',
      );
      notifyListeners();
    } else {
      // If users fetch fails, try to get count from API
      try {
        final count = await _apiService.fetchTotalUserCount();
        _totalUserCount = count;
        print('Fallback: Total user count from API: $_totalUserCount');
        notifyListeners();
      } catch (e) {
        print('Failed to fetch user count: $e');
      }
    }
  }

  Future<void> blockUser(String userId) async {
    final success = await _handleApiCall(() => _apiService.blockUser(userId));
    if (success == true) {
      await fetchUsers();
    } else {
      _error = 'Failed to block user';
      notifyListeners();
    }
  }

  Future<void> unblockUser(String userId) async {
    final success = await _handleApiCall(() => _apiService.unblockUser(userId));
    if (success == true) {
      await fetchUsers();
    } else {
      _error = 'Failed to unblock user';
      notifyListeners();
    }
  }

  // Dashboard
  Future<void> fetchDashboardStats() async {
    final stats = await _handleApiCall(() => _apiService.fetchDashboardStats());
    if (stats != null) {
      _dashboardStats = stats;
      notifyListeners();
    }
  }

  // Referral Analytics
  Future<void> fetchReferralAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Simulate API call with mock data
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock referral analytics data
      _referralStats = {
        'totalReferrals': 1247,
        'totalRewards': 0.045,
        'activeReferrers': 89,
        'conversionRate': 23.4,
        'weeklyGrowth': 15.2,
        'monthlyGrowth': 8.7,
        'totalEarnings': 0.123,
        'pendingRewards': 0.012,
      };

      // Mock referral list data
      _referralList = [
        {
          'id': '1',
          'name': 'John Doe',
          'email': 'john.doe@email.com',
          'referrals': 45,
          'earnings': '0.008 BTC',
          'status': 'active',
          'lastReferral': '2024-01-15T10:30:00Z',
        },
        {
          'id': '2',
          'name': 'Sarah Smith',
          'email': 'sarah.smith@email.com',
          'referrals': 32,
          'earnings': '0.006 BTC',
          'status': 'active',
          'lastReferral': '2024-01-14T15:20:00Z',
        },
        {
          'id': '3',
          'name': 'Mike Wilson',
          'email': 'mike.wilson@email.com',
          'referrals': 28,
          'earnings': '0.005 BTC',
          'status': 'active',
          'lastReferral': '2024-01-13T09:45:00Z',
        },
        {
          'id': '4',
          'name': 'Emma Brown',
          'email': 'emma.brown@email.com',
          'referrals': 22,
          'earnings': '0.004 BTC',
          'status': 'inactive',
          'lastReferral': '2024-01-10T14:15:00Z',
        },
        {
          'id': '5',
          'name': 'Alex Johnson',
          'email': 'alex.johnson@email.com',
          'referrals': 18,
          'earnings': '0.003 BTC',
          'status': 'active',
          'lastReferral': '2024-01-12T11:30:00Z',
        },
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch referral analytics: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Settings
  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Simulate API call with mock data
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock settings data
      _dashboardStats = {
        'systemStatus': {
          'miningServer': 'Online',
          'database': 'Online',
          'apiGateway': 'Online',
          'firebase': 'Online',
        },
        'miningSettings': {
          'autoMining': true,
          'miningPower': 85.5,
          'energyEfficiency': 92.3,
          'maintenanceMode': false,
        },
        'appSettings': {
          'notifications': true,
          'darkMode': true,
          'autoUpdate': true,
          'analytics': true,
        },
        'securitySettings': {
          'twoFactorAuth': true,
          'sessionTimeout': 30,
          'ipWhitelist': false,
          'auditLogging': true,
        },
        'advancedSettings': {
          'debugMode': false,
          'backupFrequency': 'daily',
          'logLevel': 'info',
          'cacheEnabled': true,
        },
      };

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch settings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Withdrawals
  Future<void> fetchWithdrawals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Real API call for pending withdrawals
      final withdrawals = await _handleApiCall(
        () => _apiService.fetchPendingWithdrawals(),
      );
      if (withdrawals != null) {
        _pendingWithdrawals = withdrawals;
      }
      // Real API call for withdrawal stats
      final stats = await _handleApiCall(
        () => _apiService.fetchWithdrawalStats(),
      );
      if (stats != null) {
        _withdrawalStats = stats;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch withdrawals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Withdrawals
  Future<void> fetchPendingWithdrawals() async {
    final withdrawals = await _handleApiCall(
      () => _apiService.fetchPendingWithdrawals(),
    );
    if (withdrawals != null) {
      _pendingWithdrawals = withdrawals;
    }
  }

  Future<void> approveWithdrawal(String withdrawalId, String adminNote) async {
    final success = await _handleApiCall(
      () => _apiService.approveWithdrawal(withdrawalId, adminNote),
    );
    if (success == true) {
      await fetchPendingWithdrawals();
    } else {
      _error = 'Failed to approve withdrawal';
      notifyListeners();
    }
  }

  Future<void> rejectWithdrawal(String withdrawalId, String adminNote) async {
    final success = await _handleApiCall(
      () => _apiService.rejectWithdrawal(withdrawalId, adminNote),
    );
    if (success == true) {
      await fetchPendingWithdrawals();
    } else {
      _error = 'Failed to reject withdrawal';
      notifyListeners();
    }
  }

  Future<void> fetchWithdrawalStats() async {
    final stats = await _handleApiCall(
      () => _apiService.fetchWithdrawalStats(),
    );
    if (stats != null) {
      _withdrawalStats = stats;
    }
  }

  // Referral
  Future<void> fetchReferralStats() async {
    try {
      final stats = await _handleApiCall(
        () => _apiService.fetchReferralStats(),
      );
      if (stats != null) {
        _referralStats = stats;
        print('Referral stats fetched successfully: ${stats.length} items');
      } else {
        print('Referral stats returned null, using empty data');
        _referralStats = {
          'totalReferrals': 0,
          'totalRewards': 0,
          'activeReferrers': 0,
          'conversionRate': 0,
          'weeklyGrowth': 0,
          'monthlyGrowth': 0,
          'totalEarnings': 0,
          'pendingRewards': 0,
          'referralGrowth': 0,
        };
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching referral stats: $e');
      _referralStats = {
        'totalReferrals': 0,
        'totalRewards': 0,
        'activeReferrers': 0,
        'conversionRate': 0,
        'weeklyGrowth': 0,
        'monthlyGrowth': 0,
        'totalEarnings': 0,
        'pendingRewards': 0,
        'referralGrowth': 0,
      };
      notifyListeners();
    }
  }

  Future<void> fetchReferralList() async {
    try {
      final list = await _handleApiCall(() => _apiService.fetchReferralList());
      if (list != null) {
        _referralList = list;
        print('Referral list fetched successfully: ${list.length} items');
      } else {
        print('Referral list returned null, using empty list');
        _referralList = [];
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching referral list: $e');
      _referralList = [];
      notifyListeners();
    }
  }

  // Ads
  // fetchAdStats, fetchAdList methods hata do

  // Notifications
  Future<void> sendNotification(String message) async {
    final success = await _handleApiCall(
      () => _apiService.sendNotification(message),
    );
    if (success == true) {
      await fetchNotifications();
    } else {
      _error = 'Failed to send notification';
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    final list = await _handleApiCall(() => _apiService.fetchNotifications());
    if (list != null) {
      _notifications = list;
    }
  }

  // Export methods
  Future<void> exportUsers() async {
    final response = await _handleApiCall(() => _apiService.exportUsers());
    if (response != null && response.statusCode == 200) {
      // Handle successful export
      print('Users exported successfully');
    } else {
      _error = 'Failed to export users';
    }
  }

  Future<void> exportWallets() async {
    final response = await _handleApiCall(() => _apiService.exportWallets());
    if (response != null && response.statusCode == 200) {
      // Handle successful export
      print('Wallets exported successfully');
    } else {
      _error = 'Failed to export wallets';
    }
  }

  Future<void> exportTransactions() async {
    final response = await _handleApiCall(
      () => _apiService.exportTransactions(),
    );
    if (response != null && response.statusCode == 200) {
      // Handle successful export
      print('Transactions exported successfully');
    } else {
      _error = 'Failed to export transactions';
    }
  }

  // Audit Log
  Future<void> fetchAuditLogs() async {
    final logs = await _handleApiCall(() => _apiService.fetchAuditLogs());
    if (logs != null) {
      _auditLogs = logs;
    }
  }

  Future<void> fetchActiveUserCount() async {
    final count = await _handleApiCall(
      () => _apiService.fetchActiveUserCount(),
    );
    if (count != null) {
      _activeUserCount = count;
      notifyListeners();
    }
  }

  Future<void> fetchTotalWithdrawals() async {
    final count = await _handleApiCall(
      () => _apiService.fetchTotalWithdrawals(),
    );
    if (count != null) {
      _totalWithdrawals = count;
      notifyListeners();
    }
  }

  Future<void> fetchLatestWithdrawals() async {
    final list = await _handleApiCall(
      () => _apiService.fetchLatestWithdrawals(),
    );
    if (list != null) {
      _latestWithdrawals = list;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardAnalytics() async {
    final data = await _handleApiCall(
      () => _apiService.fetchDashboardAnalytics(),
    );
    if (data != null) {
      _dashboardAnalytics = data;

      // Update dashboard stats with real data
      _dashboardStats = {
        'totalEarnings': data['totalEarnings'] ?? 0.0,
        'dailyMining': data['dailyMining'] ?? 0.0,
        'userGrowth': data['userGrowth'] ?? 0.0,
        'activeUserGrowth': data['activeUserGrowth'] ?? 0.0,
        'earningsGrowth': data['earningsGrowth'] ?? 0.0,
        'miningGrowth': data['miningGrowth'] ?? 0.0,
        'securityScore': data['systemHealth'] ?? 100.0,
        'revenueData': data['revenueData'] ?? [],
        'miningData': data['miningData'] ?? [],
      };

      notifyListeners();
    }
  }

  Future<void> fetchTotalUserCount() async {
    final count = await _handleApiCall(() => _apiService.fetchTotalUserCount());
    if (count != null) {
      _totalUserCount = count;
      print('Total user count updated: $_totalUserCount');
      notifyListeners();
    }
  }

  Future<void> fetchUserActiveHours() async {
    final hours = await _handleApiCall(
      () => _apiService.fetchUserActiveHours(),
    );
    if (hours != null) {
      _userActiveHours = hours;
      notifyListeners();
    }
  }

  Future<void> fetchPlatformUserActivityHours() async {
    try {
      final hours = await _apiService.fetchPlatformUserActivityHours();
      _platformUserActiveHours = hours;
      notifyListeners();
    } catch (e) {
      print('Failed to fetch platform user activity hours: $e');
      // Set default empty array if API fails
      _platformUserActiveHours = List.filled(24, 0);
      notifyListeners();
    }
  }

  // Wallet methods
  Future<void> fetchWalletData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final wallets = await _apiService.fetchWallets();
      _wallets.clear();
      _wallets.addAll(wallets);
      // Calculate wallet stats
      _totalWallets = _wallets.length;
      _totalWalletBalance = _wallets.fold(
        0.0,
        (sum, wallet) => sum + (wallet['balance'] ?? 0.0),
      );
      _dailyWalletGrowth = 12.5; // TODO: calculate from backend if available
      _totalTransactions = _wallets
          .fold(
            0,
            (sum, wallet) => sum + ((wallet['transactionCount'] ?? 0) as int),
          )
          .toInt();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch wallet data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWalletTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final transactions = await _apiService.fetchAllWalletTransactions();
      _walletTransactions.clear();
      _walletTransactions.addAll(transactions);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch wallet transactions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWalletBalance(
    String walletId,
    double amount,
    String notes,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Update local wallet data
      final walletIndex = _wallets.indexWhere((w) => w['id'] == walletId);
      if (walletIndex != -1) {
        _wallets[walletIndex]['balance'] =
            (_wallets[walletIndex]['balance'] ?? 0.0) + amount;
        _wallets[walletIndex]['totalEarned'] =
            (_wallets[walletIndex]['totalEarned'] ?? 0.0) + amount;
        _wallets[walletIndex]['lastTransaction'] = DateTime.now()
            .toIso8601String();
        _wallets[walletIndex]['transactionCount'] =
            (_wallets[walletIndex]['transactionCount'] ?? 0) + 1;

        // Recalculate stats
        _totalWalletBalance = _wallets.fold(
          0.0,
          (sum, wallet) => sum + (wallet['balance'] ?? 0.0),
        );
        _totalTransactions = _wallets
            .fold(
              0,
              (sum, wallet) => sum + ((wallet['transactionCount'] ?? 0) as int),
            )
            .toInt();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add balance: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> freezeWallet(String walletId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Update local wallet data
      final walletIndex = _wallets.indexWhere((w) => w['id'] == walletId);
      if (walletIndex != -1) {
        _wallets[walletIndex]['status'] = 'frozen';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to freeze wallet: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unfreezeWallet(String walletId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Update local wallet data
      final walletIndex = _wallets.indexWhere((w) => w['id'] == walletId);
      if (walletIndex != -1) {
        _wallets[walletIndex]['status'] = 'active';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to unfreeze wallet: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMarketRates() async {
    try {
      final rates = await _apiService.fetchMarketRates();
      _marketRates = rates.map(
        (k, v) => MapEntry(
          k,
          (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0,
        ),
      );
      notifyListeners();
    } catch (e) {
      print('Failed to fetch market rates: $e');
    }
  }

  void setSelectedCurrency(String currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  Future<void> fetchReferralSettings() async {
    try {
      final settings = await _apiService.getReferralSettings();
      if (settings.isNotEmpty) {
        _referralSettings = settings;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching referral settings: $e');
    }
  }

  Future<void> updateReferralSettings(double percent, int days) async {
    try {
      final updated = await _apiService.updateReferralSettings(percent, days);
      if (updated.isNotEmpty) {
        _referralSettings = updated;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating referral settings: $e');
    }
  }

  /// Returns chart data for referral analytics
  /// type: 'Rewards' (sum of daily_reward), 'Referrals' (new referrals count)
  /// period: 'Weekly' (7 days), 'Monthly' (30 days)
  Map<String, dynamic> getReferralChartData({
    String type = 'Rewards',
    String period = 'Weekly',
  }) {
    final now = DateTime.now();
    int days = period == 'Monthly' ? 30 : 7;
    List<String> labels = [];
    List<double> values = [];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final label = period == 'Monthly'
          ? '${date.day}/${date.month}'
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      labels.add(label);
      double value = 0;
      if (type == 'Rewards') {
        // Sum of all daily_reward earnings for this day
        for (final referral in _referralList) {
          if (referral['earningsHistory'] is List) {
            for (final earning in referral['earningsHistory']) {
              if (earning['type'] == 'daily_reward' &&
                  earning['timestamp'] != null) {
                final earningDate = DateTime.tryParse(
                  earning['timestamp'].toString(),
                );
                if (earningDate != null &&
                    earningDate.year == date.year &&
                    earningDate.month == date.month &&
                    earningDate.day == date.day) {
                  value += double.tryParse(earning['amount'].toString()) ?? 0.0;
                }
              }
            }
          }
        }
      } else if (type == 'Referrals') {
        // Count of new referrals created on this day
        for (final referral in _referralList) {
          if (referral['createdAt'] != null) {
            final created = DateTime.tryParse(referral['createdAt'].toString());
            if (created != null &&
                created.year == date.year &&
                created.month == date.month &&
                created.day == date.day) {
              value += 1;
            }
          }
        }
      }
      values.add(double.parse(value.toStringAsFixed(8)));
    }
    return {'labels': labels, 'values': values};
  }
}
