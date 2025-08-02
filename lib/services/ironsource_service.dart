import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

class IronSourceService {
  static IronSourceService? _instance;
  static IronSourceService get instance => _instance ??= IronSourceService._();

  IronSourceService._();

  // IronSource App Key (same for both platforms)
  static const String _appKey = '2314651cd';

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

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  Map<String, int> get adShowCounts => Map.unmodifiable(_adShowCounts);
  Map<String, int> get adFailCounts => Map.unmodifiable(_adFailCounts);

  // Logging utility for consistency
  void _log(String message, {Object? error}) {
    developer.log(message, name: 'IronSourceService', error: error);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _log('Initializing IronSource SDK...');

      // Create initialization request
      final initRequest = LevelPlayInitRequest(
        appKey: _appKey,
        userId: _getUserId(),
        legacyAdFormats: [], // Add required parameter
      );

      // Create initialization listener
      final initListener = _InitListener();

      // Initialize IronSource with the new API
      await LevelPlay.init(
        initRequest: initRequest,
        initListener: initListener,
      );

      _isInitialized = true;
      _log('IronSource SDK initialized successfully');

      // Preload ads
      await _loadNativeAd();
      await _loadInterstitialAd();
      await _loadRewardedAd();
    } catch (e) {
      _log('IronSource initialization failed: $e', error: e);
      _isInitialized = false;
    }
  }

  Future<void> _loadNativeAd() async {
    if (!_isInitialized) return;

    try {
      _nativeAd = LevelPlayNativeAd(
        listener: _NativeAdListener(),
      );

      await _nativeAd?.loadAd();
      // Note: _isNativeAdLoaded will be set in the listener callbacks
      _log('IronSource Native ad load request sent');
    } catch (e) {
      _log('IronSource Native ad load request failed: $e', error: e);
      _isNativeAdLoaded = false;
    }
  }

  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    try {
      _interstitialAd = LevelPlayInterstitialAd(
        listener: _InterstitialAdListener(),
      );

      await _interstitialAd?.loadAd();
      // Note: _isInterstitialAdLoaded will be set in the listener callbacks
      _log('IronSource Interstitial ad load request sent');
    } catch (e) {
      _log('IronSource Interstitial ad load request failed: $e', error: e);
      _isInterstitialAdLoaded = false;
    }
  }

  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) return;

    try {
      _rewardedAd = LevelPlayRewardedAd(
        listener: _RewardedAdListener(),
      );

      await _rewardedAd?.loadAd();
      // Note: _isRewardedAdLoaded will be set in the listener callbacks
      _log('IronSource Rewarded ad load request sent');
    } catch (e) {
      _log('IronSource Rewarded ad load request failed: $e', error: e);
      _isRewardedAdLoaded = false;
    }
  }

  // Reload methods for debug screen
  Future<void> reloadNativeAd() async {
    await _loadNativeAd();
  }

  Future<void> reloadInterstitialAd() async {
    await _loadInterstitialAd();
  }

  Future<void> reloadRewardedAd() async {
    await _loadRewardedAd();
  }

  Widget? getNativeAdWidget({
    double height = 350,
    double width = 300,
    LevelPlayTemplateType templateType = LevelPlayTemplateType.MEDIUM,
  }) {
    if (!_isInitialized || !_isNativeAdLoaded || _nativeAd == null) {
      _log('IronSource Native ad not ready');
      return null;
    }

    try {
      return LevelPlayNativeAdView(
        height: height,
        width: width,
        nativeAd: _nativeAd!,
        onPlatformViewCreated: () {
          _log('IronSource Native ad view created');
        },
        templateType: templateType,
      );
    } catch (e) {
      _log('IronSource Native ad widget creation failed: $e', error: e);
      return null;
    }
  }

  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || !_isInterstitialAdLoaded || _interstitialAd == null) {
      _log('IronSource Interstitial ad not ready');
      return false;
    }

    try {
      await _interstitialAd!.showAd();
      _adShowCounts['interstitial'] = (_adShowCounts['interstitial'] ?? 0) + 1;
      _log('IronSource Interstitial ad shown');
      return true;
    } catch (e) {
      _log('IronSource Interstitial ad show failed: $e', error: e);
      _adFailCounts['interstitial'] = (_adFailCounts['interstitial'] ?? 0) + 1;
      return false;
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_isInitialized || !_isRewardedAdLoaded || _rewardedAd == null) {
      _log('IronSource Rewarded ad not ready');
      return false;
    }

    try {
      await _rewardedAd!.showAd();
      _adShowCounts['rewarded'] = (_adShowCounts['rewarded'] ?? 0) + 1;
      _log('IronSource Rewarded ad shown');
      return true;
    } catch (e) {
      _log('IronSource Rewarded ad show failed: $e', error: e);
      _adFailCounts['rewarded'] = (_adFailCounts['rewarded'] ?? 0) + 1;
      return false;
    }
  }

  // Launch test suite method for debug screen
  Future<void> launchTestSuite() async {
    try {
      await LevelPlay.launchTestSuite();
      _log('IronSource test suite launched');
    } catch (e) {
      _log('Failed to launch IronSource test suite: $e', error: e);
    }
  }

  Map<String, dynamic> get metrics => {
        'is_initialized': _isInitialized,
        'native_loaded': _isNativeAdLoaded,
        'interstitial_loaded': _isInterstitialAdLoaded,
        'rewarded_loaded': _isRewardedAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
      };

  void dispose() {
    _nativeAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
  }

  String _getUserId() {
    // You can implement user ID logic here
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// IronSource Initialization Listener
class _InitListener implements LevelPlayInitListener {
  @override
  void onInitFailed(IronSourceError error) {
    IronSourceService.instance._log('IronSource initialization failed: ${error.toString()}');
  }

  @override
  void onInitSuccess() {
    IronSourceService.instance._log('IronSource initialization complete');
  }
}

// IronSource Event Listeners
class _NativeAdListener implements LevelPlayNativeAdListener {
  @override
  void onAdClicked(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    IronSourceService.instance._log('IronSource Native ad clicked');
  }

  @override
  void onAdImpression(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    IronSourceService.instance._log('IronSource Native ad impression');
  }

  @override
  void onAdLoadFailed(LevelPlayNativeAd? nativeAd, IronSourceError? error) {
    String errorMessage = 'Unknown error';
    try {
      errorMessage = error?.toString() ?? 'Unknown error';
    } catch (e) {
      errorMessage = 'Error occurred while processing ad load failure: $e';
    }
    
    IronSourceService.instance._log('IronSource Native ad load failed: $errorMessage');
    IronSourceService.instance._isNativeAdLoaded = false;
  }

  @override
  void onAdLoaded(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    IronSourceService.instance._log('IronSource Native ad loaded');
    IronSourceService.instance._isNativeAdLoaded = true;
  }
}

class _InterstitialAdListener implements LevelPlayInterstitialAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad clicked');
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad closed');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad display failed: ${error.toString()}');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad displayed');
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad impression');
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad info changed');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    IronSourceService.instance._log('IronSource Interstitial ad load failed: ${error.toString()}');
    IronSourceService.instance._isInterstitialAdLoaded = false;
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Interstitial ad loaded');
    IronSourceService.instance._isInterstitialAdLoaded = true;
  }
}

class _RewardedAdListener implements LevelPlayRewardedAdListener {
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad clicked');
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad closed');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad display failed: ${error.toString()}');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad displayed');
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad impression');
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad info changed');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    IronSourceService.instance._log('IronSource Rewarded ad load failed: ${error.toString()}');
    IronSourceService.instance._isRewardedAdLoaded = false;
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log('IronSource Rewarded ad loaded');
    IronSourceService.instance._isRewardedAdLoaded = true;
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    IronSourceService.instance._log(
      'IronSource Rewarded: user earned reward of ${reward.amount} ${reward.rewardType}'
    );
  }
}
