import 'package:flutter/material.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

class IronSourceNativeAdWidget extends StatefulWidget {
  final double height;
  final double width;
  final LevelPlayTemplateType templateType;
  final String adUnitId;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;
  final VoidCallback? onAdClicked;

  const IronSourceNativeAdWidget({
    super.key,
    this.height = 350,
    this.width = 300,
    this.templateType = LevelPlayTemplateType.MEDIUM,
    this.adUnitId = 'lcv9s3mjszw657sy', // Default ad unit ID
    this.onAdLoaded,
    this.onAdFailed,
    this.onAdClicked,
  });

  @override
  State<IronSourceNativeAdWidget> createState() =>
      _IronSourceNativeAdWidgetState();
}

class _IronSourceNativeAdWidgetState extends State<IronSourceNativeAdWidget>
    implements LevelPlayNativeAdListener {
  LevelPlayNativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _createAndLoadAd();
  }

  Future<void> _createAndLoadAd() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _nativeAd = LevelPlayNativeAd.create(
        adUnitId: widget.adUnitId,
      );
      
      // Set listener after creation
      _nativeAd?.setListener(this);

      await _nativeAd?.loadAd();
    } catch (e) {
      print('❌ Error creating IronSource Native ad: $e');
      setState(() {
        _isLoading = false;
      });
      widget.onAdFailed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdLoaded || _nativeAd == null) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'Native Ad Not Available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return LevelPlayNativeAdView(
      height: widget.height,
      width: widget.width,
      nativeAd: _nativeAd!,
      onPlatformViewCreated: () {
        print('✅ IronSource Native ad view created');
      },
      templateType: widget.templateType,
    );
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    print('🎯 IronSource Native ad clicked');
    widget.onAdClicked?.call();
  }

  @override
  void onAdImpression(LevelPlayAdInfo adInfo) {
    print('👁️ IronSource Native ad impression');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    print('❌ IronSource Native ad load failed: ${error.toString()}');
    setState(() {
      _isLoading = false;
      _isAdLoaded = false;
    });
    widget.onAdFailed?.call();
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    print('✅ IronSource Native ad loaded');
    setState(() {
      _isLoading = false;
      _isAdLoaded = true;
    });
    widget.onAdLoaded?.call();
  }

  @override
  void dispose() {
    _nativeAd = null;
    super.dispose();
  }
}

// Small Native Ad Widget
class IronSourceSmallNativeAdWidget extends StatelessWidget {
  final String adUnitId;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;
  final VoidCallback? onAdClicked;

  const IronSourceSmallNativeAdWidget({
    super.key,
    this.adUnitId = 'lcv9s3mjszw657sy', // Default ad unit ID
    this.onAdLoaded,
    this.onAdFailed,
    this.onAdClicked,
  });

  @override
  Widget build(BuildContext context) {
    return IronSourceNativeAdWidget(
      height: 175,
      width: 300,
      templateType: LevelPlayTemplateType.SMALL,
      adUnitId: adUnitId,
      onAdLoaded: onAdLoaded,
      onAdFailed: onAdFailed,
      onAdClicked: onAdClicked,
    );
  }
}

// Medium Native Ad Widget
class IronSourceMediumNativeAdWidget extends StatelessWidget {
  final String adUnitId;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;
  final VoidCallback? onAdClicked;

  const IronSourceMediumNativeAdWidget({
    super.key,
    this.adUnitId = 'lcv9s3mjszw657sy', // Default ad unit ID
    this.onAdLoaded,
    this.onAdFailed,
    this.onAdClicked,
  });

  @override
  Widget build(BuildContext context) {
    return IronSourceNativeAdWidget(
      height: 350,
      width: 300,
      templateType: LevelPlayTemplateType.MEDIUM,
      adUnitId: adUnitId,
      onAdLoaded: onAdLoaded,
      onAdFailed: onAdFailed,
      onAdClicked: onAdClicked,
    );
  }
}
