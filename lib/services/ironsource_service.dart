import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

class IronSourceService {
  static IronSourceService? _instance;
  static IronSourceService get instance => _instance ??= IronSourceService._();

  IronSourceService._();

  // IronSource App Keys
  static const String _androidAppKey = '2314651cd';
  static const String _iosAppKey = '2314651cd';

  // IronSource Ad Unit IDs (from your dashboard)
  static const Map<String, String> _adUnitIds = {
    'banner': 'qgvxpwcrq6u2y0vq', // banner_main
    'interstitial': 'i5bc3rl0ebvk8xjk', // interstitial_ad_1
    'rewarded': 'lcv9s3mjszw657sy', // rewarded_video_1
    'native': 'qgvxpwcrq6u2y0vq', // banner_main (temporary - create proper native ad unit)
  };

  bool _isInitialized = false;
  bool _isNativeAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isBannerAdLoaded = false;

  LevelPlayNativeAd? _nativeAd;
  LevelPlayInterstitialAd? _interstitialAd;
  LevelPlayRewardedAd? _rewardedAd;
  LevelPlayBannerAd? _bannerAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing IronSource SDK...',
          name: 'IronSourceService');

      // Create init request with test suite metadata
      final initRequest = LevelPlayInitRequest.create(_getAppKey())
          .withUserId(_getUserId())
          .build();

      // Initialize with listener
      await LevelPlay.init(
        initRequest: initRequest,
        initListener: _LevelPlayInitListener(),
      );

      _isInitialized = true;
      developer.log('IronSource SDK initialized successfully',
          name: 'IronSourceService');

      // Setup event listeners
      _setupEventListeners();

      // Preload ads
      await _loadNativeAd();
      await _loadInterstitialAd();
      await _loadRewardedAd();
      await _loadBannerAd();
    } catch (e) {
      developer.log('IronSource initialization failed: $e',
          name: 'IronSourceService', error: e);
      _isInitialized = false;
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

  Future<void> _loadNativeAd() async {
    if (!_isInitialized) return;

    try {
      _nativeAd = LevelPlayNativeAd.create()
          .withPlacementName(_adUnitIds['native']!)
          .withListener(_NativeAdListener())
          .build();

      await _nativeAd?.loadAd();
      _isNativeAdLoaded = true;
      developer.log('IronSource Native ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Native ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isNativeAdLoaded = false;
    }
  }

  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    try {
      _interstitialAd = LevelPlayInterstitialAd.create()
          .withAdUnitId(_adUnitIds['interstitial']!)
          .withListener(_InterstitialAdListener())
          .build();

      await _interstitialAd?.loadAd();
      _isInterstitialAdLoaded = true;
      developer.log('IronSource Interstitial ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Interstitial ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isInterstitialAdLoaded = false;
    }
  }

  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) return;

    try {
      _rewardedAd = LevelPlayRewardedAd.create()
          .withAdUnitId(_adUnitIds['rewarded']!)
          .withListener(_RewardedAdListener())
          .build();

      await _rewardedAd?.loadAd();
      _isRewardedAdLoaded = true;
      developer.log('IronSource Rewarded ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Rewarded ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isRewardedAdLoaded = false;
    }
  }

  Future<void> _loadBannerAd() async {
    if (!_isInitialized) return;

    try {
      _bannerAd = LevelPlayBannerAd.create()
          .withAdUnitId(_adUnitIds['banner']!)
          .withListener(_BannerAdListener())
          .build();

      await _bannerAd?.loadAd();
      _isBannerAdLoaded = true;
      developer.log('IronSource Banner ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Banner ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isBannerAdLoaded = false;
    }
  }

  Widget? getNativeAdWidget({
    double height = 350,
    double width = 300,
    LevelPlayTemplateType templateType = LevelPlayTemplateType.MEDIUM,
  }) {
    if (!_isInitialized || !_isNativeAdLoaded || _nativeAd == null) {
      developer.log('IronSource Native ad not ready',
          name: 'IronSourceService');
      return null;
    }

    try {
      return LevelPlayNativeAdView(
        height: height,
        width: width,
        nativeAd: _nativeAd!,
        onPlatformViewCreated: () {
          developer.log('IronSource Native ad view created',
              name: 'IronSourceService');
        },
        templateType: templateType,
      );
    } catch (e) {
      developer.log('IronSource Native ad widget creation failed: $e',
          name: 'IronSourceService', error: e);
      return null;
    }
  }

  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || !_isInterstitialAdLoaded || _interstitialAd == null) {
      developer.log('IronSource Interstitial ad not ready',
          name: 'IronSourceService');
      return false;
    }

    try {
      await _interstitialAd!.showAd();
      _adShowCounts['interstitial'] = (_adShowCounts['interstitial'] ?? 0) + 1;
      developer.log('IronSource Interstitial ad shown', name: 'IronSourceService');
      return true;
    } catch (e) {
      developer.log('IronSource Interstitial ad show failed: $e',
          name: 'IronSourceService', error: e);
      _adFailCounts['interstitial'] = (_adFailCounts['interstitial'] ?? 0) + 1;
      return false;
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_isInitialized || !_isRewardedAdLoaded || _rewardedAd == null) {
      developer.log('IronSource Rewarded ad not ready',
          name: 'IronSourceService');
      return false;
    }

    try {
      await _rewardedAd!.showAd();
      _adShowCounts['rewarded'] = (_adShowCounts['rewarded'] ?? 0) + 1;
      developer.log('IronSource Rewarded ad shown', name: 'IronSourceService');
      return true;
    } catch (e) {
      developer.log('IronSource Rewarded ad show failed: $e',
          name: 'IronSourceService', error: e);
      _adFailCounts['rewarded'] = (_adFailCounts['rewarded'] ?? 0) + 1;
      return false;
    }
  }

  Future<void> reloadNativeAd() async {
    if (_nativeAd != null) {
      await _nativeAd!.loadAd();
    }
  }

  Future<void> reloadInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.loadAd();
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

  Future<void> destroyNativeAd() async {
    if (_nativeAd != null) {
      await _nativeAd!.destroy();
      _nativeAd = null;
      _isNativeAdLoaded = false;
    }
  }

  Future<void> destroyInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.destroy();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
    }
  }

  Future<void> destroyRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.destroy();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    }
  }

  Future<void> destroyBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.destroy();
      _bannerAd = null;
      _isBannerAdLoaded = false;
    }
  }

  Future<void> launchTestSuite() async {
    if (!_isInitialized) return;

    try {
      // Note: Test suite launch is deprecated in newer versions
      // You may need to implement alternative testing methods
      developer.log(
          'Test Suite launch is deprecated in newer IronSource versions',
          name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Test Suite launch failed: $e',
          name: 'IronSourceService', error: e);
    }
  }

  Map<String, dynamic> get metrics => {
        'is_initialized': _isInitialized,
        'native_loaded': _isNativeAdLoaded,
        'interstitial_loaded': _isInterstitialAdLoaded,
        'rewarded_loaded': _isRewardedAdLoaded,
        'banner_loaded': _isBannerAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _nativeAd?.destroy();
    _interstitialAd?.destroy();
    _rewardedAd?.destroy();
    _bannerAd?.destroy(); // Added banner destroy
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
    // Handle error more robustly - use toString() as fallback
    String errorMessage = 'Unknown error';
    try {
      // Try to get more detailed error information if available
      errorMessage = error.toString();
      
      // If the error object has additional properties, we can access them safely
      // This handles potential API changes in the IronSource SDK
      if (error.runtimeType.toString().contains('LevelPlayInitError')) {
        // Log additional error details if available
        developer.log('IronSource init failed with error type: ${error.runtimeType}',
            name: 'IronSourceService');
      }
    } catch (e) {
      errorMessage = 'Error occurred while processing init failure: $e';
    }
    
    developer.log('IronSource init failed: $errorMessage',
        name: 'IronSourceService');
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    developer.log('IronSource init success', name: 'IronSourceService');
  }
}

