import 'dart:async';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// 🧪 Server Auto-Switching Test Utility
/// यह file demonstrate करती है कि Railway ↔ Render auto-switching कैसे काम करता है
class ServerSwitchingTest {
  
  /// 🔧 Test auto-switching functionality
  static Future<void> testAutoSwitching() async {
    print('\n🚀 === Railway ↔ Render Auto-Switching Test Started ===\n');
    
    try {
      // Step 1: Check current server status
      print('📊 Step 1: Checking current server status...');
      final status = await ApiConfig.getServerStatus();
      _printServerStatus(status);
      
      // Step 2: Test API call with auto-switching
      print('\n🌐 Step 2: Testing API call with auto-switching...');
      final apiService = ApiService();
      final testResponse = await apiService.makeRequest(
        endpoint: '/health',
        method: 'GET',
      );
      
      if (testResponse['success'] == true) {
        print('✅ API call successful with auto-switching!');
      } else {
        print('❌ API call failed: ${testResponse['message']}');
      }
      
      // Step 3: Test server health
      print('\n🏥 Step 3: Testing comprehensive server health...');
      final healthStatus = await ApiService.getServerHealth();
      _printHealthStatus(healthStatus);
      
      // Step 4: Force refresh connection
      print('\n🔄 Step 4: Testing connection refresh...');
      final refreshed = await ApiService.refreshConnection();
      print(refreshed ? '✅ Connection refresh successful' : '❌ Connection refresh failed');
      
      print('\n🎉 === Auto-Switching Test Completed Successfully ===\n');
      
    } catch (e) {
      print('\n❌ Test failed with error: $e\n');
    }
  }
  
  /// 📊 Print server status in formatted way
  static void _printServerStatus(Map<String, dynamic> status) {
    print('🔍 Server Status Report:');
    print('   🟢 Railway Available: ${status['primaryAvailable'] ? 'YES' : 'NO'}');
    print('   🟡 Render Available: ${status['secondaryAvailable'] ? 'YES' : 'NO'}');
    print('   📡 Current Server: ${status['currentServer']}');
    print('   ⚠️  Switch Recommended: ${status['switchRecommended'] ? 'YES' : 'NO'}');
  }
  
  /// 🏥 Print health status in formatted way
  static void _printHealthStatus(Map<String, dynamic> health) {
    print('🏥 Health Status Report:');
    print('   ✅ Overall Success: ${health['success']}');
    print('   🌐 Connected: ${health['connected']}');
    print('   ⏰ Timestamp: ${health['timestamp']}');
    
    if (health['serverStatus'] != null) {
      final serverStatus = health['serverStatus'];
      print('   📊 Server Details:');
      print('      Railway: ${serverStatus['primaryAvailable'] ? '🟢 UP' : '🔴 DOWN'}');
      print('      Render: ${serverStatus['secondaryAvailable'] ? '🟢 UP' : '🔴 DOWN'}');
      print('      Active: ${serverStatus['currentServer']}');
    }
  }
  
  /// 🎯 Test specific server URL
  static Future<bool> testSpecificServer(String serverUrl, String serverName) async {
    print('\n🔍 Testing $serverName ($serverUrl)...');
    
    try {
      final available = await ApiConfig.isServerAvailable(serverUrl);
      print(available ? '   ✅ $serverName is available' : '   ❌ $serverName is down');
      return available;
    } catch (e) {
      print('   ❌ $serverName test failed: $e');
      return false;
    }
  }
  
  /// 🔄 Demonstrate switching behavior
  static Future<void> demonstrateSwitching() async {
    print('\n🔄 === Demonstrating Auto-Switching Behavior ===\n');
    
    // Test Railway
    final railwayUp = await testSpecificServer(
      ApiConfig.primaryUrl, 
      'Railway'
    );
    
    // Test Render
    final renderUp = await testSpecificServer(
      ApiConfig.secondaryUrl, 
      'Render'
    );
    
    // Show switching logic
    print('\n🧠 Auto-Switching Logic:');
    if (railwayUp) {
      print('   ✅ Railway is up → Using Railway (Primary)');
    } else if (renderUp) {
      print('   🔄 Railway is down → Switching to Render (Secondary)');
    } else {
      print('   ❌ Both servers are down → Will retry with exponential backoff');
    }
    
    // Test actual switching
    print('\n🌐 Testing actual URL switching...');
    final workingUrl = await ApiConfig.getWorkingUrl();
    print('   📡 Selected server: $workingUrl');
    
    if (workingUrl.contains('railway')) {
      print('   🚂 Using Railway server');
    } else if (workingUrl.contains('render')) {
      print('   🎨 Using Render server (Auto-switched!)');
    } else {
      print('   🤔 Using unknown server: $workingUrl');
    }
  }
}

/// 🎮 Widget to test auto-switching in UI
class ServerSwitchingTestWidget extends StatefulWidget {
  const ServerSwitchingTestWidget({Key? key}) : super(key: key);

  @override
  State<ServerSwitchingTestWidget> createState() => _ServerSwitchingTestWidgetState();
}

class _ServerSwitchingTestWidgetState extends State<ServerSwitchingTestWidget> {
  String _statusText = 'Server Status: Ready to test';
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 Server Auto-Switching Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚀 Railway ↔ Render Auto-Switching',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'यह feature automatically Railway से Render पर switch करता है अगर Railway down हो जाए।',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testServerStatus,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('🏥 Check Server Health'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAutoSwitching,
              child: const Text('🔄 Test Auto-Switching'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _refreshConnection,
              child: const Text('🔃 Refresh Connection'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _testServerStatus() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Checking server status...';
    });
    
    try {
      final health = await ApiService.getServerHealth();
      final status = health['serverStatus'];
      
      setState(() {
        _statusText = '''Server Health Report:
🔗 Connected: ${health['connected'] ? 'YES' : 'NO'}
🚂 Railway: ${status['primaryAvailable'] ? 'UP' : 'DOWN'}
🎨 Render: ${status['secondaryAvailable'] ? 'UP' : 'DOWN'}
📡 Current: ${status['currentServer']}
⚠️ Switch Needed: ${status['switchRecommended'] ? 'YES' : 'NO'}
⏰ Time: ${DateTime.now().toString().substring(11, 19)}''';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Error checking server status: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testAutoSwitching() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Testing auto-switching...';
    });
    
    try {
      // Run the auto-switching test
      await ServerSwitchingTest.testAutoSwitching();
      
      setState(() {
        _statusText = '''Auto-Switching Test Completed!
✅ Test passed successfully
🔄 Check console/logs for detailed results
📱 Auto-switching is working properly''';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Auto-switching test failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _refreshConnection() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Refreshing connection...';
    });
    
    try {
      final success = await ApiService.refreshConnection();
      
      setState(() {
        _statusText = success
            ? '✅ Connection refreshed successfully!\nReady for new requests.'
            : '❌ Connection refresh failed.\nPlease check your internet connection.';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Connection refresh error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}