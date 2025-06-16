import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CustomAdService {
  static final CustomAdService _instance = CustomAdService._internal();
  factory CustomAdService() => _instance;
  CustomAdService._internal();

  final String _nativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110'; // Test ID

  // Ad objects
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;

  // Ad states
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isNativeAdLoaded = false;

  // Ad configuration
  final Map<String, dynamic> _adConfig = {
    'banner': {
      'size': AdSize.banner,
      'position': 'bottom',
    },
    'interstitial': {
      'frequency': 3,
    },
    'rewarded': {
      'reward': 0.00000001,
    },
    'native': {
      'height': 120.0,
    },
  };

  // Ad unit ID getters
  String _getBannerAdUnitId() {
    if (Platform.isAndroid) {
      return _adConfig['banner']?['position'] == 'bottom'
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    } else if (Platform.isIOS) {
      return _adConfig['banner']?['position'] == 'bottom'
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  String _getInterstitialAdUnitId() {
    if (Platform.isAndroid) {
      return _adConfig['interstitial']?['frequency'] == 3
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    } else if (Platform.isIOS) {
      return _adConfig['interstitial']?['frequency'] == 3
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  String _getRewardedAdUnitId() {
    if (Platform.isAndroid) {
      return _adConfig['rewarded']?['reward'] == 0.00000001
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    } else if (Platform.isIOS) {
      return _adConfig['rewarded']?['reward'] == 0.00000001
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  // Ad loading methods
  Future<void> loadBannerAd() async {
    if (kIsWeb) return;

    final String adUnitId = _getBannerAdUnitId();
    if (adUnitId.isEmpty) {
      debugPrint('Banner ad unit ID not found');
      return;
    }

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
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    );

    await _bannerAd?.load();
  }

  Future<void> loadInterstitialAd() async {
    if (kIsWeb) return;

    final String adUnitId = _getInterstitialAdUnitId();
    if (adUnitId.isEmpty) {
      debugPrint('Interstitial ad unit ID not found');
      return;
    }

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
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;

    final String adUnitId = _getRewardedAdUnitId();
    if (adUnitId.isEmpty) {
      debugPrint('Rewarded ad unit ID not found');
      return;
    }

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
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> loadNativeAd() async {
    if (_isNativeAdLoaded) return;

    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _isNativeAdLoaded = true;
          print('Native ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          _isNativeAdLoaded = false;
          ad.dispose();
          print('Native ad failed to load: $error');
        },
      ),
    );

    try {
      await _nativeAd!.load();
    } catch (e) {
      print('Error loading native ad: $e');
      _isNativeAdLoaded = false;
    }
  }

  // Ad showing methods
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

  Widget getNativeAd() {
    if (!_isNativeAdLoaded || _nativeAd == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'Loading Ad...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }

  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      return false;
    }

    bool adShown = false;
    await _interstitialAd!.show();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadInterstitialAd();
        adShown = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadInterstitialAd();
        debugPrint('Interstitial ad show error: $error');
      },
    );

    return adShown;
  }

  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      return false;
    }

    bool adShown = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        onAdDismissed();
        adShown = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        debugPrint('Rewarded ad show error: $error');
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        onRewarded(reward.amount.toDouble());
      },
    );

    return adShown;
  }

  Future<RewardedAd?> getRewardedAd() async {
    if (_rewardedAd != null) {
      return _rewardedAd;
    }

    if (!_isRewardedAdLoaded) {
      await loadRewardedAd();
    }

    return _rewardedAd;
  }

  // Getters
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isNativeAdLoaded => _isNativeAdLoaded;

  // Dispose method
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();

    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _nativeAd = null;

    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
    _isNativeAdLoaded = false;
  }
}
