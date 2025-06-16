class ApiConfig {
  // Base URL and timeout settings
  static const String baseUrl = 'http://localhost:5000';
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // API endpoints
  static const String userLogin = '/auth/login'; // User login
  static const String login = '/auth/admin/login'; // Admin login
  static const String logout = '/auth/logout';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String updateProfile = '/auth/update-profile';
  static const String getProfile = '/auth/profile';
  static const String getUsers = '/auth/users';
  static const String getUser = '/auth/user';
  static const String deleteUser = '/auth/user';
  static const String updateUser = '/auth/user';
  static const String createUser = '/auth/user';
  static const String getTransactions = '/auth/transactions';
  static const String getTransaction = '/auth/transaction';
  static const String createTransaction = '/auth/transaction';
  static const String updateTransaction = '/auth/transaction';
  static const String deleteTransaction = '/auth/transaction';
  static const String getWithdrawals = '/auth/withdrawals';
  static const String getWithdrawal = '/auth/withdrawal';
  static const String createWithdrawal = '/auth/withdrawal';
  static const String updateWithdrawal = '/auth/withdrawal';
  static const String deleteWithdrawal = '/auth/withdrawal';

  // Headers generator
  static Map<String, String> getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Error codes
  static const Map<String, String> errorCodes = {
    '400': 'Invalid request',
    '401': 'Unauthorized access',
    '403': 'Access forbidden',
    '404': 'Resource not found',
    '500': 'Server error',
  };

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
}
