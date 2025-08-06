import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// A swipeable carousel that displays native and banner ads with consistent styling
class SwipeableAdCarousel extends StatefulWidget {
  final AdService adService;
  final String screenId;
  final Duration nativeAdRefreshInterval;
  final Duration autoSwipeInterval;
  final Duration bannerAdRefreshInterval;
  final EdgeInsetsGeometry? margin;

  SwipeableAdCarousel({
    super.key,
    required this.adService,
    required this.screenId,
    this.nativeAdRefreshInterval = const Duration(minutes: 1),
    this.autoSwipeInterval = const Duration(seconds: 15),
    this.bannerAdRefreshInterval = const Duration(seconds: 30),
    this.margin,
  }) : assert(screenId.isNotEmpty, 'screenId must not be empty');

  @override
  State<SwipeableAdCarousel> createState() => _SwipeableAdCarouselState();
}

class _SwipeableAdCarouselState extends State<SwipeableAdCarousel> {
  // Controllers and timers
  late final PageController _pageController;
  Timer? _autoSwipeTimer;
  Timer? _nativeAdRefreshTimer;
  Timer? _bannerAdRefreshTimer;

  // Native ad state
  Widget? _nativeAdWidget;
  bool _isNativeAdLoading = false;
  bool _isNativeAdLoaded = false;

  // Banner ad state
  BannerAd? _bannerAd;
  bool _isBannerAdLoading = false;
  bool _isBannerAdLoaded = false;

  // Current page index
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadNativeAd();
    _loadBannerAd();
    _startAutoSwipe();
    _startAdRefreshTimers();
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _nativeAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer?.cancel();
    _bannerAd?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadNativeAd() async {
    if (!mounted || _isNativeAdLoading) return;

    setState(() {
      _isNativeAdLoading = true;
      _nativeAdWidget = _buildFallbackNativeAd();
    });

    try {
      await widget.adService.loadNativeAd().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Native ad loading timeout'),
      );

      if (widget.adService.isNativeAdLoaded && mounted) {
        setState(() {
          _nativeAdWidget = widget.adService.getNativeAd();
          _isNativeAdLoaded = true;
        });
      } else {
        throw Exception('Failed to load native ad');
      }
    } catch (e) {
      debugPrint('Error loading native ad: $e');
      if (mounted) {
        setState(() {
          _nativeAdWidget = _buildFallbackNativeAd();
          _isNativeAdLoaded = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNativeAdLoading = false;
        });
      }
    }
  }

  Future<void> _loadBannerAd() async {
    if (_isBannerAdLoading || _isBannerAdLoaded) return;

    setState(() {
      _isBannerAdLoading = true;
    });

    try {
      final bannerAdUnitId = widget.adService.getBannerAdUnitId();
      
      if (bannerAdUnitId == null || bannerAdUnitId.isEmpty) {
        throw Exception('Banner ad unit ID not available');
      }

      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isBannerAdLoaded = true;
              });
            }
            _startBannerAdAutoRefresh();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isBannerAdLoaded = false;
              });
            }
          },
          onAdImpression: (ad) {
            debugPrint('Banner ad impression for ${widget.screenId}');
          },
        ),
      );

      await _bannerAd?.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      if (mounted) {
        setState(() {
          _bannerAd = null;
          _isBannerAdLoaded = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBannerAdLoading = false;
        });
      }
    }
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(widget.autoSwipeInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextPage = (_currentPage + 1) % _getTotalPages();
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoSwipeTimer() {
    _autoSwipeTimer?.cancel();
    _startAutoSwipe();
  }

  void _startAdRefreshTimers() {
    // Native ad refresh
    _nativeAdRefreshTimer?.cancel();
    _nativeAdRefreshTimer = Timer.periodic(
      widget.nativeAdRefreshInterval,
      (_) => _loadNativeAd(),
    );

    // Banner ad refresh
    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer = Timer.periodic(
      widget.bannerAdRefreshInterval,
      (_) => _loadBannerAd(),
    );
  }

  void _startBannerAdAutoRefresh() {
    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer = Timer.periodic(
      widget.bannerAdRefreshInterval,
      (_) {
        if (mounted) {
          _loadBannerAd();
        }
      },
    );
  }

  int _getTotalPages() {
    int count = 0;
    if (_isNativeAdLoaded || _isNativeAdLoading) count++;
    if (_isBannerAdLoaded || _isBannerAdLoading) count++;
    return count > 0 ? count : 1; // At least one page for fallback
  }

  Widget _buildFallbackNativeAd() {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());
    
    return Container(
      height: 360,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ad_units,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Ad Content Not Available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBannerAd() {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());
    
    return Container(
      height: 360,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ad_units,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Advertisement',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading ad content...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [];
    
    // Add native ad if available or loading
    if (_isNativeAdLoaded || _isNativeAdLoading) {
      pages.add(
        Container(
          height: 360,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A000000), // 10% black opacity
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isNativeAdLoaded ? _nativeAdWidget : _buildFallbackNativeAd(),
        ),
      );
    }
    
    // Add banner ad if available or loading
    if (_isBannerAdLoaded || _isBannerAdLoading) {
      pages.add(
        Container(
          height: 360,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A000000), // 10% black opacity
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isBannerAdLoaded && _bannerAd != null
              ? AdWidget(ad: _bannerAd!)
              : _buildFallbackBannerAd(),
        ),
      );
    }

    // If no ads are available yet, show a single fallback
    if (pages.isEmpty) {
      pages.add(_buildFallbackNativeAd());
    }

    return Container(
      width: double.infinity,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 392, // 360 + 16*2 padding
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _currentPage = index;
                  });
                }
                _resetAutoSwipeTimer();
              },
              children: pages,
            ),
          ),
          // Dots indicator
          if (pages.length > 1)
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  pages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
