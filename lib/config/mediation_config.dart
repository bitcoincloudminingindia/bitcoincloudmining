import 'package:flutter/foundation.dart';

/// Mediation Configuration for AdMob
/// This file contains all mediation-related settings and configurations
class MediationConfig {
  // Mediation enabled/disabled
  static const bool enabled = true;

  // Waterfall timeout in seconds
  static const int waterfallTimeout = 30;

  // Retry attempts for failed ads
  static const int retryAttempts = 2;

  // Preload mediation ads
  static const bool preloadMediationAds = true;

  // Test device configuration
  static const bool enableTestDevices = kDebugMode;
  static const List<String> testDeviceIds = [
    // Add your test device IDs here
    // You can get these from AdMob console or by running the app in debug mode
    // Example: '33BE2250B43518CCDA7DE426D04EE231',
  ];

  // Supported mediation networks
  static const List<String> supportedNetworks = [
    'unity_ads',
    'facebook_audience_network',
    'applovin',
    'iron_source',
  ];

  // Unity Ads Configuration
  static const Map<String, dynamic> unityAdsConfig = {
    'enabled': true,
    'game_id_android': '5382470', // Unity Ads Game ID for Android 
    'game_id_ios': '5382471', // Unity Ads Game ID for iOS
    'test_mode': kDebugMode,
  };

  // Facebook Audience Network Configuration
  static const Map<String, dynamic> facebookConfig = {
    'enabled': true,
    'app_id_android': '1234567890123456', // Facebook App ID for Android
    'app_id_ios': '1234567890123456', // Facebook App ID for iOS
    'test_mode': kDebugMode,
  };

  // AppLovin Configuration
  static const Map<String, dynamic> appLovinConfig = {
    'enabled': true,
    'sdk_key_android': 'YOUR_APPLOVIN_SDK_KEY', // AppLovin SDK Key
    'sdk_key_ios': 'YOUR_APPLOVIN_SDK_KEY', // AppLovin SDK Key
    'test_mode': kDebugMode,
  };

  // IronSource Configuration
  static const Map<String, dynamic> ironSourceConfig = {
    'enabled': false, // Disable IronSource for now
    'app_key_android': 'YOUR_IRONSOURCE_APP_KEY_ANDROID',
    'app_key_ios': 'YOUR_IRONSOURCE_APP_KEY_IOS',
    'test_mode': kDebugMode,
  };

  // Get complete mediation configuration
  static Map<String, dynamic> get config => {
        'enabled': enabled,
        'waterfall_timeout': waterfallTimeout,
        'retry_attempts': retryAttempts,
        'preload_mediation_ads': preloadMediationAds,
        'mediation_networks': supportedNetworks,
        'unity_ads': unityAdsConfig,
        'facebook_audience_network': facebookConfig,
        'applovin': appLovinConfig,
        'iron_source': ironSourceConfig,
      };

  // Check if specific network is enabled
  static bool isNetworkEnabled(String network) {
    switch (network) {
      case 'unity_ads':
        return unityAdsConfig['enabled'] as bool;
      case 'facebook_audience_network':
        return facebookConfig['enabled'] as bool;
      case 'applovin':
        return appLovinConfig['enabled'] as bool;
      case 'iron_source':
        return ironSourceConfig['enabled'] as bool;
      default:
        return false;
    }
  }

  // Get network configuration
  static Map<String, dynamic>? getNetworkConfig(String network) {
    switch (network) {
      case 'unity_ads':
        return unityAdsConfig;
      case 'facebook_audience_network':
        return facebookConfig;
      case 'applovin':
        return appLovinConfig;
      case 'iron_source':
        return ironSourceConfig;
      default:
        return null;
    }
  }

  // Get platform-specific app ID/key
  static String? getPlatformKey(String network, String platform) {
    final config = getNetworkConfig(network);
    if (config == null) return null;

    switch (platform) {
      case 'android':
        return config['${network}_android'] as String?;
      case 'ios':
        return config['${network}_ios'] as String?;
      default:
        return null;
    }
  }
}
