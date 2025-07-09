import 'dart:async';
import 'dart:math';

import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/sound_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BitcoinMachineScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const BitcoinMachineScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  State<BitcoinMachineScreen> createState() => _BitcoinMachineScreenState();
}

class _BitcoinMachineScreenState extends State<BitcoinMachineScreen> {
  final List<String> symbols = ['💲', '💎', '🔥', '❌'];
  final List<List<String>> reels = List.generate(3, (_) => []);
  bool isSpinning = false;
  Timer? spinTimer;
  int spinCount = 0;
  bool isRewardedAdRequired = false;
  bool isAdLoading = false;
  int totalSpins = 0;
  final int maxSpins = 50;
  final Random random = Random();
  double gameWalletBalance = 0.0;
  List<String> currentResults = ['', '', ''];
  List<List<bool>> lineMatches =
      List.generate(3, (_) => List.generate(3, (_) => false));
  List<List<Color>> symbolColors =
      List.generate(3, (_) => List.generate(5, (_) => Colors.white));
  final AdService _adService = AdService();
  Future<Widget?>? _bannerAdFuture;

  @override
  void initState() {
    super.initState();
    _initializeReels();
    _loadAds();
    _bannerAdFuture = _adService.getBannerAdWidget();
    _loadAdRequiredState();
  }

  Future<void> _loadAds() async {
    await _adService.loadRewardedAd();
  }

