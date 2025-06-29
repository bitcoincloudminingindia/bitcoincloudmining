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

  // Ad unit IDs - Use Google test IDs for all ad types
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
      'native': 'ca-app-pub-3940256099942544/3986624511',
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
  bool _isNativeAdLoaded = false;

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

  // Native ad performance metrics
  int _nativeAdLoadCount = 0;
  int _nativeAdFailCount = 0;
  int _nativeAdClickCount = 0;
  int _nativeAdImpressionCount = 0;
  DateTime? _nativeAdFirstLoadTime;
  double _nativeAdAverageLoadTime = 0.0;

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

  // Get native ad performance metrics
  Map<String, dynamic> get nativeAdMetrics => {
        'load_count': _nativeAdLoadCount,
        'fail_count': _nativeAdFailCount,
        'click_count': _nativeAdClickCount,
        'impression_count': _nativeAdImpressionCount,
        'success_rate': _nativeAdLoadCount > 0
            ? ((_nativeAdLoadCount - _nativeAdFailCount) / _nativeAdLoadCount) *
                100
            : 0,
        'average_load_time': _nativeAdAverageLoadTime,
        'first_load_time': _nativeAdFirstLoadTime?.toIso8601String(),
        'is_loaded': _isNativeAdLoaded,
      };

  // Public getters for ad loaded states
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isNativeAdLoaded => _isNativeAdLoaded;

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

  /// Returns a Future that completes with the banner ad widget when loaded, or a placeholder if not available.
  Future<Widget?> getBannerAdWidget() async {
    // If already loaded, return immediately
    if (_isBannerAdLoaded && _bannerAd != null) {
      return getBannerAd();
    }
    // Try to load the banner ad
    await loadBannerAd();
    // Wait for the ad to be loaded, polling every 100ms, up to 3 seconds
    const int maxTries = 30;
    int tries = 0;
    while ((!_isBannerAdLoaded || _bannerAd == null) && tries < maxTries) {
      await Future.delayed(const Duration(milliseconds: 100));
      tries++;
    }
    if (_isBannerAdLoaded && _bannerAd != null) {
      return getBannerAd();
    } else {
      return const SizedBox(height: 0);
    }
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

  // Load rewarded ad with better error handling
  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;

    if (_isRewardedAdLoading) {
      debugPrint('Rewarded ad already loading');
      return;
    }

    _isRewardedAdLoading = true;
    debugPrint('🔄 Loading rewarded ad...');

    try {
      final adUnitId = _getAdUnitId('rewarded');
      if (adUnitId.isEmpty) {
        debugPrint('❌ No rewarded ad unit ID available');
        _isRewardedAdLoading = false;
        return;
      }

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _isRewardedAdLoading = false;
            _adCacheTimes['rewarded'] = DateTime.now();

            // Set up ad event listeners
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Rewarded ad dismissed');
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Rewarded ad failed to show: $error');
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Rewarded ad showed full screen');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _isRewardedAdLoading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _isRewardedAdLoading = false;
    }
  }

  // Auto-refresh native ad periodically
  Timer? _nativeAdRefreshTimer;

  // Load native ad with retry mechanism and auto-refresh
  Future<void> loadNativeAd() async {
    if (_isNativeAdLoaded) return;

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) {
      debugPrint('Invalid native ad unit ID');
      return;
    }

    final startTime = DateTime.now();

    await _loadAdWithRetry(
      'native',
      () async {
        // Dispose existing ad if any
        _nativeAd?.dispose();
        _nativeAd = null;
        _isNativeAdLoaded = false;

        _nativeAd = NativeAd(
          adUnitId: adUnitId,
          factoryId: 'listTile',
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              _isNativeAdLoaded = true;
              _nativeAdLoadCount++;
              _nativeAdFirstLoadTime ??= DateTime.now();

              final loadTime = DateTime.now().difference(startTime);
              _nativeAdAverageLoadTime =
                  (_nativeAdAverageLoadTime * (_nativeAdLoadCount - 1) +
                          loadTime.inMilliseconds) /
                      _nativeAdLoadCount;

              debugPrint(
                  '✅ Native ad loaded successfully in ${loadTime.inMilliseconds}ms');
              // Start auto-refresh timer
              _startNativeAdAutoRefresh();
            },
            onAdFailedToLoad: (ad, error) {
              _isNativeAdLoaded = false;
              _nativeAdFailCount++;
              ad.dispose();
              debugPrint('❌ Native ad failed to load: $error');
              _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;
              throw error;
            },
            onAdOpened: (ad) {
              debugPrint('Native ad opened');
            },
            onAdClosed: (ad) {
              debugPrint('Native ad closed');
            },
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;
              debugPrint(
                  'Native ad impression (total: $_nativeAdImpressionCount)');
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;
              debugPrint('Native ad clicked (total: $_nativeAdClickCount)');
            },
          ),
        );

        await _nativeAd!.load();
        _adCacheTimes['native'] = DateTime.now();
      },
      (success) {
        _isNativeAdLoaded = success;
      },
    );
  }

  // Start auto-refresh timer for native ads
  void _startNativeAdAutoRefresh() {
    _nativeAdRefreshTimer?.cancel();
    // Refresh native ad every 5 minutes
    _nativeAdRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      debugPrint('🔄 Auto-refreshing native ad...');
      _isNativeAdLoaded = false;
      _nativeAd?.dispose();
      _nativeAd = null;
      loadNativeAd();
    });
  }

  // Force refresh native ad
  Future<void> refreshNativeAd() async {
    debugPrint('🔄 Force refreshing native ad...');
    _isNativeAdLoaded = false;
    _nativeAd?.dispose();
    _nativeAd = null;
    await loadNativeAd();
  }

  // Get native ad widget with improved error handling and refresh capability
  Widget getNativeAd() {
    if (!_isNativeAdLoaded || _nativeAd == null) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ads_click, color: Colors.grey, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Ad Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Add refresh button for failed ads
            GestureDetector(
              onTap: () {
                debugPrint('🔄 Manually refreshing native ad...');
                _isNativeAdLoaded = false;
                _nativeAd?.dispose();
                _nativeAd = null;
                loadNativeAd();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Native ad content with error boundary
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  try {
                    return AdWidget(ad: _nativeAd!);
                  } catch (e) {
                    debugPrint('❌ Error rendering native ad: $e');
                    // Return fallback UI if ad rendering fails
                    return Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.grey, size: 20),
                            SizedBox(height: 4),
                            Text(
                              'Ad Unavailable',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            // Ad label overlay with better positioning
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Close button for better UX
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  debugPrint('User dismissed native ad');
                  // Optionally track ad dismissal
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show rewarded ad with better error handling
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (kIsWeb) {
      // Simulate ad for web testing
      await Future.delayed(const Duration(seconds: 2));
      onRewarded(5.0); // Give 5x reward for web
      return true;
    }

    if (!_canShowAd('rewarded')) {
      debugPrint('Rewarded ad frequency cap reached');
      return false;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('Rewarded ad not loaded, attempting to load...');
      await loadRewardedAd();
      if (!_isRewardedAdLoaded || _rewardedAd == null) {
        debugPrint('Failed to load rewarded ad');
        return false;
      }
    }

    bool rewardGranted = false;
    bool adShown = false;

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Rewarded ad dismissed');
          ad.dispose();
          _isRewardedAdLoaded = false;

          // Preload next ad
          loadRewardedAd();

          // Call onAdDismissed if no reward was granted
          if (!rewardGranted) {
            onAdDismissed();
          }

          _updateAdMetrics('rewarded', adShown, null);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Rewarded ad failed to show: $error');
          ad.dispose();
          _isRewardedAdLoaded = false;

          // Preload next ad
          loadRewardedAd();

          // Call onAdDismissed if ad failed to show
          onAdDismissed();

          _updateAdMetrics('rewarded', false, null);
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded ad showed full screen');
          adShown = true;
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('✅ User earned reward: ${reward.amount}');
          rewardGranted = true;
          onRewarded(reward.amount.toDouble());
        },
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error showing rewarded ad: $e');
      _isRewardedAdLoaded = false;
      _rewardedAd?.dispose();

      // Preload next ad
      loadRewardedAd();

      // Call onAdDismissed on error
      onAdDismissed();

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
      debugPrint('[AdService] getBannerAd: Banner ad not loaded or null');
      return const SizedBox(height: 50);
    }
    try {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } catch (e) {
      debugPrint('[AdService] getBannerAd: Exception building AdWidget: '
          '[31m$e[0m');
      return const SizedBox(height: 50);
    }
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
      loadNativeAd();

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
    _nativeAdRefreshTimer?.cancel();

    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
    _isRewardedAdLoading = false;
    _isNativeAdLoaded = false;

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
  static const String nativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110'; // Test ID (Android)

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
        adUnitId:
            rewardedAdUnitId, // Always use test ad unit ID for development
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
