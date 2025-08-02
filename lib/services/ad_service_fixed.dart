import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/mediation_config.dart';
import 'consent_service.dart';
import 'ironsource_service.dart';

class AdService {
  // Proper Singleton Pattern
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  // Ad configuration
  static const int MAX_RETRY_ATTEMPTS = 2;
  static const Duration RETRY_DELAY = Duration(seconds: 3);
  static const Duration AD_CACHE_DURATION = Duration(minutes: 30);

  // Ad unit IDs
  final Map<String, Map<String, String>> _adUnitIds = {
    'android': {
      'banner': 'ca-app-pub-3537329799200606/2028008282',
      'rewarded': 'ca-app-pub-3537329799200606/7827129874',
      'native': 'ca-app-pub-3537329799200606/2260507229',
    },
    'ios': {
      'banner': 'ca-app-pub-3537329799200606/2028008282',
      'rewarded': 'ca-app-pub-3537329799200606/7827129874',
      'native': 'ca-app-pub-3537329799200606/2260507229',
    },
  };

  // Ad objects with proper null safety
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;

  // Multiple Native Ads Manager
  final Map<String, NativeAd> _nativeAds = {};
  final Map<String, bool> _nativeAdLoadedStates = {};

  // Ad states
  bool _isBannerAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isRewardedAdLoading = false;
  bool _isNativeAdLoaded = false;

  // Mediation states
  final bool _isMediationEnabled = MediationConfig.enabled;
  bool _isMediationInitialized = false;
  final Map<String, bool> _mediationNetworkStates = {};

  // IronSource service
  final IronSourceService _ironSourceService = IronSourceService.instance;

  // Timers for proper cleanup
  Timer? _bannerAdRefreshTimer;
  Timer? _nativeAdRefreshTimer;
  Timer? _loadingTimeoutTimer;

  // Ad tracking with proper error handling
  final Map<String, int> _adShowCounts = {};
  final Map<String, DateTime> _lastAdShowTimes = {};
  final Map<String, int> _adLoadAttempts = {};
  final Map<String, DateTime> _adCacheTimes = {};
  final Map<String, int> _adFailures = {};
  final Map<String, List<Duration>> _adLoadTimes = {};

  // Performance metrics
  int _totalAdShows = 0;
  int _successfulAdShows = 0;
  int _failedAdShows = 0;
  double _averageAdLoadTime = 0.0;

  // Getters
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isNativeAdLoaded => _isNativeAdLoaded;

  // Check if consent is given for showing ads
  bool _canShowAds() {
    try {
      final consentService = ConsentService();
      final canShow = !consentService.isConsentRequired || consentService.hasUserConsent;
      developer.log('Consent check: Required=${consentService.isConsentRequired}, Given=${consentService.hasUserConsent}, CanShow=$canShow', name: 'AdService');
      return canShow;
    } catch (e) {
      developer.log('Consent check failed: $e', name: 'AdService');
      return false;
    }
  }

  // Get ad unit ID with proper error handling
  String _getAdUnitId(String adType) {
    try {
      if (kIsWeb) {
        developer.log('Web platform detected, no ad unit ID available', name: 'AdService');
        return '';
      }

      final platform = Platform.isAndroid ? 'android' : 'ios';
      final adUnitId = _adUnitIds[platform]?[adType] ?? '';

      developer.log('Platform: $platform, Ad Type: $adType, Ad Unit ID: ${adUnitId.isNotEmpty ? "Set" : "Empty"}', name: 'AdService');
      return adUnitId;
    } catch (e) {
      developer.log('Error getting ad unit ID: $e', name: 'AdService');
      return '';
    }
  }

