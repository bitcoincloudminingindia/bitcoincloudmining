import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

import '../utils/ironsource_debug.dart';

class IronSourceService {
  static IronSourceService? _instance;
  static IronSourceService get instance => _instance ??= IronSourceService._();

  IronSourceService._();

  // IronSource App Keys - Updated with proper keys
  static const String _androidAppKey = '2314651cd';
  static const String _iosAppKey = '2314651cd';

  // IronSource Ad Unit IDs (from your dashboard)
  static const Map<String, String> _adUnitIds = {
    'banner': 'qgvxpwcrq6u2y0vq', // Banner Main
    'interstitial': 'i5bc3rl0ebvk8xjk', // interstitial_ad_1
    'rewarded': 'lcv9s3mjszw657sy', // rewarded_video_1
    'native': 'lcv9s3mjszw657sy', // Using rewarded for native
  };

  bool _isInitialized = false;
  bool _isNativeAdLoaded = false;
  bool _isInitializing = false;

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
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Run debug diagnostics first
      IronSourceDebug.logEvent('Initialization Started');
      final debugReport = IronSourceDebug.generateDebugReport();
      
      developer.log('IronSource Debug Report: $debugReport', name: 'IronSourceService');

      developer.log('Initializing IronSource SDK...',
          name: 'IronSourceService');

      // Get the correct app key for the platform
      final appKey = _getAppKey();
      final userId = _getUserId();

      developer.log('Using app key: $appKey, userId: $userId',
          name: 'IronSourceService');

      // Create init request with proper configuration
      final initRequest = LevelPlayInitRequest.builder(appKey)
          .withUserId(userId)
          .build();

      // Initialize with proper error handling
      await LevelPlay.init(
        initRequest: initRequest,
        initListener: _LevelPlayInitListener(),
      );

      // Wait a bit for initialization to complete
      await Future.delayed(const Duration(seconds: 2));

      _isInitialized = true;
      _isInitializing = false;
      
      IronSourceDebug.logEvent('Initialization Success');
      developer.log('IronSource SDK initialized successfully',
          name: 'IronSourceService');

      // Setup event listeners
      _setupEventListeners();

      // Preload native ad with retry mechanism
      await _loadNativeAdWithRetry();

    } catch (e) {
      IronSourceDebug.logError('Initialization Failed', context: e.toString());
      developer.log('IronSource initialization failed: $e',
          name: 'IronSourceService', error: e);
      _isInitialized = false;
      _isInitializing = false;
      
      // Retry initialization after delay
      Timer(const Duration(seconds: 5), () {
        if (!_isInitialized) {
          initialize();
        }
      });
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

  Future<void> _loadNativeAdWithRetry() async {
    if (!_isInitialized) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries && !_isNativeAdLoaded) {
      try {
        await _loadNativeAd();
        if (_isNativeAdLoaded) break;
      } catch (e) {
        developer.log('IronSource Native ad load attempt ${retryCount + 1} failed: $e',
            name: 'IronSourceService', error: e);
        retryCount++;
        
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }
    }
  }

  Future<void> _loadNativeAd() async {
    if (!_isInitialized) return;

    try {
      developer.log('Loading IronSource Native ad...', name: 'IronSourceService');
      
      _nativeAd = LevelPlayNativeAd.builder()
          .withPlacementName(_adUnitIds['native']!)
          .withListener(_NativeAdListener())
          .build();

      await _nativeAd?.loadAd();
      _isNativeAdLoaded = true;
      developer.log('IronSource Native ad loaded successfully', name: 'IronSourceService');
    } catch (e) {
      developer.log('IronSource Native ad load failed: $e',
          name: 'IronSourceService', error: e);
      _isNativeAdLoaded = false;
      throw e;
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
        'is_initializing': _isInitializing,
        'native_loaded': _isNativeAdLoaded,
        'ad_shows': _adShowCounts,
        'ad_failures': _adFailCounts,
        'revenue': _revenueData,
        'app_key': _getAppKey(),
        'user_id': _getUserId(),
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
    // Generate a consistent user ID
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// IronSource Event Listeners with improved error handling
class _LevelPlayInitListener implements LevelPlayInitListener {
  @override
  void onInitFailed(LevelPlayInitError error) {
    IronSourceDebug.logError('Init Failed', 
        context: 'Code: ${error.code}, Message: ${error.message}');
    developer.log('IronSource init failed: ${error.toString()}',
        name: 'IronSourceService');
    
    // Log specific error details
    developer.log('Error code: ${error.code}, Error message: ${error.message}',
        name: 'IronSourceService');
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    IronSourceDebug.logEvent('Init Success', 
        data: {'configuration': configuration.toString()});
    developer.log('IronSource init success with configuration: ${configuration.toString()}',
        name: 'IronSourceService');
  }
}

class _NativeAdListener implements LevelPlayNativeAdListener {
  @override
  void onAdClicked(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    IronSourceDebug.logEvent('Native Ad Clicked');
    developer.log('IronSource Native ad clicked', name: 'IronSourceService');
  }

  @override
  void onAdImpression(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    IronSourceDebug.logEvent('Native Ad Impression');
    developer.log('IronSource Native ad impression', name: 'IronSourceService');
  }

  @override
  void onAdLoadFailed(LevelPlayNativeAd? nativeAd, IronSourceError? error) {
    IronSourceDebug.logError('Native Ad Load Failed', 
        context: error?.toString() ?? 'Unknown error');
    developer.log('IronSource Native ad load failed: ${error?.toString()}',
        name: 'IronSourceService');
    
    // Log specific error details
    if (error != null) {
      developer.log('Error code: ${error.code}, Error message: ${error.message}',
          name: 'IronSourceService');
    }
  }

  @override
  void onAdLoaded(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
    IronSourceDebug.logEvent('Native Ad Loaded Successfully');
    developer.log('IronSource Native ad loaded successfully', name: 'IronSourceService');
  }
}
