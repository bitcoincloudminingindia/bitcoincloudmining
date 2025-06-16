// Mock implementation of google_mobile_ads for web platform
class MobileAds {
  static MobileAds _instance = MobileAds._();
  static MobileAds get instance => _instance;
  static set instance(MobileAds value) => _instance = value;

  MobileAds._();

  Future<InitializationStatus> initialize() async {
    print('Web platform - using mock ads implementation');
    return WebInitializationStatus();
  }
}

class InitializationStatus {
  Map<String, AdapterStatus> get adapterStatuses => {};
}

class WebInitializationStatus implements InitializationStatus {
  @override
  Map<String, AdapterStatus> get adapterStatuses => {
        'web': WebAdapterStatus(),
      };
}

class AdapterStatus {
  String get state => 'ready';
}

class WebAdapterStatus implements AdapterStatus {
  @override
  String get state => 'ready';
}

// Mock BannerAd class
class BannerAd {
  static Future<BannerAd> load({
    required String adUnitId,
    required AdSize size,
    required AdRequest request,
    required BannerAdListener listener,
  }) async {
    return BannerAd();
  }

  void dispose() {}
}

// Mock InterstitialAd class
class InterstitialAd {
  static Future<InterstitialAd> load({
    required String adUnitId,
    required AdRequest request,
    required InterstitialAdLoadCallback callback,
  }) async {
    return InterstitialAd();
  }

  void dispose() {}
}

// Mock RewardedAd class
class RewardedAd {
  static Future<RewardedAd> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback callback,
  }) async {
    return RewardedAd();
  }

  void dispose() {}
}

// Mock NativeAd class
class NativeAd {
  static Future<NativeAd> load({
    required String adUnitId,
    required AdRequest request,
    required NativeAdLoadCallback callback,
  }) async {
    return NativeAd();
  }

  void dispose() {}
}

// Mock AdSize class
class AdSize {
  static const AdSize banner = AdSize(width: 320, height: 50);
  static const AdSize largeBanner = AdSize(width: 320, height: 100);
  static const AdSize mediumRectangle = AdSize(width: 300, height: 250);
  static const AdSize fullBanner = AdSize(width: 468, height: 60);
  static const AdSize leaderboard = AdSize(width: 728, height: 90);

  final int width;
  final int height;

  const AdSize({required this.width, required this.height});
}

// Mock AdRequest class
class AdRequest {
  static AdRequest get request => AdRequest();
}

// Mock callback classes
class BannerAdListener {
  final Function(Ad)? onAdLoaded;
  final Function(Ad, AdError)? onAdFailedToLoad;
  final Function(Ad)? onAdOpened;
  final Function(Ad)? onAdClosed;

  const BannerAdListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdOpened,
    this.onAdClosed,
  });
}

class InterstitialAdLoadCallback {
  final Function(InterstitialAd)? onAdLoaded;
  final Function(AdError)? onAdFailedToLoad;

  const InterstitialAdLoadCallback({
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });
}

class RewardedAdLoadCallback {
  final Function(RewardedAd)? onAdLoaded;
  final Function(AdError)? onAdFailedToLoad;

  const RewardedAdLoadCallback({
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });
}

class NativeAdLoadCallback {
  final Function(NativeAd)? onAdLoaded;
  final Function(AdError)? onAdFailedToLoad;

  const NativeAdLoadCallback({
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });
}

// Mock Ad class
class Ad {
  void dispose() {}
}

// Mock AdError class
class AdError {
  final int code;
  final String message;
  final String domain;

  const AdError({
    required this.code,
    required this.message,
    required this.domain,
  });
}
