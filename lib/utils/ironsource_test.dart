import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../services/ironsource_service.dart';
import 'ironsource_debug.dart';

/// IronSource Test Utility
/// This file contains testing and validation utilities for IronSource integration
class IronSourceTest {
  static const String _tag = 'IronSourceTest';

  /// Run comprehensive IronSource tests
  static Future<Map<String, dynamic>> runComprehensiveTest() async {
    final results = <String, dynamic>{};
    
    developer.log('Starting IronSource Comprehensive Test', name: _tag);
    
    // Test 1: Configuration validation
    results['configuration_test'] = await _testConfiguration();
    
    // Test 2: SDK initialization
    results['initialization_test'] = await _testInitialization();
    
    // Test 3: Native ad loading
    results['native_ad_test'] = await _testNativeAd();
    
    // Test 4: Error handling
    results['error_handling_test'] = await _testErrorHandling();
    
    // Test 5: Network connectivity
    results['network_test'] = await _testNetworkConnectivity();
    
    // Generate overall test summary
    results['overall_status'] = _generateOverallStatus(results);
    results['recommendations'] = _generateTestRecommendations(results);
    
    developer.log('IronSource Test Results: $results', name: _tag);
    
    return results;
  }

  /// Test IronSource configuration
  static Future<Map<String, dynamic>> _testConfiguration() async {
    final config = IronSourceDebug.checkConfiguration();
    final appKeysValid = IronSourceDebug.validateAppKeys();
    
    return {
      'status': appKeysValid ? 'PASS' : 'FAIL',
      'app_keys_valid': appKeysValid,
      'platform': config['platform'],
      'debug_mode': config['debug_mode'],
      'issues': appKeysValid ? [] : ['Invalid app keys'],
    };
  }

