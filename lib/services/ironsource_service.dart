import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

class IronSourceService {
  static IronSourceService? _instance;
  static IronSourceService get instance => _instance ??= IronSourceService._();

  IronSourceService._();

  // IronSource App Keys - VERIFY THESE ARE YOUR ACTUAL PRODUCTION KEYS
  static const String _androidAppKey = '2314651cd';
  static const String _iosAppKey = '2314651cd';

  // IronSource Ad Unit IDs - ONLY BANNER AND REWARDED (NO NATIVE)
  static const Map<String, String> _adUnitIds = {
    'banner': 'qgvxpwcrq6u2y0vq', // Banner Main
    'rewarded': 'lcv9s3mjszw657sy', // rewarded_video_1
    // Removed native ad - using AdMob for native ads only
  };

  bool _isInitialized = false;
  bool _isRewardedAdLoaded = false;
  bool _isBannerAdLoaded = false;

  LevelPlayRewardedAd? _rewardedAd;
  LevelPlayBannerAd? _bannerAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('🚀 Starting IronSource SDK initialization...',
          name: 'IronSourceService');

      // Enable debug mode in development
      if (kDebugMode) {
        await IronSource.setAdaptersDebug(true);
        developer.log('🔧 Debug mode enabled for IronSource',
            name: 'IronSourceService');
      }

      // Create init request with test suite metadata
      final initRequest = LevelPlayInitRequest.builder(_getAppKey())
          .withUserId(_getUserId())
          .build();

      developer.log('📱 Using app key: ${_getAppKey()}',
          name: 'IronSourceService');

      // Initialize with listener
      await LevelPlay.init(
        initRequest: initRequest,
        initListener: _LevelPlayInitListener(),
      );

      _isInitialized = true;
      developer.log('✅ IronSource SDK initialized successfully',
          name: 'IronSourceService');

      // Setup event listeners
      _setupEventListeners();

