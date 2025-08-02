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
  static const String _interstitialAdUnitId = 'i5bc3rl0ebvk8xjk';
  static const String _rewardedAdUnitId = 'lcv9s3mjszw657sy';

  bool _isInitialized = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  LevelPlayInterstitialAd? _interstitialAd;
  LevelPlayRewardedAd? _rewardedAd;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing IronSource SDK...',
          name: 'IronSourceService');

      // Initialize with listener - using correct API
      await LevelPlay.init(
        initRequest: LevelPlayInitRequest(
          appKey: _getAppKey(),
          userId: _getUserId(),
          legacyAdFormats: [], // Add required parameter
        ),
        initListener: _LevelPlayInitListener(),
      );

      _isInitialized = true;
      developer.log('IronSource SDK initialized successfully',
          name: 'IronSourceService');

      // Setup event listeners
      _setupEventListeners();

      // Preload ads
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

  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    try {
      _interstitialAd = LevelPlayInterstitialAd.builder()
          .withPlacementName(_interstitialAdUnitId)
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
      _rewardedAd = LevelPlayRewardedAd.builder()
          .withPlacementName(_rewardedAdUnitId)
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

  Future<void> destroyInterstitialAd() async {
    if (_interstitialAd != null) {
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
    }
  }

  Future<void> destroyRewardedAd() async {
    if (_rewardedAd != null) {
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
        'interstitial_loaded': _isInterstitialAdLoaded,
        'rewarded_loaded': _isRewardedAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _interstitialAd = null;
    _rewardedAd = null;
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

class _InterstitialAdListener implements LevelPlayInterstitialAdListener {
  @override
  void onAdClicked(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Interstitial ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdClosed(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Interstitial ad closed', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayInterstitialAd? interstitialAd, IronSourceError? error) {
    developer.log('IronSource Interstitial ad load failed: ${error?.toString()}', 
        name: 'IronSourceService');
  }

  @override
  void onAdLoaded(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Interstitial ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdOpened(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Interstitial ad opened', name: 'IronSourceService');
  }

  @override
  void onAdShowFailed(LevelPlayInterstitialAd? interstitialAd, IronSourceError? error) {
    developer.log('IronSource Interstitial ad show failed: ${error?.toString()}', 
        name: 'IronSourceService');
  }

  @override
  void onAdShowSucceeded(LevelPlayInterstitialAd? interstitialAd, IronSourceAdInfo? adInfo) {
    developer.log('IronSource Interstitial ad show succeeded', name: 'IronSourceService');
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
