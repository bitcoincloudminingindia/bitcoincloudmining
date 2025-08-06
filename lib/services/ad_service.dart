import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../config/mediation_config.dart';

class AdService with ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad configuration
  static const int MAX_RETRY_ATTEMPTS = 2; // Reduced from 3 to 2
  static const Duration RETRY_DELAY =
      Duration(seconds: 3); // Reduced from 5 to 3
  static const Duration AD_CACHE_DURATION = Duration(minutes: 30);

  // Unity Ads Configuration - User's real Game IDs
  static const String UNITY_GAME_ID_ANDROID =
      '5916099'; // User's Unity Game ID for Android
  static const String UNITY_GAME_ID_IOS =
      '5916098'; // User's Unity Game ID for iOS
  static const bool UNITY_TEST_MODE = false; // Set to false for production

  // Unity initialization retry configuration
  static const int MAX_UNITY_INIT_RETRIES = 3;
  static const Duration UNITY_INIT_RETRY_DELAY = Duration(seconds: 5);
  static const Duration UNITY_BANNER_TIMEOUT = Duration(seconds: 15);

  // Unity Ad Unit IDs - Real placement IDs for your Unity Dashboard
  final Map<String, Map<String, String>> _unityAdUnitIds = {
    'android': {
      'banner': 'Banner_Android', // Create this placement in Unity Dashboard
      'rewarded':
          'Rewarded_Android', // Create this placement in Unity Dashboard
      'interstitial':
          'Interstitial_Android', // Create this placement in Unity Dashboard
    },
    'ios': {
      'banner': 'Banner_iOS', // Create this placement in Unity Dashboard
      'rewarded': 'Rewarded_iOS', // Create this placement in Unity Dashboard
      'interstitial':
          'Interstitial_iOS', // Create this placement in Unity Dashboard
    },
  };

  // AdMob IDs
  final Map<String, Map<String, String>> _adMobUnitIds = {
    'android': {
      'native': 'ca-app-pub-3537329799200606/2260507229', // Native_Contract_Card
      'banner': 'ca-app-pub-3537329799200606/2028008282', // Home_Banner_Ad
      'swipeable_banner': 'ca-app-pub-3537329799200606/2028008282', // Using same as banner for now
    },
    'ios': {
      'native': 'ca-app-pub-3537329799200606/2260507229', // Native_Contract_Card
      'banner': 'ca-app-pub-3537329799200606/2028008282', // Home_Banner_Ad
      'swipeable_banner': 'ca-app-pub-3537329799200606/2028008282', // Using same as banner for now
    },
  };
  
  /// Returns the banner ad unit ID for the current platform
  /// This is specifically for the swipeable carousel banner ads
  String? getBannerAdUnitId() {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    return _adMobUnitIds[platform]?['swipeable_banner'];
  }

  // Unity Ad objects
  bool _isUnityInitialized = false;

  // AdMob objects (only for native ads)
  NativeAd? _nativeAd; // Legacy single instance - to be removed after migration

  // Multiple Native Ads Manager (AdMob)
  // Format: 'screenId_adType_adId' -> NativeAd
  final Map<String, NativeAd> _nativeAds = {};
  final Map<String, bool> _nativeAdLoadedStates = {};

  // Swipeable carousel ads - per screen instances
  // Format: 'screenId_adType' -> Ad instance
  final Map<String, BannerAd> _swipeableBannerAds = {};
  final Map<String, NativeAd> _swipeableNativeAds = {};
  final Map<String, bool> _swipeableAdLoadedStates = {};

  // Unity Banner fallback for native ads
  final Map<String, bool> _nativeFallbackStates = {};

  // Unity Ads retry state
  int _unityInitRetryCount = 0;
  Timer? _unityInitRetryTimer;

  // Banner widget singleton to prevent duplicates
  Widget? _bannerWidgetInstance;

  // Ad states
  bool _isBannerAdLoaded = false; // Unity banner
  BannerAd?
      _admobBannerAd; // Legacy AdMob banner (to be removed after migration)
  bool _isRewardedAdLoaded = false; // Unity rewarded
  bool _isRewardedAdLoading = false;
  bool _isInterstitialAdLoaded = false; // Unity interstitial
  bool _isInterstitialAdLoading = false;
  bool _isNativeAdLoaded = false; // AdMob native

  // Mediation states
  final bool _isMediationEnabled = MediationConfig.enabled;
  bool _isMediationInitialized = false;
  final Map<String, bool> _mediationNetworkStates = {};

  // Ad tracking
  final Map<String, int> _adShowCounts = {};
  final Map<String, DateTime> _lastAdShowTimes = {};
  final Map<String, int> _adLoadAttempts = {};
  final Map<String, DateTime> _adCacheTimes = {};
  final Map<String, int> _adFailures = {};
  final Map<String, List<Duration>> _adLoadTimes = {};

  // Mediation tracking
  final Map<String, int> _mediationAdShows = {};
  final Map<String, int> _mediationAdFailures = {};
  final Map<String, double> _mediationRevenue = {};

  // Performance metrics
  int _totalAdShows = 0;
  int _successfulAdShows = 0;
  int _failedAdShows = 0;
  double _averageAdLoadTime = 0.0;

  // Native ad performance metrics
  int _nativeAdLoadCount = 0;
  int _nativeAdFailCount = 0;
  int _nativeAdClickCount = 0;
  int _nativeAdImpressionCount = 0;
  DateTime? _nativeAdFirstLoadTime;
  double _nativeAdAverageLoadTime = 0.0;

  // Getters for metrics
  Map<String, dynamic> get adMetrics => {
        'total_shows': _totalAdShows,
        'successful_shows': _successfulAdShows,
        'failed_shows': _failedAdShows,
        'success_rate':
            _totalAdShows > 0 ? (_successfulAdShows / _totalAdShows) * 100 : 0,
        'average_load_time': _averageAdLoadTime,
        'ad_failures': _adFailures,
      };

  // Get native ad performance metrics
  Map<String, dynamic> get nativeAdMetrics => {
        'load_count': _nativeAdLoadCount,
        'fail_count': _nativeAdFailCount,
        'click_count': _nativeAdClickCount,
        'impression_count': _nativeAdImpressionCount,
        'success_rate': _nativeAdLoadCount > 0
            ? ((_nativeAdLoadCount - _nativeAdFailCount) / _nativeAdLoadCount) *
                100
            : 0,
        'average_load_time': _nativeAdAverageLoadTime,
        'first_load_time': _nativeAdFirstLoadTime?.toIso8601String(),
        'is_loaded': _isNativeAdLoaded,
      };

  // Public getters for ad loaded states
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isNativeAdLoaded => _isNativeAdLoaded;

  // Get ad unit ID based on platform and ad type
  String _getAdUnitId(String adType) {
    if (kIsWeb) return '';

    final platform = Platform.isAndroid ? 'android' : 'ios';

    // For native ads, use AdMob
    if (adType == 'native') {
      return _adMobUnitIds[platform]?[adType] ?? '';
    }

    // For banner and rewarded, use Unity
    return _unityAdUnitIds[platform]?[adType] ?? '';
  }

  String _getUnityGameId() {
    return Platform.isAndroid ? UNITY_GAME_ID_ANDROID : UNITY_GAME_ID_IOS;
  }

  // Update ad metrics
  void _updateAdMetrics(String adType, bool success, Duration? loadTime) {
    _totalAdShows++;
    if (success) {
      _successfulAdShows++;
      _adShowCounts[adType] = (_adShowCounts[adType] ?? 0) + 1;
      _lastAdShowTimes[adType] = DateTime.now();
    } else {
      _failedAdShows++;
      _adFailures[adType] = (_adFailures[adType] ?? 0) + 1;
    }

    if (loadTime != null) {
      _adLoadTimes[adType] ??= [];
      _adLoadTimes[adType]!.add(loadTime);
      _averageAdLoadTime = _adLoadTimes[adType]!
              .fold(0.0, (sum, time) => sum + time.inMilliseconds) /
          _adLoadTimes[adType]!.length;
    }

    _saveMetrics();
  }

  // Save metrics to SharedPreferences
  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_ad_shows', _totalAdShows);
      await prefs.setInt('successful_ad_shows', _successfulAdShows);
      await prefs.setInt('failed_ad_shows', _failedAdShows);
      await prefs.setDouble('average_ad_load_time', _averageAdLoadTime);
      // Convert ad failures map to JSON string
      final failuresJson =
          _adFailures.entries.map((e) => '${e.key}:${e.value}').join(',');
      await prefs.setString('ad_failures', failuresJson);
    } catch (e) {}
  }

  // Load metrics from SharedPreferences
  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalAdShows = prefs.getInt('total_ad_shows') ?? 0;
      _successfulAdShows = prefs.getInt('successful_ad_shows') ?? 0;
      _failedAdShows = prefs.getInt('failed_ad_shows') ?? 0;
      _averageAdLoadTime = prefs.getDouble('average_ad_load_time') ?? 0.0;

      // Load ad failures from JSON string
      final failuresJson = prefs.getString('ad_failures') ?? '';
      if (failuresJson.isNotEmpty) {
        _adFailures.clear();
        for (final entry in failuresJson.split(',')) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            _adFailures[parts[0]] = int.parse(parts[1]);
          }
        }
      }
    } catch (e) {}
  }

  // Load ad with retry mechanism
  Future<void> _loadAdWithRetry(
    String adType,
    Future<void> Function() loadFunction,
    Function(bool) onLoaded,
  ) async {
    if (kIsWeb) return;

    final startTime = DateTime.now();
    int attempts = 0;
    const int maxAttempts = 2; // Reduced from 3 to 2 attempts
    const Duration retryDelay =
        Duration(seconds: 3); // Reduced from 5 to 3 seconds

    while (attempts < maxAttempts) {
      try {
        await loadFunction();
        final loadTime = DateTime.now().difference(startTime);
        _updateAdMetrics(adType, true, loadTime);
        _adCacheTimes[adType] = DateTime.now();
        onLoaded(true);
        return;
      } catch (e) {
        attempts++;
        _adLoadAttempts[adType] = attempts;

        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay * attempts);
        }
      }
    }

    _updateAdMetrics(adType, false, null);
    onLoaded(false);
  }

  // Check if cached ad is still valid
  bool _isCachedAdValid(String adType) {
    final cacheTime = _adCacheTimes[adType];
    if (cacheTime == null) return false;

    return DateTime.now().difference(cacheTime) < AD_CACHE_DURATION;
  }

  Timer? _bannerAdRefreshTimer;

  // Start auto-refresh timer for Unity banner ads
  void _startBannerAdAutoRefresh() {
    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer =
        Timer.periodic(const Duration(seconds: 25), (timer) {
      // Unity ads don't need manual disposal
      _isBannerAdLoaded = false;
      loadBannerAd(); // Reload Unity banner ad
    });
  }

  // Load banner ad
  Future<void> loadBannerAd() async {
    if (!_isUnityInitialized) {
      debugPrint('Unity Ads not initialized yet');
      return;
    }

    if (_isBannerAdLoaded && _isCachedAdValid('banner')) return;

    await _loadAdWithRetry(
      'banner',
      () async {
        final adUnitId = _getAdUnitId('banner');
        if (adUnitId.isEmpty)
          throw Exception('Invalid Unity banner ad unit ID');

        // Load Unity Banner Ad
        await UnityAds.load(
          placementId: adUnitId,
          onComplete: (placementId) {
            _isBannerAdLoaded = true;
            _startBannerAdAutoRefresh();
            debugPrint('Unity Banner Ad loaded: $placementId');

            // Update mediation metrics for successful load
            if (_isMediationEnabled) {
              _updateMediationMetrics('unity', true, null);
            }
          },
          onFailed: (placementId, error, message) {
            _isBannerAdLoaded = false;
            debugPrint('Unity Banner Ad failed to load: $error - $message');

            // Update mediation metrics for failed load
            if (_isMediationEnabled) {
              _updateMediationMetrics('unity', false, null);
            }

            throw Exception('Unity banner ad failed: $message');
          },
        );
      },
      (success) {
        _isBannerAdLoaded = success;
      },
    );
  }

  /// Returns a Unity banner ad widget when loaded, or a placeholder if not available.
  Future<Widget?> getBannerAdWidget() async {
    debugPrint(
        '🎯 getBannerAdWidget called - Unity initialized: $_isUnityInitialized, Banner loaded: $_isBannerAdLoaded');

    if (!_isUnityInitialized) {
      debugPrint('⚠️ Unity not initialized, returning placeholder');
      return _getBannerPlaceholder('Unity Ads not initialized');
    }

    // If already loaded, return Unity banner widget (singleton)
    if (_isBannerAdLoaded) {
      debugPrint('✅ Banner already loaded, returning widget');
      return getUnityBannerWidget();
    }

    // Only try to load if not already loading
    if (!_isBannerAdLoaded) {
      debugPrint('🔄 Banner not loaded, attempting to load...');
      await loadBannerAd();

      // Wait for the ad to be loaded, polling every 100ms, up to 2 seconds
      const int maxTries = 20; // 20 * 100ms = 2 seconds
      int tries = 0;
      while (!_isBannerAdLoaded && tries < maxTries) {
        await Future.delayed(const Duration(milliseconds: 100));
        tries++;
      }
    }

    if (_isBannerAdLoaded) {
      debugPrint('✅ Banner loaded successfully, returning widget');
      return getUnityBannerWidget();
    } else {
      debugPrint('❌ Banner failed to load, returning placeholder');
      return _getBannerPlaceholder('Unity Banner Ad Loading...');
    }
  }

  // Helper method to get a placeholder widget when banner ad fails to load
  Widget _getBannerPlaceholder(String message) {
    // Use the same dimensions as largeBanner (320x100)
    const double width = 320;
    const double height = 100;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.ad_units,
            size: 24,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget getUnityBannerWidget() {
    // Return existing banner widget instance to prevent duplicates
    if (_bannerWidgetInstance != null) {
      debugPrint('🔄 Returning existing banner widget instance');
      return _bannerWidgetInstance!;
    }

    final adUnitId = _getAdUnitId('banner');
    debugPrint('🎯 Creating new Unity banner widget with ID: $adUnitId');

    _bannerWidgetInstance = SizedBox(
      height: 50,
      child: UnityBannerAd(
        placementId: adUnitId,
        onLoad: (placementId) {
          debugPrint('✅ Unity Banner Ad displayed: $placementId');
        },
        onClick: (placementId) {
          debugPrint('👆 Unity Banner Ad clicked: $placementId');
        },
        onFailed: (placementId, error, message) {
          debugPrint('❌ Unity Banner Ad display failed: $error - $message');
          // Reset banner instance on failure to allow retry
          _bannerWidgetInstance = null;
        },
      ),
    );

    return _bannerWidgetInstance!;
  }

  // Unity fallback widget for native ad failures
  Widget _getUnityFallbackWidget(String adId) {
    final bannerAdUnitId = _getAdUnitId('banner');

    debugPrint('🔄 Creating Unity fallback widget for ad: $adId');
    debugPrint('📱 Banner Unit ID: $bannerAdUnitId');
    debugPrint(
        '🎯 Unity Status: Init=$_isUnityInitialized, Banner=$_isBannerAdLoaded');

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header indicating this is a fallback ad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Unity Ad (Fallback)',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // Reset fallback state and try AdMob again
                    _nativeFallbackStates[adId] = false;
                    loadNativeAdWithId(adId);
                  },
                  child: Icon(
                    Icons.refresh,
                    size: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          // Unity banner ad content
          Expanded(
            child: Center(
              child: Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: UnityBannerAd(
                  placementId: bannerAdUnitId,
                  onLoad: (placementId) {
                    debugPrint('Unity Fallback Banner loaded: $placementId');
                  },
                  onClick: (placementId) {
                    debugPrint('Unity Fallback Banner clicked: $placementId');
                  },
                  onFailed: (placementId, error, message) {
                    debugPrint(
                        'Unity Fallback Banner failed: $error - $message');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Load rewarded ad with better error handling and mediation tracking
  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;

    debugPrint(' Loading Unity Rewarded Ad...');

    if (!_isUnityInitialized) {
      debugPrint(' Unity Ads not initialized yet - cannot load rewarded ad');
      return;
    }

    if (_isRewardedAdLoading) {
      debugPrint(' Rewarded ad already loading...');
      return;
    }

    _isRewardedAdLoading = true;

    try {
      final adUnitId = _getAdUnitId('rewarded');
      debugPrint(' Using rewarded ad unit ID: $adUnitId');

      if (adUnitId.isEmpty) {
        debugPrint(' Empty rewarded ad unit ID');
        _isRewardedAdLoading = false;
        return;
      }

      debugPrint(' Calling UnityAds.load for rewarded ad...');

      // Load Unity Rewarded Ad
      await UnityAds.load(
        placementId: adUnitId,
        onComplete: (placementId) {
          _isRewardedAdLoaded = true;
          _isRewardedAdLoading = false;
          _adCacheTimes['rewarded'] = DateTime.now();
          debugPrint(' Unity Rewarded Ad loaded successfully: $placementId');

          // Update mediation metrics for successful load
          if (_isMediationEnabled) {
            _updateMediationMetrics('unity', true, null);
          }
        },
        onFailed: (placementId, error, message) {
          _isRewardedAdLoading = false;
          _isRewardedAdLoaded = false;
          debugPrint(' Unity Rewarded Ad failed to load!');
          debugPrint(' Placement ID: $placementId');
          debugPrint(' Error: $error');
          debugPrint(' Message: $message');

          // Update mediation metrics for failed load
          if (_isMediationEnabled) {
            _updateMediationMetrics('unity', false, null);
          }
        },
      );
    } catch (e) {
      _isRewardedAdLoading = false;
      _isRewardedAdLoaded = false;
      debugPrint(' Unity Rewarded Ad load exception: $e');
      debugPrint(' Stack trace: ${StackTrace.current}');

      // Update mediation metrics for exception
      if (_isMediationEnabled) {
        _updateMediationMetrics('unity', false, null);
      }
    }
  }

  // Auto-refresh native ad periodically
  Timer? _nativeAdRefreshTimer;

  // Load native ad with retry mechanism and auto-refresh
  Future<void> loadNativeAd() async {
    if (_isNativeAdLoaded) {
      return;
    }

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) {
      return;
    }

    final startTime = DateTime.now();

    await _loadAdWithRetry(
      'native',
      () async {
        // Dispose existing ad if any
        _nativeAd?.dispose();
        _nativeAd = null;
        _isNativeAdLoaded = false;

        _nativeAd = NativeAd(
          adUnitId: adUnitId,
          factoryId: 'listTile',
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              _isNativeAdLoaded = true;
              _nativeAdLoadCount++;
              _nativeAdFirstLoadTime ??= DateTime.now();

              final loadTime = DateTime.now().difference(startTime);
              _nativeAdAverageLoadTime =
                  (_nativeAdAverageLoadTime * (_nativeAdLoadCount - 1) +
                          loadTime.inMilliseconds) /
                      _nativeAdLoadCount;

              // Update mediation metrics for successful load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdFailedToLoad: (ad, error) {
              _isNativeAdLoaded = false;
              _nativeAdFailCount++;
              ad.dispose();
              _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;

              // Update mediation metrics for failed load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', false, null);
              }

              throw error;
            },
            onAdOpened: (ad) {
              // Update mediation metrics for ad opened
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdClosed: (ad) {},
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;

              // Update mediation metrics for impression
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;

              // Update mediation metrics for click
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
          ),
        );

        await _nativeAd!.load();
        _adCacheTimes['native'] = DateTime.now();
      },
      (success) {
        _isNativeAdLoaded = success;
      },
    );
    _startNativeAdAutoRefresh();
  }

  // Start auto-refresh timer for native ads
  void _startNativeAdAutoRefresh() {
    _nativeAdRefreshTimer?.cancel();
    // Refresh native ad every 1 minute (60 seconds)
    _nativeAdRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _isNativeAdLoaded = false;
      _nativeAd?.dispose();
      _nativeAd = null;
      loadNativeAd();
    });
  }

  // Force refresh native ad
  Future<void> refreshNativeAd() async {
    _isNativeAdLoaded = false;
    _nativeAd?.dispose();
    _nativeAd = null;
    await loadNativeAd();
  }

  // Get native ad widget with improved error handling and refresh capability
  Widget getNativeAd() {
    if (!_isNativeAdLoaded || _nativeAd == null) {
      // Show Unity banner ad as fallback if Unity is initialized and banner is loaded
      if (_isUnityInitialized && _isBannerAdLoaded) {
        return _getUnityFallbackWidget('native_fallback');
      }

      return Container(
        height: 360,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ads_click, color: Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              _isUnityInitialized ? 'Loading Fallback Ad...' : 'Ad Loading...',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Add refresh button for failed ads
            GestureDetector(
              onTap: () {
                _isNativeAdLoaded = false;
                _nativeAd?.dispose();
                _nativeAd = null;
                loadNativeAd();
                // Also try to load banner ad for fallback
                if (_isUnityInitialized) {
                  loadBannerAd();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Native ad content with error boundary
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  try {
                    return AdWidget(ad: _nativeAd!);
                  } catch (e) {
                    // Return fallback UI if ad rendering fails
                    return Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.grey, size: 20),
                            SizedBox(height: 4),
                            Text(
                              'Ad Unavailable',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            // Close button for better UX
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  // Optionally track ad dismissal
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show rewarded ad with better error handling
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (kIsWeb) {
      // Simulate ad for web testing
      await Future.delayed(const Duration(seconds: 2));
      onRewarded(5.0); // Give 5x reward for web
      return true;
    }

    if (!_isUnityInitialized) {
      debugPrint('Unity Ads not initialized');
      onAdDismissed();
      return false;
    }

    if (!_isRewardedAdLoaded) {
      await loadRewardedAd();
      if (!_isRewardedAdLoaded) {
        onAdDismissed();
        return false;
      }
    }

    final adUnitId = _getAdUnitId('rewarded');

    try {
      await UnityAds.showVideoAd(
        placementId: adUnitId,
        onStart: (placementId) {
          debugPrint('Unity Rewarded Ad started: $placementId');
        },
        onComplete: (placementId) {
          _isRewardedAdLoaded = false;
          debugPrint('Unity Rewarded Ad completed: $placementId');

          // Grant reward (Unity doesn't provide amount, so we use default)
          onRewarded(1.0); // Default reward amount

          // Preload next ad
          loadRewardedAd();

          _updateAdMetrics('rewarded', true, null);

          // Update mediation metrics for successful show
          if (_isMediationEnabled) {
            _updateMediationMetrics('unity', true, null);
          }
        },
        onSkipped: (placementId) {
          _isRewardedAdLoaded = false;
          debugPrint('Unity Rewarded Ad skipped: $placementId');

          // Call onAdDismissed if ad was skipped (no reward)
          onAdDismissed();

          // Preload next ad
          loadRewardedAd();

          _updateAdMetrics('rewarded', false, null);
        },
        onFailed: (placementId, error, message) {
          _isRewardedAdLoaded = false;
          debugPrint('Unity Rewarded Ad failed: $error - $message');

          // Call onAdDismissed on error
          onAdDismissed();

          // Preload next ad
          loadRewardedAd();

          _updateAdMetrics('rewarded', false, null);

          // Update mediation metrics for failed show
          if (_isMediationEnabled) {
            _updateMediationMetrics('unity', false, null);
          }
        },
      );

      return true;
    } catch (e) {
      _isRewardedAdLoaded = false;
      debugPrint('Unity Rewarded Ad show exception: $e');

      // Preload next ad
      loadRewardedAd();

      // Call onAdDismissed on error
      onAdDismissed();

      _updateAdMetrics('rewarded', false, null);
      return false;
    }
  }

  // Load Unity interstitial ad
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdLoading || !_isUnityInitialized) {
      return;
    }

    _isInterstitialAdLoading = true;
    _isInterstitialAdLoaded = false;

    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final adUnitId = _unityAdUnitIds[platform]?['interstitial'] ?? '';

      if (adUnitId.isEmpty) {
        throw Exception('Interstitial ad unit ID not found for $platform');
      }

      await UnityAds.load(
        placementId: adUnitId,
        onComplete: (placementId) {
          _isInterstitialAdLoaded = true;
          _isInterstitialAdLoading = false;
          _updateAdMetrics('interstitial', true, null);
        },
        onFailed: (placementId, error, message) {
          _isInterstitialAdLoaded = false;
          _isInterstitialAdLoading = false;
          _updateAdMetrics('interstitial', false, null);
        },
      );
    } catch (e) {
      _isInterstitialAdLoaded = false;
      _isInterstitialAdLoading = false;
      _updateAdMetrics('interstitial', false, null);
    }
  }

  // Show Unity interstitial ad
  Future<bool> showInterstitialAd({
    VoidCallback? onAdDismissed,
  }) async {
    if (!_isInterstitialAdLoaded || !_isUnityInitialized) {
      onAdDismissed?.call();
      return false;
    }

    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final adUnitId = _unityAdUnitIds[platform]?['interstitial'] ?? '';

      if (adUnitId.isEmpty) {
        onAdDismissed?.call();
        return false;
      }

      await UnityAds.showVideoAd(
        placementId: adUnitId,
        onComplete: (placementId) {
          _isInterstitialAdLoaded = false; // Need to reload after showing
          onAdDismissed?.call();
          _updateAdMetrics('interstitial', true, null);
          // Preload next interstitial ad
          loadInterstitialAd();
        },
        onFailed: (placementId, error, message) {
          _isInterstitialAdLoaded = false;
          onAdDismissed?.call();
          _updateAdMetrics('interstitial', false, null);
        },
        onStart: (placementId) {
          // Ad started playing
        },
        onClick: (placementId) {
          // User clicked on ad
        },
        onSkipped: (placementId) {
          _isInterstitialAdLoaded = false;
          onAdDismissed?.call();
        },
      );
      return true;
    } catch (e) {
      _isInterstitialAdLoaded = false;
      onAdDismissed?.call();
      _updateAdMetrics('interstitial', false, null);
      return false;
    }
  }

  // Getters for interstitial ad state
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isInterstitialAdLoading => _isInterstitialAdLoading;

  // Get Unity banner ad widget (deprecated - use getBannerAdWidget instead)
  Widget getBannerAd() {
    if (!_isBannerAdLoaded || !_isUnityInitialized) {
      return const SizedBox(height: 50);
    }
    try {
      return getUnityBannerWidget();
    } catch (e) {
      return const SizedBox(height: 50);
    }
  }

  // Initialize ads
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // Initialize AdMob (for native ads only)
      await MobileAds.instance.initialize();
      await _loadMetrics();

      // Initialize Unity Ads (for banner and rewarded ads)
      await _initializeUnityAds();

      // Initialize mediation
      await _initializeMediation();

      // Preload ads
      loadBannerAd(); // Unity banner
      loadRewardedAd(); // Unity rewarded
      loadNativeAd(); // AdMob native
    } catch (e) {
      debugPrint('AdService initialization error: $e');
    }
  }

  // Initialize Unity Ads with retry logic
  Future<void> _initializeUnityAdsWithRetry() async {
    if (_unityInitRetryCount >= MAX_UNITY_INIT_RETRIES) {
      debugPrint(
          '❌ Max Unity initialization retries reached ($MAX_UNITY_INIT_RETRIES)');
      return;
    }

    _unityInitRetryCount++;
    debugPrint(
        '🔄 Unity initialization attempt $_unityInitRetryCount/$MAX_UNITY_INIT_RETRIES');

    try {
      await _initializeUnityAds();
      // Reset retry count on success
      _unityInitRetryCount = 0;
      _unityInitRetryTimer?.cancel();
      _unityInitRetryTimer = null;
    } catch (e) {
      debugPrint(
          '❌ Unity initialization attempt $_unityInitRetryCount failed: $e');

      if (_unityInitRetryCount < MAX_UNITY_INIT_RETRIES) {
        debugPrint(
            '⏳ Scheduling retry in ${UNITY_INIT_RETRY_DELAY.inSeconds} seconds...');
        _unityInitRetryTimer?.cancel();
        _unityInitRetryTimer =
            Timer(UNITY_INIT_RETRY_DELAY, _initializeUnityAdsWithRetry);
      } else {
        debugPrint('💥 All Unity initialization attempts failed');
      }
    }
  }

  Future<void> _initializeUnityAds() async {
    try {
      final gameId = _getUnityGameId();
      debugPrint('\n=== UNITY ADS INITIALIZATION DEBUG ===');
      debugPrint('🎮 Game ID: $gameId');
      debugPrint('🧪 Test Mode: $UNITY_TEST_MODE');
      debugPrint('📱 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
      debugPrint('📚 Unity Ads Plugin Version: 0.3.20');
      debugPrint('🔍 Checking Unity Ads availability...');

      // Check if Unity Ads is already initialized
      try {
        final isInitialized = await UnityAds.isInitialized();
        debugPrint('📊 Unity Ads isInitialized: $isInitialized');
        if (isInitialized) {
          _isUnityInitialized = true;
          debugPrint('✅ Unity Ads already initialized!');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Could not check Unity Ads initialization status: $e');
      }

      debugPrint('🚀 Starting Unity Ads initialization...');

      // Initialize Unity Ads with comprehensive error handling
      final completer = Completer<void>();
      bool hasCompleted = false;

      // Set timeout for initialization
      final timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!hasCompleted) {
          hasCompleted = true;
          _isUnityInitialized = false;
          debugPrint('⏰ Unity Ads initialization TIMEOUT after 45 seconds!');
          debugPrint('🔴 This usually means:');
          debugPrint('   1. Game ID is invalid: $gameId');
          debugPrint('   2. Network connectivity issues');
          debugPrint('   3. Unity Ads servers are down');
          debugPrint('   4. Unity Ads plugin is not properly installed');
          completer.completeError('Unity Ads initialization timeout');
        }
      });

      debugPrint('📞 Calling UnityAds.init()...');

      await UnityAds.init(
        gameId: gameId,
        testMode: UNITY_TEST_MODE,
        onComplete: () {
          debugPrint('📢 Unity Ads onComplete callback triggered!');
          if (!hasCompleted) {
            hasCompleted = true;
            timeoutTimer.cancel();
            _isUnityInitialized = true;
            debugPrint('✅ Unity Ads initialized successfully!');
            debugPrint('🎯 Banner Ad Unit: ${_getAdUnitId("banner")}');
            debugPrint('🎁 Rewarded Ad Unit: ${_getAdUnitId("rewarded")}');
            debugPrint('=== UNITY ADS INITIALIZATION SUCCESS ===\n');
            completer.complete();
          }
        },
        onFailed: (error, message) {
          debugPrint('📢 Unity Ads onFailed callback triggered!');
          if (!hasCompleted) {
            hasCompleted = true;
            timeoutTimer.cancel();
            _isUnityInitialized = false;
            debugPrint('❌ Unity Ads initialization FAILED!');
            debugPrint('🔴 Error Code: $error');
            debugPrint('💬 Error Message: $message');
            debugPrint('🔍 Possible solutions:');
            debugPrint('   1. Verify Game ID in Unity Dashboard: $gameId');
            debugPrint('   2. Check if game is published in Unity Dashboard');
            debugPrint('   3. Ensure Unity Ads is enabled for your project');
            debugPrint('   4. Check network connectivity');
            debugPrint('=== UNITY ADS INITIALIZATION FAILED ===\n');
            completer.completeError(
                'Unity Ads initialization failed: $error - $message');
          }
        },
      );

      debugPrint('🕰️ Waiting for Unity Ads initialization to complete...');

      // Wait for initialization to complete
      await completer.future;
    } catch (e, stackTrace) {
      _isUnityInitialized = false;
      debugPrint('💥 Unity Ads initialization EXCEPTION: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      debugPrint('🔧 This might be a plugin integration issue.');
      debugPrint('=== UNITY ADS INITIALIZATION EXCEPTION ===\n');
    }
  }

  // Initialize mediation configuration
  Future<void> _initializeMediation() async {
    if (!_isMediationEnabled) return;

    try {
      // Configure mediation settings
      await _configureMediationSettings();

      // Initialize mediation networks
      await _initializeMediationNetworks();

      _isMediationInitialized = true;

      if (kDebugMode) {
        print('✅ Mediation initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation initialization failed: $e');
      }
    }
  }

  // Configure mediation settings
  Future<void> _configureMediationSettings() async {
    try {
      // Configure AdMob mediation settings
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          testDeviceIds: MediationConfig.enableTestDevices
              ? MediationConfig.testDeviceIds
              : null,
        ),
      );

      if (kDebugMode) {
        print('✅ Mediation settings configured');
        if (MediationConfig.enableTestDevices) {
          print('🔧 Test devices enabled: ${MediationConfig.testDeviceIds}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation settings configuration failed: $e');
      }
    }
  }

  // Initialize mediation networks
  Future<void> _initializeMediationNetworks() async {
    final networks = MediationConfig.supportedNetworks;

    for (final network in networks) {
      try {
        await _initializeMediationNetwork(network);
        _mediationNetworkStates[network] = true;

        if (kDebugMode) {
          print('✅ $network mediation network initialized');
        }
      } catch (e) {
        _mediationNetworkStates[network] = false;
        if (kDebugMode) {
          print('❌ $network mediation network failed: $e');
        }
      }
    }
  }

  // Initialize specific mediation network
  Future<void> _initializeMediationNetwork(String network) async {
    switch (network) {
      case 'unity_ads':
        // Unity Ads is already initialized via build.gradle
        break;
      case 'facebook_audience_network':
        // Facebook Audience Network initialization
        break;
      case 'applovin':
        // AppLovin initialization
        break;
      case 'iron_source':
        // IronSource initialization
        break;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown mediation network: $network');
        }
    }
  }

  // Get mediation status
  Map<String, dynamic> get mediationStatus => {
        'enabled': _isMediationEnabled,
        'initialized': _isMediationInitialized,
        'networks': _mediationNetworkStates,
        'config': MediationConfig.config,
        'metrics': {
          'ad_shows': _mediationAdShows,
          'ad_failures': _mediationAdFailures,
          'revenue': _mediationRevenue,
        },
      };

  // Check if mediation is working properly
  bool get isMediationWorking {
    if (!_isMediationEnabled) return false;
    if (!_isMediationInitialized) return false;

    // Check if at least one network is active
    final activeNetworks =
        _mediationNetworkStates.values.where((state) => state).length;
    return activeNetworks > 0;
  }

  // Get mediation performance summary
  Map<String, dynamic> get mediationPerformance {
    final totalShows =
        _mediationAdShows.values.fold(0, (sum, count) => sum + count);
    final totalFailures =
        _mediationAdFailures.values.fold(0, (sum, count) => sum + count);
    final totalRevenue =
        _mediationRevenue.values.fold(0.0, (sum, revenue) => sum + revenue);

    return {
      'total_shows': totalShows,
      'total_failures': totalFailures,
      'total_revenue': totalRevenue,
      'success_rate': totalShows > 0
          ? ((totalShows - totalFailures) / totalShows) * 100
          : 0,
      'is_working': isMediationWorking,
      'active_networks':
          _mediationNetworkStates.values.where((state) => state).length,
    };
  }

  // Update mediation metrics
  void _updateMediationMetrics(String network, bool success, double? revenue) {
    if (success) {
      _mediationAdShows[network] = (_mediationAdShows[network] ?? 0) + 1;
      if (revenue != null) {
        _mediationRevenue[network] =
            (_mediationRevenue[network] ?? 0) + revenue;
      }
    } else {
      _mediationAdFailures[network] = (_mediationAdFailures[network] ?? 0) + 1;
    }

    // Log mediation metrics for debugging
    if (kDebugMode) {
      print('📊 Mediation Metrics Updated:');
      print('   Network: $network');
      print('   Success: $success');
      print('   Revenue: $revenue');
      print('   Total Shows: ${_mediationAdShows[network]}');
      print('   Total Failures: ${_mediationAdFailures[network]}');
    }
  }

  // Test mediation functionality
  Future<void> testMediation() async {
    if (!_isMediationEnabled) {
      if (kDebugMode) {
        print('❌ Mediation is disabled');
      }
      return;
    }

    if (kDebugMode) {
      print('🧪 Testing Mediation...');
      print('   Enabled: $_isMediationEnabled');
      print('   Initialized: $_isMediationInitialized');
      print('   Networks: $_mediationNetworkStates');
      print('   Metrics:');
      print('     Shows: $_mediationAdShows');
      print('     Failures: $_mediationAdFailures');
      print('     Revenue: $_mediationRevenue');
    }

    // Test ad loading with mediation
    try {
      await loadRewardedAd();
      await loadBannerAd();
      await loadNativeAd();

      if (kDebugMode) {
        print('✅ Mediation test completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation test failed: $e');
      }
    }
  }

  // Note: Main dispose method is implemented later in the file with proper cleanup

  // Reset ad metrics
  Future<void> resetMetrics() async {
    _totalAdShows = 0;
    _successfulAdShows = 0;
    _failedAdShows = 0;
    _averageAdLoadTime = 0.0;
    _adShowCounts.clear();
    _lastAdShowTimes.clear();
    _adLoadAttempts.clear();
    _adCacheTimes.clear();
    _adFailures.clear();
    _adLoadTimes.clear();

    await _saveMetrics();
  }

  static const String bannerAdUnitId =
      'ca-app-pub-3537329799200606/2028008282'; // Home_Banner_Ad
  static const String rewardedAdUnitId =
      'ca-app-pub-3537329799200606/7827129874'; // Rewarded_BTC_Ad
  static const String nativeAdUnitId =
      'ca-app-pub-3537329799200606/2260507229'; // Native_Contract_Card

  // Unity Ads doesn't need getRewardedAd function like AdMob
  // Use isRewardedAdLoaded getter and showRewardedAd() function instead
  Future<bool> getRewardedAdStatus() async {
    if (!_isUnityInitialized) {
      return false;
    }

    if (!_isRewardedAdLoaded && !_isRewardedAdLoading) {
      await loadRewardedAd();
    }

    return _isRewardedAdLoaded;
  }

  // Validate native ad size and layout
  Map<String, dynamic> validateNativeAdSize() {
    final result = {
      'container_height': 250,
      'media_height': 150,
      'button_height': 64,
      'total_estimated_height': 250,
      'recommendations': <String>[],
    };

    // Check if container height is sufficient
    if ((result['container_height'] as int) < 200) {
      (result['recommendations'] as List<String>)
          .add('Container height should be at least 200px');
    }

    // Check if media height is appropriate
    if ((result['media_height'] as int) < 120) {
      (result['recommendations'] as List<String>)
          .add('Media height should be at least 120dp');
    }

    // Check if button height is touch-friendly
    if ((result['button_height'] as int) < 48) {
      (result['recommendations'] as List<String>)
          .add('Button height should be at least 48dp for touch targets');
    }

    return result;
  }

  // Native ad loading configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);
  static const Duration _fallbackTimeout = Duration(seconds: 5);

  final Map<String, Timer> _nativeAdTimers = {};
  final Map<String, int> _nativeAdRetryCounts = {};

  // Multiple Native Ads Methods with improved fallback logic
  Future<void> loadNativeAdWithId(String adId, {bool isRetry = false}) async {
    if (kIsWeb) return;

    debugPrint('===== Loading Native Ad With ID: $adId =====');
    debugPrint(
        'Current fallback state: ${_nativeFallbackStates[adId] ?? false}');
    debugPrint('Is retry attempt: $isRetry');

    // Cancel any existing timer for this ad
    _nativeAdTimers[adId]?.cancel();

    // Initialize retry count if not exists
    _nativeAdRetryCounts[adId] = _nativeAdRetryCounts[adId] ?? 0;

    // Dispose existing ad if any
    _nativeAds[adId]?.dispose();
    _nativeAds.remove(adId);
    _nativeAdLoadedStates[adId] = false;

    // Enable fallback by default when starting to load a new ad
    _nativeFallbackStates[adId] = true;

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) {
      debugPrint('Empty ad unit ID for native ad');
      _scheduleFallback(adId);
      return;
    }

    debugPrint('Using ad unit ID: $adUnitId');
    final startTime = DateTime.now();

    // Set up a timeout for the native ad load
    _nativeAdTimers[adId] = Timer(_fallbackTimeout, () {
      if (!(_nativeAdLoadedStates[adId] ?? false)) {
        debugPrint('Native ad load timed out, falling back to Unity banner');
        _nativeFallbackStates[adId] = true;
        _notifyAdStateChange();
      }
    });

    try {
      await _loadAdWithRetry(
        'native',
        () async {
          debugPrint('🔄 Attempting to load native ad with ID: $adId');
          debugPrint('🎯 Using AdMob Unit ID: $adUnitId');

          // Try different factory IDs to avoid white screen
          String factoryId = 'listTile';
          if (_nativeAdRetryCounts[adId] != null &&
              _nativeAdRetryCounts[adId]! > 0) {
            // Try alternative factory IDs on retry
            final alternatives = ['adplacer', 'listTile', 'gridTile'];
            factoryId =
                alternatives[_nativeAdRetryCounts[adId]! % alternatives.length];
            debugPrint('🔄 Retry attempt, using factory ID: $factoryId');
          }

          final nativeAd = NativeAd(
            adUnitId: adUnitId,
            factoryId: factoryId, // Dynamic factory ID to avoid white screen
            request: const AdRequest(),
            nativeTemplateStyle: NativeTemplateStyle(
              templateType: TemplateType.medium,
              mainBackgroundColor: Colors.white,
              cornerRadius: 8.0,
              callToActionTextStyle: NativeTemplateTextStyle(
                textColor: Colors.white,
                backgroundColor: Colors.blue,
                style: NativeTemplateFontStyle.bold,
                size: 16.0,
              ),
              primaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black87,
                style: NativeTemplateFontStyle.bold,
                size: 16.0,
              ),
              secondaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black54,
                style: NativeTemplateFontStyle.normal,
                size: 14.0,
              ),
              tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black45,
                style: NativeTemplateFontStyle.normal,
                size: 12.0,
              ),
            ),
            listener: NativeAdListener(
              onAdLoaded: (ad) {
                _nativeAdTimers[adId]?.cancel();
                debugPrint('✅ Native ad loaded successfully for ID: $adId');
                debugPrint('📊 Ad details: ${ad.toString()}');
                _nativeAdLoadedStates[adId] = true;
                _nativeAdLoadCount++;
                _nativeAdFirstLoadTime ??= DateTime.now();
                _nativeAdRetryCounts[adId] =
                    0; // Reset retry counter on success

                // Add a small delay to ensure ad is fully rendered
                Future.delayed(const Duration(milliseconds: 500), () {
                  debugPrint('🎯 Native ad should be visible now');
                });

                final loadTime = DateTime.now().difference(startTime);
                _nativeAdAverageLoadTime =
                    (_nativeAdAverageLoadTime * (_nativeAdLoadCount - 1) +
                            loadTime.inMilliseconds) /
                        _nativeAdLoadCount;

                // Update mediation metrics for successful load
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
                _notifyAdStateChange();
              },
              onAdFailedToLoad: (ad, error) {
                _nativeAdTimers[adId]?.cancel();
                debugPrint('Native ad failed to load: ${error.message}');
                debugPrint('Error code: ${error.code}');
                debugPrint('Error domain: ${error.domain}');

                _nativeAdLoadedStates[adId] = false;
                _nativeAdFailCount++;
                ad.dispose();
                _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;

                // Handle retry logic
                _handleNativeAdLoadFailure(adId, error);
              },
              onAdClicked: (ad) {
                _nativeAdClickCount++;
                // Update mediation metrics for click
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
              },
              onAdOpened: (ad) {},
              onAdClosed: (ad) {},
              onAdImpression: (ad) {
                _nativeAdImpressionCount++;
                // Update mediation metrics for impression
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
              },
            ),
          );

          await nativeAd.load();
          _nativeAds[adId] = nativeAd;
          return;
        },
        (success) {
          _nativeAdLoadedStates[adId] = success;
          if (!success) {
            _handleNativeAdLoadFailure(adId, null);
          }
        },
      );
    } catch (e) {
      debugPrint('Exception while loading native ad: $e');
      _handleNativeAdLoadFailure(adId, e);
    }
  }

  void _handleNativeAdLoadFailure(String adId, dynamic error) {
    final retryCount = _nativeAdRetryCounts[adId] ?? 0;

    if (retryCount < _maxRetryAttempts) {
      // Calculate exponential backoff delay
      final delay = Duration(
          milliseconds:
              (_initialRetryDelay.inMilliseconds * (1 << (retryCount - 1)))
                  .clamp(_initialRetryDelay.inMilliseconds,
                      _maxRetryDelay.inMilliseconds));

      debugPrint('Scheduling retry $retryCount in ${delay.inSeconds} seconds');

      _nativeAdRetryCounts[adId] = retryCount + 1;
      Future.delayed(delay, () => loadNativeAdWithId(adId, isRetry: true));
    } else {
      debugPrint('Max retry attempts reached, falling back to Unity banner');
      _scheduleFallback(adId);
    }
  }

  void _scheduleFallback(String adId) {
    _nativeFallbackStates[adId] = true;
    _notifyAdStateChange();

    // If Unity is not initialized, try to initialize it with retry logic
    if (!_isUnityInitialized) {
      debugPrint(
          'Unity not initialized, attempting to initialize with retry...');
      _initializeUnityAdsWithRetry();
    } else if (!_isBannerAdLoaded) {
      // Unity is initialized but banner not loaded, try loading banner
      debugPrint('Unity initialized but banner not loaded, loading banner...');
      loadBannerAd();
    }
  }

  void _notifyAdStateChange() {
    // Notify listeners about the ad state change
    // This can be used to trigger UI updates if needed
    notifyListeners();
  }

  bool isNativeAdLoadedWithId(String adId) {
    return _nativeAdLoadedStates[adId] ?? false;
  }

  Widget getNativeAdWithId(String adId) {
    debugPrint('===== Native Ad Debug =====');
    debugPrint('Ad ID: $adId');

    final nativeAd = _nativeAds[adId];
    final isLoaded = _nativeAdLoadedStates[adId] ?? false;
    final shouldShowFallback = _nativeFallbackStates[adId] ?? false;

    debugPrint('Native Ad Loaded: $isLoaded');
    debugPrint('Should Show Fallback: $shouldShowFallback');
    debugPrint('Unity Initialized: $_isUnityInitialized');
    debugPrint('Banner Ad Loaded: $_isBannerAdLoaded');

    // Enhanced fallback logic with more flexible conditions
    if (!isLoaded && shouldShowFallback) {
      if (_isUnityInitialized && _isBannerAdLoaded) {
        debugPrint('✅ Showing Unity Fallback Banner for ad ID: $adId');
        return _getUnityFallbackWidget(adId);
      } else if (_isUnityInitialized && !_isBannerAdLoaded) {
        debugPrint(
            '🔄 Unity initialized but banner not loaded, loading banner...');
        loadBannerAd();
        return _getUnityFallbackWidget(adId); // Show fallback anyway
      } else if (!_isUnityInitialized) {
        debugPrint('🔄 Unity not initialized, initializing with retry...');
        _initializeUnityAdsWithRetry();
        return _getUnityFallbackWidget(adId); // Show fallback anyway
      }
    } else if (!isLoaded) {
      debugPrint('Native ad not loaded, fallback conditions not met:');
      if (isLoaded) debugPrint('  - Native ad is loaded');
      if (!shouldShowFallback) debugPrint('  - Fallback is disabled');
      if (!_isUnityInitialized) debugPrint('  - Unity Ads is not initialized');
      if (!_isBannerAdLoaded) debugPrint('  - Unity Banner Ad is not loaded');
    }

    if (!isLoaded || nativeAd == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ads_click, color: Colors.grey, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Native Ad Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Add refresh button for failed ads
            GestureDetector(
              onTap: () {
                loadNativeAdWithId(adId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Show fallback option - always available
            GestureDetector(
              onTap: () {
                debugPrint('🔄 Manual fallback trigger for ad: $adId');
                _nativeFallbackStates[adId] = true;
                _scheduleFallback(adId);
                _notifyAdStateChange();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Show Unity Ad',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Debug info
            Text(
              'Unity: ${_isUnityInitialized ? "✅" : "❌"} | Banner: ${_isBannerAdLoaded ? "✅" : "❌"}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Native ad content with enhanced error boundary
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  try {
                    debugPrint('🎯 Rendering AdWidget for native ad');
                    return Container(
                      color: Colors.white,
                      child: AdWidget(ad: nativeAd),
                    );
                  } catch (e) {
                    debugPrint('❌ Error rendering native ad: $e');
                    // Return fallback UI if ad rendering fails
                    return Container(
                      color: Colors.grey[50],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'Ad Display Error',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Error: ${e.toString()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            // Close button for better UX
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  // Optionally track ad dismissal
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void disposeNativeAdWithId(String adId) {
    _nativeAds[adId]?.dispose();
    _nativeAds.remove(adId);
    _nativeAdLoadedStates.remove(adId);
  }

  void disposeAllNativeAds() {
    for (final ad in _nativeAds.values) {
      ad.dispose();
    }
    _nativeAds.clear();
    _nativeAdLoadedStates.clear();
  }

  /// Load AdMob banner ad specifically for swipeable carousel for a specific screen
  /// Uses LARGE_BANNER size for better visibility in the carousel
  Future<void> loadSwipeableBannerAd(String screenId, {int retryCount = 0}) async {
    if (kIsWeb) {
      debugPrint('🌐 [SwipeableBanner] Skipping banner ad load on web platform');
      return;
    }

    const maxRetries = 2; // Maximum number of retry attempts
    final adKey = '${screenId}_banner';
    
    try {
      debugPrint('🔄 [SwipeableBanner] Loading banner ad for screen: $screenId (Attempt ${retryCount + 1}/${maxRetries + 1})');

      // Dispose existing ad if any
      if (_swipeableBannerAds[adKey] != null) {
        debugPrint('♻️ [SwipeableBanner] Disposing existing banner ad for key: $adKey');
        await _swipeableBannerAds[adKey]?.dispose();
        _swipeableBannerAds.remove(adKey);
      }
      
      _swipeableAdLoadedStates[adKey] = false;
      notifyListeners();

      // Get ad unit ID for AdMob
      final adUnitId = _getAdMobAdUnitId(screenId, 'banner');
      if (adUnitId.isEmpty) {
        debugPrint('❌ [SwipeableBanner] Invalid AdMob banner ad unit ID for screen: $screenId');
        return;
      }

      debugPrint('🎯 [SwipeableBanner] Creating LARGE_BANNER ad with ID: $adUnitId');
      
      // Create a new banner ad with LARGE_BANNER size for better visibility
      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.largeBanner, // 320x100
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ [SwipeableBanner] Banner ad loaded successfully for screen: $screenId');
            _swipeableAdLoadedStates[adKey] = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ [SwipeableBanner] Banner ad failed to load for screen: $screenId');
            debugPrint('❌ [SwipeableBanner] Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}');
            
            // Dispose the failed ad
            ad.dispose();
            _swipeableBannerAds.remove(adKey);
            _swipeableAdLoadedStates[adKey] = false;
            notifyListeners();
            
            // Retry loading if we haven't exceeded max retries
            if (retryCount < maxRetries) {
              final retryDelay = Duration(seconds: (retryCount + 1) * 2);
              debugPrint('⏳ [SwipeableBanner] Retrying in ${retryDelay.inSeconds} seconds...');
              Future.delayed(retryDelay, () {
                loadSwipeableBannerAd(screenId, retryCount: retryCount + 1);
              });
            } else {
              debugPrint('⚠️ [SwipeableBanner] Max retries ($maxRetries) reached for banner ad');
            }
          },
          onAdOpened: (ad) => debugPrint('ℹ️ [SwipeableBanner] Banner ad opened for screen: $screenId'),
          onAdClosed: (ad) => debugPrint('ℹ️ [SwipeableBanner] Banner ad closed for screen: $screenId'),
          onAdImpression: (ad) => debugPrint('📊 [SwipeableBanner] Banner ad impression for screen: $screenId'),
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            debugPrint('💰 [SwipeableBanner] Ad paid event: ${valueMicros / 1000000} $currencyCode');
          },
        ),
      );

      // Store the banner ad before loading
      _swipeableBannerAds[adKey] = bannerAd;

      // Load the ad with a timeout
      debugPrint('⏳ [SwipeableBanner] Loading banner ad for screen: $screenId');
      await bannerAd.load().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ [SwipeableBanner] Banner ad load timed out for screen: $screenId');
          throw TimeoutException('Banner ad load timed out');
        },
      );
      
      debugPrint('✅ [SwipeableBanner] Banner ad load() completed for screen: $screenId');
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in loadSwipeableBannerAd: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get AdMob banner ad widget for swipeable carousel for a specific screen
  /// Returns a properly sized container with the banner ad or a fallback UI if the ad fails to load
  Widget getSwipeableBannerAd(String screenId) {
    final adKey = '${screenId}_banner';
    final bannerAd = _swipeableBannerAds[adKey];
    final isLoaded = _swipeableAdLoadedStates[adKey] ?? false;
    
    // Log the current state
    debugPrint('🔄 [SwipeableBanner] Getting banner ad for screen: $screenId');
    debugPrint('   - Banner ad instance: ${bannerAd != null}');
    debugPrint('   - Is loaded: $isLoaded');
    
    // If no banner ad instance exists, try to load one and return a placeholder
    if (bannerAd == null) {
      debugPrint('⚠️ [SwipeableBanner] No banner ad instance found for screen: $screenId, loading...');
      // Schedule an ad load if not already loaded
      if (_swipeableAdLoadedStates[adKey] != true) {
        loadSwipeableBannerAd(screenId);
      }
      return _getBannerPlaceholder('Loading ad...');
    }
    
    // If the banner ad is not loaded yet, return a loading placeholder
    if (!isLoaded) {
      debugPrint('⏳ [SwipeableBanner] Banner ad not loaded yet for screen: $screenId');
      return _getBannerPlaceholder('Loading ad...');
    }
    
    try {
      // Get the banner ad size, default to largeBanner dimensions if not available
      final width = bannerAd.size.width.toDouble();
      final height = bannerAd.size.height.toDouble();
      
      debugPrint('✅ [SwipeableBanner] Returning banner ad widget for screen: $screenId');
      debugPrint('   - Size: ${width.toInt()}x${height.toInt()}');
      
      return Container(
        width: width,
        height: height,
        color: Colors.transparent, // Ensure background is transparent
        alignment: Alignment.center,
        child: AdWidget(ad: bannerAd),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [SwipeableBanner] Error getting banner ad widget for screen $screenId: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Try to reload the ad if it fails
      if (e is Exception) {
        debugPrint('🔄 [SwipeableBanner] Platform error, attempting to reload banner ad...');
        loadSwipeableBannerAd(screenId);
      }
      
      return _getBannerPlaceholder('Ad error');
    }
  }

  /// Load AdMob native ad specifically for swipeable carousel for a specific screen
  Future<void> loadSwipeableNativeAd(String screenId) async {
    if (kIsWeb) return;

    final adKey = '${screenId}_native';
    debugPrint('🔄 Loading swipeable native ad for screen: $screenId');

    try {
      // Dispose existing ad if any
      if (_swipeableNativeAds[adKey] != null) {
        debugPrint('♻️ Disposing existing native ad for $screenId');
        _swipeableNativeAds[adKey]?.dispose();
        _swipeableNativeAds.remove(adKey);
      }
      
      _swipeableAdLoadedStates[adKey] = false;
      notifyListeners();

      final adUnitId = _getAdMobAdUnitId(screenId, 'native');
      if (adUnitId.isEmpty) {
        debugPrint('❌ Invalid AdMob native ad unit ID for screen: $screenId');
        _handleSwipeableNativeAdLoadFailure(adKey, Exception('Invalid ad unit ID'));
        return;
      }

      debugPrint('🆔 Using ad unit ID: $adUnitId');
      
      final nativeAd = NativeAd(
        adUnitId: adUnitId,
        factoryId: 'adFactory',
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ Native ad loaded successfully for screen: $screenId');
            _swipeableAdLoadedStates[adKey] = true;
            _nativeAdLoadCount++;
            _nativeAdFirstLoadTime ??= DateTime.now();
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Failed to load native ad for screen $screenId: $error');
            _swipeableAdLoadedStates[adKey] = false;
            ad.dispose();
            _swipeableNativeAds.remove(adKey);
            _handleSwipeableNativeAdLoadFailure(adKey, error);
          },
          onAdImpression: (ad) {
            debugPrint('👁️ Native ad impression for screen: $screenId');
            _nativeAdImpressionCount++;
          },
          onAdClicked: (ad) {
            debugPrint('👆 Native ad clicked for screen: $screenId');
            _nativeAdClickCount++;
          },
        ),
      );

      _swipeableNativeAds[adKey] = nativeAd;
      await nativeAd.load().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Native ad load timed out for screen: $screenId');
          _handleSwipeableNativeAdLoadFailure(adKey, TimeoutException('Native ad load timed out'));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in loadSwipeableNativeAd: $e');
      debugPrint('Stack trace: $stackTrace');
      _handleSwipeableNativeAdLoadFailure(adKey, e);
    }
  }

  /// Get AdMob native ad widget for swipeable carousel for a specific screen
  Widget? getSwipeableNativeAd(String screenId) {
    final adKey = '${screenId}_native';
    final nativeAd = _swipeableNativeAds[adKey];
    final isLoaded = _swipeableAdLoadedStates[adKey] ?? false;

    debugPrint('🔄 Getting native ad for screen: $screenId');
    debugPrint('   - Ad exists: ${nativeAd != null}');
    debugPrint('   - Is loaded: $isLoaded');

    if (nativeAd == null || !isLoaded) {
      // Try to reload the ad if it's not loaded
      if (nativeAd == null) {
        debugPrint('⚠️ No native ad found, scheduling reload...');
        Future.microtask(() => loadSwipeableNativeAd(screenId));
      }
      return null;
    }

    try {
      debugPrint('✅ Returning native ad widget for screen: $screenId');
      return AdWidget(ad: nativeAd);
    } catch (e) {
      debugPrint('❌ Error creating ad widget: $e');
      return null;
    }
  }

  // Note: Removed duplicate _handleNativeAdLoadFailure method
  // The implementation with the correct signature is kept below

  /// Handle swipeable native ad loading failure with retry logic
  void _handleSwipeableNativeAdLoadFailure(String adKey, dynamic error) {
    debugPrint('❌ Swipeable native ad load failed for key: $adKey');
    debugPrint('Error: $error');
    
    // Check if we should retry
    final retryCount = _nativeAdRetryCounts[adKey] ?? 0;
    final maxRetryAttempts = 3; // Maximum number of retry attempts
    
    if (retryCount < maxRetryAttempts) {
      final retryDelay = Duration(seconds: 2 * (retryCount + 1)); // Exponential backoff
      
      debugPrint('🔄 Scheduling retry #${retryCount + 1} in ${retryDelay.inSeconds}s');
      
      _nativeAdRetryCounts[adKey] = retryCount + 1;
      
      // Schedule retry
      Future.delayed(retryDelay, () {
        if (_swipeableNativeAds.containsKey(adKey)) {
          debugPrint('🔄 Retrying swipeable native ad load (attempt ${retryCount + 1}/$maxRetryAttempts)');
          final screenId = adKey.replaceAll('_native', '');
          loadSwipeableNativeAd(screenId);
        }
      });
    } else {
      debugPrint('⚠️ Max retry attempts ($maxRetryAttempts) reached for swipeable native ad');
      _nativeAdRetryCounts.remove(adKey);
      
      // If we have Unity Ads fallback enabled, try to use it
      if (_isUnityInitialized) {
        debugPrint('🔄 Attempting to fall back to Unity Ads');
        // Extract screen ID from adKey (e.g., 'home_native' -> 'home')
        final screenId = adKey.replaceAll('_native', '');
        _scheduleFallback('${screenId}_native'); // Pass the correct ad ID format
      }
    }
    
    // Update metrics
    _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;
    _nativeAdFailCount++;
    notifyListeners();
  }

  /// Get AdMob ad unit ID based on screen and ad type
  String _getAdMobAdUnitId(String screenId, String adType) {
    if (kIsWeb) return '';

    final platform = Platform.isAndroid ? 'android' : 'ios';
    
    // Production ad unit IDs
    final Map<String, Map<String, String>> productionAdUnitIds = {
      'android': {
        'banner': 'ca-app-pub-3537329799200606/2028008282',
        'rewarded': 'ca-app-pub-3537329799200606/7827129874',
        'native': 'ca-app-pub-3537329799200606/2260507229',
      },
      'ios': {
        'banner': 'ca-app-pub-3537329799200606/2028008282',
        'rewarded': 'ca-app-pub-3537329799200606/7827129874',
        'native': 'ca-app-pub-3537329799200606/2260507229',
      },
    };

    // In debug mode, use test ad unit IDs but log a warning
    if (kDebugMode) {
      debugPrint('⚠️ Using TEST ad unit IDs in debug mode');
      if (platform == 'android') {
        if (adType == 'native') {
          return 'ca-app-pub-3940256099942544/2247696110';
        } else if (adType == 'banner') {
          return 'ca-app-pub-3940256099942544/6300978111';
        } else if (adType == 'rewarded') {
          return 'ca-app-pub-3940256099942544/5224354917';
        }
      } else if (platform == 'ios') {
        if (adType == 'native') {
          return 'ca-app-pub-3940256099942544/3986624511';
        } else if (adType == 'banner') {
          return 'ca-app-pub-3940256099942544/2934735716';
        } else if (adType == 'rewarded') {
          return 'ca-app-pub-3940256099942544/1712485313';
        }
      }
    }

    // In release mode, use production ad unit IDs
    final adUnitId = productionAdUnitIds[platform]?[adType] ?? '';
    debugPrint('📱 Using $adType ad unit ID for $platform: $adUnitId');
    return adUnitId;
  }

  @override
  void dispose() {
    debugPrint('Disposing AdService resources');
    _bannerAdRefreshTimer?.cancel();
    // Dispose AdMob banner ad (legacy)
    _admobBannerAd?.dispose();
    _admobBannerAd = null;

    // Cancel Unity initialization retry timer
    _unityInitRetryTimer?.cancel();
    _unityInitRetryTimer = null;

    // Clear banner widget instance to prevent memory leaks
    _bannerWidgetInstance = null;
    debugPrint('🧹 Banner widget instance cleared');

    // AdMob native ad cleanup
    _nativeAd?.dispose();
    _nativeAd = null;

    // Dispose all native ads from the map
    for (final ad in _nativeAds.values) {
      try {
        ad.dispose();
      } catch (e) {
        debugPrint('Error disposing native ad: $e');
      }
    }
    _nativeAds.clear();
    _nativeAdLoadedStates.clear();
    _nativeFallbackStates.clear();

    // Dispose any pending timers
    for (final timer in _nativeAdTimers.values) {
      try {
        timer.cancel();
      } catch (e) {
        debugPrint('Error cancelling timer: $e');
      }
    }
    _nativeAdTimers.clear();

    // Call super.dispose() to properly clean up ChangeNotifier
    super.dispose();
    debugPrint('AdService resources disposed');
  }
}
