import 'dart:async'; // For Timer
import 'dart:io' show exit, Platform;

import 'package:audioplayers/audioplayers.dart'; // For AudioPlayer
import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
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
      0.000000000000005000; // 5x increased reward

  // Variables
  final AdService _adService = AdService();
  double _hashRate = 2.5;
  bool _isMining = false;
  Timer? _miningTimer;
  Timer? _powerBoostTimer;
  int _percentage = 0;
  double _miningEarnings = 0.0;
  late AudioPlayer _audioPlayer;
  DateTime? _miningStartTime;
  DateTime? _powerBoostStartTime;
  Color? _currentColor;
  double _miningProgress = 0.0;
  bool _isSoundEnabled = true;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioPlayer = AudioPlayer();
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
        if (_isMining && _miningStartTime != null) {
          _updateMiningProgressFromElapsed();
          _startMiningUiTimer();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background - save state
        if (_isMining) {
          _saveMiningState();
        }
        break;
      case AppLifecycleState.detached:
        // App terminated
        if (_isMining) {
          _saveMiningState();
        }
        break;
    }
  }

  @override
  void dispose() {
    // Save any pending earnings before disposing
    _savePendingEarnings();

    _cancelAllTimers();
    _uiUpdateTimer?.cancel();
    _periodicSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _scrollController.dispose();
    try {
      _adService.dispose();
    } catch (e) {
      debugPrint('Ad dispose error: $e');
    }
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
      debugPrint('✅ Wallet balance loaded successfully');
    } catch (e) {
      debugPrint('Error initializing app: $e');

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
          await _resetMiningState();
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
      });
      await _saveMiningState();
      _startMiningUiTimer();
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
    _cancelAllTimers();
    _uiUpdateTimer?.cancel();
    // Store earnings before resetting state
    final double earningsToAdd = _miningEarnings;
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
    final elapsedSeconds = now.difference(_miningStartTime!).inSeconds;
    final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
    final miningRate = BASE_MINING_RATE *
        (1 + (_isPowerBoostActive ? _currentPowerBoostMultiplier : 0.0));
    final earnings = miningRate * elapsedSeconds;
    setState(() {
      _currentMiningRate = miningRate;
      _miningEarnings = double.parse(earnings.toStringAsFixed(18));
      _miningProgress = (elapsedMinutes / MINING_DURATION_MINUTES) * 100;
      if (_miningProgress > 100) _miningProgress = 100;
    });
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
      final bool loadedIsSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
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
        // Calculate total earnings for the session
        const double miningRate = BASE_MINING_RATE; // No boost after reload
        final double earningsToAdd = double.parse(
            (miningRate * (MINING_DURATION_MINUTES * 60)).toStringAsFixed(18));
        if (earningsToAdd > 0) {
          try {
            final walletProvider = context.read<WalletProvider>();
            await walletProvider.addEarning(
              earningsToAdd,
              type: 'mining',
              description: 'Mining session earnings (auto on reload)',
            );
          } catch (e) {
            // Optionally log error
          }
        }
      }

      setState(() {
        _isSoundEnabled = loadedIsSoundEnabled;
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
        await _resetMiningState();
      } else if (powerBoostExpired && _isMining) {
        // If only power boost expired, save state to update prefs
        await _saveMiningState();
      }

      if (_isSoundEnabled) {
        await _initializeAudio();
      }
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
    } catch (e) {
      // Optionally log error
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Save any pending earnings before exit
          await _savePendingEarnings();

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
              content: const Text(
                'Are you sure you want to exit the app?\n\nYour earnings have been saved.',
                style: TextStyle(fontSize: 16),
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
      child: _buildHomeScaffold(),
    );
  }

  Widget _buildHomeScaffold() {
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
            buildGameSection(),
            const SizedBox(height: 16),
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
                        ],
                      ),
                      child: _isSciFiLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : const Center(
                              child: Icon(
                                Icons.memory,
                                size: 60,
                                color: Colors.white,
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
                'Follow us for daily coupon! Catch up to 10,000\u0024 Bitcoin.\nWe share daily deposit coupons.',
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
                'Win Real Bitcoin!',
                style: TextStyle(
                  fontSize: 24,
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
            'Try your luck and earn real Bitcoin rewards through fun games!',
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
    _adTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && _isMining) {
        _showRewardedAd();
      }
    });
  }

  Future<void> _showRewardedAd() async {
    try {
      final rewardedAd = await _adService.getRewardedAd();
      if (rewardedAd != null && mounted) {
        await rewardedAd.show(
          onUserEarnedReward: (_, reward) {
            // Apply mining boost
            setState(() {
              _isPowerBoostActive = true;
              _currentPowerBoostMultiplier = 2.0;
            });

            // Start power boost timer
            _powerBoostTimer?.cancel();
            _powerBoostTimer = Timer(
                const Duration(minutes: POWER_BOOST_DURATION_MINUTES), () {
              if (!mounted) return;

              setState(() {
                _isPowerBoostActive = false;
                _currentPowerBoostMultiplier = 0.0;
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
            });
          },
        );
      }
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
    }
  }

  Future<void> _startPowerBoost() async {
    if (!mounted || !_isMining) return;

    try {
      // Show rewarded ad using AdService
      final bool adWatched = await _adService.showRewardedAd(
        onRewarded: (double amount) async {
          if (!mounted) return;

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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Power Boost activated! Mining rate increased by \\${(_currentPowerBoostMultiplier * 100).toStringAsFixed(0)}%\\n'
                'New rate: \\${_currentMiningRate.toStringAsFixed(18)} BTC/sec\\n'
                'New hash rate: \\${_hashRate.toStringAsFixed(1)} GH/s\\n'
                'Duration: 5 minutes',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Start power boost timer
          _powerBoostTimer?.cancel();
          _powerBoostTimer =
              Timer(const Duration(minutes: POWER_BOOST_DURATION_MINUTES), () {
            if (!mounted) return;

            setState(() {
              _isPowerBoostActive = false;
              _currentPowerBoostMultiplier = 0.0;
              _powerBoostClickCount = 0;
              _currentMiningRate = BASE_MINING_RATE;
              _hashRate = 2.5;
              _powerBoostStartTime = null;
            });

            if (!mounted) return;
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
          });

          // Save state immediately after power boost activation
          await _saveMiningState();
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
      debugPrint('Power boost error: $e');
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
    if (_isSciFiLoading) return;

    setState(() {
      _isSciFiLoading = true;
      _percentage = (_percentage + 1) % 100;
      _currentColor =
          _currentColor == Colors.blue ? Colors.purple : Colors.blue;
      _sciFiTapCount++;
    });

    // तुरंत reward add करें
    try {
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.addEarning(
        TAP_REWARD_RATE,
        type: 'tap',
        description: 'Tap reward',
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Magic tapped! +${TAP_REWARD_RATE.toStringAsFixed(18)} BTC',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding tap reward: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to add tap reward: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      }
    }

    // Percentage save करें
    _savePercentage();

    // Show rewarded ad every 5 taps with proper reward
    if (_sciFiTapCount >= 5) {
      _sciFiTapCount = 0;

      try {
        debugPrint('🎬 Showing rewarded ad for sci-fi tap...');
        final bool adWatched = await _adService.showRewardedAd(
          onRewarded: (double amount) async {
            if (!mounted) return;

            try {
              // Ad reward add करें (5x normal reward)
              const double adReward = 0.000000000000000500;
              final walletProvider = context.read<WalletProvider>();
              await walletProvider.addEarning(
                adReward,
                type: 'ad_reward',
                description: 'Sci-Fi Ad Reward (5x Bonus)',
              );

              if (mounted) {
                Fluttertoast.showToast(
                  msg:
                      '🎉 Ad reward earned! +${adReward.toStringAsFixed(18)} BTC',
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              }
            } catch (e) {
              debugPrint('❌ Error adding ad reward: $e');
              if (mounted) {
                Fluttertoast.showToast(
                  msg: 'Failed to add ad reward: ${e.toString()}',
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
      } catch (e) {
        debugPrint('❌ Error showing rewarded ad: $e');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Error showing ad: ${e.toString()}',
            backgroundColor: Colors.red,
          );
        }
      }
    }

    // Loading को बंद करें
    if (mounted) {
      setState(() {
        _isSciFiLoading = false;
      });
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
  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setVolume(1.0);
      // Optionally preload a sound or set other audio settings here
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  Future<void> _savePendingEarnings() async {
    try {
      // Save any pending earnings to wallet
      if (_miningEarnings > 0 && _isMining) {
        debugPrint('💾 Saving pending mining earnings: $_miningEarnings BTC');
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.addEarning(
          _miningEarnings,
          type: 'mining',
          description: 'Mining earnings (saved on exit)',
        );
        debugPrint('✅ Pending earnings saved successfully');
      }

      // Save any pending tap earnings
      if (_sciFiTapCount > 0) {
        debugPrint('💾 Saving pending tap earnings');
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.addEarning(
          TAP_REWARD_RATE * _sciFiTapCount,
          type: 'tap',
          description: 'Tap earnings (saved on exit)',
        );
        debugPrint('✅ Tap earnings saved successfully');
      }
    } catch (e) {
      debugPrint('❌ Error saving pending earnings: $e');
    }
  }

  void _startPeriodicSaveTimer() {
    _periodicSaveTimer?.cancel();
    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _savePendingEarnings();
      }
    });
  }
}