  /// Test IronSource SDK initialization
  static Future<Map<String, dynamic>> _testInitialization() async {
    try {
      final ironSourceService = IronSourceService.instance;
      
      if (ironSourceService.isInitialized) {
        return {
          'status': 'PASS',
          'initialized': true,
          'message': 'IronSource already initialized',
        };
      }
      
      // Try to initialize
      await ironSourceService.initialize();
      
      // Wait a bit for initialization
      await Future.delayed(const Duration(seconds: 3));
      
      return {
        'status': ironSourceService.isInitialized ? 'PASS' : 'FAIL',
        'initialized': ironSourceService.isInitialized,
        'message': ironSourceService.isInitialized 
            ? 'Initialization successful' 
            : 'Initialization failed',
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'initialized': false,
        'message': 'Initialization exception: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test native ad loading
  static Future<Map<String, dynamic>> _testNativeAd() async {
    try {
      final ironSourceService = IronSourceService.instance;
      
      if (!ironSourceService.isInitialized) {
        return {
          'status': 'SKIP',
          'message': 'IronSource not initialized',
        };
      }
      
      // Check if native ad is already loaded
      if (ironSourceService.isNativeAdLoaded) {
        return {
          'status': 'PASS',
          'loaded': true,
          'message': 'Native ad already loaded',
        };
      }
      
      // Try to load native ad
      await Future.delayed(const Duration(seconds: 5));
      
      return {
        'status': ironSourceService.isNativeAdLoaded ? 'PASS' : 'FAIL',
        'loaded': ironSourceService.isNativeAdLoaded,
        'message': ironSourceService.isNativeAdLoaded 
            ? 'Native ad loaded successfully' 
            : 'Native ad failed to load',
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'loaded': false,
        'message': 'Native ad test exception: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test error handling
  static Future<Map<String, dynamic>> _testErrorHandling() async {
    try {
      // Test with invalid configuration
      final issues = IronSourceDebug.diagnose200Error();
      
      return {
        'status': issues.isEmpty ? 'PASS' : 'WARN',
        'issues_found': issues.length,
        'issues': issues,
        'message': issues.isEmpty 
            ? 'No issues detected' 
            : '${issues.length} issues found',
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Error handling test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test network connectivity
  static Future<Map<String, dynamic>> _testNetworkConnectivity() async {
    try {
      // Simple network test
      final result = await InternetAddress.lookup('google.com');
      
      return {
        'status': result.isNotEmpty ? 'PASS' : 'FAIL',
        'connected': result.isNotEmpty,
        'message': result.isNotEmpty 
            ? 'Network connectivity OK' 
            : 'Network connectivity failed',
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'connected': false,
        'message': 'Network test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Generate overall test status
  static String _generateOverallStatus(Map<String, dynamic> results) {
    final tests = results.values.where((v) => v is Map && v['status'] != null).toList();
    final passedTests = tests.where((t) => t['status'] == 'PASS').length;
    final failedTests = tests.where((t) => t['status'] == 'FAIL').length;
    final skippedTests = tests.where((t) => t['status'] == 'SKIP').length;
    
    if (failedTests > 0) {
      return 'FAIL';
    } else if (skippedTests == tests.length) {
      return 'SKIP';
    } else {
      return 'PASS';
    }
  }

  /// Generate test recommendations
  static List<String> _generateTestRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    // Check configuration test
    final configTest = results['configuration_test'] as Map<String, dynamic>?;
    if (configTest != null && configTest['status'] == 'FAIL') {
      recommendations.add('Fix app key configuration');
      recommendations.add('Verify IronSource dashboard settings');
    }
    
    // Check initialization test
    final initTest = results['initialization_test'] as Map<String, dynamic>?;
    if (initTest != null && initTest['status'] == 'FAIL') {
      recommendations.add('Check network connectivity');
      recommendations.add('Verify SDK version compatibility');
      recommendations.add('Test on real device instead of simulator');
    }
    
    // Check native ad test
    final nativeTest = results['native_ad_test'] as Map<String, dynamic>?;
    if (nativeTest != null && nativeTest['status'] == 'FAIL') {
      recommendations.add('Verify ad unit IDs in IronSource dashboard');
      recommendations.add('Check if native ads are enabled for your app');
      recommendations.add('Wait longer for ad loading (can take 10-30 seconds)');
    }
    
    // Check error handling test
    final errorTest = results['error_handling_test'] as Map<String, dynamic>?;
    if (errorTest != null && errorTest['status'] == 'WARN') {
      recommendations.add('Address detected issues');
      recommendations.add('Check IronSource documentation for specific errors');
    }
    
    // General recommendations
    if (results['overall_status'] == 'FAIL') {
      recommendations.add('Test on a real device');
      recommendations.add('Check IronSource dashboard for app status');
      recommendations.add('Verify all required permissions are granted');
      recommendations.add('Clear app data and try again');
    }
    
    return recommendations;
  }

  /// Quick health check
  static Future<bool> quickHealthCheck() async {
    try {
      final ironSourceService = IronSourceService.instance;
      
      // Check if initialized
      if (!ironSourceService.isInitialized) {
        developer.log('IronSource not initialized', name: _tag);
        return false;
      }
      
      // Check if native ad is loaded
      if (!ironSourceService.isNativeAdLoaded) {
        developer.log('IronSource native ad not loaded', name: _tag);
        return false;
      }
      
      developer.log('IronSource health check passed', name: _tag);
      return true;
    } catch (e) {
      developer.log('IronSource health check failed: $e', name: _tag);
      return false;
    }
  }

  /// Get detailed metrics
  static Map<String, dynamic> getDetailedMetrics() {
    try {
      final ironSourceService = IronSourceService.instance;
      final metrics = ironSourceService.metrics;
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': metrics,
        'health_check': quickHealthCheck(),
        'debug_report': IronSourceDebug.generateDebugReport(),
      };
    } catch (e) {
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'message': 'Failed to get metrics',
      };
    }
  }
}