  // Load ad with proper retry mechanism and timeout
  Future<void> _loadAdWithRetry(
    String adType,
    Future<void> Function() loadFunction,
    Function(bool) onLoaded,
  ) async {
    if (kIsWeb) return;

    final startTime = DateTime.now();
    int attempts = 0;

    while (attempts < MAX_RETRY_ATTEMPTS) {
      try {
        // Add timeout for each attempt
        await loadFunction().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Ad load timeout', const Duration(seconds: 10));
          },
        );

        final loadTime = DateTime.now().difference(startTime);
        _updateAdMetrics(adType, true, loadTime);
        _adCacheTimes[adType] = DateTime.now();
        onLoaded(true);
        return;
      } catch (e) {
        attempts++;
        _adLoadAttempts[adType] = attempts;
        developer.log('Ad load attempt $attempts failed for $adType: $e', name: 'AdService');

        if (attempts < MAX_RETRY_ATTEMPTS) {
          await Future.delayed(RETRY_DELAY * attempts);
        }
      }
    }

    _updateAdMetrics(adType, false, null);
    onLoaded(false);
  }

  // Load banner ad with proper error handling
  Future<void> loadBannerAd() async {
    if (!_canShowAds()) return;
    if (_isBannerAdLoaded && _isCachedAdValid('banner')) return;

    await _loadAdWithRetry(
      'banner',
      () async {
        final adUnitId = _getAdUnitId('banner');
        if (adUnitId.isEmpty) throw Exception('Invalid banner ad unit ID');

        _bannerAd?.dispose();
        _bannerAd = BannerAd(
          adUnitId: adUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (_) {
              _isBannerAdLoaded = true;
              _startBannerAdAutoRefresh();
              developer.log('Banner ad loaded successfully', name: 'AdService');
            },
            onAdFailedToLoad: (ad, error) {
              _isBannerAdLoaded = false;
              ad.dispose();
              developer.log('Banner ad failed to load: $error', name: 'AdService');
              throw error;
            },
          ),
        );

        await _bannerAd?.load();
      },
      (success) {
        _isBannerAdLoaded = success;
      },
    );
  }

  // Load rewarded ad with proper timeout handling
  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;
    if (!_canShowAds()) {
      developer.log('Cannot show ads: Consent not given', name: 'AdService');
      return;
    }

    if (_isRewardedAdLoading) {
      developer.log('Rewarded ad already loading, skipping...', name: 'AdService');
      return;
    }

    _isRewardedAdLoading = true;

    // Add timeout for loading state
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (_isRewardedAdLoading) {
        developer.log('Rewarded ad loading timeout, resetting state', name: 'AdService');
        _isRewardedAdLoading = false;
      }
    });

    try {
      final adUnitId = _getAdUnitId('rewarded');
      if (adUnitId.isEmpty) {
        developer.log('Rewarded ad unit ID is empty', name: 'AdService');
        _isRewardedAdLoading = false;
        return;
      }

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            developer.log('Rewarded ad loaded successfully', name: 'AdService');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _isRewardedAdLoading = false;
            _adCacheTimes['rewarded'] = DateTime.now();
            _loadingTimeoutTimer?.cancel();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                developer.log('Rewarded ad dismissed', name: 'AdService');
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                developer.log('Rewarded ad failed to show: $error', name: 'AdService');
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdShowedFullScreenContent: (ad) {
                developer.log('Rewarded ad showed successfully', name: 'AdService');
              },
            );
          },
          onAdFailedToLoad: (error) {
            developer.log('Rewarded ad failed to load: $error', name: 'AdService');
            _isRewardedAdLoading = false;
            _loadingTimeoutTimer?.cancel();
          },
        ),
      );
    } catch (e) {
      developer.log('Rewarded ad load exception: $e', name: 'AdService');
      _isRewardedAdLoading = false;
      _loadingTimeoutTimer?.cancel();
    }
  }

  // Show rewarded ad with proper reward validation
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (kIsWeb) {
      developer.log('Web platform detected, simulating rewarded ad', name: 'AdService');
      await Future.delayed(const Duration(seconds: 2));
      onRewarded(5.0);
      return true;
    }

    if (!_canShowAds()) {
      developer.log('Cannot show rewarded ad: Consent not given', name: 'AdService');
      onAdDismissed();
      return false;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      developer.log('Rewarded ad not loaded, attempting to load...', name: 'AdService');
      await loadRewardedAd();
      if (!_isRewardedAdLoaded || _rewardedAd == null) {
        developer.log('Failed to load rewarded ad', name: 'AdService');
        onAdDismissed();
        return false;
      }
    }

    bool rewardGranted = false;
    bool adShown = false;

    try {
      developer.log('Showing rewarded ad...', name: 'AdService');

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          developer.log('User earned reward: ${reward.amount}', name: 'AdService');
          rewardGranted = true;
          onRewarded(reward.amount.toDouble());
        },
      );

      developer.log('Rewarded ad show completed successfully', name: 'AdService');
      return true;
    } catch (e) {
      developer.log('Rewarded ad show exception: $e', name: 'AdService');
      _isRewardedAdLoaded = false;
      _rewardedAd?.dispose();
      onAdDismissed();
      return false;
    }
  }

  // Initialize ads with proper error handling
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      final consentService = ConsentService();
      await consentService.initialize();

      await MobileAds.instance.initialize();
      await _loadMetrics();

      await _initializeMediation();
      await _ironSourceService.initialize();

      if (consentService.hasUserConsent) {
        loadBannerAd();
        loadRewardedAd();
        loadNativeAd();
      }

      developer.log('Ad service initialized successfully', name: 'AdService');
    } catch (e) {
      developer.log('Ad service initialization failed: $e', name: 'AdService');
    }
  }

  // Proper cleanup and disposal
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    
    _bannerAdRefreshTimer?.cancel();
    _nativeAdRefreshTimer?.cancel();
    _loadingTimeoutTimer?.cancel();

    _ironSourceService.dispose();

    _isBannerAdLoaded = false;
    _isRewardedAdLoaded = false;
    _isRewardedAdLoading = false;
    _isNativeAdLoaded = false;

    _saveMetrics();
    developer.log('Ad service disposed', name: 'AdService');
  }

  // Helper methods
  bool _isCachedAdValid(String adType) {
    final cacheTime = _adCacheTimes[adType];
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < AD_CACHE_DURATION;
  }

  void _startBannerAdAutoRefresh() {
    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _isBannerAdLoaded = false;
      _bannerAd?.dispose();
      _bannerAd = null;
      loadBannerAd();
    });
  }

  void _updateAdMetrics(String adType, bool success, Duration? loadTime) {
    _totalAdShows++;
    if (success) {
      _successfulAdShows++;
      _adShowCounts[adType] = (_adShowCounts[adType] ?? 0) + 1;
      _lastAdShowTimes[adType] = DateTime.now();
    } else {
      _failedAdShows++;
      _adFailures[adType] = (_adFailures[adType] ?? 0) + 1;
    }

    if (loadTime != null) {
      _adLoadTimes[adType] ??= [];
      _adLoadTimes[adType]!.add(loadTime);
      _averageAdLoadTime = _adLoadTimes[adType]!
              .fold(0.0, (sum, time) => sum + time.inMilliseconds) /
          _adLoadTimes[adType]!.length;
    }

    _saveMetrics();
  }

  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_ad_shows', _totalAdShows);
      await prefs.setInt('successful_ad_shows', _successfulAdShows);
      await prefs.setInt('failed_ad_shows', _failedAdShows);
      await prefs.setDouble('average_ad_load_time', _averageAdLoadTime);
    } catch (e) {
      developer.log('Error saving metrics: $e', name: 'AdService');
    }
  }

  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalAdShows = prefs.getInt('total_ad_shows') ?? 0;
      _successfulAdShows = prefs.getInt('successful_ad_shows') ?? 0;
      _failedAdShows = prefs.getInt('failed_ad_shows') ?? 0;
      _averageAdLoadTime = prefs.getDouble('average_ad_load_time') ?? 0.0;
    } catch (e) {
      developer.log('Error loading metrics: $e', name: 'AdService');
    }
  }

  Future<void> _initializeMediation() async {
    if (!_isMediationEnabled) return;

    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          testDeviceIds: MediationConfig.enableTestDevices ? MediationConfig.testDeviceIds : null,
        ),
      );

      _isMediationInitialized = true;
      developer.log('Mediation initialized successfully', name: 'AdService');
    } catch (e) {
      developer.log('Mediation initialization failed: $e', name: 'AdService');
    }
  }

  // Public getters for metrics
  Map<String, dynamic> get adMetrics => {
        'total_shows': _totalAdShows,
        'successful_shows': _successfulAdShows,
        'failed_shows': _failedAdShows,
        'success_rate': _totalAdShows > 0 ? (_successfulAdShows / _totalAdShows) * 100 : 0,
        'average_load_time': _averageAdLoadTime,
        'ad_failures': _adFailures,
      };
}