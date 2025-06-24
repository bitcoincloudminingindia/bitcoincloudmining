import 'dart:async';

import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  int tapCount = 0;
  double earnedBTC = 0.0;
  bool isAdLoaded = false;
  bool isAdLoading = false;
  String? adError;
  bool isAutoMinerActive = false;
  bool isBoostActive = false;
  bool isLoading = false;
  double tapBTCValue = 0.0000000000000001;
  Timer? autoMinerTimer;
  Timer? boostTimer;
  final AdService _adService = AdService();

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
  }

  Future<void> _initializeAds() async {
    setState(() {
      isAdLoading = true;
      adError = null;
    });

    try {
      _adService.loadBannerAd(); // No await, as this is a void method
      await _adService.loadRewardedAd();

      if (mounted) {
        setState(() {
          isAdLoaded = _adService.isBannerAdLoaded;
          isAdLoading = false;
        });
      }
    } catch (e) {
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

  @override
  void dispose() {
    autoMinerTimer?.cancel();
    boostTimer?.cancel();
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
          earnedBTC += 0.00000000000000005;
          updateTaskProgress('Auto Mining 20000 Second Count', 1);
        });
      });

      // Show countdown overlay
      showCountdownOverlay('Auto Miner', 15);

      // Stop auto mining after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
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
      showCountdownOverlay('Boost Active', 15);

      // Cancel any existing timer
      boostTimer?.cancel();

      // Start boost timer
      boostTimer = Timer(const Duration(seconds: 15), () {
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

  void handleTap() {
    tapCount++;

    if (tapCount % 25 == 0) {
      showRewardedAd(executeTapLogic);
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
        return TaskPopupDialog(
          taskList: taskList,
          areAllTasksCompleted: areAllTasksCompleted,
          onCollectReward: collectTaskReward,
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

  RewardedAd? rewardedAd;
  bool isRewardedAdReady = false;

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

  Future<void> exitGame() async {
    setState(() {
      isLoading = true;
    });

    // Transfer game earnings to main wallet before exiting
    if (earnedBTC > 0) {
      try {
        await Provider.of<WalletProvider>(context, listen: false).addEarning(
          earnedBTC,
          type: 'game',
          description: 'Hash Rush - Game Earnings',
        );
      } catch (e) {
        print('Error adding earnings to wallet: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context, earnedBTC);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              widget.gameTitle,
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.purple,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: isLoading ? null : exitGame,
            ),
          ),
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Total Earned: ${earnedBTC.toStringAsFixed(18)} BTC',
                        style: GoogleFonts.poppins(
                          color: Colors.yellowAccent,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: handleTap,
                              child: Container(
                                height: 150,
                                width: 150,
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
                                    size: 70,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
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
                          ],
                        ),
                      ),
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
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(179),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.purple),
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
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.pinkAccent,
            onPressed: () => showTaskPopup(context),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, color: Colors.white),
                Text(
                  'Tasks',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
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
