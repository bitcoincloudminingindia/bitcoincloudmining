import 'dart:async';

import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/sound_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HashRushGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const HashRushGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  _HashRushGameScreenState createState() => _HashRushGameScreenState();
}

class _HashRushGameScreenState extends State<HashRushGameScreen> {
  bool _hasExited = false;
  int tapCount = 0;
  double earnedBTC = 0.0;
  bool isAdLoaded = false;
  bool isAdLoading = false;
  String? adError;
  bool isAutoMinerActive = false;
  bool isBoostActive = false;
  bool isLoading = false;
  double tapBTCValue = 0.00000000000000001;
  Timer? autoMinerTimer;
  Timer? boostTimer;
  Timer? periodicSaveTimer;
  final AdService _adService = AdService();
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // New: Ad required state
  bool isRewardedAdRequired = false;

  List<Task> taskList = [
    Task(title: '200 Taps', target: 200),
    Task(title: 'Boost Mining 200 Tap Count', target: 200),
    Task(title: 'Auto Mining 20000 Second Count', target: 20000),
  ];

  bool get areAllTasksCompleted => taskList.every((task) => task.isCompleted);

  @override
  void initState() {
    super.initState();
    _initializeAds();
    loadTaskData();
    _startPeriodicSaveTimer();
    // New: Check if ad was required from previous session
    _loadAdRequiredState();
    _adService.addListener(_onAdStateChanged); // Listen for ad state changes
    
    // Load banner ad
    _loadBannerAd();
  }

