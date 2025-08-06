import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class HomeSwipeableAd extends StatefulWidget {
  final AdService adService;
  final String screenId;
  final Duration refreshInterval;
  final Duration autoSwipeInterval;
  final EdgeInsetsGeometry? margin;

  HomeSwipeableAd({
    super.key,
    required this.adService,
    required this.screenId,
    this.refreshInterval = const Duration(seconds: 30), // Refresh banner ad every 30 seconds
    this.autoSwipeInterval = const Duration(seconds: 15), // Auto-swipe every 15 seconds
    this.margin,
  }) : assert(screenId.isNotEmpty, 'screenId cannot be empty');

  @override
  State<HomeSwipeableAd> createState() => _HomeSwipeableAdState();
}

class _HomeSwipeableAdState extends State<HomeSwipeableAd> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSwipeTimer;
  Timer? _refreshTimer;
  Widget? _nativeAdWidget;
  bool _isBannerAdLoading = false;
  bool _isBannerAdLoaded = false;
  Widget? _bannerAdWidget;
  Timer? _bannerAdTimer;

  @override
  void initState() {
    super.initState();
    // Initialize page controller with initial page
    _pageController = PageController(initialPage: 0);
    
    // Load ads
    _loadNativeAd();
    _loadBannerAd();
    
    // Start timers
    _startAutoSwipe();
    _startRefreshTimer();
  }

  void _startBannerAdAutoRefresh() {
    _bannerAdTimer?.cancel();
    _bannerAdTimer = Timer.periodic(
      const Duration(minutes: 1), // Refresh banner every minute
      (_) {
        if (mounted) {
          _isBannerAdLoaded = false;
          _loadBannerAd();
        }
      },
    );
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _refreshTimer?.cancel();
    _bannerAdTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildBannerPlaceholder(String message) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    
    // Using withAlpha instead of withOpacity for better precision
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());
    
    return Container(
      height: 360, // Match native ad height
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
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackNativeAd() {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());
    
    return Container(
      height: 360, // Match native ad height
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

  Future<void> _loadNativeAd() async {
    try {
      await widget.adService.loadNativeAd();
      if (mounted && widget.adService.isNativeAdLoaded) {
        if (mounted) {
          setState(() {
            _nativeAdWidget = widget.adService.getNativeAd();
          });
        }
      } else {
        throw Exception('Native ad not loaded');
      }
    } catch (e) {
      debugPrint('Failed to load native ad: $e');
      if (mounted) {
        setState(() {
          _nativeAdWidget = _buildFallbackNativeAd();
        });
      }
    }
  }

  Future<void> _loadBannerAd() async {
    if (_isBannerAdLoading || _isBannerAdLoaded) return;
    
    _isBannerAdLoading = true;
    if (mounted) setState(() {});

    try {
      // Get the banner ad unit ID from AdService
      final bannerAdUnitId = await widget.adService.getBannerAdUnitId();
      
      if (bannerAdUnitId == null || bannerAdUnitId.isEmpty) {
        throw Exception('Banner ad unit ID not available');
      }

      // Create and load the banner ad
      final bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle, // 300x250 banner
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('AdMob banner ad loaded for ${widget.screenId}');
            if (mounted) {
              setState(() {
                _bannerAdWidget = Container(
                  height: 390, // Height for banner container
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: AdWidget(ad: ad as BannerAd),
                );
                _isBannerAdLoaded = true;
              });
            }
            _startBannerAdAutoRefresh();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('AdMob banner ad failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAdWidget = null;
                _isBannerAdLoaded = false;
              });
            }
          },
          onAdImpression: (ad) {
            debugPrint('AdMob banner ad impression for ${widget.screenId}');
          },
        ),
      );

          // Load the ad
      await bannerAd.load();
      
    } catch (e) {
      debugPrint('Error loading AdMob banner ad: $e');
      if (mounted) {
        setState(() {
          _bannerAdWidget = _buildBannerPlaceholder('Ad failed to load');
          _isBannerAdLoaded = false;
        });
      }
    } finally {
      _isBannerAdLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(
      widget.autoSwipeInterval,
      (timer) {
        if (!mounted) return;
        if (_pageController.hasClients) {
          final nextPage = (_currentPage + 1) % 2; // Only 2 pages: native and banner
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  void _resetAutoSwipeTimer() {
    _autoSwipeTimer?.cancel();
    _startAutoSwipe();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // Initial refresh
    _loadBannerAd();
    _loadNativeAd();
    
    // Set up periodic refresh
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      if (mounted) {
        _loadBannerAd();
        _loadNativeAd();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [];
    final theme = Theme.of(context);

    // Add native ad if available
    if (_nativeAdWidget != null) {
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
          child: _nativeAdWidget!,
        ),
      );
    }

    // Add banner ad if available
    if (_bannerAdWidget != null) {
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
          child: _bannerAdWidget!,
        ),
      );
    } else if (!_isBannerAdLoading) {
      pages.add(_buildBannerPlaceholder('Loading ad...'));
    }

    // If no ads available, show fallback
    if (pages.isEmpty) {
      pages.add(_buildFallbackNativeAd());
    }

    return Container(
      width: double.infinity,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SizedBox(
            height: 392, // 360 + 16*2 padding
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _currentPage = index;
                  });
                }
                _resetAutoSwipeTimer();
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return pages[index];
              },
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
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withAlpha(51), // 20% opacity
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
