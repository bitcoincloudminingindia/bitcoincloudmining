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
    // Native ad removed - will use AdMob native ad instead
  };

  bool _isInitialized = false;
  bool _isBannerAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  LevelPlayBannerAd? _bannerAd;
  LevelPlayRewardedAd? _rewardedAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing IronSource SDK...',
          name: 'IronSourceService');

      // Create init request with test suite metadata
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

      // Preload banner and rewarded ads
      await _loadBannerAd();
      await _loadRewardedAd();
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

  Widget? getBannerAdWidget({
    double height = 50,
    double width = 320,
  }) {
    if (!_isInitialized || !_isBannerAdLoaded || _bannerAd == null) {
      developer.log('IronSource Banner ad not ready',
          name: 'IronSourceService');
      return null;
    }

    try {
      return LevelPlayBannerAdView(
        height: height,
        width: width,
        bannerAd: _bannerAd!,
        onPlatformViewCreated: () {
          developer.log('IronSource Banner ad view created',
              name: 'IronSourceService');
        },
      );
    } catch (e) {
      developer.log('IronSource Banner ad widget creation failed: $e',
          name: 'IronSourceService', error: e);
      return null;
    }
  }

  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (!_isInitialized || !_isRewardedAdLoaded || _rewardedAd == null) {
      developer.log('IronSource Rewarded ad not ready',
          name: 'IronSourceService');
      return false;
    }

    try {
      await _rewardedAd!.showAd();
      return true;
    } catch (e) {
      developer.log('IronSource Rewarded ad show failed: $e',
          name: 'IronSourceService', error: e);
      return false;
    }
  }

  Future<void> reloadBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.loadAd();
    }
  }

  Future<void> reloadRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.loadAd();
    }
  }

  Future<void> destroyBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.destroyAd();
      _bannerAd = null;
      _isBannerAdLoaded = false;
    }
  }

  Future<void> destroyRewardedAd() async {
    if (_rewardedAd != null) {
      await _rewardedAd!.destroyAd();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
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
        'banner_loaded': _isBannerAdLoaded,
        'rewarded_loaded': _isRewardedAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _bannerAd?.destroyAd();
    _rewardedAd?.destroyAd();
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

class _BannerAdListener implements LevelPlayBannerAdListener {
  @override
  void onAdClicked(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Banner ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayBannerAd? bannerAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Banner ad impression', name: 'IronSourceService');
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
}

class _RewardedAdListener implements LevelPlayRewardedAdListener {
  @override
  void onAdClicked(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad impression', name: 'IronSourceService');
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
  void onAdRewarded(LevelPlayRewardedAd? rewardedAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Rewarded ad reward earned', name: 'IronSourceService');
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
