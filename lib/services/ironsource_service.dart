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
    'banner': 'qgvxpwcrq6u2y0vq', // Banner Main
    'interstitial': 'i5bc3rl0ebvk8xjk', // interstitial_ad_1
    'rewarded': 'lcv9s3mjszw657sy', // rewarded_video_1
    'native': 'lcv9s3mjszw657sy', // Using rewarded for native (you may need to create a native ad unit)
  };

  bool _isInitialized = false;
  bool _isNativeAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isBannerAdLoaded = false;

  LevelPlayNativeAd? _nativeAd;
  LevelPlayRewardedAd? _rewardedAd;
  LevelPlayBannerAd? _bannerAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing IronSource SDK...',
          name: 'IronSourceService');

      // Create init request
      final initRequest = LevelPlayInitRequest.builder(_getAppKey())
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
      await _loadRewardedAd();
      await _loadNativeAd();
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

  // Load Rewarded Ad
  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) return;

    try {
      _rewardedAd = LevelPlayRewardedAd.builder()
          .withPlacementName(_adUnitIds['rewarded']!)
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

  // Show Rewarded Ad
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (!_isInitialized || !_isRewardedAdLoaded || _rewardedAd == null) {
      developer.log('IronSource Rewarded ad not ready', name: 'IronSourceService');
      return false;
    }

    try {
      await _rewardedAd!.showAd();
      
      // Track successful show
      _adShowCounts['rewarded'] = (_adShowCounts['rewarded'] ?? 0) + 1;
      
      developer.log('IronSource Rewarded ad shown successfully', name: 'IronSourceService');
      return true;
    } catch (e) {
      developer.log('IronSource Rewarded ad show failed: $e', name: 'IronSourceService', error: e);
      _adFailCounts['rewarded'] = (_adFailCounts['rewarded'] ?? 0) + 1;
      return false;
    }
  }

  // Load Banner Ad
  Future<void> _loadBannerAd() async {
    if (!_isInitialized) return;

    try {
      _bannerAd = LevelPlayBannerAd.builder()
          .withPlacementName(_adUnitIds['banner']!)
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

  // Get Banner Ad Widget
  Widget? getBannerAdWidget() {
    if (!_isInitialized || !_isBannerAdLoaded || _bannerAd == null) {
      developer.log('IronSource Banner ad not ready', name: 'IronSourceService');
      return null;
    }

    try {
      return LevelPlayBannerAdView(
        bannerAd: _bannerAd!,
        onPlatformViewCreated: () {
          developer.log('IronSource Banner ad view created', name: 'IronSourceService');
        },
      );
    } catch (e) {
      developer.log('IronSource Banner ad widget creation failed: $e',
          name: 'IronSourceService', error: e);
      return null;
    }
  }

  Future<void> _loadNativeAd() async {
    if (!_isInitialized) return;

    try {
      _nativeAd = LevelPlayNativeAd.builder()
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

  Future<void> reloadBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.loadAd();
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
        'rewarded_loaded': _isRewardedAdLoaded,
        'banner_loaded': _isBannerAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _nativeAd?.destroyAd();
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
    developer.log('IronSource init failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    developer.log('IronSource init success', name: 'IronSourceService');
  }
}

class _NativeAdListener implements LevelPlayNativeAdListener {
  @override
  void onAdClicked(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Native ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Native ad impression', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayNativeAd? nativeAd, IronSourceError? error) {
    developer.log('IronSource Native ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Native ad loaded', name: 'IronSourceService');
  }
}

class _RewardedAdListener implements LevelPlayRewardedAdListener {
  @override
  void onAdClicked(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad closed', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayRewardedAd? rewardedAd, IronSourceError? error) {
    developer.log('IronSource Rewarded ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdOpened(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad opened', name: 'IronSourceService');
  }

  @override
  void onAdRewarded(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad rewarded', name: 'IronSourceService');
  }

  @override
  void onAdShowFailed(LevelPlayRewardedAd? rewardedAd, IronSourceError? error) {
    developer.log('IronSource Rewarded ad show failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdShowSucceeded(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad show succeeded', name: 'IronSourceService');
  }
}

class _BannerAdListener implements LevelPlayBannerAdListener {
  @override
  void onAdClicked(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Banner ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayBannerAd? bannerAd, IronSourceError? error) {
    developer.log('IronSource Banner ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Banner ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdScreenDismissed(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Banner ad screen dismissed', name: 'IronSourceService');
  }

  @override
  void onAdScreenPresented(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Banner ad screen presented', name: 'IronSourceService');
  }
}
