import 'dart:async'; // For Timer
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart'; // For AudioPlayer
import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/custom_ad_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
  static const double TAP_REWARD_RATE = 0.000000000000001000;
  static const int STATE_SAVE_INTERVAL_SECONDS = 30;

  // Variables
  final CustomAdService _adService = CustomAdService();
  double _hashRate = 2.5;
  bool _isMining = false;
  Timer? _miningTimer;
  Timer? _powerBoostTimer;
  int _percentage = 0;
  int _tapCount = 0;
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

  bool _isVibrationEnabled = true;
  bool _isDarkMode = false;

  // Add static variables to maintain state across screen changes
  static bool _staticIsMining = false;
  static DateTime? _staticMiningStartTime;
  static double _staticMiningProgress = 0.0;
  static double _staticMiningEarnings = 0.0;
  static double _staticCurrentMiningRate = BASE_MINING_RATE;
  static double _staticHashRate = 2.5;
  static bool _staticIsPowerBoostActive = false;
  static double _staticCurrentPowerBoostMultiplier = 0.0;
  static Timer? _staticMiningTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Restore state from static variables
    setState(() {
      _isMining = _staticIsMining;
      _miningStartTime = _staticMiningStartTime;
      _miningProgress = _staticMiningProgress;
      _miningEarnings = _staticMiningEarnings;
      _currentMiningRate = _staticCurrentMiningRate;
      _hashRate = _staticHashRate;
      _isPowerBoostActive = _staticIsPowerBoostActive;
      _currentPowerBoostMultiplier = _staticCurrentPowerBoostMultiplier;
    });

    _audioPlayer = AudioPlayer();
    _initializeData();
    _loadUserProfile();
    _initializeMining();
    _loadPercentage();
    _loadAds();
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
          final now = DateTime.now();
          final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;

          if (elapsedMinutes >= MINING_DURATION_MINUTES) {
            // Complete mining if time is up
            print('Mining duration completed, finalizing earnings');
            _resetMiningState();
          } else {
            // Resume mining if not completed
            if (kIsWeb) {
              _startWebMining();
            } else if (Platform.isWindows) {
              _startForegroundMining();
            } else {
              _startMiningTimer();
            }
          }
        }
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background - save state and continue mining
        if (_isMining) {
          _saveMiningState();
        }
        break;

      case AppLifecycleState.detached:
        // App terminated
        if (_isMining) {
          print('App terminated, saving final mining state');
          _saveMiningState();
        }
        break;
    }
  }

  @override
  void dispose() {
    // Save state to static variables
    _staticIsMining = _isMining;
    _staticMiningStartTime = _miningStartTime;
    _staticMiningProgress = _miningProgress;
    _staticMiningEarnings = _miningEarnings;
    _staticCurrentMiningRate = _currentMiningRate;
    _staticHashRate = _hashRate;
    _staticIsPowerBoostActive = _isPowerBoostActive;
    _staticCurrentPowerBoostMultiplier = _currentPowerBoostMultiplier;

    // Only cancel timers if app is being closed, not during navigation
    if (!mounted) {
      _cancelAllTimers();
      _staticMiningTimer?.cancel();
    }

    // Remove observer and dispose resources
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _scrollController.dispose();

    try {
      _adService.dispose();
    } catch (e) {
      print('Ad dispose error: $e');
    }

    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    try {
      // Initialize all processes silently
      await _initializeData();
      await _loadUserProfile();
      _initializeMining();
      await _loadPercentage();
      await _loadAds();

      // Get wallet balance from backend
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.loadWallet();
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
        _isVibrationEnabled = prefs.getBool('isVibrationEnabled') ?? true;
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
        _isMining = prefs.getBool('isMining') ?? false;
        _miningStartTime = prefs.getString('miningStartTime') != null
            ? DateTime.parse(prefs.getString('miningStartTime')!)
            : null;
        _miningProgress = prefs.getDouble('miningProgress') ?? 0.0;
        _miningEarnings = prefs.getDouble('miningEarnings') ?? 0.0;
        _miningStatus = prefs.getString('miningStatus') ?? 'Inactive';
        _currentMiningRate =
            prefs.getDouble('currentMiningRate') ?? BASE_MINING_RATE;
        _lastMiningTime = prefs.getInt('lastMiningTime') ?? 0;
        _isPowerBoostActive = prefs.getBool('powerBoostActive') ?? false;
        _currentPowerBoostMultiplier =
            prefs.getDouble('currentPowerBoostMultiplier') ?? 0.0;
        _powerBoostClickCount = prefs.getInt('powerBoostClickCount') ?? 0;
        _powerBoostStartTime = prefs.getString('powerBoostStartTime') != null
            ? DateTime.parse(prefs.getString('powerBoostStartTime')!)
            : null;
        _hashRate = prefs.getDouble('hashRate') ?? 2.5;
      });

      // Initialize audio only if sound is enabled
      if (_isSoundEnabled) {
        await _initializeAudio();
      }
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  Future<void> _initializeAudio() async {
    if (!mounted) return;

    try {
      await _audioPlayer.dispose();
      _audioPlayer = AudioPlayer();

      // Web platform check
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _isSoundEnabled = false;
          });
        }
        return;
      }

      // Mobile platform check
      bool isSupportedPlatform = false;
      try {
        if (!kIsWeb) {
          isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
        }
      } catch (e) {
        print('Platform check error: $e');
        return;
      }

      if (isSupportedPlatform) {
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.setVolume(0.5);

        bool audioLoaded = false;

        // Try loading main audio file first
        const audioPath = 'audio/reward_sound.mp3';
        try {
          final source = AssetSource(audioPath);
          await _audioPlayer.setSource(source);
          audioLoaded = true;
        } catch (e) {
          print('Main audio file error: $e');
        }

        // Try backup file if main file fails
        if (!audioLoaded) {
          const backupAudioPath = 'audio/collect.mp3';
          try {
            final backupSource = AssetSource(backupAudioPath);
            await _audioPlayer.setSource(backupSource);
            audioLoaded = true;
          } catch (e) {
            print('Backup audio file error: $e');
          }
        }

        if (!audioLoaded && mounted) {
          setState(() {
            _isSoundEnabled = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isSoundEnabled = false;
        });
      }
    } catch (e) {
      print('Audio initialization error: $e');
      if (mounted) {
        setState(() {
          _isSoundEnabled = false;
        });
      }
    }
  }

  void _cancelAllTimers() {
    // Cancel all timers
    _miningTimer?.cancel();
    _adTimer?.cancel();
    _adReloadTimer?.cancel();
    _powerBoostTimer?.cancel();
    _staticMiningTimer?.cancel();

    // Reset timer variables
    _miningTimer = null;
    _adTimer = null;
    _adReloadTimer = null;
    _powerBoostTimer = null;
    _staticMiningTimer = null;
  }

  Future<void> _saveMiningState() async {
    if (!mounted) {
      print('Widget not mounted, skipping state save');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_isMining && _miningStartTime != null) {
        // Save essential mining state
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
        }
        await prefs.setString('miningStatus', _miningStatus);
        await prefs.setInt('lastMiningTime', _lastMiningTime);

        print('Mining state saved successfully');
      }
    } catch (e) {
      print('Mining state save error: $e');
    }
  }

  void _playMiningSound() async {
    if (!_isSoundEnabled || !mounted) return;

    // Skip sound on web platform
    if (kIsWeb) return;

    // Skip sound on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // Try playing main audio file first
      const audioPath = 'audio/reward_sound.mp3';
      try {
        final source = AssetSource(audioPath);
        await _audioPlayer.play(source).timeout(
              const Duration(seconds: 2),
              onTimeout: () => null,
            );
        return;
      } catch (e) {
        print('Main sound play error: $e');
      }

      // Try backup file if main file fails
      const backupAudioPath = 'audio/collect.mp3';
      try {
        final backupSource = AssetSource(backupAudioPath);
        await _audioPlayer.play(backupSource).timeout(
              const Duration(seconds: 2),
              onTimeout: () => null,
            );
      } catch (e) {
        print('Backup sound play error: $e');
        if (mounted) {
          setState(() {
            _isSoundEnabled = false;
          });
        }
      }
    } catch (e) {
      print('Sound play error: $e');
      if (mounted) {
        setState(() {
          _isSoundEnabled = false;
        });
      }
    }
  }

  Future<void> _loadPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _percentage = prefs.getInt('sci_fi_tap_percentage') ?? 0;
    });
  }

  Future<void> _savePercentage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sci_fi_tap_percentage', _percentage);
    await _saveDataToPreferences();
  }

  void _onSciFiObjectTapped() async {
    if (!mounted) return;

    const double rewardAmount = TAP_REWARD_RATE;

    try {
      // Show rewarded ad every 10 taps
      if (_tapCount % 10 == 0) {
        // Show loading dialog after ad
        final success = await _adService.showRewardedAd(
          onRewarded: (reward) async {
            // Show loading dialog after ad is watched
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              );
            }

            // Double the reward when ad is watched
            const double finalReward = rewardAmount * 2;
            setState(() {
              _tapCount++;
              _percentage++;
              if (_percentage > 100) _percentage = 0;
            });
            await _savePercentage(); // Save percentage after update
            await _saveDataToPreferences(); // Save other data

            if (mounted) {
              try {
                final walletProvider = context.read<WalletProvider>();
                await walletProvider.addEarning(
                  finalReward,
                  type: 'tap',
                  description: 'Sci-Fi Object Tap Reward (Ad Bonus)',
                );

                // Close loading dialog before showing congratulations
                if (mounted) Navigator.pop(context);

                // Show congratulations dialog
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.blue[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        '🎉 Congratulations!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'You won',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${finalReward.toStringAsFixed(18)} BTC',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      actions: [
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isSoundEnabled) {
                  const audioPath = 'audio/reward_sound.mp3';
                  final source = AssetSource(audioPath);

                  try {
                    if (_audioPlayer.source == null) {
                      await _audioPlayer.setSource(source);
                    }
                    await _audioPlayer.play(source).timeout(
                      const Duration(seconds: 2),
                      onTimeout: () {
                        print('Timeout playing tap sound');
                        return;
                      },
                    );
                  } catch (e) {
                    print('Error playing sound: $e');
                  }
                }
              } catch (e) {
                print('Error adding earning: $e');
                // Close loading dialog if there's an error
                if (mounted) Navigator.pop(context);
              }
            }
          },
          onAdDismissed: () {
            // Show loading dialog after ad is dismissed
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              );
            }
            // Show regular reward if ad is dismissed
            _addRegularReward(rewardAmount);
          },
        );

        if (!success) {
          // Show loading dialog if ad fails to load
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              ),
            );
          }
          // Show regular reward if ad fails to load
          _addRegularReward(rewardAmount);
        }
      } else {
        // Show loading dialog for regular reward
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
          );
        }
        // Regular reward without ad
        _addRegularReward(rewardAmount);
      }
    } catch (e) {
      print('Error in _onSciFiObjectTapped: $e');
      // Ensure loading dialog is closed in case of any error
      if (mounted) Navigator.pop(context);
    }
  }

  // Add new method for regular reward
  Future<void> _addRegularReward(double rewardAmount) async {
    setState(() {
      _tapCount++;
      _percentage++;
      if (_percentage > 100) _percentage = 0;
    });
    await _savePercentage(); // Save percentage after update
    await _saveDataToPreferences(); // Save other data

    if (mounted) {
      try {
        final walletProvider = context.read<WalletProvider>();
        await walletProvider.addEarning(
          rewardAmount,
          type: 'tap',
          description: 'Sci-Fi Object Tap Reward',
        );

        // Close loading dialog before showing congratulations
        if (mounted) Navigator.pop(context);

        // Show congratulations dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.blue[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🎉 Congratulations!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You won',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${rewardAmount.toStringAsFixed(18)} BTC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (_isSoundEnabled) {
          const audioPath = 'audio/reward_sound.mp3';
          final source = AssetSource(audioPath);

          try {
            if (_audioPlayer.source == null) {
              await _audioPlayer.setSource(source);
            }
            await _audioPlayer.play(source).timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                print('Timeout playing tap sound');
                return;
              },
            );
          } catch (e) {
            print('Error playing sound: $e');
          }
        }
      } catch (e) {
        print('Error adding earning: $e');
        // Close loading dialog if there's an error
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _handleNavigation() {
    // Don't stop mining during navigation, just save state
    if (_isMining) {
      _saveMiningState();
    }
  }

  void _navigateToWalletScreen() async {
    if (mounted) {
      Navigator.pushNamed(context, '/wallet');
    }
  }

  void _navigateToGameScreen() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }

  void _navigateToRewardScreen() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RewardScreen()),
      );
    }
  }

  void _navigateToReferralScreen() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReferralScreen()),
      );
    }
  }

  Future<void> _loadAds() async {
    // Platform check
    bool isSupportedPlatform = false;
    try {
      isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      print('Platform check error: $e');
      return;
    }

    if (isSupportedPlatform) {
      try {
        await _adService.loadNativeAd();
      } catch (e) {
        print('Ads loading error: $e');
      }
    } else {
      print('Ads only supported on Android and iOS');
    }
  }

  Future<void> _resetMiningState() async {
    print('Resetting mining state');

    // Cancel all timers first
    _cancelAllTimers();
    _staticMiningTimer?.cancel();
    _staticMiningTimer = null;

    // Reset static variables
    _staticIsMining = false;
    _staticMiningStartTime = null;
    _staticMiningProgress = 0.0;
    _staticCurrentMiningRate = BASE_MINING_RATE;
    _staticHashRate = 2.5;
    _staticIsPowerBoostActive = false;
    _staticCurrentPowerBoostMultiplier = 0.0;
    _staticMiningEarnings = 0.0;

    // Reset instance variables
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

    // Save state
    await _saveMiningState();

    // Show completion message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Mining session completed! You can start a new session now.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _startMiningTimer() {
    print('Starting mining timer');
    _cancelAllTimers();

    if (_miningStartTime == null) {
      print('No mining start time, cannot start timer');
      return;
    }

    // Use static timer if it exists and is active
    if (_staticMiningTimer != null && _staticMiningTimer!.isActive) {
      _miningTimer = _staticMiningTimer;
      return;
    }

    // Create new timer
    _staticMiningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_staticIsMining || _staticMiningStartTime == null) {
        timer.cancel();
        _staticMiningTimer = null;
        return;
      }

      final now = DateTime.now();
      final elapsedMinutes = now.difference(_staticMiningStartTime!).inMinutes;

      if (elapsedMinutes >= MINING_DURATION_MINUTES) {
        print('Mining duration completed');
        timer.cancel();
        _staticMiningTimer = null;
        _resetMiningState();
        return;
      }

      // Update both static and instance variables
      _staticMiningEarnings += _staticCurrentMiningRate;
      _staticMiningEarnings =
          double.parse(_staticMiningEarnings.toStringAsFixed(18));
      _staticMiningProgress = (elapsedMinutes / MINING_DURATION_MINUTES) * 100;

      // Update UI if mounted
      if (mounted) {
        setState(() {
          _isMining = _staticIsMining;
          _miningStartTime = _staticMiningStartTime;
          _miningProgress = _staticMiningProgress;
          _miningEarnings = _staticMiningEarnings;
          _currentMiningRate = _staticCurrentMiningRate;
          _hashRate = _staticHashRate;
          _isPowerBoostActive = _staticIsPowerBoostActive;
          _currentPowerBoostMultiplier = _staticCurrentPowerBoostMultiplier;
        });
      }

      // Save state periodically
      if (_lastMiningTime % STATE_SAVE_INTERVAL_SECONDS == 0) {
        _saveMiningState();
      }

      // Play sound if enabled and mounted
      if (_isSoundEnabled && mounted) {
        _playMiningSound();
      }
    });

    _miningTimer = _staticMiningTimer;
  }

  void _startForegroundMining() {
    print('Starting foreground mining');
    _cancelAllTimers();

    // Set mining start time
    _miningStartTime = DateTime.now();

    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_isMining) {
        timer.cancel();
        return;
      }

      // Check if 30 minutes have passed
      final now = DateTime.now();
      final miningDuration = now.difference(_miningStartTime!).inMinutes;

      if (miningDuration >= MINING_DURATION_MINUTES) {
        print('Mining session completed after $miningDuration minutes');
        timer.cancel();
        _resetMiningState();
        return;
      }

      // Use setState only if widget is mounted
      if (mounted) {
        setState(() {
          // Calculate current mining rate with power boost multiplier
          _currentMiningRate = BASE_MINING_RATE *
              (1 + (_isPowerBoostActive ? _currentPowerBoostMultiplier : 0.0));

          // Add earnings based on current rate
          _miningEarnings += _currentMiningRate;
          _miningEarnings = double.parse(_miningEarnings.toStringAsFixed(18));

          // Update progress
          _miningProgress = (miningDuration / MINING_DURATION_MINUTES) * 100;
          _lastMiningTime++;
          _totalMiningTime++;
        });
      }

      // Save state every STATE_SAVE_INTERVAL_SECONDS seconds
      if (_lastMiningTime % STATE_SAVE_INTERVAL_SECONDS == 0) {
        await _saveMiningState();
      }

      // Play mining sound if enabled and mounted
      if (_isSoundEnabled && mounted) {
        _playMiningSound();
      }
    });
  }

  void _startWebMining() {
    print('Starting web mining');
    _cancelAllTimers();

    // Set mining start time if not set
    _miningStartTime ??= DateTime.now();

    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_isMining) {
        timer.cancel();
        return;
      }

      // Calculate mining duration
      final now = DateTime.now();
      final miningDuration = now.difference(_miningStartTime!).inMinutes;

      // Check if mining session is complete
      if (miningDuration >= MINING_DURATION_MINUTES) {
        print('Mining session completed after $miningDuration minutes');
        timer.cancel();
        _resetMiningState();
        return;
      }

      setState(() {
        // Calculate current mining rate with power boost multiplier
        _currentMiningRate = BASE_MINING_RATE *
            (1 + (_isPowerBoostActive ? _currentPowerBoostMultiplier : 0.0));

        // Add earnings based on current rate
        _miningEarnings += _currentMiningRate;
        _miningEarnings = double.parse(_miningEarnings.toStringAsFixed(18));

        // Update progress
        _miningProgress = (miningDuration / MINING_DURATION_MINUTES) * 100;
        _lastMiningTime++;
        _totalMiningTime++;
      });

      // Save state every STATE_SAVE_INTERVAL_SECONDS seconds
      if (_lastMiningTime % STATE_SAVE_INTERVAL_SECONDS == 0) {
        await _saveMiningState();
        print(
            'Mining earnings updated: ${_miningEarnings.toStringAsFixed(18)} BTC');
      }

      // Play mining sound if enabled
      if (_isSoundEnabled && mounted) {
        _playMiningSound();
      }
    });
  }

  Future<void> _startMiningProcess() async {
    try {
      // Check if previous mining session is still active
      if (_isMining && _miningStartTime != null) {
        final now = DateTime.now();
        final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;

        if (elapsedMinutes < MINING_DURATION_MINUTES) {
          print('Previous mining session still active');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait ${MINING_DURATION_MINUTES - elapsedMinutes} minutes for current session to complete',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        } else {
          // Complete previous session if time is up
          _resetMiningState();
        }
      }

      // Start new mining session
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

      // Save initial state
      await _saveMiningState();
      print('New mining session started at: ${now.toIso8601String()}');

      // Start appropriate mining based on platform
      if (kIsWeb) {
        _startWebMining();
      } else if (Platform.isWindows) {
        _startForegroundMining();
      } else {
        _startMiningTimer();
      }

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
      print('Start mining error: $e');
      _showError('Start Mining Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
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
                          color: Colors.black.withValues(alpha: 102),
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 26),
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
                                color: const Color(0xFF00F5A0)
                                    .withValues(alpha: 102),
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
                          if (_isMining)
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
                        child: const Center(
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
                      const telegramUrl = 'https://www.telegram.com';
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
                      const instagramUrl = 'https://www.instagram.com';
                      final Uri instagramUri = Uri.parse(instagramUrl);
                      if (await launchUrl(instagramUri)) {
                        await launchUrl(instagramUri);
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Could not open Instagram.');
                      }
                    },
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp,
                        color: Colors.green, size: 36),
                    onPressed: () async {
                      const whatsappUrl = 'https://www.whatsapp.com';
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
                  'Contact Us After Withdraw, We Are on Duty',
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
                            color:
                                _lastError != null ? Colors.red : Colors.blue,
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
    if (!_isMining || _miningStartTime == null) return '';

    final now = DateTime.now();
    final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
    final remainingMinutes = MINING_DURATION_MINUTES - elapsedMinutes;

    if (remainingMinutes <= 0) return 'Completed';

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

  Future<void> _initializeMining() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Reset mining state on app start
      await prefs.setBool('isMining', false);
      await prefs.setString('miningStartTime', '');
      await prefs.setDouble('miningProgress', 0.0);
      await prefs.setDouble('miningEarnings', 0.0);
      await prefs.setString('miningStatus', 'Inactive');
      await prefs.setDouble('currentMiningRate', BASE_MINING_RATE);
      await prefs.setInt('lastMiningTime', 0);
      await prefs.setBool('powerBoostActive', false);
      await prefs.setDouble('currentPowerBoostMultiplier', 0.0);
      await prefs.setInt('powerBoostClickCount', 0);
      await prefs.setString('powerBoostStartTime', '');
      await prefs.setDouble('hashRate', 2.5);

      setState(() {
        _isMining = false;
        _miningStartTime = null;
        _miningProgress = 0.0;
        _miningEarnings = 0.0;
        _miningStatus = 'Inactive';
        _currentMiningRate = BASE_MINING_RATE;
        _lastMiningTime = 0;
        _totalMiningTime = 0;
        _isPowerBoostActive = false;
        _currentPowerBoostMultiplier = 0.0;
        _powerBoostClickCount = 0;
        _powerBoostStartTime = null;
        _hashRate = 2.5;
      });
    } catch (e) {
      print('Error initializing mining: $e');
    }
  }

  Future<void> _saveDataToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final btcBalance = context.read<WalletProvider>().btcBalance;
    await prefs.setDouble('btcBalance', btcBalance);
    await prefs.setInt('tapCount', _tapCount);
    await prefs.setBool('isSoundEnabled', _isSoundEnabled);
    await prefs.setBool('isVibrationEnabled', _isVibrationEnabled);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void _loadSavedSettings() {
    // Implement the logic to load saved settings from SharedPreferences
  }

  void _startAdReloadTimer() {
    _adReloadTimer?.cancel();
    _adReloadTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _loadAds();
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
      print('Error showing rewarded ad: $e');
    }
  }

  Future<void> _startPowerBoost() async {
    if (!mounted || !_isMining) return;

    try {
      // Show rewarded ad using CustomAdService
      final bool adWatched = await _adService.showRewardedAd(
        onRewarded: (double amount) async {
          // After ad is watched, activate power boost
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Power Boost activated! Mining rate increased by ${(_currentPowerBoostMultiplier * 100).toStringAsFixed(0)}%\n'
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

          // Save state immediately after power boost activation
          await _saveMiningState();
        },
        onAdDismissed: () {
          // What to do when ad is closed without reward
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Watch the full ad to activate Power Boost!'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );

      if (!adWatched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not available. Please try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Power boost error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating power boost: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
