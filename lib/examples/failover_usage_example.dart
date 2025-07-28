import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/backend_failover_manager.dart';

/// Example usage of the BackendFailoverManager
/// This shows how to integrate the failover system into your Flutter app

class FailoverUsageExample {
  
  /// 1. Initialize the failover system during app startup
  /// Call this in your main.dart or app initialization
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize the failover system
    await ApiService.initializeFailover();
    
    // Your other initialization code...
  }

  /// 2. Example: Login function with automatic failover
  static Future<Map<String, dynamic>> loginWithFailover(
    String email, 
    String password,
  ) async {
    try {
      // The ApiService automatically uses BackendFailoverManager in production
      final response = await ApiService().login(email, password);
      
      if (response['success'] == true) {
        debugPrint('✅ Login successful with backend: ${BackendFailoverManager().getCachedBackendUrl()}');
        return response;
      } else {
        debugPrint('❌ Login failed: ${response['message']}');
        return response;
      }
    } catch (e) {
      debugPrint('💥 Login error: $e');
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  /// 3. Example: Manual backend status check
  static Future<void> checkBackendStatus() async {
    final failoverManager = BackendFailoverManager();
    
    try {
      // Get current status
      final status = failoverManager.getStatus();
      debugPrint('📊 Backend Status: $status');
      
      // Force refresh to check both backends
      final activeBackend = await failoverManager.forceRefresh();
      debugPrint('🎯 Active backend after refresh: $activeBackend');
      
    } catch (e) {
      debugPrint('⚠️ Error checking backend status: $e');
    }
  }

  /// 4. Example: Custom API call with failover
  static Future<Map<String, dynamic>> getWalletBalanceWithFailover() async {
    try {
      // The ApiService._makeRequest automatically handles failover
      final response = await ApiService().getWalletBalance();
      
      debugPrint('💰 Wallet balance retrieved from: ${BackendFailoverManager().getCachedBackendUrl()}');
      return {'success': true, 'balance': response};
      
    } catch (e) {
      debugPrint('💥 Error getting wallet balance: $e');
      return {
        'success': false,
        'message': 'Failed to get wallet balance: ${e.toString()}',
      };
    }
  }

  /// 5. Example: Widget that shows current backend status
  static Widget buildBackendStatusWidget() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getBackendStatusInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Checking backend...', style: TextStyle(fontSize: 12)),
            ],
          );
        }
        
        if (snapshot.hasError) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text('Backend Error', style: TextStyle(fontSize: 12, color: Colors.red)),
            ],
          );
        }
        
        final status = snapshot.data!;
        final isHealthy = status['healthy'] as bool;
        final backendName = status['name'] as String;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHealthy ? Icons.cloud_done : Icons.cloud_off,
              color: isHealthy ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              backendName,
              style: TextStyle(
                fontSize: 12,
                color: isHealthy ? Colors.green : Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 6. Example: Reset failover cache (useful for testing)
  static Future<void> resetFailoverCache() async {
    try {
      await BackendFailoverManager().clearCache();
      debugPrint('🔄 Failover cache cleared');
      
      // Initialize fresh backend selection
      await ApiService.initializeFailover();
      
    } catch (e) {
      debugPrint('⚠️ Error resetting failover cache: $e');
    }
  }

  /// Helper method to get backend status info
  static Future<Map<String, dynamic>> _getBackendStatusInfo() async {
    try {
      final failoverManager = BackendFailoverManager();
      final status = failoverManager.getStatus();
      final cachedUrl = status['cachedBackendUrl'] as String?;
      
      if (cachedUrl == null) {
        // No cached URL, try to get one
        final activeUrl = await failoverManager.getActiveBackendUrl();
        return {
          'healthy': true,
          'name': _getBackendName(activeUrl),
        };
      }
      
      return {
        'healthy': status['isCacheValid'] as bool,
        'name': _getBackendName(cachedUrl),
      };
    } catch (e) {
      return {
        'healthy': false,
        'name': 'Unknown',
      };
    }
  }

  /// Helper method to get friendly backend name
  static String _getBackendName(String url) {
    if (url.contains('onrender.com')) {
      return 'Render';
    } else if (url.contains('railway.app')) {
      return 'Railway';
    } else if (url.contains('localhost') || url.contains('10.0.2.2')) {
      return 'Local';
    }
    return 'Custom';
  }
}

/// Example: How to use in your main.dart
/*
void main() async {
  // Initialize the app and failover system
  await FailoverUsageExample.initializeApp();
  
  runApp(MyApp());
}
*/

/// Example: How to use in a login screen
/*
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await FailoverUsageExample.loginWithFailover(
        _emailController.text,
        _passwordController.text,
      );
      
      if (result['success'] == true) {
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        actions: [
          // Show current backend status
          Padding(
            padding: EdgeInsets.all(8.0),
            child: FailoverUsageExample.buildBackendStatusWidget(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Your login form here...
          
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading 
              ? CircularProgressIndicator() 
              : Text('Login'),
          ),
        ],
      ),
    );
  }
}
*/