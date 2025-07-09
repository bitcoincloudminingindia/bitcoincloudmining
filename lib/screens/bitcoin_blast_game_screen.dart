import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/sound_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BitcoinBlastGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const BitcoinBlastGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  _BitcoinBlastGameScreenState createState() => _BitcoinBlastGameScreenState();
}

class _BitcoinBlastGameScreenState extends State<BitcoinBlastGameScreen> {
  double score = 0.0;
  double gameEarnings = 0.0; // Add temporary wallet for game earnings
  int timeLeft = 60;
  bool gameOver = false;
  bool shieldActive = false;
  bool doubleBTCActive = false;
  bool gameStarted = false;
  bool isAdLoaded = false;
  bool isAdLoading = false;
  bool isDialogOpen = false; // Track if a dialog is open
  String? adError;
  List<FallingItem> fallingItems = [];
  Timer? gameTimer;
  Timer? itemTimer;
  Timer? animationTimer;
  double fallingSpeed = 3.5;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AdService _adService = AdService();
  // Bubble state
  bool showAdBubble = false;
  Timer? adBubbleTimer;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, showStartPopup);
    _initializeAudio();
    _initializeAds();
  }

  void _disposeBannerAd() {
    // No need to null a widget, just let AdService handle disposal if needed
  }

  @override
  void dispose() {
    try {
      _audioPlayer.stop();
      _audioPlayer.dispose();
    } catch (e) {}
    gameTimer?.cancel();
    itemTimer?.cancel();
    animationTimer?.cancel();
    _disposeBannerAd();
    _adService.dispose();
    exitGame();
    adBubbleTimer?.cancel();
    super.dispose();
  }

  Future<void> _reloadBannerAd() async {
    await _adService.loadBannerAd();
    if (mounted) {
      setState(() {
        isAdLoaded = _adService.isBannerAdLoaded;
      });
    }
  }

  @override
  void didUpdateWidget(covariant BitcoinBlastGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isDialogOpen && _adService.isBannerAdLoaded) {
      _reloadBannerAd();
    }
  }

  void _onDialogClose() {
    setState(() {
      isDialogOpen = false;
    });
    _reloadBannerAd();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      // Try to play background music with better error handling
      try {
        await _audioPlayer.play(AssetSource('audio/background.mp3'));
      } catch (e) {
        // Continue without background music
      }
    } catch (e) {
      // Continue without audio
    }
  }

  Future<void> _initializeAds() async {
    setState(() {
      isAdLoading = true;
      adError = null;
    });

    try {
      await _adService.loadBannerAd();
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

  Future<void> _showRewardedAd(VoidCallback onRewarded) async {
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

    setState(() {
      isAdLoading = true;
    });

    try {
      if (!_adService.isRewardedAdLoaded) {
        await _adService.loadRewardedAd();
      }

      if (mounted) {
        await _adService.showRewardedAd(
          onRewarded: (amount) {
            const double rewardAmount = 0.000000000000000100;
            setState(() {
              score += rewardAmount;
              gameEarnings += rewardAmount;
            });
            Provider.of<WalletProvider>(context, listen: false).addEarning(
              rewardAmount,
              type: 'tap',
              description: 'Bitcoin Blast - Ad Reward',
            );

            // Play earning sound for ad reward
            SoundNotificationService.playEarningSound();

            onRewarded();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reward earned! 🎉'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
          onAdDismissed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please watch the full ad to earn rewards.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
      }
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
    } finally {
      if (mounted) {
        setState(() {
          isAdLoading = false;
        });
      }
    }
  }

  void showStartPopup() {
    pauseGame();
    setState(() => isDialogOpen = true);
    _disposeBannerAd();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orangeAccent,
          title: Text('Welcome to ${widget.gameTitle}!',
              style: GoogleFonts.roboto(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          content: Text('Tap to collect Bitcoin and avoid obstacles!',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onDialogClose();
                resumeGame();
                startNewGame();
              },
              child: const Text('Start Game',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _onDialogClose();
    });
  }

  void pauseGame() {
    gameTimer?.cancel();
    itemTimer?.cancel();
    animationTimer?.cancel();
    adBubbleTimer?.cancel();
  }

  void resumeGame() {
    if (!gameOver && gameStarted) {
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timeLeft > 0) {
          setState(() {
            timeLeft--;
            // Speed increase logic removed - speed will stay constant
          });
        } else {
          showWinScreen();
        }
      });

      itemTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        spawnItem();
      });

      animationTimer =
          Timer.periodic(const Duration(milliseconds: 16), (timer) {
        updateItemPositions();
      });

      // हर 20 सेकंड में ad bubble दिखाने के लिए
      adBubbleTimer?.cancel();
      adBubbleTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        if (!showAdBubble && !gameOver && gameStarted && mounted) {
          showRewardedAdBubble();
        }
      });
    }
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      gameOver = false;
      score = 0.0;
      timeLeft = 60;
      fallingItems.clear();
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
          // Speed increase logic removed - speed will stay constant
        });
      } else {
        showWinScreen();
      }
    });

    itemTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      spawnItem();
    });

    animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateItemPositions();
    });
  }

  void startNewGame() {
    setState(() {
      gameStarted = true;
      gameOver = false;
      score = 0.0;
      timeLeft = 60;
      fallingItems.clear();
      fallingSpeed = 3.5; // पहली बार गेम शुरू करने पर स्पीड रीसेट करें
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
          // Speed increase logic removed - speed will stay constant
        });
      } else {
        showWinScreen();
      }
    });

    itemTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      spawnItem();
    });

    animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateItemPositions();
    });
  }

  void playAgain() {
    // Play Again के लिए कॉमन फंक्शन
    Navigator.of(context).pop();
    _onDialogClose();
    startNewGame(); // स्पीड रीसेट करने के लिए startNewGame का उपयोग करें
    _showRewardedAd(() {}); // Play Again पर rewarded ad दिखाएं
  }

  void updateItemPositions() {
    if (!mounted) return;
    setState(() {
      for (var item in fallingItems) {
        item.yPosition += fallingSpeed;
      }
    });
  }

  void endGame() {
    if (!gameOver) {
      gameOver = true;
      gameTimer?.cancel();
      itemTimer?.cancel();
      animationTimer?.cancel();
      showGameOverScreen();
    }
  }

  void showGameOverScreen() {
    pauseGame();
    setState(() => isDialogOpen = true);
    _disposeBannerAd();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orangeAccent,
          title: Text('Game Over',
              style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          content: Text('You lost! Try again.',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.white)),
          actions: [
            TextButton(
              onPressed: playAgain,
              child: const Text('Play Again',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onDialogClose();
                exitGame();
              },
              child: const Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _onDialogClose();
    });
  }

  void showWinScreen() {
    pauseGame();
    setState(() => isDialogOpen = true);
    _disposeBannerAd();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orangeAccent,
          title: Text('You Win!',
              style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          content: Text(
              'Congrats! You earned ${gameEarnings.toStringAsFixed(18)} BTC.',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.white)),
          actions: [
            TextButton(
              onPressed: playAgain,
              child: const Text('Play Again',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onDialogClose();
                exitGame();
              },
              child: const Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _onDialogClose();
    });
  }

  void resetGame() {
    setState(() {
      gameOver = true;
      gameStarted = false;
      adBubbleTimer?.cancel();
    });
  }

  void exitGame() {
    pauseGame();
    resetGame();

    // Transfer game earnings to main wallet before exiting
    if (gameEarnings > 0) {
      Provider.of<WalletProvider>(context, listen: false).addEarning(
        gameEarnings,
        type: 'game',
        description: 'Bitcoin Blast - Game Earnings',
      );

      // Play earning sound for game completion
      SoundNotificationService.playEarningSound();
    }

    Navigator.pop(context, gameEarnings);
  }

  void spawnItem() {
    if (!mounted) return;
    final Random random = Random();
    final int itemType = random.nextInt(5) + 1; // 1 से 5 तक (type 6 हटा दिया)
    final double position =
        random.nextDouble() * (MediaQuery.of(context).size.width - 50);
    setState(() {
      fallingItems.add(FallingItem(itemType, position, 0));
    });
  }

  void collectItem(FallingItem item) {
    if (!mounted) return;

    double collectedBTC = 0.0;

    if (item.type == 1) {
      collectedBTC =
          doubleBTCActive ? 0.000000000000000040 : 0.000000000000000020;
    } else if (item.type == 2) {
      collectedBTC =
          doubleBTCActive ? 0.000000000000000100 : 0.000000000000000050;
    } else if (item.type == 3) {
      collectedBTC = -0.000000000000000010;
    } else if (item.type == 4) {
      if (!shieldActive) {
        endGame();
      }
    } else if (item.type == 5) {
      shieldActive = true;
      setState(() {
        fallingItems.remove(item);
      });
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            shieldActive = false;
          });
        }
      });
    }

    if (collectedBTC != 0.0) {
      setState(() {
        score += collectedBTC;
        gameEarnings += collectedBTC;
        fallingItems.remove(item);
      });
    }

    _playCollectSound();
  }

  Future<void> _playCollectSound() async {
    try {
      // Try to play collect sound with better error handling
      await _audioPlayer.play(AssetSource('audio/collect.mp3'));
    } catch (e) {
      // Continue without sound
    }
  }

  Widget buildFallingItems() {
    return Stack(
      children: fallingItems.map((item) {
        return Positioned(
          left: item.xPosition,
          top: item.yPosition,
          child: GestureDetector(
            onTap: () => collectItem(item),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.type == 1
                    ? Colors.amber
                    : item.type == 2
                        ? Colors.green
                        : item.type == 3
                            ? Colors.red
                            : item.type == 4
                                ? Colors.black
                                : item.type == 5
                                    ? Colors.blue
                                    : Colors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  item.type == 1
                      ? '💰'
                      : item.type == 2
                          ? '⚡'
                          : item.type == 3
                              ? '🔥'
                              : item.type == 4
                                  ? '💣'
                                  : item.type == 5
                                      ? '🛡️'
                                      : '🔄',
                  style: GoogleFonts.roboto(
                    fontSize: 24, // Adjust the size as needed
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Bubble state
  void showRewardedAdBubble() {
    setState(() {
      showAdBubble = true;
    });
  }

  void hideRewardedAdBubble() {
    setState(() {
      showAdBubble = false;
    });
  }

  Future<void> _showRewardedAdFor2x() async {
    pauseGame();
    await _adService.showRewardedAd(
      onRewarded: (amount) {
        setState(() {
          doubleBTCActive = true;
        });
        resumeGame();
        hideRewardedAdBubble();
        // Double earning 10 seconds के लिए active (या जितना चाहें)
        Timer(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              doubleBTCActive = false;
            });
          }
        });
      },
      onAdDismissed: () {
        resumeGame();
        hideRewardedAdBubble();
      },
    );
  }

  Widget buildAdBubble() {
    if (!showAdBubble) return const SizedBox.shrink();
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 70,
      top: MediaQuery.of(context).size.height / 2 - 70,
      child: GestureDetector(
        onTap: _showRewardedAdFor2x,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha((0.95 * 255).toInt()),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_fill,
                    size: 48, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Watch Ad for\n2x reward',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          exitGame();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.gameTitle,
                  style: GoogleFonts.roboto(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.orange,
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.orangeAccent),
                ),
                buildFallingItems(),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Time Left: $timeLeft sec',
                        style: GoogleFonts.roboto(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'Game Earnings: ${gameEarnings.toStringAsFixed(18)} BTC',
                        style: GoogleFonts.roboto(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isAdLoading)
                  Container(
                    color: Colors.black.withAlpha(179),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading ad...',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (adError != null)
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adError!,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                adError = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                buildAdBubble(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FallingItem {
  int type;
  double xPosition;
  double yPosition;

  FallingItem(this.type, this.xPosition, this.yPosition);
}
