import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad configuration
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 5);
  static const Duration AD_CACHE_DURATION = Duration(minutes: 30);
  static const int MAX_OTHER_ADS_PER_HOUR = 20;
  static const Duration FREQUENCY_CAP_DURATION = Duration(hours: 1);
  static const Duration INTERSTITIAL_AD_INTERVAL = Duration(minutes: 5);

  // Ad unit IDs - Replace with real IDs in production
  final Map<String, Map<String, String>> _adUnitIds = {
    'android': {
      'banner': 'ca-app-pub-3940256099942544/6300978111',
      'interstitial': 'ca-app-pub-3940256099942544/1033173712',
      'rewarded': 'ca-app-pub-3940256099942544/5224354917',
      'native': 'ca-app-pub-3940256099942544/2247696110',
    },
    'ios': {
      'banner': 'ca-app-pub-3940256099942544/2934735716',
      'interstitial': 'ca-app-pub-3940256099942544/4411468910',
      'rewarded': 'ca-app-pub-3940256099942544/1712485313',
      'native': 'ca-app-pub-3940256099942544/2247696110',
    },
  };

  // Ad objects
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;

  // Ad states
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isRewardedAdLoading = false;

  // Ad tracking
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

  // Getters for metrics
  Map<String, dynamic> get adMetrics => {
        'total_shows': _totalAdShows,
        'successful_shows': _successfulAdShows,
        'failed_shows': _failedAdShows,
        'success_rate':
            _totalAdShows > 0 ? (_successfulAdShows / _totalAdShows) * 100 : 0,
        'average_load_time': _averageAdLoadTime,
        'ad_failures': _adFailures,
      };

  // Get ad unit ID based on platform and ad type
  String _getAdUnitId(String adType) {
    if (kIsWeb) return '';

    final platform = Platform.isAndroid ? 'android' : 'ios';
    return _adUnitIds[platform]?[adType] ?? '';
  }

  // Check if ad can be shown based on frequency cap
  bool _canShowAd(String adType) {
    // No limit for rewarded and banner ads
    if (adType == 'rewarded' || adType == 'banner') {
      return true;
    }

    // Special handling for interstitial ads - show every 5 minutes
    if (adType == 'interstitial') {
      final lastShowTime = _lastAdShowTimes[adType];
      if (lastShowTime != null) {
        final timeSinceLastShow = DateTime.now().difference(lastShowTime);
        if (timeSinceLastShow < INTERSTITIAL_AD_INTERVAL) {
          debugPrint(
              'Interstitial ad interval not reached. Next ad in ${(INTERSTITIAL_AD_INTERVAL - timeSinceLastShow).inMinutes} minutes');
          return false;
        }
      }
      return true;
    }

    // For other ads (native), apply frequency cap
    final now = DateTime.now();
    final lastShowTime = _lastAdShowTimes[adType];
    final showCount = _adShowCounts[adType] ?? 0;

    if (lastShowTime != null) {
      final timeSinceLastShow = now.difference(lastShowTime);
      if (timeSinceLastShow < FREQUENCY_CAP_DURATION &&
          showCount >= MAX_OTHER_ADS_PER_HOUR) {
        debugPrint('Ad frequency cap reached for $adType');
        return false;
      }
    }

    return true;
  }

  // Update ad metrics
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

  // Save metrics to SharedPreferences
  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_ad_shows', _totalAdShows);
      await prefs.setInt('successful_ad_shows', _successfulAdShows);
      await prefs.setInt('failed_ad_shows', _failedAdShows);
      await prefs.setDouble('average_ad_load_time', _averageAdLoadTime);
      // Convert ad failures map to JSON string
      final failuresJson =
          _adFailures.entries.map((e) => '${e.key}:${e.value}').join(',');
      await prefs.setString('ad_failures', failuresJson);
    } catch (e) {
      debugPrint('Error saving ad metrics: $e');
    }
  }

  // Load metrics from SharedPreferences
  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalAdShows = prefs.getInt('total_ad_shows') ?? 0;
      _successfulAdShows = prefs.getInt('successful_ad_shows') ?? 0;
      _failedAdShows = prefs.getInt('failed_ad_shows') ?? 0;
      _averageAdLoadTime = prefs.getDouble('average_ad_load_time') ?? 0.0;

      // Load ad failures from JSON string
      final failuresJson = prefs.getString('ad_failures') ?? '';
      if (failuresJson.isNotEmpty) {
        _adFailures.clear();
        for (final entry in failuresJson.split(',')) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            _adFailures[parts[0]] = int.parse(parts[1]);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading ad metrics: $e');
    }
  }

  // Load ad with retry mechanism
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
        await loadFunction();
        final loadTime = DateTime.now().difference(startTime);
        _updateAdMetrics(adType, true, loadTime);
        _adCacheTimes[adType] = DateTime.now();
        onLoaded(true);
        return;
      } catch (e) {
        attempts++;
        _adLoadAttempts[adType] = attempts;
        debugPrint('Failed to load $adType ad (attempt $attempts): $e');

        if (attempts < MAX_RETRY_ATTEMPTS) {
          await Future.delayed(RETRY_DELAY * attempts);
        }
      }
    }

    _updateAdMetrics(adType, false, null);
    onLoaded(false);
  }

  // Check if cached ad is still valid
  bool _isCachedAdValid(String adType) {
    final cacheTime = _adCacheTimes[adType];
    if (cacheTime == null) return false;

    return DateTime.now().difference(cacheTime) < AD_CACHE_DURATION;
  }

  // Load banner ad
  Future<void> loadBannerAd() async {
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
              debugPrint('Banner ad loaded');
            },
            onAdFailedToLoad: (ad, error) {
              _isBannerAdLoaded = false;
              ad.dispose();
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

  // Load interstitial ad
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdLoaded && _isCachedAdValid('interstitial')) return;

    await _loadAdWithRetry(
      'interstitial',
      () async {
        final adUnitId = _getAdUnitId('interstitial');
        if (adUnitId.isEmpty)
          throw Exception('Invalid interstitial ad unit ID');

        await InterstitialAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              _interstitialAd = ad;
              _isInterstitialAdLoaded = true;
              debugPrint('Interstitial ad loaded');
            },
            onAdFailedToLoad: (error) {
              _isInterstitialAdLoaded = false;
              throw error;
            },
          ),
        );
      },
      (success) {
        _isInterstitialAdLoaded = success;
      },
    );
  }

  // Load rewarded ad
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdLoaded && _isCachedAdValid('rewarded')) return;

    await _loadAdWithRetry(
      'rewarded',
      () async {
        final adUnitId = _getAdUnitId('rewarded');
        if (adUnitId.isEmpty) throw Exception('Invalid rewarded ad unit ID');

        await RewardedAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _rewardedAd = ad;
              _isRewardedAdLoaded = true;
              debugPrint('Rewarded ad loaded');
            },
            onAdFailedToLoad: (error) {
              _isRewardedAdLoaded = false;
              throw error;
            },
          ),
        );
      },
      (success) {
        _isRewardedAdLoaded = success;
      },
    );
  }

  // Show rewarded ad with frequency capping
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (!_canShowAd('rewarded')) {
      debugPrint('Rewarded ad frequency cap reached');
      return false;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('Rewarded ad not loaded');
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd(); // Preload next ad
        onAdDismissed();
        _updateAdMetrics('rewarded', true, null);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        debugPrint('Rewarded ad show error: $error');
        _updateAdMetrics('rewarded', false, null);
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          onRewarded(reward.amount.toDouble());
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      _updateAdMetrics('rewarded', false, null);
      return false;
    }
  }

  // Show interstitial ad with frequency capping
  Future<bool> showInterstitialAd() async {
    if (!_canShowAd('interstitial')) {
      debugPrint('Interstitial ad frequency cap reached');
      return false;
    }

    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('Interstitial ad not loaded');
      return false;
    }

    try {
      await _interstitialAd!.show();
      _updateAdMetrics('interstitial', true, null);
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _updateAdMetrics('interstitial', false, null);
      return false;
    }
  }

  // Get banner ad widget
  Widget getBannerAd() {
    if (!_isBannerAdLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  // Initialize ads
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await MobileAds.instance.initialize();
      await _loadMetrics();

      // Preload ads
      loadBannerAd();
      loadInterstitialAd();
      loadRewardedAd();

      debugPrint('Ad service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ad service: $e');
    }
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();

    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
    _isRewardedAdLoading = false;

    _saveMetrics();
  }

  // Reset ad metrics
  Future<void> resetMetrics() async {
    _totalAdShows = 0;
    _successfulAdShows = 0;
    _failedAdShows = 0;
    _averageAdLoadTime = 0.0;
    _adShowCounts.clear();
    _lastAdShowTimes.clear();
    _adLoadAttempts.clear();
    _adCacheTimes.clear();
    _adFailures.clear();
    _adLoadTimes.clear();

    await _saveMetrics();
  }

  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Test ID
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Test ID

  Future<RewardedAd?> getRewardedAd() async {
    if (_rewardedAd != null) {
      return _rewardedAd;
    }

    if (_isRewardedAdLoading) {
      return null;
    }

    _isRewardedAdLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: kDebugMode
            ? rewardedAdUnitId // Test ad unit ID
            : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY', // Your production ad unit ID
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoading = false;
          },
          onAdFailedToLoad: (error) {
            print('Rewarded ad failed to load: $error');
            _isRewardedAdLoading = false;
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isRewardedAdLoading = false;
    }

    return _rewardedAd;
  }
}
