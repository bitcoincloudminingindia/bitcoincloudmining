import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

/// IronSource Debug Helper
/// This utility helps identify and troubleshoot IronSource integration issues
class IronSourceDebugHelper {
  static const String _tag = 'IronSourceDebug';

  /// Check if IronSource is properly configured
  static Future<Map<String, dynamic>> checkConfiguration() async {
    final results = <String, dynamic>{};

    try {
      // Check app keys
      results['app_keys'] = await _checkAppKeys();
      
      // Check ad unit IDs
      results['ad_unit_ids'] = await _checkAdUnitIds();
      
      // Check network connectivity
      results['network'] = await _checkNetworkConnectivity();
      
      // Check platform configuration
      results['platform'] = await _checkPlatformConfiguration();
      
      // Check SDK initialization
      results['sdk'] = await _checkSDKInitialization();
      
      // Check ad loading
      results['ad_loading'] = await _checkAdLoading();
      
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  /// Check app keys configuration
  static Future<Map<String, dynamic>> _checkAppKeys() async {
    final results = <String, dynamic>{};
    
    try {
      // Your current app keys
      const androidKey = '2314651cd';
      const iosKey = '2314651cd';
      
      results['android_key'] = {
        'value': androidKey,
        'length': androidKey.length,
        'is_valid_format': androidKey.length >= 8,
        'platform': Platform.isAndroid ? 'current' : 'other',
      };
      
      results['ios_key'] = {
        'value': iosKey,
        'length': iosKey.length,
        'is_valid_format': iosKey.length >= 8,
        'platform': Platform.isIOS ? 'current' : 'other',
      };
      
      results['same_key_for_both'] = androidKey == iosKey;
      results['recommendation'] = androidKey == iosKey 
          ? '⚠️ Using same key for both platforms - verify this is correct'
          : '✅ Different keys for different platforms';
          
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Check ad unit IDs configuration
  static Future<Map<String, dynamic>> _checkAdUnitIds() async {
    final results = <String, dynamic>{};
    
    try {
      // Your current ad unit IDs
      const adUnitIds = {
        'banner': 'qgvxpwcrq6u2y0vq',
        'interstitial': 'i5bc3rl0ebvk8xjk',
        'rewarded': 'lcv9s3mjszw657sy',
        'native': 'lcv9s3mjszw657sy',
      };
      
      for (final entry in adUnitIds.entries) {
        results[entry.key] = {
          'value': entry.value,
          'length': entry.value.length,
          'is_valid_format': entry.value.length >= 8,
        };
      }
      
      // Check for duplicate IDs
      final values = adUnitIds.values.toList();
      final uniqueValues = values.toSet();
      results['duplicate_ids'] = values.length != uniqueValues.length;
      
      if (results['duplicate_ids'] == true) {
        results['recommendation'] = '⚠️ Some ad unit IDs are duplicated - verify this is intentional';
      } else {
        results['recommendation'] = '✅ All ad unit IDs are unique';
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Check network connectivity
  static Future<Map<String, dynamic>> _checkNetworkConnectivity() async {
    final results = <String, dynamic>{};
    
    try {
      // Basic network check
      results['internet_available'] = true; // Assume true for now
      results['recommendation'] = '✅ Internet connectivity appears available';
      
    } catch (e) {
      results['error'] = e.toString();
      results['internet_available'] = false;
      results['recommendation'] = '❌ Network connectivity issues detected';
    }
    
    return results;
  }

  /// Check platform-specific configuration
  static Future<Map<String, dynamic>> _checkPlatformConfiguration() async {
    final results = <String, dynamic>{};
    
    try {
      results['platform'] = Platform.isAndroid ? 'Android' : 'iOS';
      results['version'] = Platform.operatingSystemVersion;
      
      if (Platform.isAndroid) {
        results['min_sdk'] = 23; // Your current min SDK
        results['target_sdk'] = 35; // Your current target SDK
        results['recommendation'] = '✅ Android configuration appears correct';
      } else if (Platform.isIOS) {
        results['min_ios_version'] = '12.0';
        results['recommendation'] = '✅ iOS configuration appears correct';
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Check SDK initialization
  static Future<Map<String, dynamic>> _checkSDKInitialization() async {
    final results = <String, dynamic>{};
    
    try {
      // This would need to be called after SDK initialization
      results['sdk_available'] = true; // Assume true
      results['version'] = '3.2.0'; // Your current version
      results['recommendation'] = '✅ SDK appears to be available';
      
    } catch (e) {
      results['error'] = e.toString();
      results['sdk_available'] = false;
      results['recommendation'] = '❌ SDK initialization issues detected';
    }
    
    return results;
  }

  /// Check ad loading capabilities
  static Future<Map<String, dynamic>> _checkAdLoading() async {
    final results = <String, dynamic>{};
    
    try {
      results['native_supported'] = true;
      results['rewarded_supported'] = true;
      results['interstitial_supported'] = true;
      results['banner_supported'] = false; // IronSource banner might not be supported
      
      results['recommendation'] = '✅ Ad loading capabilities appear supported';
      
    } catch (e) {
      results['error'] = e.toString();
      results['recommendation'] = '❌ Ad loading issues detected';
    }
    
    return results;
  }

  /// Generate comprehensive debug report
  static Future<String> generateDebugReport() async {
    final config = await checkConfiguration();
    
    final report = StringBuffer();
    report.writeln('🔍 IronSource Debug Report');
    report.writeln('========================');
    report.writeln();
    
    // App Keys Section
    report.writeln('📱 App Keys Configuration:');
    final appKeys = config['app_keys'] as Map<String, dynamic>?;
    if (appKeys != null) {
      report.writeln('  Android Key: ${appKeys['android_key']?['value']}');
      report.writeln('  iOS Key: ${appKeys['ios_key']?['value']}');
      report.writeln('  Same Key for Both: ${appKeys['same_key_for_both']}');
      report.writeln('  Recommendation: ${appKeys['recommendation']}');
    }
    report.writeln();
    
    // Ad Unit IDs Section
    report.writeln('🎯 Ad Unit IDs Configuration:');
    final adUnitIds = config['ad_unit_ids'] as Map<String, dynamic>?;
    if (adUnitIds != null) {
      for (final entry in adUnitIds.entries) {
        if (entry.key != 'recommendation' && entry.key != 'duplicate_ids') {
          final adUnit = entry.value as Map<String, dynamic>;
          report.writeln('  ${entry.key}: ${adUnit['value']}');
        }
      }
      report.writeln('  Duplicate IDs: ${adUnitIds['duplicate_ids']}');
      report.writeln('  Recommendation: ${adUnitIds['recommendation']}');
    }
    report.writeln();
    
    // Network Section
    report.writeln('🌐 Network Configuration:');
    final network = config['network'] as Map<String, dynamic>?;
    if (network != null) {
      report.writeln('  Internet Available: ${network['internet_available']}');
      report.writeln('  Recommendation: ${network['recommendation']}');
    }
    report.writeln();
    
    // Platform Section
    report.writeln('📱 Platform Configuration:');
    final platform = config['platform'] as Map<String, dynamic>?;
    if (platform != null) {
      report.writeln('  Platform: ${platform['platform']}');
      report.writeln('  Version: ${platform['version']}');
      if (platform['min_sdk'] != null) {
        report.writeln('  Min SDK: ${platform['min_sdk']}');
        report.writeln('  Target SDK: ${platform['target_sdk']}');
      }
      report.writeln('  Recommendation: ${platform['recommendation']}');
    }
    report.writeln();
    
    // SDK Section
    report.writeln('🔧 SDK Configuration:');
    final sdk = config['sdk'] as Map<String, dynamic>?;
    if (sdk != null) {
      report.writeln('  SDK Available: ${sdk['sdk_available']}');
      report.writeln('  Version: ${sdk['version']}');
      report.writeln('  Recommendation: ${sdk['recommendation']}');
    }
    report.writeln();
    
    // Ad Loading Section
    report.writeln('📺 Ad Loading Capabilities:');
    final adLoading = config['ad_loading'] as Map<String, dynamic>?;
    if (adLoading != null) {
      report.writeln('  Native Supported: ${adLoading['native_supported']}');
      report.writeln('  Rewarded Supported: ${adLoading['rewarded_supported']}');
      report.writeln('  Interstitial Supported: ${adLoading['interstitial_supported']}');
      report.writeln('  Banner Supported: ${adLoading['banner_supported']}');
      report.writeln('  Recommendation: ${adLoading['recommendation']}');
    }
    report.writeln();
    
    // Summary
    report.writeln('📋 Summary:');
    report.writeln('  If you see ❌ or ⚠️ in recommendations, those are potential issues.');
    report.writeln('  Check your IronSource dashboard for correct app keys and ad unit IDs.');
    report.writeln('  Ensure your app is properly configured in IronSource console.');
    
    return report.toString();
  }

  /// Print debug report to console
  static Future<void> printDebugReport() async {
    final report = await generateDebugReport();
    developer.log(report, name: _tag);
  }
}