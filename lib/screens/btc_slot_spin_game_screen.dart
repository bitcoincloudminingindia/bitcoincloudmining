import 'dart:async';
import 'dart:math';

import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BTCSlotSpinGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const BTCSlotSpinGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  State<BTCSlotSpinGameScreen> createState() => _BTCSlotSpinGameScreenState();
}

class _BTCSlotSpinGameScreenState extends State<BTCSlotSpinGameScreen> {
  final List<String> symbols = ['🪙', '💎', '🔥', '❌'];
  final List<List<String>> reels = List.generate(3, (_) => []);
  bool isSpinning = false;
  Timer? spinTimer;
  int spinCount = 0;
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

  @override
  void initState() {
    super.initState();
    _initializeReels();
    _loadAds();
  }

  Future<void> _loadAds() async {
    await _adService.loadRewardedAd();
    await _adService.loadInterstitialAd();
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

  Future<void> _showInterstitialAd() async {
    await _adService.showInterstitialAd();
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
        lineMatches[1][i] = reels[i][2] == '🪙' || reels[i][2] == '💎';
        symbolColors[i][2] =
            lineMatches[1][i] ? Colors.greenAccent : Colors.white;
      }
    });
  }

  void _spin() {
    if (isSpinning) return;

    try {
      setState(() {
        isSpinning = true;
        spinCount = 0;
        totalSpins++;
      });

      // Show interstitial ad every 10 spins
      if (totalSpins % 10 == 0) {
        _showInterstitialAd();
      }

      spinTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        setState(() {
          for (int i = 0; i < 3; i++) {
            // Move symbols down
            for (int j = 4; j > 0; j--) {
              reels[i][j] = reels[i][j - 1];
            }
            reels[i][0] = symbols[random.nextInt(symbols.length)];
          }
          spinCount++;

          if (spinCount > maxSpins * 0.7) {
            timer.cancel();
            Timer.periodic(const Duration(milliseconds: 400), (slowTimer) {
              setState(() {
                for (int i = 0; i < 3; i++) {
                  // Move symbols down slowly
                  for (int j = 4; j > 0; j--) {
                    reels[i][j] = reels[i][j - 1];
                  }
                  reels[i][0] = symbols[random.nextInt(symbols.length)];
                }
                spinCount++;

                if (spinCount >= maxSpins) {
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

  void _checkWinnings() {
    double reward = 0;
    String message = '';

    // Check only middle line
    if (currentResults.contains('❌')) {
      reward = 0;
      message = 'Cross appeared! No reward!';
    } else if (currentResults.every((symbol) => symbol == '🪙')) {
      reward = 0.000000000000002500;
      message = '3x Bitcoin Coin! +0.000000000000002500 BTC';
    } else if (currentResults.where((symbol) => symbol == '🪙').length == 2) {
      reward = 0.000000000000001000;
      message = '2x Bitcoin Coin! +0.000000000000001000 BTC';
    } else if (currentResults.every((symbol) => symbol == '💎')) {
      reward = 0.000000000000010000;
      message = '3x BTC Gem (Jackpot)! +0.000000000000010000 BTC';
    } else if (currentResults.where((symbol) => symbol == '💎').length == 2) {
      reward = 0.000000000000005000;
      message = '2x BTC Gem! +0.000000000000005000 BTC';
    } else if (currentResults
        .any((symbol) => symbol == '🪙' || symbol == '💎')) {
      reward = 0.000000000000000500;
      message = '1x Match! +0.000000000000000500 BTC';
    }

    _updateMatchingSections();

    if (reward > 0) {
      setState(() {
        gameWalletBalance += reward;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameTitle),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Show interstitial ad first
            await _showInterstitialAd();

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
                          'Slot Wallet: ${gameWalletBalance.toStringAsFixed(18)} BTC',
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
                      // Slot Machine
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Container(
                              height: 280,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (index) {
                                      return Container(
                                        width: 80,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(26),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(51),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              List.generate(5, (symbolIndex) {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3.0),
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: symbolColors[index]
                                                            [symbolIndex] ==
                                                        Colors.greenAccent
                                                    ? Colors.greenAccent
                                                        .withAlpha(51)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                reels[index][symbolIndex],
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  color: symbolColors[index]
                                                      [symbolIndex],
                                                  fontWeight: symbolColors[
                                                                  index]
                                                              [symbolIndex] ==
                                                          Colors.greenAccent
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
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
                                        height: 50,
                                        width: 230,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.yellowAccent
                                                .withAlpha(128),
                                            width: 2.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color:
                                              Colors.yellowAccent.withAlpha(26),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withAlpha(40),
                                              blurRadius: 24,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 2),
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
                              onPressed: isSpinning ? null : _spin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellowAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 5,
                                shadowColor: Colors.yellowAccent.withAlpha(100),
                              ),
                              child: Text(
                                isSpinning ? 'SPINNING...' : 'SPIN',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info Section
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Winning Combinations',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.help_outline,
                                              color: Colors.greenAccent),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor:
                                                    Colors.blue.shade900,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                title: Text(
                                                  'How to Play',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildInstruction(
                                                        '1. Press the spin button'),
                                                    const SizedBox(height: 12),
                                                    _buildInstruction(
                                                        '2. Check for matching symbols in the middle line'),
                                                    const SizedBox(height: 12),
                                                    _buildInstruction(
                                                        '3. No reward if cross (❌) appears'),
                                                    const SizedBox(height: 12),
                                                    _buildInstruction(
                                                        '4. Get rewards according to winning combinations'),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text(
                                                      'Got it',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color:
                                                            Colors.greenAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildWinningCombo(
                                        '🪙🪙🪙', '0.000000000000002500 BTC'),
                                    const SizedBox(height: 8),
                                    _buildWinningCombo(
                                        '🪙🪙', '0.000000000000001000 BTC'),
                                    const SizedBox(height: 8),
                                    _buildWinningCombo(
                                        '💎💎💎', '0.000000000000010000 BTC'),
                                    const SizedBox(height: 8),
                                    _buildWinningCombo(
                                        '💎💎', '0.000000000000005000 BTC'),
                                    const SizedBox(height: 8),
                                    _buildWinningCombo(
                                        'Any 1x', '0.000000000000000500 BTC'),
                                  ],
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
      ),
    );
  }

  Widget _buildWinningCombo(String symbols, String reward) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbols,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reward,
            style: GoogleFonts.poppins(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.arrow_right, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