  void _onAdStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAdRequiredState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isRewardedAdRequired = prefs.getBool('hashrush_ad_required') ?? false;
    });
  }

  Future<void> _saveAdRequiredState(bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hashrush_ad_required', required);
  }

  Future<void> _initializeAds() async {
    setState(() {
      isAdLoading = true;
      adError = null;
    });

    try {
      debugPrint('🎯 Hash Rush: Initializing ads...');

      // Load rewarded ad (async)
      await _adService.loadRewardedAd();
      debugPrint(
          '🎯 Hash Rush: Rewarded ad loaded: ${_adService.isRewardedAdLoaded}');

      // Load interstitial ad for exit (MISSING!)
      await _adService.loadInterstitialAd();
      debugPrint(
          '🎯 Hash Rush: Interstitial ad loaded: ${_adService.isInterstitialAdLoaded}');

      if (mounted) {
        setState(() {
          isAdLoaded = _adService.isBannerAdLoaded ||
              _adService.isRewardedAdLoaded ||
              _adService.isInterstitialAdLoaded;
          isAdLoading = false;
        });

        debugPrint('🎯 Hash Rush: All ads initialized. Status: $isAdLoaded');
      }
    } catch (e) {
      debugPrint('❌ Hash Rush: Ad initialization failed: $e');
      if (mounted) {
        setState(() {
          isAdLoaded = false;
          isAdLoading = false;
          adError =
              'Failed to load ads. Please check your internet connection.';
        });
      }
    }
  }

  Future<void> loadTaskData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      for (var task in taskList) {
        task.currentProgress = prefs.getInt(task.title) ?? 0;
        task.isCompleted = task.currentProgress >= task.target;
      }
    });
  }

  Future<void> saveTaskData() async {
    final prefs = await SharedPreferences.getInstance();

    for (var task in taskList) {
      await prefs.setInt(task.title, task.currentProgress);
    }
  }

  // Load banner ad
  void _loadBannerAd() {
    // Dispose the existing banner ad if it exists
    _bannerAd?.dispose();
    
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3537329799200606/2028008282', // Your banner ad unit ID
      size: AdSize.mediumRectangle, // 300x250 banner ad
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          // Schedule the next ad refresh after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) {
              _loadBannerAd();
            }
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Retry loading the ad after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              _loadBannerAd();
            }
          });
        },
      ),
    );
    
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _adService.removeListener(_onAdStateChanged); // Remove ad state listener
    // Save ad required state
    _saveAdRequiredState(isRewardedAdRequired);
    // Don't add earnings here; handled in exit logic to prevent double addition.
    // Save task data
    saveTaskData();
    autoMinerTimer?.cancel();
    boostTimer?.cancel();
    periodicSaveTimer?.cancel();
    _adService.dispose();
    super.dispose();
  }

  void activateAutoMiner() {
    if (isAutoMinerActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto miner is already active!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isAdLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we load the ad...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showRewardedAd(() {
      setState(() {
        isAutoMinerActive = true;
      });

      // Cancel any existing timer
      autoMinerTimer?.cancel();

      // Start auto mining
      autoMinerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          earnedBTC += 0.00000000000000002;
          updateTaskProgress('Auto Mining 20000 Second Count', 1);
        });
      });

      // Show countdown overlay
      showCountdownOverlay('Auto Miner', 180);

      // Stop auto mining after 180 seconds
      Future.delayed(const Duration(seconds: 180), () {
        if (mounted && autoMinerTimer != null && autoMinerTimer!.isActive) {
          autoMinerTimer!.cancel();
          setState(() {
            isAutoMinerActive = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto mining completed! ⚡'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  void activateBoost() {
    if (isBoostActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boost is already active!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isAdLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we load the ad...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showRewardedAd(() {
      setState(() {
        isBoostActive = true;
      });

      // Show countdown overlay
      showCountdownOverlay('Boost Active', 180);

      // Cancel any existing timer
      boostTimer?.cancel();

      // Start boost timer
      boostTimer = Timer(const Duration(seconds: 180), () {
        if (mounted) {
          setState(() {
            isBoostActive = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Boost mining completed! ⚡'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });

      updateTaskProgress('Boost Mining 200 Tap Count', 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boost activated! Double mining for 15 seconds! ⚡'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void showCountdownOverlay(String title, int duration) {
    setState(() {
      countdownWidget = CountdownOverlay(
        title: title,
        durationInSeconds: duration,
        onComplete: () {
          setState(() {
            countdownWidget = null;
          });
        },
      );
    });
  }

  Widget? countdownWidget;

  void handleTap() async {
    if (isRewardedAdRequired) {
      // Show ad first, then allow tap
      await showRewardedAd(() {
        setState(() {
          isRewardedAdRequired = false;
        });
        _saveAdRequiredState(false);
      });
      return;
    }
    tapCount++;
    if (tapCount % 250 == 0) {
      setState(() {
        isRewardedAdRequired = true;
      });
      _saveAdRequiredState(true);
      await showRewardedAd(() {
        setState(() {
          isRewardedAdRequired = false;
        });
        _saveAdRequiredState(false);
        executeTapLogic();
      });
    } else {
      executeTapLogic();
    }
  }

  void executeTapLogic() {
    final double btcEarned = isBoostActive ? tapBTCValue * 2 : tapBTCValue;

    setState(() {
      earnedBTC += btcEarned;
      updateTaskProgress('200 Taps', 1);
    });
  }

  void showTaskPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, bool? result) async {
            if (!didPop) {
              await _handleBackButton();
            }
          },
          child: TaskPopupDialog(
            taskList: taskList,
            areAllTasksCompleted: areAllTasksCompleted,
            onCollectReward: collectTaskReward,
          ),
        );
      },
    );
  }

  void collectTaskReward() {
    const taskReward = 0.00000000000005;
    setState(() {
      earnedBTC += taskReward;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task reward added to your game earnings!'),
      ),
    );
    Navigator.pop(context); // Close task dialog after collection
  }

  void updateTaskProgress(String taskTitle, int progress) {
    setState(() {
      final task = taskList.firstWhere((task) => task.title == taskTitle);
      task.updateProgress(progress);
      saveTaskData(); // Save progress after updating
    });
  }

  Future<void> showRewardedAd(VoidCallback onAdComplete) async {
    if (!_adService.isRewardedAdLoaded) {
      setState(() {
        isAdLoading = true;
      });

      try {
        await _adService.loadRewardedAd();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load ad. Please try again later.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() {
            isAdLoading = false;
          });
        }
      }
    }

    try {
      await _adService.showRewardedAd(
        onRewarded: (amount) {
          onAdComplete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reward earned! 🎉'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        onAdDismissed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Ad dismissed. Please watch the full ad to earn rewards.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error showing ad. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Combined exit method that handles both ad display and game exit logic
  Future<void> exitGame() async {
    // Prevent multiple exit attempts
    if (_hasExited) {
      debugPrint(
          '⚠️ Hash Rush: Exit already in progress, ignoring duplicate call');
      return;
    }

    if (isLoading) {
      debugPrint(
          '⚠️ Hash Rush: Operation already in progress, ignoring exit request');
      return;
    }

    debugPrint('🚪 Hash Rush: Starting exit game process');
    _hasExited = true;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(earnedBTC > 0
                    ? 'Saving ${earnedBTC.toStringAsFixed(18)} BTC to wallet...'
                    : 'Exiting game...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Check if we should show an ad before exiting
      final bool shouldShowAd = _adService.isInterstitialAdLoaded;
      debugPrint(
          '🎯 Hash Rush: Interstitial ad status - Loaded: $shouldShowAd');

      if (shouldShowAd) {
        debugPrint('🔄 Hash Rush: Attempting to show interstitial ad');

        // Show the ad and wait for it to be dismissed
        final adShown = await _adService.showInterstitialAd();
        debugPrint('🎯 Hash Rush: Interstitial ad shown: $adShown');

        // Small delay after ad is dismissed
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Save earnings and exit
      if (earnedBTC > 0) {
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.addEarning(
          earnedBTC,
          type: 'game',
          description: 'Hash Rush - Game Earnings',
        );
        await SoundNotificationService.playNotificationSound('success_chime');
      }

      // Save task data
      await saveTaskData();

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        // Navigate back with the result
        Navigator.of(context).pop(earnedBTC);
      }
    } catch (e) {
      debugPrint('❌ Hash Rush: Error during exit: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save progress. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // Reset exit state to allow retry
        _hasExited = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Periodic save timer to save earnings every 30 seconds
  void _startPeriodicSaveTimer() {
    periodicSaveTimer?.cancel();
    periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && earnedBTC > 0) {
        _saveEarningsPeriodically();
      }
    });
  }

  // Save earnings periodically without showing loading
  Future<void> _saveEarningsPeriodically() async {
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.addEarning(
        earnedBTC,
        type: 'game',
        description: 'Hash Rush - Periodic Save',
      );

      // Play coin drop sound for periodic save
      await SoundNotificationService.playNotificationSound('success_chime');

      // Reset earned BTC after saving
      setState(() {
        earnedBTC = 0.0;
      });
    } catch (e) {}
  }

  // Handle back button press (for both app bar and Android back button)
  // Returns true if the back action should proceed, false otherwise
  Future<bool> _handleBackButton() async {
    try {
      if (isLoading) return false;

      if (_hasExited) return true;

      bool shouldExit = true;

      if (earnedBTC > 0) {
        shouldExit = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Exit Game'),
                  ],
                ),
                content: Text(
                  'You have ${earnedBTC.toStringAsFixed(18)} BTC earnings!\n\nDo you want to save and exit?',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save & Exit'),
                  ),
                ],
              ),
            ) ??
            false;
      }

      if (!shouldExit) {
        _hasExited = false;
        return false;
      }

      await exitGame();
      return true;
    } catch (e) {
      debugPrint('Error in _handleBackButton: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isLoading) return;
        final shouldPop = await _handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(earnedBTC);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.purple,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              try {
                if (isLoading) return;
                final shouldPop = await _handleBackButton();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                debugPrint('Error in back button: $e');
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: Text(
            widget.gameTitle,
            style: GoogleFonts.poppins(
              fontSize: 20, 
              fontWeight: FontWeight.bold
            ),
          ),
          toolbarHeight: 50,
        ),
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background with scrollable content
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Total Earned: ${earnedBTC.toStringAsFixed(18)} BTC',
                      style: GoogleFonts.poppins(
                        color: Colors.yellowAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: isRewardedAdRequired ? null : handleTap,
                          child: Opacity(
                            opacity: isRewardedAdRequired ? 0.5 : 1.0,
                            child: Container(
                              height: 130,
                              width: 130,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.amber, Colors.deepOrange],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(255, 255, 0, 0.5),
                                    blurRadius: 12,
                                    offset: Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (isRewardedAdRequired) ...[
                          Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 12.0),
                                child: Text(
                                  'Watch rewarded ad to continue!',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: isAdLoading
                                    ? null
                                    : () async {
                                        await showRewardedAd(() {
                                          setState(() {
                                            isRewardedAdRequired = false;
                                          });
                                          _saveAdRequiredState(false);
                                        });
                                      },
                                icon: const Icon(Icons.ondemand_video),
                                label: Text(
                                    isAdLoading ? 'Loading Ad...' : 'Watch Ad'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: activateAutoMiner,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAutoMinerActive
                                    ? Colors.grey
                                    : Colors.greenAccent,
                              ),
                              child: Text(isAutoMinerActive
                                  ? 'Auto Miner ON'
                                  : 'Start Auto Miner'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: activateBoost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                              ),
                              child: const Text('Boost Mining'),
                            ),
                          ],
                        ),
                        if (!isAdLoaded && adError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                Text(
                                  adError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _initializeAds,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry Loading Ad'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // 300x250 Banner Ad
                        if (_isBannerAdLoaded && _bannerAd != null)
                          Container(
                            width: 300,
                            height: 250,
                            margin: const EdgeInsets.only(
                              bottom: 16, 
                              top: 30,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AdWidget(ad: _bannerAd!),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(179),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Adding ${earnedBTC.toStringAsFixed(18)} BTC to wallet...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskPopupDialog extends StatelessWidget {
  final List<Task> taskList;
  final bool areAllTasksCompleted;
  final VoidCallback onCollectReward;

  const TaskPopupDialog({
    super.key,
    required this.taskList,
    required this.areAllTasksCompleted,
    required this.onCollectReward,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '⚡ Daily Mining Tasks',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...taskList.map(buildTaskCard),
              const SizedBox(height: 20),
              if (areAllTasksCompleted)
                Center(
                  child: ElevatedButton(
                    onPressed: onCollectReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      elevation: 10,
                      shadowColor: const Color.fromRGBO(255, 182, 42, 0.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Collect Reward',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskCard(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: task.isCompleted
                ? [Colors.greenAccent, Colors.blueAccent]
                : [Colors.grey.shade800, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: task.isCompleted
                  ? const Color.fromRGBO(0, 255, 140, 0.3)
                  : Colors.black45,
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: task.currentProgress / task.target,
              color: task.isCompleted ? Colors.greenAccent : Colors.orange,
              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.2),
              strokeWidth: 6,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.currentProgress}/${task.target}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              task.isCompleted ? Icons.check_circle : Icons.timelapse,
              color: task.isCompleted
                  ? Colors.greenAccent
                  : const Color.fromRGBO(255, 165, 0, 0.5),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  String title;
  int target;
  int currentProgress;
  bool isCompleted;

  Task({
    required this.title,
    required this.target,
    this.currentProgress = 0,
    this.isCompleted = false,
  });

  void updateProgress(int value) {
    if (!isCompleted) {
      currentProgress += value;
      if (currentProgress >= target) {
        currentProgress = target;
        isCompleted = true;
      }
    }
  }
}

class CountdownOverlay extends StatefulWidget {
  final String title;
  final int durationInSeconds;
  final VoidCallback onComplete;

  const CountdownOverlay({
    super.key,
    required this.title,
    required this.durationInSeconds,
    required this.onComplete,
  });

  @override
  _CountdownOverlayState createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int remainingTime = 0;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.durationInSeconds;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 1) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16, // You can change this to left: 16 for left-side placement
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(255, 165, 0, 0.5),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              remainingTime.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
