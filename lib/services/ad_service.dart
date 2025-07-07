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
  static const int MAX_RETRY_ATTEMPTS = 2; // Reduced from 3 to 2
  static const Duration RETRY_DELAY =
      Duration(seconds: 3); // Reduced from 5 to 3
  static const Duration AD_CACHE_DURATION = Duration(minutes: 30);
  static const int MAX_OTHER_ADS_PER_HOUR = 20;
  static const Duration FREQUENCY_CAP_DURATION = Duration(hours: 1);

  // Ad unit IDs - Real AdMob IDs for production
  final Map<String, Map<String, String>> _adUnitIds = {
    'android': {
      'banner': 'ca-app-pub-3537329799200606/2028008282', // Home_Banner_Ad
      'rewarded': 'ca-app-pub-3537329799200606/7827129874', // Rewarded_BTC_Ad
      'native':
          'ca-app-pub-3537329799200606/2260507229', // Native_Contract_Card
    },
    'ios': {
      'banner': 'ca-app-pub-3537329799200606/2028008282', // Home_Banner_Ad
      'rewarded': 'ca-app-pub-3537329799200606/7827129874', // Rewarded_BTC_Ad
      'native':
          'ca-app-pub-3537329799200606/2260507229', // Native_Contract_Card
    },
  };

  // Ad objects
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

    // For other ads (native), apply frequency cap
    final now = DateTime.now();
    final lastShowTime = _lastAdShowTimes[adType];
    final showCount = _adShowCounts[adType] ?? 0;

    if (lastShowTime != null) {
      final timeSinceLastShow = now.difference(lastShowTime);
      if (timeSinceLastShow < FREQUENCY_CAP_DURATION &&
          showCount >= MAX_OTHER_ADS_PER_HOUR) {
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
    } catch (e) {}
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
    } catch (e) {}
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
    const int maxAttempts = 2; // Reduced from 3 to 2 attempts
    const Duration retryDelay =
        Duration(seconds: 3); // Reduced from 5 to 3 seconds

    while (attempts < maxAttempts) {
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

        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay * attempts);
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

  Timer? _bannerAdRefreshTimer;

  // Start auto-refresh timer for banner ads
  void _startBannerAdAutoRefresh() {
    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer =
        Timer.periodic(const Duration(seconds: 60), (timer) {
      _isBannerAdLoaded = false;
      _bannerAd?.dispose();
      _bannerAd = null;
      loadBannerAd();
    });
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
              _startBannerAdAutoRefresh(); // Start auto-refresh timer
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

    // Wait for the ad to be loaded, polling every 50ms, up to 1.5 seconds (faster)
    const int maxTries = 30; // 30 * 50ms = 1.5 seconds
    int tries = 0;
    while ((!_isBannerAdLoaded || _bannerAd == null) && tries < maxTries) {
      await Future.delayed(
          const Duration(milliseconds: 50)); // Reduced from 100ms to 50ms
      tries++;
    }

    if (_isBannerAdLoaded && _bannerAd != null) {
      return getBannerAd();
    } else {
      // Return a placeholder instead of empty widget for better UX
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Ad',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  // Load rewarded ad with better error handling
  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;

    if (_isRewardedAdLoading) {
      return;
    }

    _isRewardedAdLoading = true;

    try {
      final adUnitId = _getAdUnitId('rewarded');
      if (adUnitId.isEmpty) {
        _isRewardedAdLoading = false;
        return;
      }

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _isRewardedAdLoading = false;
            _adCacheTimes['rewarded'] = DateTime.now();

            // Set up ad event listeners
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdShowedFullScreenContent: (ad) {},
            );
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoading = false;
          },
        ),
      );
    } catch (e) {
      _isRewardedAdLoading = false;
    }
  }

  // Auto-refresh native ad periodically
  Timer? _nativeAdRefreshTimer;

  // Load native ad with retry mechanism and auto-refresh
  Future<void> loadNativeAd() async {
    if (_isNativeAdLoaded) {
      return;
    }

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) {
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
            },
            onAdFailedToLoad: (ad, error) {
              _isNativeAdLoaded = false;
              _nativeAdFailCount++;
              ad.dispose();
              _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;
              throw error;
            },
            onAdOpened: (ad) {},
            onAdClosed: (ad) {},
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;
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
    _startNativeAdAutoRefresh();
  }

  // Start auto-refresh timer for native ads
  void _startNativeAdAutoRefresh() {
    _nativeAdRefreshTimer?.cancel();
    // Refresh native ad every 5 minutes
    _nativeAdRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _isNativeAdLoaded = false;
      _nativeAd?.dispose();
      _nativeAd = null;
      loadNativeAd();
    });
  }

  // Force refresh native ad
  Future<void> refreshNativeAd() async {
    _isNativeAdLoaded = false;
    _nativeAd?.dispose();
    _nativeAd = null;
    await loadNativeAd();
  }

  // Get native ad widget with improved error handling and refresh capability
  Widget getNativeAd() {
    if (!_isNativeAdLoaded || _nativeAd == null) {
      return Container(
        height: 350,
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
      height: 350,
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
            // Close button for better UX
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
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
      return false;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      await loadRewardedAd();
      if (!_isRewardedAdLoaded || _rewardedAd == null) {
        return false;
      }
    }

    bool rewardGranted = false;
    bool adShown = false;

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
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
          ad.dispose();
          _isRewardedAdLoaded = false;

          // Preload next ad
          loadRewardedAd();

          // Call onAdDismissed if ad failed to show
          onAdDismissed();

          _updateAdMetrics('rewarded', false, null);
        },
        onAdShowedFullScreenContent: (ad) {
          adShown = true;
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardGranted = true;
          onRewarded(reward.amount.toDouble());
        },
      );

      return true;
    } catch (e) {
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

  // Get banner ad widget
  Widget getBannerAd() {
    if (!_isBannerAdLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }
    try {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } catch (e) {
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
      loadRewardedAd();
      loadNativeAd();
    } catch (e) {}
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    _nativeAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer?.cancel(); // Dispose banner refresh timer

    _isBannerAdLoaded = false;
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
      'ca-app-pub-3537329799200606/2028008282'; // Home_Banner_Ad
  static const String rewardedAdUnitId =
      'ca-app-pub-3537329799200606/7827129874'; // Rewarded_BTC_Ad
  static const String nativeAdUnitId =
      'ca-app-pub-3537329799200606/2260507229'; // Native_Contract_Card

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
        adUnitId: rewardedAdUnitId, // Real ad unit ID for production
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoading = false;
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoading = false;
          },
        ),
      );
    } catch (e) {
      _isRewardedAdLoading = false;
    }

    return _rewardedAd;
  }

  // Validate native ad size and layout
  Map<String, dynamic> validateNativeAdSize() {
    final result = {
      'container_height': 250,
      'media_height': 150,
      'button_height': 64,
      'total_estimated_height': 250,
      'recommendations': <String>[],
    };

    // Check if container height is sufficient
    if ((result['container_height'] as int) < 200) {
      (result['recommendations'] as List<String>)
          .add('Container height should be at least 200px');
    }

    // Check if media height is appropriate
    if ((result['media_height'] as int) < 120) {
      (result['recommendations'] as List<String>)
          .add('Media height should be at least 120dp');
    }

    // Check if button height is touch-friendly
    if ((result['button_height'] as int) < 48) {
      (result['recommendations'] as List<String>)
          .add('Button height should be at least 48dp for touch targets');
    }

    return result;
  }

  // Multiple Native Ads Methods
  Future<void> loadNativeAdWithId(String adId) async {
    if (kIsWeb) return;

    // Dispose existing ad if any
    _nativeAds[adId]?.dispose();
    _nativeAds.remove(adId);
    _nativeAdLoadedStates[adId] = false;

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) return;

    final startTime = DateTime.now();

    await _loadAdWithRetry(
      'native',
      () async {
        final nativeAd = NativeAd(
          adUnitId: adUnitId,
          factoryId: 'listTile',
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              _nativeAdLoadedStates[adId] = true;
              _nativeAdLoadCount++;
              _nativeAdFirstLoadTime ??= DateTime.now();

              final loadTime = DateTime.now().difference(startTime);
              _nativeAdAverageLoadTime =
                  (_nativeAdAverageLoadTime * (_nativeAdLoadCount - 1) +
                          loadTime.inMilliseconds) /
                      _nativeAdLoadCount;
            },
            onAdFailedToLoad: (ad, error) {
              _nativeAdLoadedStates[adId] = false;
              _nativeAdFailCount++;
              ad.dispose();
              throw error;
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;
            },
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;
            },
          ),
        );

        await nativeAd.load();
        _nativeAds[adId] = nativeAd;
      },
      (success) {
        _nativeAdLoadedStates[adId] = success;
      },
    );
  }

  bool isNativeAdLoadedWithId(String adId) {
    return _nativeAdLoadedStates[adId] ?? false;
  }

  Widget getNativeAdWithId(String adId) {
    final nativeAd = _nativeAds[adId];
    final isLoaded = _nativeAdLoadedStates[adId] ?? false;

    if (!isLoaded || nativeAd == null) {
      return Container(
        height: 250,
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
                loadNativeAdWithId(adId);
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
      height: 250,
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
                    return AdWidget(ad: nativeAd);
                  } catch (e) {
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
            // Close button for better UX
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
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

  void disposeNativeAdWithId(String adId) {
    _nativeAds[adId]?.dispose();
    _nativeAds.remove(adId);
    _nativeAdLoadedStates.remove(adId);
  }

  void disposeAllNativeAds() {
    for (final ad in _nativeAds.values) {
      ad.dispose();
    }
    _nativeAds.clear();
    _nativeAdLoadedStates.clear();
  }
}
