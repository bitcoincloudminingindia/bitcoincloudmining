import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// ✅ Auto-switching base URL based on environment with DNS fallbacks
  static String get baseUrl {
    if (kReleaseMode) {
      // 🎯 For Play Store / App Store builds with multiple fallbacks
      return 'https://bitcoincloudmining.onrender.com';
    }

    if (kIsWeb) {
      // 🧪 Web - use production server to avoid CORS issues
      return 'https://bitcoincloudmining.onrender.com';
    }

    if (Platform.isAndroid) {
      // 🧪 Android Emulator on PC
      return 'http://10.0.2.2:5000';
    }

    if (Platform.isIOS) {
      // 🧪 iOS Simulator (Mac)
      return 'http://localhost:5000';
    }

    // 🧪 Fallback (desktop)
    return 'http://localhost:5000';
  }

  /// 🔄 Fallback URLs for DNS resolution issues
  static List<String> get fallbackUrls {
    if (kReleaseMode) {
      return [
        'https://bitcoincloudmining.onrender.com',
        'https://bitcoin-cloud-mining-api.onrender.com',
        'https://bitcoin-mining-api.onrender.com',
        'https://bitcoincloudmining-backend.onrender.com',
      ];
    }

    if (kIsWeb) {
      return [
        'https://bitcoincloudmining.onrender.com',
        'http://localhost:5000',
        'https://bitcoin-cloud-mining-api.onrender.com',
        'https://bitcoin-mining-api.onrender.com',
      ];
    }

    return [baseUrl];
  }

  /// 🌐 Get working URL with optimized DNS fallback
  static Future<String> getWorkingUrl() async {
    // Try primary URL first with shorter timeout
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Origin': kIsWeb
              ? 'https://bitcoincloudmining.onrender.com'
              : 'http://localhost:3000',
        },
      ).timeout(const Duration(seconds: 5)); // Reduced from 10 to 5 seconds

      if (response.statusCode == 200) {
        return baseUrl;
      }
    } catch (e) {
      // Only try fallback URLs if primary fails
      for (String url in fallbackUrls.skip(1)) { // Skip first URL as it's the same as baseUrl
        try {
          final response = await http.get(
            Uri.parse('$url/health'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Origin': kIsWeb
                  ? 'https://bitcoincloudmining.onrender.com'
                  : 'http://localhost:3000',
            },
          ).timeout(const Duration(seconds: 3)); // Even shorter timeout for fallbacks

          if (response.statusCode == 200) {
            return url;
          }
        } catch (e) {
          continue;
        }
      }
    }

    return baseUrl;
  }

  /// ⚙️ API Endpoints

  static const String apiVersion = ''; // No prefix
  static bool get isDebugMode => !kReleaseMode;

  // API Timeout Configuration - Reduced for better performance
  static const int connectionTimeout = 15000; // 15 seconds (reduced from 30)
  static const int receiveTimeout = 15000; // 15 seconds (reduced from 30)
  static const int sendTimeout = 15000; // 15 seconds (reduced from 30)

  // Retry Configuration - Reduced retries for faster failure detection
  static const int maxRetries = 1; // Reduced from 3 to 1
  static const Duration retryDelay = Duration(seconds: 1); // Reduced from 2 to 1

  // Connection retry settings - Optimized
  static const Duration connectionRetryInterval = Duration(seconds: 1); // Reduced from 2
  static const int maxConnectionRetries = 2; // Reduced from 3 to 2

  // Health Check Configuration - Reduced frequency
  static const Duration healthCheckTimeout = Duration(seconds: 5); // Reduced from 10
  static const Duration healthCheckTotalTimeout = Duration(seconds: 15); // Reduced from 30
  static const int maxHealthCheckRetries = 1; // Reduced from 2 to 1
  static const Duration healthCheckBaseDelay = Duration(seconds: 1); // Reduced from 2

  // Health check settings - Increased interval to reduce overhead
  static const Duration healthCheckInterval = Duration(seconds: 60); // Increased from 30 to 60

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
  }

  static void setRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
  }

  static void setUserId(String userId) {
    _userId = userId;
  }

  static void clear() {
    _token = null;
    _refreshToken = null;
    _userId = null;
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
      'Origin': kIsWeb
          ? 'https://bitcoincloudmining.onrender.com'
          : 'http://localhost:3000',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Content-Type, Authorization, Accept, X-Requested-With, Origin',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Add connection status check with better error handling
  static Future<bool> isServerAvailable() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        // First try health endpoint
        final healthResponse = await http
            .get(
              Uri.parse('$baseUrl/health'),
              headers: getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        if (healthResponse.statusCode == 200) {
          return true;
        }

        // If health check fails, try base URL
        final baseResponse = await http
            .get(
              Uri.parse(baseUrl),
              headers: getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        if (baseResponse.statusCode < 500) {
          return true;
        }

        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      } on SocketException {
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      }
    }

    return false;
  }

  // FCM Token endpoint
  static const String fcmTokenEndpoint = '/api/auth/fcm-token';
  static String get fcmTokenUrl => '$baseUrl$fcmTokenEndpoint';

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