class _NativeAdListener implements LevelPlayNativeAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Native ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Native ad impression', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    // Handle error more robustly - use toString() as fallback
    String errorMessage = 'Unknown error';
    try {
      errorMessage = error.toString();
      
      // If the error object has additional properties, we can access them safely
      // This handles potential API changes in the IronSource SDK
      if (error.runtimeType.toString().contains('LevelPlayAdError')) {
        // Log additional error details if available
        developer.log('IronSource ad load failed with error type: ${error.runtimeType}',
            name: 'IronSourceService');
      }
    } catch (e) {
      errorMessage = 'Error occurred while processing ad load failure: $e';
    }
    
    developer.log('IronSource Native ad load failed: $errorMessage',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Native ad loaded', name: 'IronSourceService');
  }
}

class _InterstitialAdListener implements LevelPlayInterstitialAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed() {
    developer.log('IronSource Interstitial ad closed', name: 'IronSourceService');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error) {
    developer.log('IronSource Interstitial ad display failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdDisplayed() {
    developer.log('IronSource Interstitial ad displayed', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad impression', name: 'IronSourceService');
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad info changed', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    developer.log('IronSource Interstitial ad load failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad loaded', name: 'IronSourceService');
  }
}

class _RewardedAdListener implements LevelPlayRewardedAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed() {
    developer.log('IronSource Rewarded ad closed', name: 'IronSourceService');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error) {
    developer.log('IronSource Rewarded ad display failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdDisplayed() {
    developer.log('IronSource Rewarded ad displayed', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad impression', name: 'IronSourceService');
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad info changed', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    developer.log('IronSource Rewarded ad load failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad rewarded', name: 'IronSourceService');
  }
}

class _BannerAdListener implements LevelPlayBannerAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Banner ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Banner ad impression', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    developer.log('IronSource Banner ad load failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Banner ad loaded', name: 'IronSourceService');
  }
}
