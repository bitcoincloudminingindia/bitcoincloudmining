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
    'native':
        'lcv9s3mjszw657sy', // Using rewarded for native (you may need to create a native ad unit)
  };

  bool _isInitialized = false;
  bool _isNativeAdLoaded = false;

  LevelPlayNativeAd? _nativeAd;

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

      // Preload native ad
      await _loadNativeAd();
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

  Future<void> destroyNativeAd() async {
    if (_nativeAd != null) {
      await _nativeAd!.destroyAd();
      _nativeAd = null;
      _isNativeAdLoaded = false;
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
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
      };

  void dispose() {
    _nativeAd?.destroyAd();
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
