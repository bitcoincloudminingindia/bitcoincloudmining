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

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final Map<String, int> _adShowCounts = {};
  final Map<String, int> _adFailCounts = {};
  final Map<String, double> _revenueData = {};

  bool get isInitialized => _isInitialized;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
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

      // Preload rewarded ad
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

  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) return;

    try {
      await LevelPlayRewardedAd.loadAd();
      developer.log('IronSource Rewarded ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Rewarded ad load failed: $e',
          name: 'IronSourceService', error: e);
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      developer.log('IronSource not initialized', name: 'IronSourceService');
      return false;
    }

    try {
      final isAdAvailable = await LevelPlayRewardedAd.isAdAvailable();
      if (!isAdAvailable) {
        developer.log('IronSource Rewarded ad not available', name: 'IronSourceService');
        return false;
      }

      await LevelPlayRewardedAd.showAd();
      _adShowCounts['rewarded'] = (_adShowCounts['rewarded'] ?? 0) + 1;
      
      developer.log('IronSource Rewarded ad shown successfully', name: 'IronSourceService');
      return true;
    } catch (e) {
      _adFailCounts['rewarded'] = (_adFailCounts['rewarded'] ?? 0) + 1;
      developer.log('IronSource Rewarded ad show failed: $e',
          name: 'IronSourceService', error: e);
      return false;
    }
  }

  Future<void> loadBannerAd() async {
    if (!_isInitialized) return;

    try {
      await LevelPlayBannerAd.loadAd(
        adUnitId: _adUnitIds['banner']!,
        adSize: LevelPlayBannerAdSize.BANNER,
        listener: _BannerAdListener(),
      );
      developer.log('IronSource Banner ad loaded', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Banner ad load failed: $e',
          name: 'IronSourceService', error: e);
    }
  }

  Widget getBannerAd() {
    if (!_isInitialized) {
      return const SizedBox(height: 50);
    }

    try {
      return LevelPlayBannerAd(
        adUnitId: _adUnitIds['banner']!,
        adSize: LevelPlayBannerAdSize.BANNER,
        listener: _BannerAdListener(),
      );
    } catch (e) {
      developer.log('IronSource Banner ad widget creation failed: $e',
          name: 'IronSourceService', error: e);
      return const SizedBox(height: 50);
    }
  }

  void dispose() {
    _eventController.close();
    developer.log('IronSource service disposed', name: 'IronSourceService');
  }

  Map<String, dynamic> get metrics => {
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
        'is_initialized': _isInitialized,
      };

  String _getAppKey() {
    if (Platform.isAndroid) {
      return _androidAppKey;
    } else if (Platform.isIOS) {
      return _iosAppKey;
    }
    return _androidAppKey; // Default to Android
  }

  String _getUserId() {
    // Generate a unique user ID or use existing one
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class _LevelPlayInitListener implements LevelPlayInitListener {
  @override
  void onInitializationComplete() {
    developer.log('IronSource initialization completed', name: 'IronSourceService');
  }
}

class _BannerAdListener implements LevelPlayBannerAdListener {
  @override
  void onAdLoaded(LevelPlayBannerAd ad) {
    developer.log('IronSource Banner ad loaded', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayBannerAd ad, LevelPlayAdError error) {
    developer.log('IronSource Banner ad load failed: ${error.description}', 
        name: 'IronSourceService');
  }

  @override
  void onAdClicked(LevelPlayBannerAd ad) {
    developer.log('IronSource Banner ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdScreenPresented(LevelPlayBannerAd ad) {
    developer.log('IronSource Banner ad screen presented', name: 'IronSourceService');
  }

  @override
  void onAdScreenDismissed(LevelPlayBannerAd ad) {
    developer.log('IronSource Banner ad screen dismissed', name: 'IronSourceService');
  }

  @override
  void onAdLeftApplication(LevelPlayBannerAd ad) {
    developer.log('IronSource Banner ad left application', name: 'IronSourceService');
  }
}
