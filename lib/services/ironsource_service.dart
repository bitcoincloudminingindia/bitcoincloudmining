import 'package:flutter/foundation.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

class IronSourceService {
  static final IronSourceService _instance = IronSourceService._internal();
  factory IronSourceService() => _instance;
  IronSourceService._internal();

  final _interstitialListener = _InterstitialAdListener();
  final _rewardedAdListener = _RewardedAdListener();

  Future<void> initIronSource(String appKey) async {
    await IronSource.setAdaptersDebug(true);

    IronSource.setInterstitialListener(_interstitialListener);
    IronSource.setRewardedVideoListener(_rewardedAdListener);

    await IronSource.init(
      appKey: appKey,
      adUnits: [IronSourceAdUnit.interstitial, IronSourceAdUnit.rewardedVideo],
    );
  }

  // INTERSTITIAL
  Future<void> loadInterstitialAd() async {
    await IronSource.loadInterstitial();
  }

  Future<void> showInterstitialAd() async {
    if (await IronSource.isInterstitialReady()) {
      await IronSource.showInterstitial();
    }
  }

  // REWARDED VIDEO
  Future<void> showRewardedAd() async {
    if (await IronSource.isRewardedVideoAvailable()) {
      await IronSource.showRewardedVideo();
    }
  }

  // GETTERS
  Future<bool> get isInterstitialAdLoaded async =>
      await IronSource.isInterstitialReady();

  Future<bool> get isRewardedAdLoaded async =>
      await IronSource.isRewardedVideoAvailable();
}

class _InterstitialAdListener extends InterstitialListener {
  @override
  void onAdReady() {
    debugPrint("Interstitial Ad is ready");
  }

  @override
  void onAdLoadFailed(IronSourceError error) {
    debugPrint("Interstitial load failed: ${error.message}");
  }

  @override
  void onAdOpened(LevelPlayAdInfo adInfo) {
    debugPrint("Interstitial Ad opened: ${adInfo.adUnitId}");
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    debugPrint("Interstitial Ad closed: ${adInfo.adUnitId}");
  }

  @override
  void onAdShowFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    debugPrint("Interstitial Ad show failed: ${error.message}, ad: ${adInfo.adUnitId}");
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    debugPrint("Interstitial Ad clicked: ${adInfo.adUnitId}");
  }

  @override
  void onAdShowSucceeded(LevelPlayAdInfo adInfo) {
    debugPrint("Interstitial Ad show succeeded: ${adInfo.adUnitId}");
  }
}

class _RewardedAdListener extends RewardedVideoListener {
  @override
  void onAdRewarded(LevelPlayAdInfo adInfo) {
    debugPrint("User rewarded for ad: ${adInfo.adUnitId}");
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    debugPrint("Rewarded Ad closed: ${adInfo.adUnitId}");
  }

  @override
  void onAdOpened(LevelPlayAdInfo adInfo) {
    debugPrint("Rewarded Ad opened: ${adInfo.adUnitId}");
  }

  @override
  void onAdShowFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    debugPrint("Rewarded Ad show failed: ${error.message}, ad: ${adInfo.adUnitId}");
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    debugPrint("Rewarded Ad clicked: ${adInfo.adUnitId}");
  }

  @override
  void onAdAvailable(LevelPlayAdInfo adInfo) {
    debugPrint("Rewarded Ad available: ${adInfo.adUnitId}");
  }

  @override
  void onAdUnavailable() {
    debugPrint("Rewarded Ad unavailable");
  }
}
