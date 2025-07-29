import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/backend_failover_manager.dart';

/// Utility class for debugging and testing backend failover system
class BackendFailoverDebug {
  static final BackendFailoverManager _failoverManager = BackendFailoverManager();

  /// Print comprehensive backend status
  static Future<void> printBackendStatus() async {
    print('\n🔍 ========== BACKEND FAILOVER STATUS ==========');
    
    // Current status
    final status = ApiConfig.getFailoverStatus();
    print('📊 Current Backend: ${status['cachedBackendUrl'] ?? 'None cached'}');
    print('⏰ Last Health Check: ${status['lastHealthCheck'] ?? 'Never'}');
    print('✅ Cache Valid: ${status['isCacheValid']}');
    print('🔄 Health Checking: ${status['isHealthChecking']}');
    
    // All available backends
    print('\n🌐 Available Backends:');
    final allBackends = status['allBackends'] as List<String>;
    for (int i = 0; i < allBackends.length; i++) {
      final priority = i == 0 ? 'PRIMARY' : i == 1 ? 'SECONDARY' : 'BACKUP ${i - 1}';
      print('  ${i + 1}. [$priority] ${allBackends[i]}');
    }
    
    print('\n🏥 Health Check Results:');
    try {
      final healthResults = await ApiConfig.checkAllBackendsHealth();
      final results = healthResults['results'] as Map<String, dynamic>;
      
      results.forEach((backend, data) {
        final status = data['healthy'] ? '✅ ONLINE' : '❌ OFFLINE';
        final responseTime = data['responseTime'];
        print('  $status $backend (${responseTime}ms)');
      });
    } catch (e) {
      print('  ❌ Failed to check health: $e');
    }
    
    print('============================================\n');
  }

  /// Test failover functionality
  static Future<void> testFailover() async {
    print('\n🧪 ========== TESTING FAILOVER ==========');
    
    try {
      // Force refresh to test selection
      print('🔄 Forcing backend refresh...');
      final selectedBackend = await ApiConfig.forceRefreshBackend();
      print('✅ Selected backend: $selectedBackend');
      
      // Test API call
      print('🌐 Testing API call...');
      final response = await _failoverManager.makeRequest(
        endpoint: '/health',
        method: 'GET',
        headers: {'Accept': 'application/json'},
      );
      
      print('📋 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ API test successful: ${data['message'] ?? 'OK'}');
        } catch (e) {
          print('✅ API responded but non-JSON: ${response.body.substring(0, 100)}...');
        }
      } else {
        print('❌ API test failed: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Failover test failed: $e');
    }
    
    print('=====================================\n');
  }

  /// Quick backend connectivity check
  static Future<bool> quickConnectivityCheck() async {
    try {
      final backend = await _failoverManager.getActiveBackendUrl();
      print('🔗 Quick check: Using $backend');
      return true;
    } catch (e) {
      print('❌ Quick check failed: $e');
      return false;
    }
  }

  /// Get backend status as formatted string for UI display
  static Future<String> getBackendStatusString() async {
    try {
      final status = ApiConfig.getFailoverStatus();
      final currentBackend = status['cachedBackendUrl'] ?? 'None';
      final isValid = status['isCacheValid'] ?? false;
      
      String result = 'Backend: ';
      if (currentBackend.contains('railway')) {
        result += '🚂 Railway';
      } else if (currentBackend.contains('render')) {
        result += '🎨 Render';
      } else {
        result += '🌐 Custom';
      }
      
      result += isValid ? ' ✅' : ' ⚠️';
      
      return result;
    } catch (e) {
      return 'Backend: ❌ Error';
    }
  }

  /// Development helper - log failover events
  static void logFailoverEvent(String event, String backend) {
    if (kDebugMode) {
      print('🔄 Failover Event: $event -> $backend');
    }
  }
}