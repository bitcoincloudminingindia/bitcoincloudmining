import 'dart:async'; // For Timer
import 'dart:io' show exit, Platform;

import 'package:audioplayers/audioplayers.dart'; // For AudioPlayer
import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/providers/network_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/mining_notification_service.dart';
import 'package:bitcoin_cloud_mining/services/sound_notification_service.dart';
import 'package:bitcoin_cloud_mining/widgets/network_status_widget.dart';
import 'package:bitcoin_cloud_mining/widgets/server_connection_animation.dart';
import 'package:bitcoin_cloud_mining/widgets/world_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For Flutter Toast
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For FontAwesomeIcons
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For SharedPreferences
import 'package:url_launcher/url_launcher.dart'; // Add this import

import '../screens/game_screen.dart';
import '../screens/referral_screen.dart';
import '../screens/reward_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Constants
  static const int MINING_DURATION_MINUTES = 30;
  static const double BASE_MINING_RATE =
      0.000000000000000009; // 0.000000000000000009 BTC per second
  static const double INITIAL_POWER_BOOST_RATE =
      0.5; // Initial boost multiplier
  static const double POWER_BOOST_INCREMENT = 0.1; // Increment per click
  static const int POWER_BOOST_DURATION_MINUTES = 5; // 5 minutes duration
  static const double TAP_REWARD_RATE =
      0.000000000000001000; // 5x increased reward

  // Variables
  late final AdService _adService;
  double _hashRate = 2.5;
  bool _isMining = false;
  Timer? _miningTimer;
  Timer? _powerBoostTimer;
  int _percentage = 0;
  double _miningEarnings = 0.0;
  late AudioPlayer _audioPlayer;
  DateTime? _miningStartTime;
  DateTime? _powerBoostStartTime;
  Color _currentColor = Colors.purple;
  double _miningProgress = 0.0;
  int _lastMiningTime = 0;
  int _totalMiningTime = 0;
  Timer? _adTimer;
  Timer? _adReloadTimer;
  bool _isPowerBoostActive = false;
  double _currentPowerBoostMultiplier = 0.0;
  int _powerBoostClickCount = 0;
  double _currentMiningRate = BASE_MINING_RATE;
  String _miningStatus = 'Ready';
  String? _lastError;

  // Add ScrollController
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String? _errorMessage;

  Timer? _uiUpdateTimer; // Add a timer for UI updates only

  // Counter for sci-fi object taps
  int _sciFiTapCount = 0;
  bool _isSciFiLoading = false;

  // Periodic save timer to save earnings every 30 seconds
  Timer? _periodicSaveTimer;

  // Network connection state
  bool _isConnectingToServer = false;
  bool _isServerConnected = false;

  // New variables
  double _totalEarnings = 0.0;
  DateTime? _lastEarningUpdateTime;
  double _lastPowerBoostMultiplier = 0.0;
  bool _wasPowerBoostActive = false;

  Timer? _adUiUpdateTimer;

  // Banner ad future
  Future<Widget?>? _bannerAdFuture;

  // Home screen ke liye dedicated banner ad load function
  void _loadHomeBannerAd() {
    setState(() {
      _bannerAdFuture = _getHomeBannerAdWidget();
    });
  }

  // Enhanced banner ad loading with better error handling
  Future<Widget?> _getHomeBannerAdWidget() async {
    try {
      // Check if banner ad is already loaded
      if (_adService.isBannerAdLoaded) {
        return _adService.getBannerAd();
      }

      // Load banner ad with timeout
      await _adService.loadBannerAd().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Banner ad loading timeout');
        },
      );

      if (_adService.isBannerAdLoaded) {
        return _adService.getBannerAd();
      } else {
        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading Banner Ad...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Return a minimal placeholder for banner ad
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

  // Home screen ke liye dedicated native ad widget function
  Future<Widget?> _getHomeNativeAdWidget() async {
    try {
      // Check if ad is already loaded
      if (_adService.isNativeAdLoaded) {
        return _adService.getNativeAd();
      }

      // Load native ad with timeout
      await _adService.loadNativeAd().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Ad loading timeout');
        },
      );

      if (_adService.isNativeAdLoaded) {
        return _adService.getNativeAd();
      } else {
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ads_click, color: Colors.grey, size: 24),
                SizedBox(height: 4),
                Text(
                  'Ad Loading...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Return a more user-friendly error state
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ads_click, color: Colors.grey, size: 24),
              const SizedBox(height: 8),
              const Text(
                'Ad Unavailable',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check your internet connection',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              // Add refresh button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _nativeAdFuture = _getHomeNativeAdWidget();
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  // Native ad future
  Future<Widget?>? _nativeAdFuture;

  // Bottom section ads (Click for Magic & Reward ke niche)
  Future<Widget?>? _bottomBannerAdFuture;
  Future<Widget?>? _bottomNativeAdFuture;
  Future<Widget?>? _middleBannerAdFuture;

  // Bottom section ad load functions
  void _loadBottomBannerAd() {
    setState(() {
      _bottomBannerAdFuture = _getBottomBannerAdWidget();
    });
  }

  void _loadBottomNativeAd() {
    setState(() {
      _bottomNativeAdFuture = _getBottomNativeAdWidget();
    });
  }

  void _loadMiddleBannerAd() {
    setState(() {
      _middleBannerAdFuture = _getMiddleBannerAdWidget();
    });
  }

  // Enhanced middle banner ad loading
  Future<Widget?> _getMiddleBannerAdWidget() async {
    try {
      // Load banner ad with timeout
      await _adService.loadBannerAd().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Middle banner ad loading timeout');
        },
      );

      if (_adService.isBannerAdLoaded) {
        return _adService.getBannerAd();
      } else {
        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading Middle Banner...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
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

  // Enhanced bottom banner ad loading
  Future<Widget?> _getBottomBannerAdWidget() async {
    try {
      // Load banner ad with timeout
      await _adService.loadBannerAd().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Bottom banner ad loading timeout');
        },
      );

      if (_adService.isBannerAdLoaded) {
        return _adService.getBannerAd();
      } else {
        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading Bottom Banner...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
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

  // Enhanced bottom native ad loading
  Future<Widget?> _getBottomNativeAdWidget() async {
    try {
      // Load native ad with timeout
      await _adService.loadNativeAd().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Bottom native ad loading timeout');
        },
      );

      if (_adService.isNativeAdLoaded) {
        return _adService.getNativeAd();
      } else {
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Loading Bottom Native Ad...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ads_click, color: Colors.grey, size: 24),
              const SizedBox(height: 8),
              const Text(
                'Bottom Ad Unavailable',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check your internet connection',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _bottomNativeAdFuture = _getBottomNativeAdWidget();
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioPlayer = AudioPlayer();
    _adService = AdService();
    Future.microtask(() async {
      await _adService.initialize();
      _loadHomeBannerAd();
      _nativeAdFuture = _getHomeNativeAdWidget();
      // Load bottom section ads separately
      _loadBottomBannerAd();
      _loadBottomNativeAd();
      _loadMiddleBannerAd();
    });
    _adUiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    _initializeData();
    _loadUserProfile();
    _loadPercentage();

    _loadSavedSettings();
    _startAdReloadTimer();
    _startAdTimer();

    // Add scroll listener
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    // Start mining UI update timer if mining is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMining && _miningStartTime != null) {
        _startMiningUiTimer();
      }
    });

    // Start periodic save timer
    _startPeriodicSaveTimer();

    // Start server connection simulation
    _startServerConnectionSimulation();
  }

  void _startMiningUiTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isMining || _miningStartTime == null) {
        timer.cancel();
        return;
      }
      _updateMiningProgressFromElapsed();
      // If mining completed, stop timer
      final now = DateTime.now();
      final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
      if (elapsedMinutes >= MINING_DURATION_MINUTES) {
        timer.cancel();
        _resetMiningState();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        if (mounted) {
          setState(() {
            _loadHomeBannerAd();
            _nativeAdFuture = _getHomeNativeAdWidget(); // Native ad reload karo
            // Reload bottom section ads separately
            _loadBottomBannerAd();
            _loadBottomNativeAd();
            _loadMiddleBannerAd();
          });
        }
        if (_isMining && _miningStartTime != null) {
          _updateMiningProgressFromElapsed();
          _startMiningUiTimer();

          // Don't start notification here as it's already active from _startMiningProcess
          // Just update the existing notification if needed
          if (MiningNotificationService.isActive) {
            final walletProvider = context.read<WalletProvider>();
            final currentBalance = walletProvider.balance.toStringAsFixed(18);
            MiningNotificationService.updateMiningStats(
              balance: currentBalance,
              hashRate: _hashRate.toStringAsFixed(1),
              status: _isPowerBoostActive
                  ? '⛏️ Mining with Power Boost!'
                  : '⛏️ Mining in progress...',
            );
          }
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background - save state
        if (_isMining) {
          _saveMiningState();
          // Mining ke dauran hi floating bubble show karo
        }
        break;
      case AppLifecycleState.detached:
        // App terminated
        if (_isMining) {
          _saveMiningState();
          // Keep mining notification active even if app is terminated
        }
        break;
    }
  }

  @override
  void dispose() {
    // Only save mining state, don't add earnings prematurely
    if (_isMining) {
      _saveMiningState();
    }

    _cancelAllTimers();
    _uiUpdateTimer?.cancel();
    _periodicSaveTimer?.cancel();
    _adUiUpdateTimer?.cancel();

    // Stop mining notification
    MiningNotificationService.stopMiningNotification();

    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _scrollController.dispose();
    try {
      _adService.dispose();
    } catch (e) {}
    super.dispose();
  }

  void _cancelAllTimers() {
    _miningTimer?.cancel();
    _adTimer?.cancel();
    _adReloadTimer?.cancel();
    _powerBoostTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _miningTimer = null;
    _adTimer = null;
    _adReloadTimer = null;
    _powerBoostTimer = null;
    _uiUpdateTimer = null;
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    try {
      // Initialize all processes silently
      await _initializeData();
      await _loadUserProfile();
      await _loadPercentage();

      // Load wallet balance from backend
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.loadWallet();
    } catch (e) {
      // Check if it's a DNS error and provide better message
      String errorMessage = 'Error initializing app: ${e.toString()}';
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('no address associated with hostname')) {
        errorMessage =
            'Network connection issue. Please check your internet connection and try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _initializeApp,
            ),
          ),
        );
      }
    }
  }

  // --- MINING LOGIC START ---

  // Start a new mining session
  Future<void> _startMiningProcess() async {
    try {
      if (_isMining && _miningStartTime != null) {
        final now = DateTime.now();
        final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
        if (elapsedMinutes < MINING_DURATION_MINUTES) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait \\${MINING_DURATION_MINUTES - elapsedMinutes} minutes for current session to complete',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        } else {
          // '⏰ Previous mining session completed, resetting state without adding earnings');
          if (mounted) {
            setState(() {
              _isMining = false;
              _miningStartTime = null;
              _miningProgress = 0.0;
              _currentMiningRate = BASE_MINING_RATE;
              _hashRate = 2.5;
              _isPowerBoostActive = false;
              _currentPowerBoostMultiplier = 0.0;
              _miningEarnings = 0.0;
              _miningStatus = 'Inactive';
              _lastMiningTime = 0;
              _powerBoostClickCount = 0;
              _powerBoostStartTime = null;
              _totalEarnings = 0.0;
              _lastEarningUpdateTime = null;
              _lastPowerBoostMultiplier = 0.0;
              _wasPowerBoostActive = false;
            });
          }
          await _saveMiningState();
        }
      }
      final now = DateTime.now();
      setState(() {
        _isMining = true;
        _miningStartTime = now;
        _miningProgress = 0.0;
        _miningEarnings = 0.0;
        _miningStatus = 'Active';
        _currentMiningRate = BASE_MINING_RATE;
        _lastMiningTime = 0;
        _totalMiningTime = 0;
        _isPowerBoostActive = false;
        _hashRate = 2.5;
        _totalEarnings = 0.0;
        _lastEarningUpdateTime = now;
        _lastPowerBoostMultiplier = 0.0;
        _wasPowerBoostActive = false;
      });
      await _saveMiningState();
      _startMiningUiTimer();

      // Start mining notification
      final walletProvider = context.read<WalletProvider>();
      final currentBalance = walletProvider.balance.toStringAsFixed(18);
      await MiningNotificationService.startMiningNotification(
        initialBalance: currentBalance,
        initialHashRate: _hashRate.toStringAsFixed(1),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mining started! Session will complete in 30 minutes',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      _showError('Start Mining Error', e.toString());
    }
  }

  // End/reset the mining session
  Future<void> _resetMiningState() async {
    // Mining complete par notification update karo (remove mat karo)
    await MiningNotificationService.completeMiningNotification();

    _cancelAllTimers();
    _uiUpdateTimer?.cancel();

    // Calculate final earnings based on actual elapsed time
    double earningsToAdd = 0.0;
    if (_isMining && _miningStartTime != null) {
      final now = DateTime.now();
      final elapsedSeconds = now.difference(_miningStartTime!).inSeconds;
      final elapsedMinutes = elapsedSeconds ~/ 60;

      // Only add earnings if mining session was at least partially completed
      // and mining session has actually completed (30 minutes or more)
      if (elapsedMinutes >= MINING_DURATION_MINUTES) {
        final miningRate = BASE_MINING_RATE *
            (1 + (_isPowerBoostActive ? _currentPowerBoostMultiplier : 0.0));
        earningsToAdd =
            double.parse((miningRate * elapsedSeconds).toStringAsFixed(18));

        // Show mining completion notification
        await SoundNotificationService.showAlertNotification(
          title: '⛏️ Mining Session Completed!',
          message:
              'Your mining session has completed successfully! You can start a new session now.',
        );
      } else {
        // '⏰ Mining session not completed yet ($elapsedMinutes/$MINING_DURATION_MINUTES minutes), no earnings added');
      }
    }

    if (mounted) {
      setState(() {
        _isMining = false;
        _miningStartTime = null;
        _miningProgress = 0.0;
        _currentMiningRate = BASE_MINING_RATE;
        _hashRate = 2.5;
        _isPowerBoostActive = false;
        _currentPowerBoostMultiplier = 0.0;
        _miningEarnings = 0.0;
        _miningStatus = 'Completed';
        _lastMiningTime = 0;
        _powerBoostClickCount = 0;
        _powerBoostStartTime = null;
      });
    }

    if (earningsToAdd > 0) {
      try {
        final walletProvider = context.read<WalletProvider>();
        await walletProvider.addEarning(
          earningsToAdd,
          type: 'mining',
          description: 'Mining session earnings',
        );

        // Show earnings notification
        await SoundNotificationService.showRewardNotification(
          amount: earningsToAdd,
          type: 'mining',
        );

        // Play earning sound for mining completion
        await SoundNotificationService.playEarningSound();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You earned \\${earningsToAdd.toStringAsFixed(18)} BTC from mining! Added to your wallet.',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add mining earnings to wallet: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Always save state after resetting, to clear mining keys
    await _saveMiningState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Mining session completed! You can start a new session now.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _miningStatus = 'Inactive';
      });
    }
  }

  // Update mining progress and earnings
  void _updateMiningProgressFromElapsed() {
    if (!_isMining || _miningStartTime == null) return;
    final now = DateTime.now();
    if (_lastEarningUpdateTime == null) {
      _lastEarningUpdateTime = now;
      _lastPowerBoostMultiplier = _currentPowerBoostMultiplier;
      _wasPowerBoostActive = _isPowerBoostActive;
      return;
    }
    final secondsElapsed = now.difference(_lastEarningUpdateTime!).inSeconds;
    if (secondsElapsed > 0) {
      double rate = BASE_MINING_RATE;
      if (_wasPowerBoostActive) {
        rate = BASE_MINING_RATE * (1 + _lastPowerBoostMultiplier);
      }
      final earningToAdd = rate * secondsElapsed;
      _totalEarnings += earningToAdd;
      _lastEarningUpdateTime = now;
      _lastPowerBoostMultiplier = _currentPowerBoostMultiplier;
      _wasPowerBoostActive = _isPowerBoostActive;
    }
    setState(() {
      _currentMiningRate = _isPowerBoostActive
          ? BASE_MINING_RATE * (1 + _currentPowerBoostMultiplier)
          : BASE_MINING_RATE;
      _miningEarnings = double.parse(_totalEarnings.toStringAsFixed(18));
      final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
      _miningProgress = (elapsedMinutes / MINING_DURATION_MINUTES) * 100;
      if (_miningProgress > 100) _miningProgress = 100;
    });

    // Update mining notification stats (but don't trigger immediate update)
    // Let the timer handle notification updates to prevent spam
    if (MiningNotificationService.isActive) {
      final walletProvider = context.read<WalletProvider>();
      final currentBalance = walletProvider.balance.toStringAsFixed(18);
      MiningNotificationService.updateMiningStats(
        balance: currentBalance,
        hashRate: _hashRate.toStringAsFixed(1),
        status: _isPowerBoostActive
            ? '⛏️ Mining with Power Boost!'
            : '⛏️ Mining in progress...',
      );
    }
  }

  // Save mining state
  Future<void> _saveMiningState() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isMining && _miningStartTime != null) {
        await prefs.setBool('isMining', true);
        await prefs.setString(
            'miningStartTime', _miningStartTime!.toIso8601String());
        await prefs.setDouble('miningEarnings', _miningEarnings);
        await prefs.setDouble('miningProgress', _miningProgress);
        await prefs.setDouble('hashRate', _hashRate);
        await prefs.setDouble(
            'currentPowerBoostMultiplier', _currentPowerBoostMultiplier);
        await prefs.setBool('powerBoostActive', _isPowerBoostActive);
        await prefs.setInt('totalMiningTime', _totalMiningTime);
        await prefs.setDouble('currentMiningRate', _currentMiningRate);
        await prefs.setInt('powerBoostClickCount', _powerBoostClickCount);
        if (_powerBoostStartTime != null) {
          await prefs.setString(
              'powerBoostStartTime', _powerBoostStartTime!.toIso8601String());
        } else {
          await prefs.remove('powerBoostStartTime');
        }
        await prefs.setString('miningStatus', _miningStatus);
        await prefs.setInt('lastMiningTime', _lastMiningTime);
      } else {
        // Mining is not active, clear mining-related keys
        await prefs.setBool('isMining', false);
        await prefs.remove('miningStartTime');
        await prefs.remove('miningEarnings');
        await prefs.remove('miningProgress');
        await prefs.remove('hashRate');
        await prefs.remove('currentPowerBoostMultiplier');
        await prefs.remove('powerBoostActive');
        await prefs.remove('totalMiningTime');
        await prefs.remove('currentMiningRate');
        await prefs.remove('powerBoostClickCount');
        await prefs.remove('powerBoostStartTime');
        await prefs.setString('miningStatus', 'Inactive');
        await prefs.remove('lastMiningTime');
      }
    } catch (e) {
      // Optionally log error
    }
  }

  // Load mining state and settings
  Future<void> _initializeData() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final DateTime? loadedMiningStartTime =
          prefs.getString('miningStartTime') != null
              ? DateTime.parse(prefs.getString('miningStartTime')!)
              : null;
      final bool loadedIsMining = prefs.getBool('isMining') ?? false;
      final double loadedMiningEarnings =
          prefs.getDouble('miningEarnings') ?? 0.0;
      final String loadedMiningStatus =
          prefs.getString('miningStatus') ?? 'Inactive';
      final double loadedCurrentMiningRate =
          prefs.getDouble('currentMiningRate') ?? BASE_MINING_RATE;
      final int loadedLastMiningTime = prefs.getInt('lastMiningTime') ?? 0;
      final bool loadedIsPowerBoostActive =
          prefs.getBool('powerBoostActive') ?? false;
      final double loadedCurrentPowerBoostMultiplier =
          prefs.getDouble('currentPowerBoostMultiplier') ?? 0.0;
      final int loadedPowerBoostClickCount =
          prefs.getInt('powerBoostClickCount') ?? 0;
      final DateTime? loadedPowerBoostStartTime =
          prefs.getString('powerBoostStartTime') != null
              ? DateTime.parse(prefs.getString('powerBoostStartTime')!)
              : null;
      final double loadedHashRate = prefs.getDouble('hashRate') ?? 2.5;
      final double loadedMiningProgress =
          prefs.getDouble('miningProgress') ?? 0.0;
      final int loadedPercentage = prefs.getInt('percentage') ?? 0;

      // Check if mining session should be expired
      bool miningExpired = false;
      int elapsedSeconds = 0;
      if (loadedIsMining && loadedMiningStartTime != null) {
        final now = DateTime.now();
        elapsedSeconds = now.difference(loadedMiningStartTime).inSeconds;
        final elapsedMinutes = elapsedSeconds ~/ 60;
        if (elapsedMinutes >= MINING_DURATION_MINUTES) {
          miningExpired = true;
        }
      }

      // Check if power boost should be expired
      bool powerBoostExpired = false;
      if (loadedIsPowerBoostActive && loadedPowerBoostStartTime != null) {
        final now = DateTime.now();
        final elapsedSecondsPB =
            now.difference(loadedPowerBoostStartTime).inSeconds;
        if (elapsedSecondsPB >= POWER_BOOST_DURATION_MINUTES * 60) {
          powerBoostExpired = true;
        }
      }

      if (miningExpired && loadedIsMining && loadedMiningStartTime != null) {
        // Don't add earnings here, let _resetMiningState() handle it
        // This prevents duplicate earnings being added
      }

      setState(() {
        _percentage = loadedPercentage;
        if (miningExpired) {
          _isMining = false;
          _miningStartTime = null;
          _miningProgress = 0.0;
          _miningEarnings = 0.0;
          _miningStatus = 'Completed';
          _currentMiningRate = BASE_MINING_RATE;
          _lastMiningTime = 0;
          _isPowerBoostActive = false;
          _currentPowerBoostMultiplier = 0.0;
          _powerBoostClickCount = 0;
          _powerBoostStartTime = null;
          _hashRate = 2.5;
        } else if (!loadedIsMining) {
          // Explicitly reset all mining state if not mining
          _isMining = false;
          _miningStartTime = null;
          _miningProgress = 0.0;
          _miningEarnings = 0.0;
          _miningStatus = 'Inactive';
          _currentMiningRate = BASE_MINING_RATE;
          _lastMiningTime = 0;
          _isPowerBoostActive = false;
          _currentPowerBoostMultiplier = 0.0;
          _powerBoostClickCount = 0;
          _powerBoostStartTime = null;
          _hashRate = 2.5;
        } else {
          _isMining = loadedIsMining;
          _miningStartTime = loadedMiningStartTime;
          _miningProgress = loadedMiningProgress;
          _miningEarnings = loadedMiningEarnings;
          _miningStatus = loadedMiningStatus;
          _currentMiningRate = loadedCurrentMiningRate;
          _lastMiningTime = loadedLastMiningTime;
          if (powerBoostExpired) {
            _isPowerBoostActive = false;
            _currentPowerBoostMultiplier = 0.0;
            _powerBoostClickCount = 0;
            _powerBoostStartTime = null;
            _hashRate = 2.5;
          } else {
            _isPowerBoostActive = loadedIsPowerBoostActive;
            _currentPowerBoostMultiplier = loadedCurrentPowerBoostMultiplier;
            _powerBoostClickCount = loadedPowerBoostClickCount;
            _powerBoostStartTime = loadedPowerBoostStartTime;
            _hashRate = loadedHashRate;
          }
        }
      });

      // If mining expired, reset mining state (this will also clear prefs)
      if (miningExpired) {
        // Don't call _resetMiningState() here as it will add earnings prematurely
        // Just reset the state without adding earnings
      }

      // Show mining completion notification for expired session
      await SoundNotificationService.showAlertNotification(
        title: '⛏️ Mining Session Completed!',
        message:
            'Your previous mining session has completed. You can start a new session now.',
      );

      if (mounted) {
        setState(() {
          _isMining = false;
          _miningStartTime = null;
          _miningProgress = 0.0;
          _currentMiningRate = BASE_MINING_RATE;
          _hashRate = 2.5;
          _isPowerBoostActive = false;
          _currentPowerBoostMultiplier = 0.0;
          _miningEarnings = 0.0;
          _miningStatus = 'Inactive';
          _lastMiningTime = 0;
          _powerBoostClickCount = 0;
          _powerBoostStartTime = null;
        });
      }
      await _saveMiningState();
    } catch (e) {
      // Optionally log error
    }
  }

  // Loads the mining progress percentage from SharedPreferences
  Future<void> _loadPercentage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _percentage = prefs.getInt('percentage') ?? 0;
      });
    } catch (e) {
      // Optionally log error
    }
  }

  Future<void> _savePercentage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('percentage', _percentage);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final currentServer = networkProvider.currentServer;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Only save mining state, don't add earnings prematurely
          if (_isMining) {
            await _saveMiningState();
          }

          // Show confirmation dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Exit App'),
                ],
              ),
              content: Text(
                _isMining
                    ? 'Are you sure you want to exit the app?\n\nYour mining session will continue in the background and earnings will be added when complete.'
                    : 'Are you sure you want to exit the app?\n\nYour earnings have been saved.',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            if (Platform.isAndroid || Platform.isIOS) {
              SystemNavigator.pop();
            } else {
              exit(0);
            }
          }
        }
      },
      child: _buildHomeScaffold(currentServer),
    );
  }

  Widget _buildHomeScaffold(String currentServer) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: _isScrolled ? 70 : 140,
        flexibleSpace: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(26, 35, 126, 0.95),
                Color.fromRGBO(13, 71, 161, 0.95),
                Color.fromRGBO(2, 119, 189, 0.95),
              ],
            ),
          ),
        ),
        title: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(_isScrolled ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(51),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.currency_bitcoin,
              size: _isScrolled ? 35 : 64,
              color: Colors.amber[400],
            ),
          ),
        ),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _navigateToWalletScreen,
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 35),
                    const SizedBox(width: 4),
                    Consumer<WalletProvider>(
                      builder: (context, walletProvider, _) {
                        return Text(
                          '${walletProvider.btcBalance.toStringAsFixed(18)} BTC',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              if (!_isScrolled) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D3A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(102),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha(26),
                        offset: const Offset(-1, -1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF00F5A0),
                            Color(0xFF00D9F5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'HAVE A NICE DAY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00F5A0),
                              Color(0xFF00D9F5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F5A0).withAlpha(102),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🌟',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (_errorMessage != null) {
                  return const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                }

                final fullName = authProvider.fullName;
                if (fullName == null || fullName.isEmpty) {
                  return const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                }

                return Text(
                  'Welcome Back, $fullName!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                );
              },
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Add Network Status Widget
            NetworkStatusWidget(
              isMining: _isMining,
              hashRate: _hashRate,
              onServerChange: () {
                setState(() {});
              },
            ),
            // Banner Ad Box (mining state ke upar)
            FutureBuilder<Widget?>(
              future: _bannerAdFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: snapshot.data,
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading Banner Ad...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 12),
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
              },
            ),
            // Native Ad Box (banner ad ke neeche)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: FutureBuilder<Widget?>(
                future: _nativeAdFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return snapshot.data!;
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Loading Ad...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ads_click, color: Colors.grey, size: 24),
                            SizedBox(height: 8),
                            Text(
                              'Ad Unavailable',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
            const SizedBox(height: 16),
            // Add Server Connection Animation
            ServerConnectionAnimation(
              serverName: currentServer,
              isConnecting: _isConnectingToServer,
              isConnected: _isServerConnected,
              onConnectionComplete: () {
                setState(() {
                  _isServerConnected = true;
                });
              },
            ),
            const SizedBox(height: 16),
            // Add World Map Widget
            WorldMapWidget(
              serverLocation: currentServer,
              isConnected: _isServerConnected,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            buildGameSection(),
            const SizedBox(height: 16),
            // Middle Banner Ad (Game section ke niche, mining state ke upar)
            FutureBuilder<Widget?>(
              future: _middleBannerAdFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: snapshot.data,
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading Middle Banner...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
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
              },
            ),
            Row(
              children: [
                buildStatCard(
                  title: 'Hash Rate',
                  value: '${_hashRate.toStringAsFixed(1)} GH/s',
                  icon: Icons.speed,
                ),
                const SizedBox(width: 16),
                buildStatCard(
                  title: 'Mining Earnings',
                  value: '${_miningEarnings.toStringAsFixed(18)} BTC',
                  icon: Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMining ? _startPowerBoost : null,
                    icon: Icon(
                      Icons.power,
                      color: _isMining ? Colors.white : Colors.grey,
                    ),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPowerBoostActive
                              ? 'Power Boost Active'
                              : 'Power Boost',
                          style: TextStyle(
                            color: _isMining ? Colors.white : Colors.grey,
                          ),
                        ),
                        if (_isPowerBoostActive) ...[
                          Text(
                            '+${(_currentPowerBoostMultiplier * 100).toStringAsFixed(0)}% Rate',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _getPowerBoostRemainingTime(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isPowerBoostActive ? Colors.green : Colors.red,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isMining ? null : _startMiningProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Start Mining'),
                        // Only show remaining if mining is active and not completed
                        if (_isMining &&
                            _miningStatus != 'Completed' &&
                            _miningStartTime != null)
                          Text(
                            'Remaining: ${_getRemainingTime()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _onSciFiObjectTapped,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 120 + _percentage.toDouble(),
                      height: 120 + _percentage.toDouble(),
                      decoration: BoxDecoration(
                        color: _currentColor == Colors.blue
                            ? Colors.blueAccent
                            : Colors.purple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _currentColor == Colors.blue
                                ? const Color.fromRGBO(0, 122, 255, 0.7)
                                : const Color.fromRGBO(128, 0, 128, 0.7),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          // Add pulsing effect for sci-fi feel
                          BoxShadow(
                            color: _currentColor == Colors.blue
                                ? const Color.fromRGBO(0, 255, 255, 0.3)
                                : const Color.fromRGBO(255, 0, 255, 0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isSciFiLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _sciFiTapCount % 10 == 0
                                        ? Icons.emoji_events
                                        : _sciFiTapCount % 5 == 0
                                            ? Icons.flash_on
                                            : Icons.memory,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                  if (_sciFiTapCount > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_sciFiTapCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Click for Magic & Reward',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff055366),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bottom Banner Ad (Click for Magic & Reward ke niche)
            FutureBuilder<Widget?>(
              future: _bottomBannerAdFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: snapshot.data,
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading Bottom Banner...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
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
              },
            ),
            // Bottom Native Ad (Banner ad ke niche)
            FutureBuilder<Widget?>(
              future: _bottomNativeAdFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: snapshot.data,
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    height: 250,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Loading Bottom Native Ad...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    height: 250,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.ads_click, color: Colors.grey, size: 24),
                          SizedBox(height: 8),
                          Text(
                            'Bottom Ad Unavailable',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            Row(
              children: [
                buildInfoCard(
                  title: 'Reward Program',
                  icon: Icons.card_giftcard,
                  description: 'Complete tasks to earn rewards!',
                  color: Colors.orange,
                  onTap: _navigateToRewardScreen,
                ),
                const SizedBox(width: 16),
                buildInfoCard(
                  title: 'Referral Program',
                  icon: Icons.group_add,
                  description: 'Invite friends to earn extra rewards!',
                  color: Colors.purple,
                  onTap: _navigateToReferralScreen,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.telegram,
                      color: Colors.blue, size: 36),
                  onPressed: () async {
                    const telegramUrl = 'https://t.me/+v6K5Agkb5r8wMjhl';
                    final Uri telegramUri = Uri.parse(telegramUrl);
                    if (await launchUrl(telegramUri)) {
                      await launchUrl(telegramUri);
                    } else {
                      Fluttertoast.showToast(msg: 'Could not open Telegram.');
                    }
                  },
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.instagram,
                      color: Colors.pink, size: 36),
                  onPressed: () async {
                    const instagramUrl =
                        'https://www.instagram.com/bitcoincloudmining/';
                    final Uri instagramUri = Uri.parse(instagramUrl);
                    if (await launchUrl(instagramUri)) {
                      await launchUrl(instagramUri);
                    } else {
                      Fluttertoast.showToast(msg: 'Could not open Instagram.');
                    }
                  },
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp,
                      color: Colors.green, size: 36),
                  onPressed: () async {
                    const whatsappUrl =
                        'https://chat.whatsapp.com/InL9NrT9gtuKpXRJ3Gu5A5';
                    final Uri whatsappUri = Uri.parse(whatsappUrl);
                    if (await launchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri);
                    } else {
                      Fluttertoast.showToast(msg: 'Could not open WhatsApp.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Join our community for exclusive coupons and BTC reward opportunities!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xdde12a2a),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isMining || _lastError != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lastError != null
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lastError != null ? Icons.error : Icons.info,
                      color: _lastError != null ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastError ?? 'Mining Status: $_miningStatus',
                        style: TextStyle(
                          color: _lastError != null ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                    if (_lastError != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _retryLastOperation,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildGameSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.videogame_asset,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(width: 10),
              Text(
                'Play & Earn BTC Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Bitcoin',
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white54, thickness: 1, height: 20),
          const SizedBox(height: 8),
          const Text(
            'Play fun games and get BTC rewards for your achievements!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _navigateToGameScreen,
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            label: const Text(
              'Play Games',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent[700],
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            animation: true,
            percent: _percentage / 100,
            center: Text(
              '$_percentage%',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Colors.white),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.yellowAccent,
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(
      {required String title, required String value, required IconData icon}) {
    return Expanded(
      child: Card(
        color: Colors.indigo,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard(
      {required String title,
      required IconData icon,
      required String description,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _handleNavigation();
          onTap();
        },
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                Text(description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    setState(() => _lastError = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _retryLastOperation() async {
    if (_lastError == null) return;

    try {
      if (_isMining) {
        await _startMiningProcess();
      }
      setState(() => _lastError = null);
    } catch (e) {
      _showError(
          'Retry Failed', 'Failed to retry operation. Please try again.');
    }
  }

  String _getRemainingTime() {
    // If not mining or mining just completed, return empty string
    if (!_isMining ||
        _miningStartTime == null ||
        _miningStatus == 'Completed') {
      return '';
    }

    final now = DateTime.now();
    final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
    final remainingMinutes = MINING_DURATION_MINUTES - elapsedMinutes;

    if (remainingMinutes <= 0) return '';

    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getPowerBoostRemainingTime() {
    if (!_isPowerBoostActive || _powerBoostStartTime == null) return '';

    final now = DateTime.now();
    final elapsedSeconds = now.difference(_powerBoostStartTime!).inSeconds;
    final remainingSeconds =
        (POWER_BOOST_DURATION_MINUTES * 60) - elapsedSeconds;

    if (remainingSeconds <= 0) return '';

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadUserProfile();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user profile: ${e.toString()}';
        });
      }
    }
  }

  void _loadSavedSettings() {
    // Implement the logic to load saved settings from SharedPreferences
  }

  void _startAdReloadTimer() {
    _adReloadTimer?.cancel();
    _adReloadTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        // _loadAds(); // Removed as only rewarded ads are used
      }
    });
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted && _isMining) {
        // _showRewardedAd(); // Auto-call hata diya gaya hai (AdMob policy compliance)
      }
    });
  }

  Future<void> _startPowerBoost() async {
    if (!mounted || !_isMining) return;
    try {
      // Show rewarded ad using AdService
      final bool adWatched = await _adService.showRewardedAd(
        onRewarded: (double amount) async {
          if (!mounted) return;
          // Power up sound bajao
          await SoundNotificationService.playSciFiPowerUpSound();
          // Power boost start hone se pehle earning update karo
          _updateMiningProgressFromElapsed();
          setState(() {
            _isPowerBoostActive = true;
            _powerBoostClickCount++;

            // Calculate new multiplier
            if (_powerBoostClickCount == 1) {
              _currentPowerBoostMultiplier = INITIAL_POWER_BOOST_RATE;
            } else {
              _currentPowerBoostMultiplier += POWER_BOOST_INCREMENT;
            }

            // Update mining rate with new multiplier
            _currentMiningRate =
                BASE_MINING_RATE * (1 + _currentPowerBoostMultiplier);
            _hashRate = 2.5 * (1 + _currentPowerBoostMultiplier);
            _powerBoostStartTime = DateTime.now();
          });

          // Show boost activation message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Auto Power Boost activated! Mining rate increased by ${(_currentPowerBoostMultiplier * 100).toStringAsFixed(0)}%\n'
                  'New rate: ${_currentMiningRate.toStringAsFixed(18)} BTC/sec\n'
                  'New hash rate: ${_hashRate.toStringAsFixed(1)} GH/s\n'
                  'Duration: 5 minutes',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Start power boost timer
          _powerBoostTimer?.cancel();
          _powerBoostTimer = Timer(
            const Duration(minutes: POWER_BOOST_DURATION_MINUTES),
            () {
              if (!mounted) return;
              setState(() {
                _isPowerBoostActive = false;
                _currentPowerBoostMultiplier = 0.0;
                _hashRate = 2.5;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Power Boost ended! Mining rate back to normal',
                      style: TextStyle(fontSize: 16),
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          );

          // Save state immediately after power boost activation
          _saveMiningState();
        },
        onAdDismissed: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Watch the full ad to activate Power Boost!'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
      if (!adWatched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error activating power boost: \\${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Restore navigation and tap handler functions
  void _navigateToWalletScreen() {
    Navigator.of(context).pushNamed('/wallet');
  }

  void _onSciFiObjectTapped() async {
    // Prevent multiple taps while loading
    if (_isSciFiLoading) return;

    // Check if widget is still mounted
    if (!mounted) return;

    try {
      setState(() {
        _isSciFiLoading = true;
        _percentage = (_percentage + 1) % 100;
        _currentColor =
            _currentColor == Colors.blue ? Colors.purple : Colors.blue;
        _sciFiTapCount++;
      });

      // Add reward safely
      try {
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.addEarning(
          TAP_REWARD_RATE,
          type: 'tap',
          description: 'Tap reward',
        );

        // Play different sci-fi sounds based on tap count
        try {
          if (_sciFiTapCount % 10 == 0) {
            // Every 10th tap - achievement sound
            await SoundNotificationService.playSciFiAchievementSound();
          } else if (_sciFiTapCount % 5 == 0) {
            // Every 5th tap - power up sound
            await SoundNotificationService.playSciFiPowerUpSound();
          }
        } catch (soundError) {}

        // Show different messages based on tap count
        if (mounted) {
          String message =
              '🚀 Magic tapped! +${TAP_REWARD_RATE.toStringAsFixed(18)} BTC';
          Color backgroundColor = Colors.green;

          if (_sciFiTapCount % 10 == 0) {
            message =
                '🏆 Achievement Unlocked! +${TAP_REWARD_RATE.toStringAsFixed(18)} BTC';
            backgroundColor = Colors.amber;
          } else if (_sciFiTapCount % 5 == 0) {
            message = '⚡ Power Up! +${TAP_REWARD_RATE.toStringAsFixed(18)} BTC';
            backgroundColor = Colors.orange;
          }

          Fluttertoast.showToast(
            msg: message,
            backgroundColor: backgroundColor,
            textColor: Colors.white,
          );
        }
      } catch (rewardError) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Failed to add tap reward. Please try again.',
            backgroundColor: Colors.red,
          );
        }
      }

      // Save percentage safely
      try {
        await _savePercentage();
      } catch (saveError) {}

      // Show rewarded ad every 5 taps
      if (_sciFiTapCount >= 5) {
        _sciFiTapCount = 0;

        try {
          final bool adWatched = await _adService.showRewardedAd(
            onRewarded: (double amount) async {
              if (!mounted) return;

              try {
                const double adReward = 0.000000000000000500;
                final walletProvider =
                    Provider.of<WalletProvider>(context, listen: false);
                await walletProvider.addEarning(
                  adReward,
                  type: 'ad_reward',
                  description: 'Sci-Fi Ad Reward (5x Bonus)',
                );

                // Play sci-fi achievement sound safely
                try {
                  await SoundNotificationService.playSciFiAchievementSound();
                } catch (soundError) {}

                if (mounted) {
                  Fluttertoast.showToast(
                    msg:
                        '🎉 Ad reward earned! +${adReward.toStringAsFixed(18)} BTC',
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                }
              } catch (adRewardError) {
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: 'Failed to add ad reward. Please try again.',
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
            onAdDismissed: () {
              if (!mounted) return;
              Fluttertoast.showToast(
                msg: 'Watch the full ad to get a bonus!',
                backgroundColor: Colors.orange,
              );
            },
          );

          if (!adWatched && mounted) {
            Fluttertoast.showToast(
              msg: 'Ad not available. Please try again later.',
              backgroundColor: Colors.orange,
            );
          }
        } catch (adError) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Error showing ad. Please try again.',
              backgroundColor: Colors.red,
            );
          }
        }
      }
    } catch (generalError) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() {
          _isSciFiLoading = false;
        });
      }
    }
  }

  void _navigateToRewardScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RewardScreen()),
    );
  }

  void _navigateToReferralScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ReferralScreen()),
    );
  }

  void _navigateToGameScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  void _handleNavigation() {
    FocusScope.of(context).unfocus();
  }

  // Initialize audio player settings

  Future<void> _savePendingEarnings() async {
    try {
      // Only save tap earnings periodically, NOT mining earnings
      // Mining earnings should only be saved when mining session completes

      // Note: Tap rewards are already added immediately in _onSciFiObjectTapped()
      // So we don't need to add them again here
      // This method is kept for any future pending earnings that might need periodic saving
    } catch (e) {}
  }

  void _startPeriodicSaveTimer() {
    _periodicSaveTimer?.cancel();
    _periodicSaveTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _savePendingEarnings();
      }
    });
  }

  // Start server connection simulation
  void _startServerConnectionSimulation() {
    setState(() {
      _isConnectingToServer = true;
      _isServerConnected = false;
    });

    // Simulate connection process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isConnectingToServer = false;
          _isServerConnected = true;
        });
      }
    });
  }
}