  Future<void> _showRewardedAd() async {
    if (await _adService.showRewardedAd(
      onRewarded: (double reward) {
        // Give bonus reward for watching ad
        setState(() {
          gameWalletBalance +=
              0.000000000000000100; // 0.000000000000000100 BTC bonus
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bonus reward for watching ad: +0.000000000000000100 BTC',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      },
      onAdDismissed: () {
        // Handle ad dismissal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ad dismissed. Spin again to earn more!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      },
    )) {
      // Ad was shown successfully
    }
  }

  Future<void> _loadAdRequiredState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isRewardedAdRequired =
          prefs.getBool('bitcoin_machine_ad_required') ?? false;
    });
  }

  Future<void> _saveAdRequiredState(bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bitcoin_machine_ad_required', required);
  }

  void _initializeReels() {
    for (int i = 0; i < 3; i++) {
      reels[i] =
          List.generate(5, (_) => symbols[random.nextInt(symbols.length)]);
    }
    currentResults = reels.map((reel) => reel[2]).toList();
    _updateMatchingSections();
  }

  void _updateMatchingSections() {
    setState(() {
      // Check only middle line
      for (int i = 0; i < 3; i++) {
        lineMatches[1][i] = reels[i][2] == '💲' || reels[i][2] == '💎';
        symbolColors[i][2] =
            lineMatches[1][i] ? Colors.greenAccent : Colors.white;
      }
    });
  }

  void _spin() {
    if (isSpinning || isRewardedAdRequired || isAdLoading) return;

    // हर 20 spin पर ad जरूरी
    totalSpins++;
    if (totalSpins % 20 == 0) {
      setState(() {
        isRewardedAdRequired = true;
      });
      _saveAdRequiredState(true);
      _showAdForSpin();
      return;
    }

    try {
      setState(() {
        isSpinning = true;
        spinCount = 0;
      });

      // Total spin duration: 5 seconds (5000 ms)
      const int totalSpinDurationMs = 5000;
      const int fastSpinMs = 200;
      const int slowSpinMs = 400;
      const int fastSpinCount = totalSpinDurationMs * 0.7 ~/ fastSpinMs;
      const int slowSpinCount = totalSpinDurationMs * 0.3 ~/ slowSpinMs;
      const int maxSpinCount = fastSpinCount + slowSpinCount;

      spinTimer =
          Timer.periodic(const Duration(milliseconds: fastSpinMs), (timer) {
        setState(() {
          for (int i = 0; i < 3; i++) {
            // Move symbols down
            for (int j = 4; j > 0; j--) {
              reels[i][j] = reels[i][j - 1];
            }
            reels[i][0] = symbols[random.nextInt(symbols.length)];
          }
          spinCount++;

          if (spinCount >= fastSpinCount) {
            timer.cancel();
            Timer.periodic(const Duration(milliseconds: slowSpinMs),
                (slowTimer) {
              setState(() {
                for (int i = 0; i < 3; i++) {
                  // Move symbols down slowly
                  for (int j = 4; j > 0; j--) {
                    reels[i][j] = reels[i][j - 1];
                  }
                  reels[i][0] = symbols[random.nextInt(symbols.length)];
                }
                spinCount++;

                if (spinCount >= maxSpinCount) {
                  slowTimer.cancel();
                  isSpinning = false;
                  currentResults = reels.map((reel) => reel[2]).toList();
                  _checkWinnings();

                  // Show rewarded ad every 10 spins
                  if (totalSpins % 10 == 0) {
                    _showRewardedAd();
                  }
                }
              });
            });
          }
        });
      });
    } catch (e) {
      setState(() {
        isSpinning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An error occurred while spinning. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAdForSpin() async {
    setState(() {
      isAdLoading = true;
    });
    await _adService.showRewardedAd(
      onRewarded: (amount) {
        setState(() {
          isRewardedAdRequired = false;
          isAdLoading = false;
        });
        _saveAdRequiredState(false);
      },
      onAdDismissed: () {
        setState(() {
          isRewardedAdRequired = false;
          isAdLoading = false;
        });
        _saveAdRequiredState(false);
      },
    );
  }

  void _showCongratsDialog(String message, double reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blue.shade900,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Congratulations!',
            style: TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
                fontSize: 24),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration,
                  color: Colors.yellowAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          gameWalletBalance += reward;
                        });
                        Navigator.of(context).pop();
                        setState(_initializeReels);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellowAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Collect Reward',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _showRewardedAdFor2x(reward);
                        setState(_initializeReels);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Watch Ad for 2x',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRewardedAdFor2x(double reward) async {
    await _adService.showRewardedAd(
      onRewarded: (amount) {
        setState(() {
          gameWalletBalance += (reward * 2);
        });
      },
      onAdDismissed: () {},
    );
  }

  void _checkWinnings() {
    double reward = 0;
    String message = '';

    // Check only middle line
    if (currentResults.contains('❌')) {
      reward = 0;
      message = 'Cross appeared! No reward!';
    } else if (currentResults.every((symbol) => symbol == '💲')) {
      reward = 0.000000000000002500;
      message = '3x Dollar! +0.000000000000002500 BTC';
    } else if (currentResults.where((symbol) => symbol == '💲').length == 2) {
      reward = 0.000000000000001000;
      message = '2x Dollar! +0.000000000000001000 BTC';
    } else if (currentResults.every((symbol) => symbol == '💎')) {
      reward = 0.000000000000010000;
      message = '3x BTC Gem (Jackpot)! +0.000000000000010000 BTC';
    } else if (currentResults.where((symbol) => symbol == '💎').length == 2) {
      reward = 0.000000000000005000;
      message = '2x BTC Gem! +0.000000000000005000 BTC';
    } else if (currentResults
        .any((symbol) => symbol == '💲' || symbol == '💎')) {
      reward = 0.000000000000000500;
      message = '1x Match! +0.000000000000000500 BTC';
    }

    _updateMatchingSections();

    if (reward > 0) {
      _showCongratsDialog(message, reward);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _transferToMainWallet() {
    if (gameWalletBalance > 0) {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      walletProvider.addEarning(
        gameWalletBalance,
        type: 'game',
        description: 'Won from ${widget.gameTitle}',
      );

      // Play earning sound for game completion
      SoundNotificationService.playEarningSound();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transferred ${gameWalletBalance.toStringAsFixed(18)} BTC to main wallet!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    spinTimer?.cancel();
    _transferToMainWallet();
    _adService.dispose();
    _saveAdRequiredState(isRewardedAdRequired);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bitcoin Machine'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return PopScope(
                  canPop: false,
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withAlpha(200),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.greenAccent),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Transferring to Main Wallet...',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );

            // Transfer balance and pop
            _transferToMainWallet();
            await Future.delayed(const Duration(
                seconds: 1)); // Show loading for at least 1 second
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              Navigator.pop(context); // Go back
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.black.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Colors.greenAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'BTC Machine Wallet: ${gameWalletBalance.toStringAsFixed(18)} BTC',
                                style: GoogleFonts.poppins(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Slot Machine centered
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 340, // Decreased from 380
                                      width: 270, // Decreased from 320
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(26),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.black.withAlpha(51),
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(3, (index) {
                                              return Container(
                                                width: 80, // Decreased from 100
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal:
                                                            4), // Less spacing
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withAlpha(26),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withAlpha(51),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List.generate(5,
                                                      (symbolIndex) {
                                                    return Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          vertical:
                                                              4.0), // Less vertical space
                                                      padding: const EdgeInsets
                                                          .all(
                                                          3), // Less padding
                                                      decoration: BoxDecoration(
                                                        color: symbolColors[
                                                                        index][
                                                                    symbolIndex] ==
                                                                Colors
                                                                    .greenAccent
                                                            ? Colors.greenAccent
                                                                .withAlpha(51)
                                                            : Colors
                                                                .transparent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Text(
                                                        reels[index]
                                                            [symbolIndex],
                                                        style: TextStyle(
                                                          fontSize: 30,
                                                          color: symbolColors[
                                                                  index]
                                                              [symbolIndex],
                                                          fontWeight: symbolColors[
                                                                          index]
                                                                      [
                                                                      symbolIndex] ==
                                                                  Colors
                                                                      .greenAccent
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              );
                                            }),
                                          ),
                                          Positioned.fill(
                                            child: Center(
                                              child: Container(
                                                height: 55, // Decreased from 70
                                                width:
                                                    210, // Decreased from 300
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.yellowAccent
                                                        .withAlpha(128),
                                                    width: 2.5, // Thinner
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  color: Colors.yellowAccent
                                                      .withAlpha(26),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withAlpha(40),
                                                      blurRadius: 20,
                                                      spreadRadius: 1,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: (isSpinning ||
                                              isRewardedAdRequired ||
                                              isAdLoading)
                                          ? null
                                          : _spin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.yellowAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        elevation: 5,
                                        shadowColor:
                                            Colors.yellowAccent.withAlpha(100),
                                      ),
                                      child: Text(
                                        isSpinning ? '...' : 'START',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Good luck!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Banner Ad at the bottom
              FutureBuilder<Widget?>(
                future: _bannerAdFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return snapshot.data!;
                  } else {
                    return const SizedBox(height: 0);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
