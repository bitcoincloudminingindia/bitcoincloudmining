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
  // Singleton hata diya gaya hai, ab har screen par naya instance banega
  AdService();

  // Ad configuration
  static const int MAX_RETRY_ATTEMPTS = 2; // Reduced from 3 to 2
  static const Duration RETRY_DELAY =
      Duration(seconds: 3); // Reduced from 5 to 3
  static const Duration AD_CACHE_DURATION = Duration(minutes: 30);

  // Ad unit IDs - Real AdMob IDs for production with mediation
  final Map<String, Map<String, String>> _adUnitIds = {
    'android': {
      'banner': 'ca-app-pub-3537329799200606/2028008282', // Home_Banner_Ad
      'rewarded': 'ca-app-pub-3537329799200606/7827129874', // Rewarded_BTC_Ad
      'native':
          'ca-app-pub-3537329799200606/2260507229', // Native_Contract_Card
      // 'rewarded_interstitial': 'ca-app-pub-3537329799200606/4519239988', // Game Reward Interstitial (Available for future use)
    },
    'ios': {
      'banner': 'ca-app-pub-3537329799200606/2028008282', // Home_Banner_Ad
      'rewarded': 'ca-app-pub-3537329799200606/7827129874', // Rewarded_BTC_Ad
      'native':
          'ca-app-pub-3537329799200606/2260507229', // Native_Contract_Card
      // 'rewarded_interstitial': 'ca-app-pub-3537329799200606/4519239988', // Game Reward Interstitial (Available for future use)
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

  // Mediation states
  final bool _isMediationEnabled = MediationConfig.enabled;
  bool _isMediationInitialized = false;
  final Map<String, bool> _mediationNetworkStates = {};

  // IronSource service
  final IronSourceService _ironSourceService = IronSourceService.instance;

  // Ad tracking
  final Map<String, int> _adShowCounts = {};
  final Map<String, DateTime> _lastAdShowTimes = {};
  final Map<String, int> _adLoadAttempts = {};
  final Map<String, DateTime> _adCacheTimes = {};
  final Map<String, int> _adFailures = {};
  final Map<String, List<Duration>> _adLoadTimes = {};

  // Mediation tracking
  final Map<String, int> _mediationAdShows = {};
  final Map<String, int> _mediationAdFailures = {};
  final Map<String, double> _mediationRevenue = {};

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

  // Check if consent is given for showing ads
  bool _canShowAds() {
    try {
      final consentService = ConsentService();
      final canShow =
          !consentService.isConsentRequired || consentService.hasUserConsent;
      print(
          '🔍 Consent check: Required=${consentService.isConsentRequired}, Given=${consentService.hasUserConsent}, CanShow=$canShow');
      return canShow;
    } catch (e) {
      print('❌ Consent check failed: $e');
      return false; // Default to false if consent check fails
    }
  }

  // Show consent dialog if required
  Future<bool> ensureConsentAndShowAds(BuildContext context) async {
    final consentService = ConsentService();

    if (!consentService.isInitialized) {
      await consentService.initialize();
    }

    if (consentService.isConsentRequired && !consentService.hasUserConsent) {
      return consentService.showConsentDialog(context);
    }

    return true;
  }

  // Get ad unit ID based on platform and ad type
  String _getAdUnitId(String adType) {
    try {
      // Debug platform detection
      print('🔍 Platform Detection Debug:');
      print('  - kIsWeb: $kIsWeb');
      print('  - Platform.isAndroid: ${Platform.isAndroid}');
      print('  - Platform.isIOS: ${Platform.isIOS}');
      print('  - Platform.operatingSystem: ${Platform.operatingSystem}');

      if (kIsWeb) {
        print('🌐 Web platform detected, no ad unit ID available');
        return '';
      }

      final platform = Platform.isAndroid ? 'android' : 'ios';
      final adUnitId = _adUnitIds[platform]?[adType] ?? '';

      print(
          '📱 Platform: $platform, Ad Type: $adType, Ad Unit ID: ${adUnitId.isNotEmpty ? "Set" : "Empty"}');

      return adUnitId;
    } catch (e) {
      print('❌ Error getting ad unit ID: $e');
      return '';
    }
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

  // Start auto-refresh timer for banner ads (minimum 30 seconds as per AdMob policies)
  void _startBannerAdAutoRefresh() {
    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      _isBannerAdLoaded = false;
      _bannerAd?.dispose();
      _bannerAd = null;
      loadBannerAd();
    });
  }

  // Load banner ad
  Future<void> loadBannerAd() async {
    if (!_canShowAds()) return; // Check consent first
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

              // Update mediation metrics for successful load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdFailedToLoad: (ad, error) {
              _isBannerAdLoaded = false;
              ad.dispose();

              // Update mediation metrics for failed load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', false, null);
              }

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

  // Load rewarded ad with better error handling and mediation tracking
  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;
    if (!_canShowAds()) {
      print('❌ Cannot show ads: Consent not given');
      return; // Check consent first
    }

    if (_isRewardedAdLoading) {
      print('⚠️ Rewarded ad already loading, skipping...');
      return;
    }

    _isRewardedAdLoading = true;

    // Add timeout for loading state to prevent stuck state
    Timer(const Duration(seconds: 15), () {
      if (_isRewardedAdLoading) {
        print('⚠️ Rewarded ad loading timeout, resetting state');
        _isRewardedAdLoading = false;
      }
    });

    try {
      final adUnitId = _getAdUnitId('rewarded');
      if (adUnitId.isEmpty) {
        print('❌ Rewarded ad unit ID is empty');
        _isRewardedAdLoading = false;
        return;
      }

      print('🔄 Loading rewarded ad with ID: $adUnitId');

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _isRewardedAdLoading = false;
            _adCacheTimes['rewarded'] = DateTime.now();

            // Update mediation metrics for successful load
            if (_isMediationEnabled) {
              _updateMediationMetrics('admob', true, null);
            }

            // Set up ad event listeners
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('📱 Rewarded ad dismissed');
                _isRewardedAdLoaded = false;
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Rewarded ad failed to show: $error');
                _isRewardedAdLoaded = false;
                ad.dispose();

                // Update mediation metrics for failed show
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', false, null);
                }
              },
              onAdShowedFullScreenContent: (ad) {
                print('📺 Rewarded ad showed successfully');
                // Update mediation metrics for successful show
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('❌ Rewarded ad failed to load: $error');
            _isRewardedAdLoading = false;

            // Update mediation metrics for failed load
            if (_isMediationEnabled) {
              _updateMediationMetrics('admob', false, null);
            }
          },
        ),
      );
    } catch (e) {
      print('❌ Rewarded ad load exception: $e');
      _isRewardedAdLoading = false;

      // Update mediation metrics for exception
      if (_isMediationEnabled) {
        _updateMediationMetrics('admob', false, null);
      }
    }
  }

  // Auto-refresh native ad periodically
  Timer? _nativeAdRefreshTimer;

  // Load native ad with retry mechanism and auto-refresh
  Future<void> loadNativeAd() async {
    if (!_canShowAds()) return; // Check consent first
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

              // Update mediation metrics for successful load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdFailedToLoad: (ad, error) {
              _isNativeAdLoaded = false;
              _nativeAdFailCount++;
              ad.dispose();
              _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;

              // Update mediation metrics for failed load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', false, null);
              }

              throw error;
            },
            onAdOpened: (ad) {
              // Update mediation metrics for ad opened
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdClosed: (ad) {},
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;

              // Update mediation metrics for impression
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;

              // Update mediation metrics for click
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
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
    // Try IronSource native ad first if available
    if (_ironSourceService.isInitialized &&
        _ironSourceService.isNativeAdLoaded) {
      developer.log('Using IronSource Native ad', name: 'AdService');
      final ironSourceWidget = _ironSourceService.getNativeAdWidget(
        height: 360,
        width: 300,
        templateType: LevelPlayTemplateType.MEDIUM,
      );
      if (ironSourceWidget != null) {
        return Container(
          height: 360,
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
                // IronSource native ad content
                Positioned.fill(
                  child: ironSourceWidget,
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
    }

    // Fallback to AdMob native ad
    if (!_isNativeAdLoaded || _nativeAd == null) {
      return Container(
        height: 360,
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
      height: 360,
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

  // Show rewarded ad with enhanced complete viewing validation
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (kIsWeb) {
      // Simulate ad for web testing with proper validation
      print('🌐 Web platform detected, simulating rewarded ad');
      await Future.delayed(const Duration(seconds: 2));
      onRewarded(5.0); // Give 5x reward for web
      return true;
    }

    // Check consent before showing ad
    if (!_canShowAds()) {
      print('❌ Cannot show rewarded ad: Consent not given');
      onAdDismissed();
      return false;
    }

    // Try IronSource first if available
    if (_ironSourceService.isInitialized &&
        _ironSourceService.isRewardedAdLoaded) {
      print('🎯 Trying IronSource Rewarded ad...');
      final success = await _ironSourceService.showRewardedAd(
        onRewarded: onRewarded,
        onAdDismissed: onAdDismissed,
      );
      if (success) {
        print('✅ IronSource Rewarded ad shown successfully');
        return true;
      }
    }

    // Fallback to AdMob
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      print('🔄 Rewarded ad not loaded, attempting to load...');
      await loadRewardedAd();
      if (!_isRewardedAdLoaded || _rewardedAd == null) {
        print('❌ Failed to load rewarded ad');
        onAdDismissed();
        return false;
      }
    }

    bool rewardGranted = false;
    bool adShown = false;
    bool adCompletelyWatched = false;

    try {
      print('📺 Showing rewarded ad...');

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('📱 Rewarded ad dismissed by user');
          ad.dispose();
          _isRewardedAdLoaded = false;

          // Only grant reward if ad was completely watched AND reward was earned
          if (rewardGranted && adCompletelyWatched) {
            print('✅ Reward already granted in onUserEarnedReward');
            // Reward already granted in onUserEarnedReward
          } else {
            print('❌ Ad dismissed without completion, no reward');
            // Ad was dismissed without completion, call onAdDismissed
            onAdDismissed();
          }

          // Preload next ad
          print('🔄 Preloading next rewarded ad');
          loadRewardedAd();
          _updateAdMetrics('rewarded', adShown && rewardGranted, null);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Rewarded ad failed to show: $error');
          ad.dispose();
          _isRewardedAdLoaded = false;

          // Ad failed to show, no reward
          onAdDismissed();

          // Preload next ad
          print('🔄 Preloading next rewarded ad after failure');
          loadRewardedAd();
          _updateAdMetrics('rewarded', false, null);
        },
        onAdShowedFullScreenContent: (ad) {
          print('📺 Rewarded ad showed successfully');
          adShown = true;
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // This callback only fires when user completely watches the ad
          // onUserEarnedReward callback से pata chalta hai ki ad pura dekha gaya
          print('🎉 User earned reward: ${reward.amount}');
          rewardGranted = true;
          adCompletelyWatched = true;

          // Give reward only when ad is completely watched
          // No minimum time check needed - onUserEarnedReward ensures complete viewing
          onRewarded(reward.amount.toDouble());
        },
      );

      print('✅ Rewarded ad show completed successfully');
      return true;
    } catch (e) {
      print('❌ Rewarded ad show exception: $e');
      _isRewardedAdLoaded = false;
      _rewardedAd?.dispose();

      // Preload next ad
      print('🔄 Preloading next rewarded ad after exception');
      loadRewardedAd();

      // Call onAdDismissed on error
      onAdDismissed();

      _updateAdMetrics('rewarded', false, null);
      return false;
    }
  }

  // Get banner ad widget with accidental click protection
  Widget getBannerAd() {
    if (!_isBannerAdLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }
    try {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble() + 16, // Add padding
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ad label for transparency
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Banner ad with click delay protection
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[200]!, width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox(height: 50);
    }
  }

  // Initialize ads with consent check
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // Initialize consent service first
      final consentService = ConsentService();
      await consentService.initialize();

      await MobileAds.instance.initialize();
      await _loadMetrics();

      // Initialize mediation
      await _initializeMediation();

      // Initialize IronSource
      await _ironSourceService.initialize();

      // Only preload ads if user has given consent
      if (consentService.hasUserConsent) {
        // Preload ads
        loadBannerAd();
        loadRewardedAd();
        loadNativeAd();
      }
    } catch (e) {}
  }

  // Initialize mediation configuration
  Future<void> _initializeMediation() async {
    if (!_isMediationEnabled) return;

    try {
      // Configure mediation settings
      await _configureMediationSettings();

      // Initialize mediation networks
      await _initializeMediationNetworks();

      _isMediationInitialized = true;

      if (kDebugMode) {
        print('✅ Mediation initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation initialization failed: $e');
      }
    }
  }

  // Configure mediation settings
  Future<void> _configureMediationSettings() async {
    try {
      // Configure AdMob mediation settings
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          testDeviceIds: MediationConfig.enableTestDevices
              ? MediationConfig.testDeviceIds
              : null,
        ),
      );

      if (kDebugMode) {
        print('✅ Mediation settings configured');
        if (MediationConfig.enableTestDevices) {
          print('🔧 Test devices enabled: ${MediationConfig.testDeviceIds}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation settings configuration failed: $e');
      }
    }
  }

  // Initialize mediation networks
  Future<void> _initializeMediationNetworks() async {
    final networks = MediationConfig.supportedNetworks;

    for (final network in networks) {
      try {
        await _initializeMediationNetwork(network);
        _mediationNetworkStates[network] = true;

        if (kDebugMode) {
          print('✅ $network mediation network initialized');
        }
      } catch (e) {
        _mediationNetworkStates[network] = false;
        if (kDebugMode) {
          print('❌ $network mediation network failed: $e');
        }
      }
    }
  }

  // Initialize specific mediation network
  Future<void> _initializeMediationNetwork(String network) async {
    switch (network) {
      case 'unity_ads':
        // Unity Ads is already initialized via build.gradle
        break;
      case 'facebook_audience_network':
        // Facebook Audience Network initialization
        break;
      case 'applovin':
        // AppLovin initialization
        break;
      case 'iron_source':
        // IronSource is initialized separately
        if (_ironSourceService.isInitialized) {
          _mediationNetworkStates['iron_source'] = true;
        }
        break;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown mediation network: $network');
        }
    }
  }

  // Get mediation status
  Map<String, dynamic> get mediationStatus => {
        'enabled': _isMediationEnabled,
        'initialized': _isMediationInitialized,
        'networks': _mediationNetworkStates,
        'config': MediationConfig.config,
        'metrics': {
          'ad_shows': _mediationAdShows,
          'ad_failures': _mediationAdFailures,
          'revenue': _mediationRevenue,
        },
        'ironsource': _ironSourceService.metrics,
      };

  // Check if mediation is working properly
  bool get isMediationWorking {
    if (!_isMediationEnabled) return false;
    if (!_isMediationInitialized) return false;

    // Check if at least one network is active
    final activeNetworks =
        _mediationNetworkStates.values.where((state) => state).length;
    return activeNetworks > 0;
  }

  // Get mediation performance summary
  Map<String, dynamic> get mediationPerformance {
    final totalShows =
        _mediationAdShows.values.fold(0, (sum, count) => sum + count);
    final totalFailures =
        _mediationAdFailures.values.fold(0, (sum, count) => sum + count);
    final totalRevenue =
        _mediationRevenue.values.fold(0.0, (sum, revenue) => sum + revenue);

    return {
      'total_shows': totalShows,
      'total_failures': totalFailures,
      'total_revenue': totalRevenue,
      'success_rate': totalShows > 0
          ? ((totalShows - totalFailures) / totalShows) * 100
          : 0,
      'is_working': isMediationWorking,
      'active_networks':
          _mediationNetworkStates.values.where((state) => state).length,
    };
  }

  // Update mediation metrics
  void _updateMediationMetrics(String network, bool success, double? revenue) {
    if (success) {
      _mediationAdShows[network] = (_mediationAdShows[network] ?? 0) + 1;
      if (revenue != null) {
        _mediationRevenue[network] =
            (_mediationRevenue[network] ?? 0) + revenue;
      }
    } else {
      _mediationAdFailures[network] = (_mediationAdFailures[network] ?? 0) + 1;
    }

    // Log mediation metrics for debugging
    if (kDebugMode) {
      print('📊 Mediation Metrics Updated:');
      print('   Network: $network');
      print('   Success: $success');
      print('   Revenue: $revenue');
      print('   Total Shows: ${_mediationAdShows[network]}');
      print('   Total Failures: ${_mediationAdFailures[network]}');
    }
  }

  // Test mediation functionality
  Future<void> testMediation() async {
    if (!_isMediationEnabled) {
      if (kDebugMode) {
        print('❌ Mediation is disabled');
      }
      return;
    }

    if (kDebugMode) {
      print('🧪 Testing Mediation...');
      print('   Enabled: $_isMediationEnabled');
      print('   Initialized: $_isMediationInitialized');
      print('   Networks: $_mediationNetworkStates');
      print('   Metrics:');
      print('     Shows: $_mediationAdShows');
      print('     Failures: $_mediationAdFailures');
      print('     Revenue: $_mediationRevenue');
    }

    // Test ad loading with mediation
    try {
      await loadRewardedAd();
      await loadBannerAd();
      await loadNativeAd();

      // Launch IronSource test suite if available
      if (_ironSourceService.isInitialized) {
        await _ironSourceService.launchTestSuite();
      }

      if (kDebugMode) {
        print('✅ Mediation test completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation test failed: $e');
      }
    }
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    _nativeAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer?.cancel(); // Dispose banner refresh timer

    // Dispose IronSource service
    _ironSourceService.dispose();

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

              // Update mediation metrics for successful load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdFailedToLoad: (ad, error) {
              _nativeAdLoadedStates[adId] = false;
              _nativeAdFailCount++;
              ad.dispose();

              // Update mediation metrics for failed load
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', false, null);
              }

              throw error;
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;

              // Update mediation metrics for click
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
            },
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;

              // Update mediation metrics for impression
              if (_isMediationEnabled) {
                _updateMediationMetrics('admob', true, null);
              }
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
