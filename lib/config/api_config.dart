import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  // Base URL for API
  static String get baseUrl => kReleaseMode
      ? 'https://bitcoincloudmining.onrender.com'
      : (kIsWeb
          ? 'http://localhost:5000'
          : (Platform.isAndroid
              ? 'http://10.0.2.2:5000'
              : 'http://localhost:5000'));

  // API Version
  static const String apiVersion =
      ''; // Empty string as we don't need version prefix

  // Debug mode
  static bool get isDebugMode => true;

  // API Timeout Configuration
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Connection retry settings
  static const Duration connectionRetryInterval = Duration(seconds: 2);
  static const int maxConnectionRetries = 3;

  // Health Check Configuration
  static const Duration healthCheckTimeout = Duration(seconds: 3);
  static const Duration healthCheckTotalTimeout = Duration(seconds: 30);
  static const int maxHealthCheckRetries = 2;
  static const Duration healthCheckBaseDelay = Duration(seconds: 2);

  // Health check settings
  static const Duration healthCheckInterval = Duration(seconds: 30);

  // Get platform name safely
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String sendVerificationOTP = '/api/auth/send-verification-otp';
  static const String resetPassword = '/api/auth/reset-password';
  static const String checkUsername = '/api/auth/check-username';
  static const String checkEmail = '/api/auth/check-email';
  static const String validateToken = '/api/auth/validate-token';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token';
  static const String profile = '/api/auth/profile';
  static const String userProfile = '/api/auth/profile';
  // Password reset endpoints
  static const String requestPasswordReset = '/api/auth/request-password-reset';
  static const String verifyResetOtp = '/api/auth/verify-reset-otp';
  // Alias for sendVerificationOTP for backward compatibility
  static String get sendVerificationOtp => sendVerificationOTP;
  // Using verifyEmail endpoint for OTP verification
  @deprecated
  static const String verifyOTP = '/api/auth/verify-email';
  // Alias for verifyOTP for backward compatibility
  // The verifyOtp getter should point to verifyEmail endpoint since that's what the backend uses
  static String get verifyOtp => verifyEmail;
  static const String resendOTP = '/api/auth/resend-verification';

  // Referral endpoints
  static const String validateReferralCode = '/api/referrals/validate';
  static const String getReferrals = '/api/referrals/list';
  static const String getReferralEarnings = '/api/referrals/earnings';
  static const String claimReferralRewards = '/api/referrals/claim';
  static const String getReferralStats = '/api/referrals/stats';
  static const String getReferralInfo = '/api/referrals/info';
  static const String getReferredUsers = '/api/referrals/users';

  // Mining endpoints
  static const String miningStats = '/mining/stats';
  static const String miningHistory = '/mining/history';
  static const String startMining = '/mining/start';
  static const String stopMining = '/mining/stop';

  // Wallet endpoints - Update these
  static const String walletBalance = '/api/wallet/balance';
  static const String walletTransactions = '/api/wallet/transactions';
  static const String walletPendingTransactions =
      '/api/wallet/transactions/pending';
  static const String walletWithdrawals = '/api/wallet/withdrawals';
  static const String withdrawFunds = '/api/wallet/withdraw';
  static const String depositFunds = '/api/wallet/deposit';
  static const String walletInfo = '/api/wallet/info';
  static const String syncBalance = '/api/wallet/sync-balance';
  static const String walletTransactionById = '/api/wallet/transactions/';
  static const String walletTransactionStatus =
      '/api/wallet/transactions/status/';
  static const String walletWithdrawalStatus =
      '/api/wallet/transactions/withdrawal/';
  static const String walletAddTransaction = '/api/wallet/transactions';
  static const String walletStartMining = '/api/wallet/start-mining';
  static const String walletStopMining = '/api/wallet/stop-mining';

  // Add missing getters for full URLs
  static String get getWalletBalanceUrl => '$baseUrl$walletBalance';
  static String get getWalletTransactionsUrl => '$baseUrl$walletTransactions';
  static String get getWalletInfoUrl => '$baseUrl$walletInfo';

  // User endpoints
  static const String updateProfile = '/api/auth/update-profile';
  static const String changePassword = '/user/change-password';
  static const String notifications = '/user/notifications';
  static const String settings = '/user/settings';

  // Rewards endpoints
  static const String rewardsTotal = '/rewards/total';
  static const String rewardsClaimed = '/rewards/claimed';
  static const String rewardsUpdate = '/rewards/update';
  static const String rewardsHistory = '/rewards/history';
  static const String rewardsClaim = '/rewards/claim';

  // Token and User ID storage
  static String? _token;
  static String? _refreshToken;
  static String? _userId;

  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static String? get userId => _userId;

  static void setToken(String token) {
    _token = token;
    print('🔑 Token updated in ApiConfig: ${token.substring(0, 10)}...');
  }

  static void setRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
    print(
        '🔑 Refresh token updated in ApiConfig: ${refreshToken.substring(0, 10)}...');
  }

  static void setUserId(String userId) {
    _userId = userId;
    print('👤 UserId updated in ApiConfig: $userId');
  }

  static void clear() {
    _token = null;
    _refreshToken = null;
    _userId = null;
    print('🧹 ApiConfig cleared');
  }

  static void setTokenSilently(String? token) {
    _token = token;
    // No logging for silent updates
  }

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Add connection status check with better error handling
  static Future<bool> isServerAvailable() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        print(
            '🔍 Checking server availability (attempt ${attempts + 1}/$maxAttempts)...');

        // First try health endpoint
        final healthResponse = await http
            .get(Uri.parse('$baseUrl/health'))
            .timeout(const Duration(seconds: 5));

        if (healthResponse.statusCode == 200) {
          print('✅ Server is available');
          return true;
        }

        // If health check fails, try base URL
        final baseResponse = await http
            .get(Uri.parse(baseUrl))
            .timeout(const Duration(seconds: 5));

        if (baseResponse.statusCode < 500) {
          print('✅ Server is available');
          return true;
        }

        attempts++;
        if (attempts < maxAttempts) {
          print(
              '⚠️ Server check failed, retrying in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } on SocketException {
        print('❌ Server check failed: No connection');
        attempts++;
        if (attempts < maxAttempts) {
          print('⚠️ Retrying in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        print('❌ Server check failed: Timeout');
        attempts++;
        if (attempts < maxAttempts) {
          print('⚠️ Retrying in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        print('❌ Server check failed: $e');
        attempts++;
        if (attempts < maxAttempts) {
          print('⚠️ Retrying in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      }
    }

    print('❌ Server check failed after $maxAttempts attempts');
    return false;
  }

  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error':
        'Network connection issue. Please check your internet connection.',
    'timeout': 'No response from server. Please try again later.',
    'server_error': 'Server issue. Please try again later.',
    'unauthorized': 'Your session has expired. Please login again.',
    'invalid_token': 'Invalid token. Please login again.',
    'connectivity_failed':
        'Unable to connect to server. Please check your internet connection.',
    'server_unavailable':
        'Server is currently unavailable. Please try again later.',
    'health_check_failed': 'Service health check failed. Please try again.',
    'connectivity_timeout':
        'Connection timed out. Please check your internet connection.',
    'all_retries_failed':
        'Unable to connect after several attempts. Please try again later.',
    'memory_warning':
        'Application is running low on memory. Please restart if issues persist.',
  };
}
