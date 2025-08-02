import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ironsource_service.dart';

/// Test utility for IronSource functionality
class IronSourceTest {
  static final IronSourceTest _instance = IronSourceTest._internal();
  factory IronSourceTest() => _instance;
  IronSourceTest._internal();

  /// Test IronSource initialization
  static Future<bool> testInitialization() async {
    try {
      final ironSourceService = IronSourceService();
      await ironSourceService.initIronSource('2314651cd');
      return true;
    } catch (e) {
      debugPrint('IronSource initialization test failed: $e');
      return false;
    }
  }

  /// Test network connectivity
  static Future<bool> testNetworkConnectivity() async {
    try {
      // Test basic internet connectivity
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Network connectivity test failed: $e');
      return false;
    }
  }

  /// Test interstitial ad loading
  static Future<bool> testInterstitialAdLoading() async {
    try {
      final ironSourceService = IronSourceService();
      await ironSourceService.initIronSource('2314651cd');
      await ironSourceService.loadInterstitialAd();
      
      // Wait a bit for loading
      await Future.delayed(const Duration(seconds: 2));
      
      return await ironSourceService.isInterstitialAdLoaded;
    } catch (e) {
      debugPrint('Interstitial ad loading test failed: $e');
      return false;
    }
  }

  /// Test rewarded ad availability
  static Future<bool> testRewardedAdAvailability() async {
    try {
      final ironSourceService = IronSourceService();
      await ironSourceService.initIronSource('2314651cd');
      
      // Wait a bit for initialization
      await Future.delayed(const Duration(seconds: 2));
      
      return await ironSourceService.isRewardedAdLoaded;
    } catch (e) {
      debugPrint('Rewarded ad availability test failed: $e');
      return false;
    }
  }

  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};
    
    results['initialization'] = await testInitialization();
    results['network_connectivity'] = await testNetworkConnectivity();
    results['interstitial_ad_loading'] = await testInterstitialAdLoading();
    results['rewarded_ad_availability'] = await testRewardedAdAvailability();
    
    return results;
  }

  /// Get test summary
  static String getTestSummary(Map<String, bool> results) {
    final totalTests = results.length;
    final passedTests = results.values.where((result) => result).length;
    final failedTests = totalTests - passedTests;
    
    return '''
Test Summary:
- Total Tests: $totalTests
- Passed: $passedTests
- Failed: $failedTests
- Success Rate: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%
''';
  }
}

/// Widget for running IronSource tests
class IronSourceTestWidget extends StatefulWidget {
  const IronSourceTestWidget({super.key});

  @override
  State<IronSourceTestWidget> createState() => _IronSourceTestWidgetState();
}

class _IronSourceTestWidgetState extends State<IronSourceTestWidget> {
  Map<String, bool> _testResults = {};
  bool _isRunningTests = false;
  String _testSummary = '';

  Future<void> _runTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = {};
      _testSummary = '';
    });

    try {
      final results = await IronSourceTest.runAllTests();
      final summary = IronSourceTest.getTestSummary(results);
      
      setState(() {
        _testResults = results;
        _testSummary = summary;
      });
    } catch (e) {
      setState(() {
        _testSummary = 'Test execution failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IronSource Tests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isRunningTests ? null : _runTests,
              child: _isRunningTests
                  ? const CircularProgressIndicator()
                  : const Text('Run Tests'),
            ),
            const SizedBox(height: 20),
            if (_testResults.isNotEmpty) ...[
              const Text(
                'Test Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._testResults.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.error,
                      color: entry.value ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              const Text(
                'Summary:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(_testSummary),
            ],
          ],
        ),
      ),
    );
  }
}