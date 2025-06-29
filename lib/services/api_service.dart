import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/api_config.dart';
import '../utils/error_handler.dart';
import '../utils/number_formatter.dart';
import '../utils/storage_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Constants for retry logic
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Other instance variables
  bool _isConnected = false;
  IO.Socket? _socket;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 2);
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  static const Duration _timeout = Duration(seconds: 30);

  // Add callbacks
  Function(double)? onBalanceUpdate;
  Function(String)? _onError;
  Function()? onReconnected;
  Function()? onDisconnected;
  set onError(Function(String)? callback) => _onError = callback;

  Future<String?> _getAuthToken() async {
    try {
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No auth token found');
        return null; // Return null instead of throwing for public endpoints
      }
      debugPrint('✅ Got auth token: ${token.substring(0, 10)}...');
      debugPrint('🔐 Token parts: ${token.split('.').length}');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null; // Return null instead of throwing for public endpoints
    }
  }

  static Future<bool> checkConnectivity() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        debugPrint(
            'Checking connectivity (attempt ${attempts + 1}/$maxAttempts)');

        // Try to get working URL first
        final workingUrl = await ApiConfig.getWorkingUrl();
        debugPrint('Using working URL: $workingUrl');

        final isAvailable = await ApiConfig.isServerAvailable();
        if (isAvailable) {
          debugPrint('Server connection successful');
          return true;
        }

        attempts++;
        if (attempts < maxAttempts) {
          const delay = ApiConfig.retryDelay;
          debugPrint('Waiting ${delay.inSeconds}s before next attempt');
          await Future.delayed(delay);
        }
      } catch (e) {
        debugPrint('Connection error: $e');
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(ApiConfig.retryDelay);
        }
      }
    }

    debugPrint('All connection attempts failed');
    return false;
  }

  Future<void> reconnect() async {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _reconnectAttempts = 0;

    while (_reconnectAttempts < maxReconnectAttempts && !_isConnected) {
      _reconnectAttempts++;
      debugPrint('Attempting to reconnect... Attempt: $_reconnectAttempts');

      try {
        if (await checkConnectivity()) {
          _socket?.connect();
          _isConnected = true;
          _isReconnecting = false;
          onReconnected?.call();
          debugPrint('Reconnection successful');
          return;
        }
      } catch (e) {
        debugPrint('Reconnection attempt failed: $e');
      }

      if (!_isConnected) {
        await Future.delayed(reconnectDelay * _reconnectAttempts);
      }
    }

    if (!_isConnected) {
      _isReconnecting = false;
      _onError?.call(
          'Failed to reconnect to server after $maxReconnectAttempts attempts');
    }
  }

  static String buildUrl(String endpoint) {
    // Ensure endpoint starts with '/'
    final String cleanEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';

    // Build the URL with base URL
    final String finalUrl = ApiConfig.baseUrl + cleanEndpoint;

    // Remove any double slashes except after protocol (http:// or https://)
    final String cleanUrl = finalUrl.replaceAll(RegExp(r'(?<!:)\/\/+'), '/');

    debugPrint('🌐 Built URL: $cleanUrl');
    return cleanUrl;
  }

  static Future<String> buildUrlWithFallback(String endpoint) async {
    // Ensure endpoint starts with '/'
    final String cleanEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';

    // Get working URL with fallback
    final String workingUrl = await ApiConfig.getWorkingUrl();

    // Build the URL with working URL
    final String finalUrl = workingUrl + cleanEndpoint;

    // Remove any double slashes except after protocol (http:// or https://)
    final String cleanUrl = finalUrl.replaceAll(RegExp(r'(?<!:)\/\/+'), '/');

    debugPrint('🌐 Built URL with fallback: $cleanUrl');
    return cleanUrl;
  }

  // List of endpoints that don't require authentication
  static const List<String> publicEndpoints = [
    '/api/auth/register',
    '/api/auth/login',
    '/api/auth/check-username',
    '/api/auth/check-email',
    '/api/auth/verify-email',
    '/api/auth/resend-verification',
    '/api/auth/request-password-reset',
    '/api/auth/reset-password',
    '/api/auth/health'
  ];

  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        // Use fallback URL for DNS resolution issues
        final urlString = retryCount == 0
            ? buildUrl(endpoint)
            : await buildUrlWithFallback(endpoint);

        final url = Uri.parse(urlString);
        debugPrint(
            '🌐 Making $method request to: $url (attempt ${retryCount + 1})');

        final isPublicEndpoint =
            publicEndpoints.any((e) => endpoint.endsWith(e));
        final Map<String, String> finalHeaders = ApiConfig.getHeaders();

        // Add custom headers if provided
        if (headers != null) {
          finalHeaders.addAll(headers);
        }

        if (!isPublicEndpoint) {
          final token = await _getAuthToken();
          if (token != null) {
            finalHeaders['Authorization'] = 'Bearer $token';
          }
        }

        debugPrint('📤 Final request headers: $finalHeaders');

        // Debug headers
        final headersDebug = Map<String, String>.from(finalHeaders);
        if (headersDebug.containsKey('Authorization')) {
          final authHeader = headersDebug['Authorization'] ?? '';
          if (authHeader.startsWith('Bearer ')) {
            final token = authHeader.substring(7);
            headersDebug['Authorization'] =
                'Bearer ${token.substring(0, 10)}...';
            debugPrint(
                '🔐 Token length: ${token.length}, parts: ${token.split('.').length}');
          }
        }
        debugPrint('📤 Request headers: $headersDebug');

        late http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response =
                await http.get(url, headers: finalHeaders).timeout(_timeout);
            break;
          case 'POST':
            response = await http
                .post(
                  url,
                  headers: finalHeaders,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(_timeout);
            break;
          case 'PUT':
            response = await http
                .put(
                  url,
                  headers: finalHeaders,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(_timeout);
            break;
          case 'DELETE':
            response =
                await http.delete(url, headers: finalHeaders).timeout(_timeout);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        debugPrint('📥 Response status: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          return data;
        } else {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Request failed',
            'error': errorData['error'] ?? 'UNKNOWN_ERROR'
          };
        }
      } catch (e) {
        debugPrint('❌ Request error (attempt ${retryCount + 1}): $e');

        // Check if it's a DNS resolution error
        if (e.toString().contains('Failed host lookup') ||
            e.toString().contains('no address associated with hostname') ||
            e.toString().contains('SocketException')) {
          if (retryCount < maxRetries) {
            retryCount++;
            debugPrint('🔄 DNS error detected, retrying with fallback URL...');
            await Future.delayed(
                Duration(seconds: retryCount * 2)); // Exponential backoff
            continue;
          }
        }

        // If it's not a DNS error or we've exhausted retries, return error
        return {
          'success': false,
          'message': 'Network error: ${e.toString()}',
          'error': 'NETWORK_ERROR',
          'details': e.toString(),
        };
      }
    }

    // This should never be reached, but just in case
    return {
      'success': false,
      'message': 'All retry attempts failed',
      'error': 'MAX_RETRIES_EXCEEDED',
    };
  }

  // Update static methods to use static _makeRequest
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.baseUrl + endpoint);
      final headers = ApiConfig.getHeaders();

      if (requiresAuth) {
        final token = await _instance._getAuthToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      // Remove null values from data
      data.removeWhere((key, value) => value == null);

      // Convert empty strings to null and remove them
      data.forEach((key, value) {
        if (value is String && value.trim().isEmpty) {
          data[key] = null;
        }
      });
      data.removeWhere((key, value) => value == null);

      // Validate required fields based on endpoint
      if (endpoint == ApiConfig.updateProfile) {
        if (!data.containsKey('fullName') ||
            data['fullName'] == null ||
            data['fullName'].toString().trim().isEmpty) {
          throw ValidationError('Full name is required');
        }
      }

      debugPrint('📤 POST request to $url');
      debugPrint('📦 Request data: $data');

      final response = await http
          .post(
            url,
            headers: headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📦 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        final errorResponse = json.decode(response.body);
        throw ApiError(errorResponse['message'] ?? 'Unknown error occurred',
            code: errorResponse['error']);
      }
    } on FormatException catch (_) {
      throw ApiError('Invalid response format from server');
    } on ValidationError catch (e) {
      throw ApiError(e.message);
    } catch (e) {
      debugPrint('❌ POST request error: $e');
      throw ApiError('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = Uri.parse(buildUrl(endpoint));
      debugPrint('🌐 Making GET request to: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${await _instance._getAuthToken()}',
          ...?customHeaders,
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Request failed',
          'error': errorData['error'] ?? 'UNKNOWN_ERROR'
        };
      }
    } catch (e) {
      debugPrint('❌ Request error: $e');
      return {
        'success': false,
        'message': 'Request failed',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? customHeaders,
  }) async {
    return _makeRequest(
        endpoint: endpoint, method: 'PUT', body: data, headers: customHeaders);
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? customHeaders,
  }) async {
    return _makeRequest(
        endpoint: endpoint, method: 'DELETE', headers: customHeaders);
  }

  Future<String?> getToken() async {
    try {
      final response = await get(ApiConfig.validateToken);
      final success = response['success'] as bool?;
      final token = response['token'] as String?;
      if (success == true && token != null) {
        return token;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      debugPrint('🔑 Validating token...');
      final response = await post(
        ApiConfig.validateToken,
        {'token': token},
      );

      debugPrint('📥 Token validation response: $response');

      if (response['success'] == true || response['status'] == 'success') {
        return {
          'success': true,
          'data': response['data'] ?? response['user'] ?? {}
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Token validation failed'
      };
    } catch (e) {
      debugPrint('❌ Token validation error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      debugPrint('👤 Getting user profile...');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No auth token found');
        throw AuthenticationError('No token found');
      }
      debugPrint('🔐 Using token: ${token.substring(0, 10)}...');

      final response = await _makeRequest(
        endpoint: '/api/auth/profile',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('📥 Profile response: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      rethrow;
    }
  }

  // Reward methods
  Future<Map<String, dynamic>> updateRewards({
    required double amount,
    required String type,
    String? description,
  }) async {
    try {
      debugPrint('💰 Updating rewards...');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationError('No token found');
      }

      return _makeRequest(
        endpoint: '/api/rewards/update',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'amount': amount,
          'type': type,
          if (description != null) 'description': description,
        },
      );
    } catch (e) {
      debugPrint('❌ Error updating rewards: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClaimedRewardsInfo() async {
    try {
      debugPrint('🎁 Getting claimed rewards info...');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationError('No token found');
      }

      return _makeRequest(
        endpoint: '/api/rewards/claimed',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('❌ Error getting claimed rewards: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> withdrawFunds({
    required String method,
    required String destination,
    required double amount,
    required String currency,
    required double btcAmount,
  }) async {
    try {
      final token = await StorageUtils.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      // Format BTC amount to 18 decimal places
      final formattedBTCAmount = NumberFormatter.formatBTCAmount(btcAmount);
      debugPrint('BTC Amount (18 decimals): $formattedBTCAmount');

      // Normalize method name
      final normalizedMethod = method == 'Bitcoin' ? 'BTC' : method;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'method': normalizedMethod,
          'destination': destination,
          'amount': NumberFormatter.formatBTCAmount(amount),
          'currency': currency,
          'btcAmount': formattedBTCAmount,
          'status': 'pending',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Withdrawal request failed');
      }
    } catch (e) {
      debugPrint('Withdrawal error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWithdrawalHistory() async {
    try {
      debugPrint('🔄 Fetching withdrawal history...');

      final response = await get(ApiConfig.walletWithdrawals);

      if (response['success']) {
        debugPrint('✅ Withdrawal history fetched successfully');
        return response;
      } else {
        debugPrint(
            '❌ Failed to fetch withdrawal history: ${response['message']}');
        return response;
      }
    } catch (e) {
      debugPrint('❌ Error fetching withdrawal history: $e');
      rethrow;
    }
  }

  // Centralized method for balance sync
  Future<Map<String, dynamic>> syncWalletBalance(String balance) async {
    try {
      debugPrint('🔄 Syncing wallet balance...');

      // Convert scientific notation to regular decimal format
      final formattedBalance =
          NumberFormatter.formatBTCAmount(double.parse(balance));
      debugPrint('💰 Formatted balance for sync: $formattedBalance');

      final response = await _makeRequest(
        endpoint: '/api/wallet/sync-balance',
        method: 'POST',
        body: {
          'balance': formattedBalance,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response['success']) {
        debugPrint('✅ Wallet balance synced successfully');

        // Format the balance in response to 18 decimal places
        if (response['data'] != null && response['data']['balance'] != null) {
          final serverBalance = response['data']['balance'].toString();
          final formattedServerBalance =
              NumberFormatter.formatBTCAmount(double.parse(serverBalance));
          response['data']['balance'] = formattedServerBalance;
          debugPrint('💰 Server balance after sync: $formattedServerBalance');
        }

        return response;
      } else {
        debugPrint('❌ Failed to sync wallet balance: ${response['message']}');
        throw Exception(response['message'] ?? 'Failed to sync wallet balance');
      }
    } catch (e) {
      debugPrint('❌ Error syncing wallet balance: $e');
      rethrow;
    }
  }

  // Update wallet balance
  Future<Map<String, dynamic>> updateWalletBalance(double balance) async {
    try {
      debugPrint('🔄 Updating wallet balance: $balance');

      // Format balance to 18 decimal places (string)
      final formattedBalanceStr = NumberFormatter.formatBTCAmount(balance);
      // Parse string to double for backend
      final formattedBalance = double.tryParse(formattedBalanceStr) ?? 0.0;
      debugPrint('💰 Formatted balance for update (number): $formattedBalance');

      final response = await _makeRequest(
        endpoint: ApiConfig.syncBalance,
        method: 'POST',
        body: {
          'balance': formattedBalance,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response['success']) {
        // Check if sync was skipped
        if (response['message']?.toString().contains('Sync skipped') == true) {
          debugPrint('ℹ️ ${response['message']}');
          return {
            'success': true,
            'skipped': true,
            'message': response['message'],
            'data': {'balance': formattedBalanceStr}
          };
        }

        // Check if we have balance data
        final serverBalanceData = response['data'];
        if (serverBalanceData == null || serverBalanceData['balance'] == null) {
          // No balance data, return the local balance
          return {
            'success': true,
            'data': {'balance': formattedBalanceStr}
          };
        }

        final serverBalance = serverBalanceData['balance'];
        debugPrint('💰 Server balance after update: $serverBalance');

        // If server returns 0 but we sent a non-zero balance, keep our balance
        final serverBalanceNum = double.tryParse(serverBalance.toString()) ?? 0;
        if (serverBalanceNum == 0 && balance > 0) {
          debugPrint(
              '⚠️ Server returned 0 balance, keeping local balance: $balance');
          return {
            'success': true,
            'data': {'balance': formattedBalanceStr}
          };
        }

        return response;
      }

      return {
        'success': false,
        'message': 'Failed to update balance',
        'data': {'balance': formattedBalance}
      };
    } catch (e) {
      debugPrint('❌ Error updating wallet balance: $e');
      return {
        'success': false,
        'message': 'Failed to update balance',
        'data': {'balance': balance.toString()}
      };
    }
  }

  /// Get the user's wallet balance
  Future<double> getWalletBalance() async {
    try {
      debugPrint('💰 Getting wallet balance...');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No auth token found');
        throw AuthenticationError('No token found');
      }
      debugPrint('🔐 Using token: ${token.substring(0, 10)}...');

      final headers = {'Authorization': 'Bearer $token'};
      debugPrint('📤 Setting request headers: $headers');

      // Get wallet balance directly
      final response = await _makeRequest(
        endpoint: '/api/wallet/balance',
        method: 'GET',
        headers: headers,
      );

      debugPrint('📥 Response data: $response');

      if (response['success'] && response['data']?['balance'] != null) {
        final balance =
            NumberFormatter.parseDouble(response['data']['balance'].toString());
        debugPrint('💰 Parsed balance: $balance');
        return balance;
      }

      if (response['error'] == 'UNAUTHORIZED') {
        throw AuthenticationError('Please log in to access this resource');
      }

      throw ApiError(response['message'] ?? 'Failed to get wallet balance');
    } catch (e) {
      debugPrint('❌ Wallet balance error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactions() async {
    try {
      debugPrint('🔄 Fetching transactions...');
      final token = await StorageUtils.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await _makeRequest(
        endpoint: '/api/wallet/transactions',
        method: 'GET',
        headers: headers,
      );

      debugPrint('✅ Transactions fetched successfully');
      debugPrint('📊 Response data: ${response['data']}');

      return response;
    } catch (e) {
      debugPrint('❌ Error fetching transactions: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getTransactionById(String id) async {
    try {
      debugPrint('🔄 Fetching transaction details for ID: $id');

      final token = await StorageUtils.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _makeRequest(
        endpoint: '/api/wallet/transactions/$id',
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response['success']) {
        debugPrint('✅ Transaction details fetched successfully');
        return response;
      } else {
        debugPrint(
            '❌ Failed to fetch transaction details: ${response['message']}');
        return {
          'success': false,
          'message':
              response['message'] ?? 'Failed to fetch transaction details'
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching transaction details: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPendingTransactions() async {
    try {
      debugPrint('🔄 Fetching pending transactions...');

      final token = await StorageUtils.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _makeRequest(
        endpoint: '/api/wallet/transactions/pending',
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response['success']) {
        debugPrint('✅ Pending transactions fetched successfully');
        return response;
      } else {
        debugPrint(
            '❌ Failed to fetch pending transactions: ${response['message']}');
        return {
          'success': false,
          'message':
              response['message'] ?? 'Failed to fetch pending transactions'
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching pending transactions: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCompletedTransactions() async {
    try {
      debugPrint('🔄 Fetching completed transactions...');

      final token = await StorageUtils.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _makeRequest(
        endpoint: '/api/wallet/transactions/completed',
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response['success']) {
        debugPrint('✅ Completed transactions fetched successfully');
        return response;
      } else {
        debugPrint(
            '❌ Failed to fetch completed transactions: ${response['message']}');
        return {
          'success': false,
          'message':
              response['message'] ?? 'Failed to fetch completed transactions'
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching completed transactions: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWithdrawals() async {
    try {
      final token = await StorageUtils.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/wallet/withdrawals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get withdrawals: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkUsername(String userName) async {
    try {
      debugPrint('📤 Checking username availability: $userName');

      // Make direct HTTP request for this public endpoint
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/check-username');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'userName': userName}),
      );

      debugPrint('📥 Username check status: ${response.statusCode}');
      debugPrint('📥 Username check response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Username checked successfully',
          'available': !data['exists'] && data['success'] == true
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to check username',
        'available': false
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check username availability',
        'error': e.toString()
      };
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
      final body = {
        'fullName': fullName,
        'userName': userName,
        'userEmail': userEmail,
        'password': password,
      };
      if (referredByCode != null && referredByCode.isNotEmpty) {
        body['referredByCode'] = referredByCode;
      }
      final response = await _makeRequest(
        method: 'POST',
        endpoint: ApiConfig.register,
        body: body,
      );

      if (response['status'] == 'success') {
        return {
          'success': true,
          'data': response['data'],
          'message': 'Registration successful'
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
          'error': response['error']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed',
        'error': e.toString()
      };
    }
  }

  void initializeSocket(String userId) {
    _socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId})
          .setReconnectionAttempts(maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .enableReconnection()
          .enableAutoConnect()
          .build(),
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socket?.on('connect', (_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('Socket connected');
    });

    _socket?.on('disconnect', (_) {
      _isConnected = false;
      onDisconnected?.call();
      _onError?.call('Socket disconnected');
      reconnect();
    });

    _socket?.on('connect_error', (error) {
      _isConnected = false;
      _onError?.call('Connection error: $error');
      reconnect();
    });

    _socket?.on('error', (error) => _onError?.call('Socket error: $error'));

    _socket?.on('balanceUpdate', (data) {
      if (data != null && data['balance'] != null) {
        final balance = double.tryParse(data['balance'].toString());
        if (balance != null) {
          onBalanceUpdate?.call(balance);
        }
      }
    });
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    _isReconnecting = false;
    onBalanceUpdate = null;
    _onError = null;
    onReconnected = null;
    onDisconnected = null;
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      debugPrint('📤 Requesting password reset for email: $email');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/request-reset'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'email': email}),
          )
          .timeout(_timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully'
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send OTP',
          'error': errorData['error'] ?? 'UNKNOWN_ERROR'
        };
      }
    } on SocketException {
      debugPrint('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection',
        'error': 'NETWORK_ERROR'
      };
    } on TimeoutException {
      debugPrint('❌ Request timed out');
      return {
        'success': false,
        'message': 'Request timed out',
        'error': 'TIMEOUT_ERROR'
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> verifyResetOTP(
      String email, String otp) async {
    try {
      debugPrint('📤 Verifying reset OTP for email: $email');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-reset-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'email': email,
              'otp': otp,
            }),
          )
          .timeout(_timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified successfully',
          'resetToken': data['resetToken']
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to verify OTP',
          'error': errorData['error'] ?? 'UNKNOWN_ERROR'
        };
      }
    } on SocketException {
      debugPrint('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection',
        'error': 'NETWORK_ERROR'
      };
    } on TimeoutException {
      debugPrint('❌ Request timed out');
      return {
        'success': false,
        'message': 'Request timed out',
        'error': 'TIMEOUT_ERROR'
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'error': 'UNKNOWN_ERROR'
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    try {
      debugPrint('📤 Resetting password with token');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'resetToken': resetToken,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successful'
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to reset password',
          'error': errorData['error'] ?? 'UNKNOWN_ERROR'
        };
      }
    } on SocketException {
      debugPrint('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection',
        'error': 'NETWORK_ERROR'
      };
    } on TimeoutException {
      debugPrint('❌ Request timed out');
      return {
        'success': false,
        'message': 'Request timed out',
        'error': 'TIMEOUT_ERROR'
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'error': 'UNKNOWN_ERROR'
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('📤 Login attempt: $email');

      final response = await _makeRequest(
        endpoint: ApiConfig.login,
        method: 'POST',
        body: {
          'email': email,
          'password': password,
        },
      );

      debugPrint('📥 Login response: $response');

      if (response['success'] == true) {
        try {
          // Get token and user data from response
          final token = response['data']['token'];
          final userData = response['data']['user'];

          if (token == null || userData == null) {
            throw Exception('Invalid response format');
          }

          // Save token first
          await StorageUtils.saveToken(token);
          debugPrint('✅ Token saved successfully');

          // Save user ID and set in ApiConfig
          final userId =
              userData['userId']?.toString() ?? userData['_id']?.toString();
          if (userId == null) {
            throw Exception('User ID is required');
          }

          // Add userId to userData
          userData['userId'] = userId;

          await StorageUtils.saveUserId(userId);
          ApiConfig.setUserId(userId);
          debugPrint('✅ User ID saved and set in ApiConfig');

          // Save user data
          await StorageUtils.saveUserData(userData);
          debugPrint('✅ User data saved successfully');

          return response;
        } catch (e) {
          debugPrint('❌ Error saving data: $e');
          throw Exception('Failed to save login data: $e');
        }
      } else {
        debugPrint('❌ Login failed: ${response['message']}');
        return response;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addTransaction(
      Map<String, dynamic> transaction) async {
    try {
      debugPrint('🔄 Adding transaction to backend...');
      debugPrint('📝 Transaction data: $transaction');

      final token = await StorageUtils.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      // Format amount to 18 decimal places
      if (transaction['amount'] != null) {
        transaction['amount'] = NumberFormatter.formatBTCAmount(
            double.parse(transaction['amount'].toString()));
      }

      // Format balance fields to 18 decimal places
      if (transaction['balanceBefore'] != null) {
        transaction['balanceBefore'] = NumberFormatter.formatBTCAmount(
            double.parse(transaction['balanceBefore'].toString()));
      }

      if (transaction['balanceAfter'] != null) {
        transaction['balanceAfter'] = NumberFormatter.formatBTCAmount(
            double.parse(transaction['balanceAfter'].toString()));
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          ...transaction,
          'timestamp': DateTime.now().toIso8601String(),
          'currency': 'BTC',
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📝 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          debugPrint('✅ Transaction added successfully');

          // If this is a withdrawal transaction, also update withdrawal status
          if (transaction['type']
                  .toString()
                  .toLowerCase()
                  .contains('withdrawal') &&
              transaction['withdrawalId'] != null) {
            debugPrint('🔄 Updating withdrawal status...');
            await http.post(
              Uri.parse('${ApiConfig.baseUrl}/api/wallet/withdrawals/update'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'withdrawalId': transaction['withdrawalId'],
                'status': transaction['status'],
                'transactionId': transaction['transactionId'],
              }),
            );
            debugPrint('✅ Withdrawal status updated');
          }
        }
        return responseData;
      } else {
        debugPrint('❌ Failed to add transaction: ${response.statusCode}');
        throw Exception('Failed to add transaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  // Transaction methods
  Future<Map<String, dynamic>> claimRejectedTransaction(
      String transactionId) async {
    try {
      debugPrint('🔄 Claiming rejected transaction: $transactionId');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationError('No token found');
      }

      return _makeRequest(
        endpoint: '/api/transactions/claim/$transactionId',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('❌ Error claiming rejected transaction: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTransactionStatus(
      String transactionId, String newStatus) async {
    try {
      debugPrint(
          '🔄 Updating transaction status: $transactionId -> $newStatus');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationError('No token found');
      }

      return _makeRequest(
        endpoint: '/api/transactions/status/$transactionId',
        method: 'PUT',
        headers: {'Authorization': 'Bearer $token'},
        body: {'status': newStatus},
      );
    } catch (e) {
      debugPrint('❌ Error updating transaction status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _makeRequestWithRetry(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await _makeRequest(
          endpoint: endpoint,
          method: method,
          body: body,
        );
        return response;
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    throw Exception('Failed after $maxRetries attempts');
  }

  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    return _makeRequestWithRetry(
      'POST',
      '/api/referral/validate',
      body: {'code': code},
    );
  }

  Future<Map<String, dynamic>> checkReferralCode(String code) async {
    return _makeRequestWithRetry(
      'GET',
      '/api/referral/check/$code',
    );
  }

  Future<Map<String, dynamic>> generateReferralCode(String code) async {
    return _makeRequestWithRetry(
      'POST',
      '/api/referral/generate',
      body: {'code': code},
    );
  }

  Future<Map<String, dynamic>> getReferralStatistics() async {
    return _makeRequestWithRetry('GET', '/api/referral/stats');
  }

  Future<Map<String, dynamic>> getReferralUsers() async {
    return _makeRequestWithRetry('GET', '/api/referral/users');
  }

  Future<Map<String, dynamic>> getReferralEarnings() async {
    return _makeRequestWithRetry(
      'GET',
      '/api/referral/earnings',
    );
  }

  Future<Map<String, dynamic>> getReferralList() async {
    return _makeRequestWithRetry('GET', '/api/referral/list');
  }

  Future<Map<String, dynamic>> createReferral(String userId) async {
    return _makeRequestWithRetry(
      'POST',
      '/api/referral/create',
      body: {'userId': userId},
    );
  }

  // Make authenticated POST request
  static Future<Map<String, dynamic>> postWithAuth(
    String url,
    Map<String, dynamic> data, {
    required String authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      return {
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      debugPrint('❌ API error: $e');
      throw Exception('Failed to make API request: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      debugPrint('🔐 Verifying OTP for email: $email');
      final response = await _makeRequest(
        endpoint: '/api/auth/verify-email',
        method: 'POST',
        body: {
          'email': email,
          'otp': otp,
        },
      );

      debugPrint('📥 OTP verification response: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Failed to verify OTP: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> getCurrencyRates() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/market/rates',
        method: 'GET',
      );

      if (response['success']) {
        return response;
      } else {
        debugPrint('❌ Failed to get currency rates: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to get currency rates',
          'data': {
            'rates': {'USD': 1.0, 'INR': 83.0, 'EUR': 0.91},
            'btcPrice': 45000.0
          }
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching currency rates: $e');
      return {
        'success': false,
        'message': 'Error fetching currency rates',
        'data': {
          'rates': {'USD': 1.0, 'INR': 83.0, 'EUR': 0.91},
          'btcPrice': 45000.0
        }
      };
    }
  }

  Future<Map<String, dynamic>> createWithdrawal(
      Map<String, dynamic> withdrawalData) async {
    try {
      debugPrint('🔄 Creating withdrawal request...');

      final response = await _makeRequest(
          endpoint: '/api/wallet/withdraw',
          method: 'POST',
          body: withdrawalData);

      debugPrint('📥 Withdrawal response: $response');

      if (response['success']) {
        debugPrint('✅ Withdrawal request created successfully');
        return response;
      } else {
        debugPrint('❌ Failed to create withdrawal: ${response['message']}');
        return {
          'success': false,
          'message':
              response['message'] ?? 'Failed to create withdrawal request'
        };
      }
    } catch (e) {
      debugPrint('❌ Error creating withdrawal: $e');
      return {'success': false, 'message': 'Error creating withdrawal: $e'};
    }
  }

  Future<Map<String, dynamic>> claimTransaction(String transactionId) async {
    try {
      debugPrint('🔄 Claiming transaction: $transactionId');
      final token = await StorageUtils.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationError('No token found');
      }

      return _makeRequest(
        endpoint: '/api/transactions/claim',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'transactionId': transactionId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error claiming transaction: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final Uri url = Uri.parse(ApiConfig.baseUrl + endpoint);
      debugPrint('🌐 Making $method request to: $url');

      // Get auth token
      final token = await _getAuthToken();

      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };

      debugPrint('📤 Request headers: $requestHeaders');

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return responseData;
    } catch (e) {
      debugPrint('❌ API request error: $e');
      rethrow;
    }
  }
}
