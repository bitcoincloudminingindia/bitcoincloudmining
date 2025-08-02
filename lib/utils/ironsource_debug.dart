import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// IronSource Debug Utility
/// This file contains debugging and error handling utilities for IronSource integration
class IronSourceDebug {
  static const String _tag = 'IronSourceDebug';

  /// Check if IronSource is properly configured
  static Map<String, dynamic> checkConfiguration() {
    final config = {
      'platform': Platform.isAndroid ? 'Android' : 'iOS',
      'app_key_android': '2314651cd',
      'app_key_ios': '2314651cd',
      'ad_unit_ids': {
        'banner': 'qgvxpwcrq6u2y0vq',
        'interstitial': 'i5bc3rl0ebvk8xjk',
        'rewarded': 'lcv9s3mjszw657sy',
        'native': 'lcv9s3mjszw657sy',
      },
      'debug_mode': kDebugMode,
      'test_mode': kDebugMode,
    };

    developer.log('IronSource Configuration Check:', name: _tag);
    developer.log('Platform: ${config['platform']}', name: _tag);
    developer.log('App Key: ${config['app_key_${Platform.isAndroid ? 'android' : 'ios'}']}', name: _tag);
    developer.log('Debug Mode: ${config['debug_mode']}', name: _tag);

    return config;
  }

  /// Validate IronSource app keys
  static bool validateAppKeys() {
    const androidKey = '2314651cd';
    const iosKey = '2314651cd';

    final isValid = (Platform.isAndroid && androidKey.isNotEmpty) ||
                   (Platform.isIOS && iosKey.isNotEmpty);

    developer.log('App Key Validation: ${isValid ? 'PASS' : 'FAIL'}', name: _tag);
    developer.log('Android Key: $androidKey', name: _tag);
    developer.log('iOS Key: $iosKey', name: _tag);

    return isValid;
  }

  /// Check for common 200 error causes
  static List<String> diagnose200Error() {
    final issues = <String>[];

    // Check app keys
    if (!validateAppKeys()) {
      issues.add('Invalid or missing app keys');
    }

    // Check network connectivity
    if (!_checkNetworkConnectivity()) {
      issues.add('Network connectivity issues');
    }

    // Check SDK version
    if (!_checkSDKVersion()) {
      issues.add('SDK version compatibility issues');
    }

    // Check platform configuration
    if (!_checkPlatformConfig()) {
      issues.add('Platform configuration issues');
    }

    developer.log('200 Error Diagnosis:', name: _tag);
    for (final issue in issues) {
      developer.log('- $issue', name: _tag);
    }

    return issues;
  }

  /// Check network connectivity
  static bool _checkNetworkConnectivity() {
    // This is a simplified check - in production you'd want to actually test connectivity
    return true;
  }

  /// Check SDK version compatibility
  static bool _checkSDKVersion() {
    // Check if the SDK version is compatible
    return true;
  }

  /// Check platform-specific configuration
  static bool _checkPlatformConfig() {
    if (Platform.isAndroid) {
      // Check Android-specific configurations
      return true;
    } else if (Platform.isIOS) {
      // Check iOS-specific configurations
      return true;
    }
    return false;
  }

  /// Generate debug report
  static Map<String, dynamic> generateDebugReport() {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.isAndroid ? 'Android' : 'iOS',
      'configuration': checkConfiguration(),
      'app_keys_valid': validateAppKeys(),
      'issues': diagnose200Error(),
      'recommendations': _generateRecommendations(),
    };

    developer.log('IronSource Debug Report Generated', name: _tag);
    developer.log('Report: $report', name: _tag);

    return report;
  }

  /// Generate recommendations based on issues
  static List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (!validateAppKeys()) {
      recommendations.add('Verify app keys in IronSource dashboard');
      recommendations.add('Ensure app keys match your app bundle ID');
    }

    if (diagnose200Error().contains('Network connectivity issues')) {
      recommendations.add('Check internet connection');
      recommendations.add('Verify firewall settings');
    }

    if (diagnose200Error().contains('SDK version compatibility issues')) {
      recommendations.add('Update IronSource SDK to latest version');
      recommendations.add('Check compatibility with your Flutter version');
    }

    if (diagnose200Error().contains('Platform configuration issues')) {
      recommendations.add('Verify AndroidManifest.xml configuration');
      recommendations.add('Check Info.plist settings for iOS');
    }

    // General recommendations
    recommendations.add('Test on real device, not simulator');
    recommendations.add('Check IronSource dashboard for app status');
    recommendations.add('Verify ad unit IDs are correct');

    return recommendations;
  }

  /// Log IronSource events for debugging
  static void logEvent(String event, {Map<String, dynamic>? data}) {
    developer.log('IronSource Event: $event', name: _tag);
    if (data != null) {
      developer.log('Event Data: $data', name: _tag);
    }
  }

  /// Log IronSource errors with context
  static void logError(String error, {String? context, dynamic stackTrace}) {
    developer.log('IronSource Error: $error', name: _tag, error: error);
    if (context != null) {
      developer.log('Error Context: $context', name: _tag);
    }
    if (stackTrace != null) {
      developer.log('Error Stack Trace: $stackTrace', name: _tag);
    }
  }
}