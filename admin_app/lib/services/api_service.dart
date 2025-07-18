import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.baseUrl + endpoint);
      final headers = {
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };
      print('POST $url');
      print('Request headers: $headers');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      // Check for authentication errors
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      }

      return response;
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized: Token expired or invalid');
      }
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> get(String endpoint, {bool auth = false}) async {
    try {
      final url = Uri.parse(ApiConfig.baseUrl + endpoint);
      final headers = {
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };
      print('GET $url');
      print('Request headers: $headers');
      final response = await http.get(url, headers: headers);

      // Check for authentication errors
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      }

      return response;
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized: Token expired or invalid');
      }
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.baseUrl + endpoint);
      final headers = {
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };
      print('PUT $url');
      print('Request headers: $headers');
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      }
      return response;
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized: Token expired or invalid');
      }
      throw Exception('Network error: $e');
    }
  }

  // Users
  Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await get(
        ApiConfig.getUsers,
        auth: true,
      ); // auth: true hardcoded
      print(
        'fetchUsers response: statusCode =  [32m [1m [4m [7m [41m [43m [44m [45m [46m [47m [49m [0m${response.statusCode}, body = ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['users'] ?? [];
      } else {
        print(
          'fetchUsers error: statusCode = ${response.statusCode}, body = ${response.body}',
        );
        throw Exception('Failed to load users');
      }
    } catch (e, stack) {
      print('Exception in fetchUsers: $e');
      print('Stacktrace: $stack');
      throw Exception('Failed to load users: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserById(String userId) async {
    // yahan userId (USR...) hi bhejna hai
    final response = await get(ApiConfig.getUserById + userId, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<bool> blockUser(String userId) async {
    // yahan userId (USR...) hi bhejna hai
    final response = await post(
      '${ApiConfig.blockUser}$userId/block',
      {},
      auth: true,
    );
    return response.statusCode == 200;
  }

  Future<bool> unblockUser(String userId) async {
    // yahan userId (USR...) hi bhejna hai
    final response = await post(
      '${ApiConfig.unblockUser}$userId/unblock',
      {},
      auth: true,
    );
    return response.statusCode == 200;
  }

  // Wallet
  Future<Map<String, dynamic>> fetchUserWallet(String userId) async {
    // yahan userId (USR...) hi bhejna hai
    final response = await get(
      '${ApiConfig.getUserWallet}$userId/wallet',
      auth: true, // Ensure auth header is always sent
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load wallet');
    }
  }

  Future<dynamic> adjustWallet({
    required String userId,
    required double amount,
    required String type, // 'credit' ya 'debit'
    String? note,
  }) async {
    // yahan userId (USR...) hi bhejna hai
    final url =
        '${ApiConfig.baseUrl}${ApiConfig.adjustWallet}$userId/wallet/adjust';
    final headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final body = {
      'amount': amount.toStringAsFixed(18), // <-- yahan fix kiya
      'type': type,
      'status': 'completed', // <-- status field add kiya
      if (note != null) 'note': note,
    };
    print('Current token (adjustWallet): $_token'); // <-- yahan print kiya
    print(
      'Adjusting wallet: userId=\x1b[32m$userId\x1b[0m, amount=\x1b[33m${body['amount']}\x1b[0m, type=\x1b[36m$type\x1b[0m, status=\x1b[35m${body['status']}\x1b[0m, note=$note',
    );
    print('POST $url');
    print('Request headers: $headers');
    print('Request body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print(
        'AdjustWallet response: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print(
          'AdjustWallet error: status=${response.statusCode}, body=${response.body}',
        );
        throw Exception(
          'Failed to adjust wallet: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('AdjustWallet exception: $e');
      print('Exception type: ${e.runtimeType}');

      // Detailed error analysis
      if (e is SocketException) {
        print('Network error: SocketException - ${e.message}');
        print('OS Error: ${e.osError}');
        print('Address: ${e.address}');
        print('Port: ${e.port}');
      } else if (e is HttpException) {
        print('HTTP error: HttpException - ${e.message}');
      } else if (e is FormatException) {
        print('Format error: FormatException - ${e.message}');
      } else if (e is TimeoutException) {
        print('Timeout error: TimeoutException - ${e.message}');
      } else if (e is HandshakeException) {
        print('SSL/TLS error: HandshakeException - ${e.message}');
      } else if (e is CertificateException) {
        print('Certificate error: CertificateException - ${e.message}');
      }

      // Check if it's a CORS issue
      if (e.toString().contains('CORS') || e.toString().contains('cors')) {
        print('CORS ERROR DETECTED! This is likely a CORS policy issue.');
      }

      // Check if it's a connection refused
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('connection refused')) {
        print(
          'CONNECTION REFUSED! Backend server might not be running on port 5000.',
        );
      }

      // Check if it's a timeout
      if (e.toString().contains('timeout') ||
          e.toString().contains('Timeout')) {
        print('TIMEOUT ERROR! Request took too long to complete.');
      }

      throw Exception('Failed to adjust wallet: $e');
    }
  }

  Future<List<dynamic>> fetchWalletTransactions(String userId) async {
    // yahan userId (USR...) hi bhejna hai
    final response = await get(
      '${ApiConfig.getWalletTransactions}$userId/wallet/transactions',
      auth: true,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load wallet transactions');
    }
  }

  // Withdrawals
  Future<List<dynamic>> fetchPendingWithdrawals() async {
    final response = await get(ApiConfig.getPendingWithdrawals, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['withdrawals'] ?? [];
    } else {
      throw Exception('Failed to load withdrawals');
    }
  }

  Future<bool> approveWithdrawal(String withdrawalId, String adminNote) async {
    final response = await post(ApiConfig.approveWithdrawal, {
      'withdrawalId': withdrawalId,
      'adminNote': adminNote,
    }, auth: true);
    return response.statusCode == 200;
  }

  Future<bool> rejectWithdrawal(String withdrawalId, String adminNote) async {
    final response = await post(ApiConfig.rejectWithdrawal, {
      'withdrawalId': withdrawalId,
      'adminNote': adminNote,
    }, auth: true);
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> fetchWithdrawalStats() async {
    final response = await get(ApiConfig.getWithdrawalStats, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load withdrawal stats');
    }
  }

  // Referral
  Future<Map<String, dynamic>> fetchReferralStats() async {
    final response = await get(ApiConfig.getReferralStats, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load referral stats');
    }
  }

  Future<List<dynamic>> fetchReferralList() async {
    final response = await get(ApiConfig.getReferralList, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load referral list');
    }
  }

  // Ads
  // fetchAdStats aur fetchAdList methods hata do

  // Notifications
  Future<bool> sendNotification(String message) async {
    final response = await post(ApiConfig.sendNotification, {
      'message': message,
    }, auth: true);
    return response.statusCode == 200;
  }

  Future<List<dynamic>> fetchNotifications() async {
    final response = await get(ApiConfig.getNotifications, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Export
  Future<http.Response> exportUsers() async {
    return await get(ApiConfig.exportUsers, auth: true);
  }

  Future<http.Response> exportWallets() async {
    return await get(ApiConfig.exportWallets, auth: true);
  }

  Future<http.Response> exportTransactions() async {
    return await get(ApiConfig.exportTransactions, auth: true);
  }

  // Manual Wallet Control
  Future<bool> manualWalletCredit(
    String userId,
    double amount,
    String note,
  ) async {
    final response = await post(ApiConfig.manualWalletCredit, {
      'userId': userId,
      'amount': amount,
      'note': note,
    }, auth: true);
    return response.statusCode == 200;
  }

  Future<bool> manualWalletDebit(
    String userId,
    double amount,
    String note,
  ) async {
    final response = await post(ApiConfig.manualWalletDebit, {
      'userId': userId,
      'amount': amount,
      'note': note,
    }, auth: true);
    return response.statusCode == 200;
  }

  // Audit Log
  Future<List<dynamic>> fetchAuditLogs() async {
    final response = await get(ApiConfig.getAuditLogs, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load audit logs');
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await get(ApiConfig.getDashboardStats, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  Future<int> fetchActiveUserCount() async {
    final response = await get('/admin/users/active-count', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['count'] ?? 0;
    } else {
      throw Exception('Failed to load active user count');
    }
  }

  Future<int> fetchTotalWithdrawals() async {
    final response = await get('/admin/withdrawals/stats', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data['data']['total']['totalWithdrawals'] ?? 0;
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    } else {
      throw Exception('Failed to load total withdrawals');
    }
  }

  Future<List<dynamic>> fetchLatestWithdrawals() async {
    final response = await get('/admin/withdrawals?limit=5', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawList = data['data']['withdrawals'] ?? [];
      if (rawList is List) return rawList;
      // अगर string में आ जाए तो empty list return करो
      return [];
    } else {
      throw Exception('Failed to load latest withdrawals');
    }
  }

  Future<Map<String, dynamic>> fetchDashboardAnalytics() async {
    final response = await get('/admin/withdrawals/stats', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final total = data['data']['total'] ?? {};
      return {
        'totalWithdrawals': total['totalWithdrawals'] ?? 0,
        'totalAmount': total['totalAmount'] ?? '0',
        'averageAmount': total['averageAmount'] ?? '0',
      };
    } else {
      throw Exception('Failed to load dashboard analytics');
    }
  }

  Future<int> fetchTotalUserCount() async {
    final response = await get('/admin/users/count', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['count'] ?? 0;
    } else {
      throw Exception('Failed to load total user count');
    }
  }

  Future<List<int>> fetchUserActiveHours() async {
    final response = await get('/admin/users/active-hours', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final activeHours = data['data'] ?? List.filled(24, 0);

      // Handle both String and int types
      return activeHours.map<int>((item) {
        if (item is int) {
          return item;
        } else if (item is String) {
          return int.tryParse(item) ?? 0;
        } else {
          return 0;
        }
      }).toList();
    } else {
      throw Exception('Failed to load user active hours');
    }
  }

  // Platform-wide user activity (hourly)
  Future<List<int>> fetchPlatformUserActivityHours() async {
    final response = await get('/admin/users/activity-hours', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final hours = data['data'] ?? List.filled(24, 0);
      return List<int>.from(hours);
    } else {
      throw Exception('Failed to load platform user activity hours');
    }
  }

  // Wallets
  Future<List<dynamic>> fetchWallets() async {
    final response = await get('/admin/wallets', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['wallets'] ?? [];
    } else {
      throw Exception('Failed to load wallets');
    }
  }

  // All wallet transactions
  Future<List<dynamic>> fetchAllWalletTransactions() async {
    final response = await get('/admin/wallets/transactions', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['transactions'] ?? [];
    } else {
      throw Exception('Failed to load wallet transactions');
    }
  }

  // Market rates
  Future<Map<String, dynamic>> fetchMarketRates() async {
    final response = await get('/admin/wallets/rates', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load market rates');
    }
  }

  // Referral Settings
  Future<Map<String, dynamic>> getReferralSettings() async {
    final response = await get('/admin/settings/referral', auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load referral settings');
    }
  }

  Future<Map<String, dynamic>> updateReferralSettings(
    double percent,
    int days,
  ) async {
    final response = await put('/admin/settings/referral', {
      'referralDailyPercent': percent,
      'referralEarningDays': days,
    }, auth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to update referral settings');
    }
  }
}
