class ApiConfig {
  // Multiple server URLs for failover
  static const List<String> serverUrls = [
    'https://bitcoincloudmining.onrender.com/api',  // Primary: Render
    'https://bitcoincloudmining-production.up.railway.app/api',  // Fallback: Railway
  ];
  
  static const List<String> proxyImageBases = [
    'https://bitcoincloudmining.onrender.com/api/proxy?url=',  // Primary: Render
    'https://bitcoincloudmining-production.up.railway.app/api/proxy?url=',  // Fallback: Railway
  ];

  // Current active server index (0 = Render, 1 = Railway)
  static int _currentServerIndex = 0;
  
  // Get current base URL
  static String get baseUrl => serverUrls[_currentServerIndex];
  
  // Get current proxy image base
  static String get proxyImageBase => proxyImageBases[_currentServerIndex];
  
  // Switch to next server (failover)
  static void switchToNextServer() {
    _currentServerIndex = (_currentServerIndex + 1) % serverUrls.length;
    print('🔄 Switched to server: ${serverUrls[_currentServerIndex]}');
  }
  
  // Reset to primary server
  static void resetToPrimaryServer() {
    _currentServerIndex = 0;
    print('🔄 Reset to primary server: ${serverUrls[_currentServerIndex]}');
  }
  
  // Get current server name for display
  static String get currentServerName {
    switch (_currentServerIndex) {
      case 0:
        return 'Render.com';
      case 1:
        return 'Railway.app';
      default:
        return 'Unknown';
    }
  }
  
  // Check if using fallback server
  static bool get isUsingFallback => _currentServerIndex > 0;
  
  // Manual server switch for testing
  static void manualSwitchToRailway() {
    _currentServerIndex = 1;
    print('🔧 Manual switch to Railway: ${serverUrls[_currentServerIndex]}');
  }
  
  static void manualSwitchToRender() {
    _currentServerIndex = 0;
    print('🔧 Manual switch to Render: ${serverUrls[_currentServerIndex]}');
  }
  
  // Get all available servers info
  static List<Map<String, dynamic>> get serverInfo {
    return [
      {
        'name': 'Render.com',
        'url': serverUrls[0],
        'status': _currentServerIndex == 0 ? 'active' : 'standby',
        'primary': true,
      },
      {
        'name': 'Railway.app', 
        'url': serverUrls[1],
        'status': _currentServerIndex == 1 ? 'active' : 'standby',
        'primary': false,
      },
    ];
  }
  
  // Test server connectivity
  static Future<bool> testServerConnectivity(int serverIndex) async {
    try {
      final url = '${serverUrls[serverIndex]}/health';
      print('🧪 Testing connectivity to: $url');
      // This would need actual HTTP implementation
      return true; // Placeholder
    } catch (e) {
      print('❌ Server $serverIndex connectivity test failed: $e');
      return false;
    }
  }

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
