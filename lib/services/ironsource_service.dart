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
    'interstitial': 'i5bc3rl0ebvk8xjk', // interstitial_ad_1
    'rewarded': 'lcv9s3mjszw657sy', // rewarded_video_1
    'native': 'lcv9s3mjszw657sy', // Using rewarded for native (you may need to create a native ad unit)
  };

  bool _isInitialized = false;
  bool _isNativeAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  LevelPlayNativeAd? _nativeAd;
  LevelPlayInterstitialAd? _interstitialAd;
  LevelPlayRewardedAd? _rewardedAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing IronSource SDK...',
          name: 'IronSourceService');

      // Initialize IronSource
      await IronSource.init(
        appKey: _getAppKey(),
        adUnits: [
          IronSourceAdUnit.INTERSTITIAL,
          IronSourceAdUnit.REWARDED_VIDEO,
          IronSourceAdUnit.NATIVE_ADVANCED,
        ],
      );

      // Set up listeners
      IronSource.setLevelPlayInterstitialListener(_InterstitialAdListener());
      IronSource.setLevelPlayRewardedVideoListener(_RewardedAdListener());
      IronSource.setLevelPlayNativeAdListener(_NativeAdListener());

      _isInitialized = true;
      developer.log('IronSource SDK initialized successfully',
          name: 'IronSourceService');

      // Setup event listeners
      _setupEventListeners();

      // Preload ads
      await _loadNativeAd();
      await _loadInterstitialAd();
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

  Future<void> _loadNativeAd() async {
    if (!_isInitialized) return;

    try {
      // Load native ad using IronSource API
      await IronSource.loadNativeAd(
        placementName: _adUnitIds['native']!,
      );
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
      // Load interstitial ad using IronSource API
      await IronSource.loadInterstitial();
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
      // Load rewarded ad using IronSource API
      await IronSource.loadRewardedVideo();
      _isRewardedAdLoaded = true;
      developer.log('IronSource Rewarded ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Rewarded ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isRewardedAdLoaded = false;
    }
  }

  Widget? getNativeAdWidget({
    double height = 350,
    double width = 300,
  }) {
    if (!_isInitialized || !_isNativeAdLoaded) {
      developer.log('IronSource Native ad not ready',
          name: 'IronSourceService');
      return null;
    }

    try {
      // Return a placeholder widget for native ad
      // You'll need to implement the actual native ad widget based on your requirements
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Native Ad Placeholder'),
        ),
      );
    } catch (e) {
      developer.log('IronSource Native ad widget creation failed: $e',
          name: 'IronSourceService', error: e);
      return null;
    }
  }

  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || !_isInterstitialAdLoaded) {
      developer.log('IronSource Interstitial ad not ready',
          name: 'IronSourceService');
      return false;
    }

    try {
      await IronSource.showInterstitial();
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
    if (!_isInitialized || !_isRewardedAdLoaded) {
      developer.log('IronSource Rewarded ad not ready',
          name: 'IronSourceService');
      return false;
    }

    try {
      await IronSource.showRewardedVideo();
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
    await _loadNativeAd();
  }

  Future<void> reloadInterstitialAd() async {
    await _loadInterstitialAd();
  }

  Future<void> reloadRewardedAd() async {
    await _loadRewardedAd();
  }

  Future<void> destroyNativeAd() async {
    _nativeAd = null;
    _isNativeAdLoaded = false;
  }

  Future<void> destroyInterstitialAd() async {
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  Future<void> destroyRewardedAd() async {
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
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
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
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
    String errorMessage = 'Unknown error';
    try {
      errorMessage = error?.toString() ?? 'Unknown error';
    } catch (e) {
      errorMessage = 'Error occurred while processing ad load failure: $e';
    }
    
    developer.log('IronSource Native ad load failed: $errorMessage',
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Native ad loaded', name: 'IronSourceService');
  }
}

class _InterstitialAdListener implements LevelPlayInterstitialAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad closed', name: 'IronSourceService');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    developer.log('IronSource Interstitial ad display failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
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
  void onAdClosed(LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad closed', name: 'IronSourceService');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    developer.log('IronSource Rewarded ad display failed: ${error.toString()}',
        name: 'IronSourceService');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
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
