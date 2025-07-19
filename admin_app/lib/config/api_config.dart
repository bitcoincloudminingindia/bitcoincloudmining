class ApiConfig {
  // Local development
  // static const String baseUrl = 'http://localhost:5000/api';
  // Proxy image base url
  // static const String proxyImageBase = 'http://localhost:5000/api/proxy?url=';
  // Local development
  // static const String baseUrl = 'http://localhost:5000/api';
  // static const String proxyImageBase = 'http://localhost:5000/api/proxy?url=';

  // Production ke liye (deploy ke time isko uncomment karen):
  static const String baseUrl = 'https://bitcoincloudmining.onrender.com/api';
  static const String proxyImageBase =
      'https://bitcoincloudmining.onrender.com/api/proxy?url=';

  // Auth
  static const String adminLogin = '/admin/login';

  // Users
  static const String getUsers = '/admin/users';
  static const String getUserById =
      '/admin/users/'; // + userId (yahan :userId bhejna hai)
  static const String blockUser =
      '/admin/users/'; // + userId + '/block' (yahan :userId bhejna hai)
  static const String unblockUser =
      '/admin/users/'; // + userId + '/unblock' (yahan :userId bhejna hai)
  static const String exportUsers = '/admin/users/export';

  // Wallet
  static const String getUserWallet =
      '/admin/users/'; // + userId + '/wallet' (yahan :userId bhejna hai)
  static const String adjustWallet =
      '/admin/users/'; // + userId + '/wallet/adjust' (yahan :userId bhejna hai)
  static const String getWalletTransactions =
      '/admin/users/'; // + userId + '/wallet/transactions' (yahan :userId bhejna hai)
  static const String exportWallets = '/admin/wallets/export';

  // Withdrawals
  static const String getPendingWithdrawals = '/admin/withdrawals/pending';
  static const String approveWithdrawal = '/admin/withdrawals/approve';
  static const String rejectWithdrawal = '/admin/withdrawals/reject';
  static const String getWithdrawalStats = '/admin/withdrawals/stats';

  // Referral
  static const String getReferralStats = '/admin/referral/stats';
  static const String getReferralList = '/admin/referral';

  // Ads
  // static const String getAdStats = '/admin/ads/stats';
  // static const String getAdList = '/admin/ads';

  // Notifications
  static const String sendNotification = '/admin/notifications';
  static const String getNotifications = '/admin/notifications/list';

  // Export
  static const String exportTransactions = '/admin/transactions/export';

  // Manual Wallet Control
  static const String manualWalletCredit = '/admin/wallet/manual-credit';
  static const String manualWalletDebit = '/admin/wallet/manual-debit';

  // Audit Log
  static const String getAuditLogs = '/admin/audit/logs';

  // Dashboard
  static const String getDashboardStats = '/admin/dashboard';
}