      // Preload ads (only rewarded and banner)
      await _preloadAds();
    } catch (e) {
      developer.log('❌ IronSource initialization failed: $e',
          name: 'IronSourceService', error: e);
      _isInitialized = false;
      
      // Add to event stream for debugging
      _eventController.add({
        'type': 'initialization_error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _preloadAds() async {
    if (!_isInitialized) return;

    try {
      developer.log('🔄 Preloading IronSource ads (Banner & Rewarded only)...',
          name: 'IronSourceService');

      // Load rewarded ad
      await _loadRewardedAd();
      
      // Load banner ad
      await _loadBannerAd();

      developer.log('✅ IronSource ads preloaded (Banner & Rewarded)',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource ad preloading failed: $e',
          name: 'IronSourceService', error: e);
    }
  }

  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) return;

    try {
      developer.log('🔄 Loading IronSource Rewarded ad...',
          name: 'IronSourceService');

      _rewardedAd = LevelPlayRewardedAd.builder()
          .withPlacementName(_adUnitIds['rewarded']!)
          .withListener(_RewardedAdListener())
          .build();

      await _rewardedAd?.loadAd();
      _isRewardedAdLoaded = true;
      developer.log('✅ IronSource Rewarded ad loaded successfully',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource Rewarded ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isRewardedAdLoaded = false;
    }
  }

  Future<void> _loadBannerAd() async {
    if (!_isInitialized) return;

    try {
      developer.log('🔄 Loading IronSource Banner ad...',
          name: 'IronSourceService');

      _bannerAd = LevelPlayBannerAd.builder()
          .withPlacementName(_adUnitIds['banner']!)
          .withListener(_BannerAdListener())
          .build();

      await _bannerAd?.loadAd();
      _isBannerAdLoaded = true;
      developer.log('✅ IronSource Banner ad loaded successfully',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource Banner ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isBannerAdLoaded = false;
    }
  }

  void _setupEventListeners() {
    // Listen to IronSource events
    _eventController.add({
      'type': 'initialization',
      'status': 'success',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Get IronSource Banner Widget
  Widget? getBannerAdWidget({
    double height = 50,
    double width = 320,
  }) {
    if (!_isInitialized || !_isBannerAdLoaded || _bannerAd == null) {
      developer.log('❌ IronSource Banner ad not ready - initialized: $_isInitialized, loaded: $_isBannerAdLoaded',
          name: 'IronSourceService');
      return null;
    }

    try {
      developer.log('🎯 Creating IronSource Banner ad widget',
          name: 'IronSourceService');
      
      return LevelPlayBannerAdView(
        height: height,
        width: width,
        bannerAd: _bannerAd!,
        onPlatformViewCreated: () {
          developer.log('✅ IronSource Banner ad view created',
              name: 'IronSourceService');
        },
      );
    } catch (e) {
      developer.log('❌ IronSource Banner ad widget creation failed: $e',
          name: 'IronSourceService', error: e);
      return null;
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_isInitialized || !_isRewardedAdLoaded || _rewardedAd == null) {
      developer.log('❌ IronSource Rewarded ad not ready - initialized: $_isInitialized, loaded: $_isRewardedAdLoaded',
          name: 'IronSourceService');
      return false;
    }

    try {
      developer.log('🎯 Showing IronSource Rewarded ad',
          name: 'IronSourceService');
      
      await _rewardedAd!.show();
      return true;
    } catch (e) {
      developer.log('❌ IronSource Rewarded ad show failed: $e',
          name: 'IronSourceService', error: e);
      return false;
    }
  }

  Future<void> reloadRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.loadAd();
    }
  }

  Future<void> reloadBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.loadAd();
    }
  }

  Future<void> destroyRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.destroyAd();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    }
  }

  Future<void> destroyBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.destroyAd();
      _bannerAd = null;
      _isBannerAdLoaded = false;
    }
  }

  Future<void> launchTestSuite() async {
    if (!_isInitialized) return;

    try {
      developer.log('🧪 Launching IronSource Test Suite...',
          name: 'IronSourceService');
      
      // Note: Test suite launch is deprecated in newer versions
      // You may need to implement alternative testing methods
      developer.log(
          '⚠️ Test Suite launch is deprecated in newer IronSource versions',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource Test Suite launch failed: $e',
          name: 'IronSourceService', error: e);
    }
  }

  Map<String, dynamic> get metrics => {
        'is_initialized': _isInitialized,
        'rewarded_loaded': _isRewardedAdLoaded,
        'banner_loaded': _isBannerAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _rewardedAd?.destroyAd();
    _bannerAd?.destroyAd();
    _eventController.close();
  }

  String _getAppKey() {
    if (Platform.isAndroid) {
      return _androidAppKey;
    } else if (Platform.isIOS) {
      return _iosAppKey;
    }
    return _androidAppKey; // Default fallback
  }

  String _getUserId() {
    // You can implement user ID logic here
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// IronSource Event Listeners
class _LevelPlayInitListener implements LevelPlayInitListener {
  @override
  void onInitFailed(LevelPlayInitError error) {
    developer.log('❌ IronSource init failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    developer.log('✅ IronSource init success', name: 'IronSourceService');
  }
}

class _RewardedAdListener implements LevelPlayRewardedAdListener {
  @override
  void onAdClicked(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('🎯 IronSource Rewarded ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed(LevelPlayRewardedAd? rewardedAd) {
    developer.log('🔒 IronSource Rewarded ad closed', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayRewardedAd? rewardedAd, IronSourceError? error) {
    developer.log('❌ IronSource Rewarded ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('✅ IronSource Rewarded ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdOpened(LevelPlayRewardedAd? rewardedAd) {
    developer.log('🔓 IronSource Rewarded ad opened', name: 'IronSourceService');
  }

  @override
  void onAdRewarded(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('💰 IronSource Rewarded ad rewarded', name: 'IronSourceService');
  }

  @override
  void onAdShowFailed(LevelPlayRewardedAd? rewardedAd, IronSourceError? error) {
    developer.log('❌ IronSource Rewarded ad show failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdShowSucceeded(LevelPlayRewardedAd? rewardedAd) {
    developer.log('✅ IronSource Rewarded ad show succeeded', name: 'IronSourceService');
  }
}

class _BannerAdListener implements LevelPlayBannerAdListener {
  @override
  void onAdClicked(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('🎯 IronSource Banner ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayBannerAd? bannerAd, IronSourceError? error) {
    developer.log('❌ IronSource Banner ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('✅ IronSource Banner ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdScreenDismissed(LevelPlayBannerAd? bannerAd) {
    developer.log('🔒 IronSource Banner ad screen dismissed', name: 'IronSourceService');
  }

  @override
  void onAdScreenPresented(LevelPlayBannerAd? bannerAd) {
    developer.log('🔓 IronSource Banner ad screen presented', name: 'IronSourceService');
  }
}
