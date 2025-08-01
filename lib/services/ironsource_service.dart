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

  // IronSource Ad Unit IDs - VERIFY THESE ARE YOUR ACTUAL PRODUCTION UNITS
  static const Map<String, String> _adUnitIds = {
    'banner': 'qgvxpwcrq6u2y0vq', // Banner Main
    'interstitial': 'i5bc3rl0ebvk8xjk', // interstitial_ad_1
    'rewarded': 'lcv9s3mjszw657sy', // rewarded_video_1
    'native': 'lcv9s3mjszw657sy', // Using rewarded for native
  };

  bool _isInitialized = false;
  bool _isNativeAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isInterstitialAdLoaded = false;

  LevelPlayNativeAd? _nativeAd;
  LevelPlayRewardedAd? _rewardedAd;
  LevelPlayInterstitialAd? _interstitialAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
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

      // Preload ads
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
      developer.log('🔄 Preloading IronSource ads...',
          name: 'IronSourceService');

      // Load native ad
      await _loadNativeAd();
      
      // Load rewarded ad
      await _loadRewardedAd();
      
      // Load interstitial ad
      await _loadInterstitialAd();

      developer.log('✅ IronSource ads preloaded',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource ad preloading failed: $e',
          name: 'IronSourceService', error: e);
    }
  }

  Future<void> _loadNativeAd() async {
    if (!_isInitialized) return;

    try {
      developer.log('🔄 Loading IronSource Native ad...',
          name: 'IronSourceService');

      _nativeAd = LevelPlayNativeAd.builder()
          .withPlacementName(_adUnitIds['native']!)
          .withListener(_NativeAdListener())
          .build();

      await _nativeAd?.loadAd();
      _isNativeAdLoaded = true;
      developer.log('✅ IronSource Native ad loaded successfully',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource Native ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isNativeAdLoaded = false;
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

  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    try {
      developer.log('🔄 Loading IronSource Interstitial ad...',
          name: 'IronSourceService');

      _interstitialAd = LevelPlayInterstitialAd.builder()
          .withPlacementName(_adUnitIds['interstitial']!)
          .withListener(_InterstitialAdListener())
          .build();

      await _interstitialAd?.loadAd();
      _isInterstitialAdLoaded = true;
      developer.log('✅ IronSource Interstitial ad loaded successfully',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('❌ IronSource Interstitial ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isInterstitialAdLoaded = false;
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

  Widget? getNativeAdWidget({
    double height = 350,
    double width = 300,
    LevelPlayTemplateType templateType = LevelPlayTemplateType.MEDIUM,
  }) {
    if (!_isInitialized || !_isNativeAdLoaded || _nativeAd == null) {
      developer.log('❌ IronSource Native ad not ready - initialized: $_isInitialized, loaded: $_isNativeAdLoaded',
          name: 'IronSourceService');
      return null;
    }

    try {
      developer.log('🎯 Creating IronSource Native ad widget',
          name: 'IronSourceService');
      
      return LevelPlayNativeAdView(
        height: height,
        width: width,
        nativeAd: _nativeAd!,
        onPlatformViewCreated: () {
          developer.log('✅ IronSource Native ad view created',
              name: 'IronSourceService');
        },
        templateType: templateType,
      );
    } catch (e) {
      developer.log('❌ IronSource Native ad widget creation failed: $e',
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

  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || !_isInterstitialAdLoaded || _interstitialAd == null) {
      developer.log('❌ IronSource Interstitial ad not ready - initialized: $_isInitialized, loaded: $_isInterstitialAdLoaded',
          name: 'IronSourceService');
      return false;
    }

    try {
      developer.log('🎯 Showing IronSource Interstitial ad',
          name: 'IronSourceService');
      
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      developer.log('❌ IronSource Interstitial ad show failed: $e',
          name: 'IronSourceService', error: e);
      return false;
    }
  }

  Future<void> reloadNativeAd() async {
    if (_nativeAd != null) {
      await _nativeAd!.loadAd();
    }
  }

  Future<void> reloadRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.loadAd();
    }
  }

  Future<void> reloadInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.loadAd();
    }
  }

  Future<void> destroyNativeAd() async {
    if (_nativeAd != null) {
      await _nativeAd!.destroyAd();
      _nativeAd = null;
      _isNativeAdLoaded = false;
    }
  }

  Future<void> destroyRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.destroyAd();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    }
  }

  Future<void> destroyInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.destroyAd();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
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
        'native_loaded': _isNativeAdLoaded,
        'rewarded_loaded': _isRewardedAdLoaded,
        'interstitial_loaded': _isInterstitialAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _nativeAd?.destroyAd();
    _rewardedAd?.destroyAd();
    _interstitialAd?.destroyAd();
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

class _NativeAdListener implements LevelPlayNativeAdListener {
  @override
  void onAdClicked(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('🎯 IronSource Native ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('👁️ IronSource Native ad impression', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayNativeAd? nativeAd, IronSourceError? error) {
    developer.log('❌ IronSource Native ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('✅ IronSource Native ad loaded', name: 'IronSourceService');
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

class _InterstitialAdListener implements LevelPlayInterstitialAdListener {
  @override
  void onAdClicked(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('🎯 IronSource Interstitial ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed(LevelPlayInterstitialAd? interstitialAd) {
    developer.log('🔒 IronSource Interstitial ad closed', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayInterstitialAd? interstitialAd, IronSourceError? error) {
    developer.log('❌ IronSource Interstitial ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('✅ IronSource Interstitial ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdOpened(LevelPlayInterstitialAd? interstitialAd) {
    developer.log('🔓 IronSource Interstitial ad opened', name: 'IronSourceService');
  }

  @override
  void onAdShowFailed(LevelPlayInterstitialAd? interstitialAd, IronSourceError? error) {
    developer.log('❌ IronSource Interstitial ad show failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdShowSucceeded(LevelPlayInterstitialAd? interstitialAd) {
    developer.log('✅ IronSource Interstitial ad show succeeded', name: 'IronSourceService');
  }
}
