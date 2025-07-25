import 'dart:async';
import 'dart:math';

import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/sound_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoCrazeGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const CryptoCrazeGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  _CryptoCrazeGameScreenState createState() => _CryptoCrazeGameScreenState();
}

class _CryptoCrazeGameScreenState extends State<CryptoCrazeGameScreen> {
  final Random _random = Random();
  final AdService _adService = AdService();
  List<Offset> _cryptoPositions = [];
  int _tapCount = 0;
  int _currentLevel = 1;
  double _btcScore = 0.0;
  double _sessionEarnings = 0.0;
  late SharedPreferences _prefs;
  Timer? _adTimer;
  List<bool> _completedLevels = List.generate(1000, (_) => false);
  late WalletProvider _walletProvider;

  bool _isAdLoading = false;
  String? _adError;
  bool _isDoubleMiningActive = false;
  Timer? _doubleMiningTimer;
  int? _pendingAdLevel;
// default reward

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _adService.loadBannerAd();
    // Pending ad level load karo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pendingAdLevel = prefs.getInt('pendingAdLevel');
      });
      if (_pendingAdLevel != null) {
        _showWatchAdToContinueDialog(_pendingAdLevel!);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _initializeCryptoPositions();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _doubleMiningTimer?.cancel();
    _adService.dispose();

    super.dispose();
  }

  final double boxWidth = 320;
  final double boxHeight = 420;
  final double objectSize = 50;

  void _initializeCryptoPositions() {
    if (!mounted) return;
    _cryptoPositions = List.generate(
      6,
      (index) => Offset(
        _random.nextDouble() * (boxWidth - objectSize),
        _random.nextDouble() * (boxHeight - objectSize),
      ),
    );
  }

  Future<void> _loadGameData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _tapCount = _prefs.getInt('tapCount') ?? 0;
      _btcScore = _prefs.getDouble('btcScore') ?? 0.0;
      _currentLevel = _prefs.getInt('currentLevel') ?? 1;
      _completedLevels = (_prefs.getStringList('completedLevels') ??
              List.generate(1000, (_) => 'false'))
          .map((level) => level == 'true')
          .toList();
    });
  }

  void _saveGameData() {
    _prefs.setInt('tapCount', _tapCount);
    _prefs.setDouble('btcScore', _btcScore);
    _prefs.setInt('currentLevel', _currentLevel);
    _prefs.setStringList(
        'completedLevels', _completedLevels.map((e) => e.toString()).toList());
  }

  void _tapCrypto(int index) {
    if (_pendingAdLevel != null) return;
    setState(() {
      _tapCount++;
      const double earnedAmount = 0.00000000000000001;
      final double reward =
          _isDoubleMiningActive ? earnedAmount * 2 : earnedAmount;
      _btcScore += reward;
      _sessionEarnings += reward;
      _cryptoPositions[index] = Offset(
        _random.nextDouble() * (boxWidth - objectSize),
        _random.nextDouble() * (boxHeight - objectSize),
      );
    });

    _checkLevelUp();
  }

  void _checkLevelUp() async {
    final int newLevel = (_tapCount ~/ 100) + 1;
    if (newLevel > _currentLevel && newLevel <= 1000) {
      setState(() {
        _currentLevel = newLevel;
        _completedLevels[newLevel - 1] = true;
        const double levelUpBonus = 0.00000000000000001;
        _btcScore += levelUpBonus;
        _sessionEarnings += levelUpBonus;
      });

      _saveGameData();

      // Agar 2, 4, 6... par hai to ad gating lagao
      if (newLevel % 2 == 0) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _pendingAdLevel = newLevel;
        });
        prefs.setInt('pendingAdLevel', newLevel);
        _showWatchAdToContinueDialog(newLevel);
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Level Up!'),
          content: Text(
              'Congratulations! You reached Level $_currentLevel and earned 0.00000000000000001 BTC!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showLevelProgress() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.9),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔥 Win up to 1 Bitcoin every day! 🔥',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _completedLevels.where((c) => c).length / 1000,
                  backgroundColor: Colors.grey[800],
                  color: Colors.orangeAccent,
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 400,
                  child: GridView.builder(
                    itemCount: 1000,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Add level-specific action if needed
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _completedLevels[index]
                                ? const Color.fromRGBO(0, 255, 140, 0.8)
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: _completedLevels[index]
                                    ? const Color.fromRGBO(0, 255, 140, 0.5)
                                    : Colors.black,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Lvl ${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _completedLevels[index]
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startDoubleMiningTimer() {
    _doubleMiningTimer?.cancel();
    _doubleMiningTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _isDoubleMiningActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Double mining ended. Rewards back to normal.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _saveEarningsAndExit() async {
    // Show confirmation dialog if there are earnings
    if (_sessionEarnings > 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.orange),
              SizedBox(width: 8),
              Text('Exit Game'),
            ],
          ),
          content: Text(
            'You have ${_sessionEarnings.toStringAsFixed(18)} BTC earnings!\n\nDo you want to save and exit?',
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & Exit'),
            ),
          ],
        ),
      );

      if (shouldExit != true) {
        return; // User cancelled
      }
    }

    // Save earnings to wallet
    if (_sessionEarnings > 0) {
      try {
        await _walletProvider.addEarning(
          _sessionEarnings,
          type: 'game',
          description: 'Crypto Craze Game Earnings - Level $_currentLevel',
        );

        // Play earning sound for game completion
        await SoundNotificationService.playEarningSound();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 ${_sessionEarnings.toStringAsFixed(18)} BTC added to wallet!',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving earnings: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    // Save game data
    _saveGameData();

    // Earnings reset karo
    _sessionEarnings = 0.0;

    // Navigate back
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showRewardedAdForLevel(int level) async {
    setState(() {
      _isAdLoading = true;
    });
    try {
      if (!_adService.isRewardedAdLoaded) {
        await _adService.loadRewardedAd();
      }
      if (mounted) {
        await _adService.showRewardedAd(
          onRewarded: (amount) async {
            // Double mining activate karo
            setState(() {
              _isDoubleMiningActive = true;
            });
            _startDoubleMiningTimer();
            // Ad dekhne ke baad gating hatao
            final prefs = await SharedPreferences.getInstance();
            setState(() {
              _pendingAdLevel = null;
            });
            prefs.remove('pendingAdLevel');
          },
          onAdDismissed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please watch the full ad to continue.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
              // Ad dismiss hua bina reward ke, firse dialog dikhao
              Future.delayed(const Duration(milliseconds: 500), () {
                _showWatchAdToContinueDialog(level);
              });
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to show ad. Please try again later.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdLoading = false;
        });
      }
    }
  }

  void _showWatchAdToContinueDialog(int level) async {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss dialog
      builder: (context) => AlertDialog(
        title: Text('Level $level Unlocked!'),
        content:
            Text('You must watch a rewarded ad to continue playing the game.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() {
                _isAdLoading = true;
              });
              await _adService.showRewardedAd(
                onRewarded: (amount) async {
                  // Ad dekhne par reward do
                  const double adReward = 0.00000000000000001;
                  setState(() {
                    _btcScore += adReward;
                    _sessionEarnings += adReward;
                    _pendingAdLevel = null;
                  });
                  _saveGameData();
                  final prefs = await SharedPreferences.getInstance();
                  prefs.remove('pendingAdLevel');
                  // User ko reward message bhi dikha sakte hain
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'You earned 0.000000000000000010 BTC for watching the ad!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onAdDismissed: () {
                  // If ad not watched, show dialog again
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _showWatchAdToContinueDialog(level);
                  });
                },
              );
              setState(() {
                _isAdLoading = false;
              });
            },
            child: Text('Watch Ad to Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _saveEarningsAndExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.gameTitle,
            style:
                GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saveEarningsAndExit,
          ),
        ),
        body: SafeArea(
          bottom: true,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Top bar: Current Level, Taps, FAB
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Current Level: $_currentLevel',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent, fontSize: 18),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Taps: $_tapCount',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 70,
                  child: FloatingActionButton(
                    onPressed: _showLevelProgress,
                    backgroundColor: Colors.tealAccent,
                    mini: true,
                    child: const Icon(Icons.list),
                  ),
                ),
                // Main vertical content
                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 40),
                        // Tap Object Box
                        Container(
                          width: boxWidth,
                          height: boxHeight,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((255 * 0.2).toInt()),
                            border: Border.all(color: Colors.yellow, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              for (int i = 0; i < _cryptoPositions.length; i++)
                                Positioned(
                                  left: _cryptoPositions[i].dx,
                                  top: _cryptoPositions[i].dy,
                                  child: GestureDetector(
                                    onTap: () => _tapCrypto(i),
                                    child: Icon(
                                      Icons.currency_bitcoin,
                                      size: objectSize,
                                      color: Colors.yellowAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Watch Ad Button
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showRewardedAdForLevel(_currentLevel),
                          icon: const Icon(Icons.play_circle_fill,
                              color: Colors.white),
                          label: const Text(
                            'Watch Ad for BTC + Double Mining',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                            shadowColor: Colors.orange.withAlpha(100),
                          ),
                        ),
                        SizedBox(height: 8),
                        // BTC Wallet Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(0, 0, 0, 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BTC: ${_btcScore.toStringAsFixed(18)}',
                            style: GoogleFonts.poppins(
                                color: Colors.yellowAccent, fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Banner Ad
                        Container(
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _adService.isBannerAdLoaded
                              ? _adService.getBannerAd()
                              : Container(
                                  color: Colors.black.withAlpha(13),
                                  child: const Center(
                                    child: Text(
                                      'Ad Space',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 12),
                                    ),
                                  ),
                                ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Loading/Error overlays
                if (_isAdLoading)
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
                if (_adError != null)
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
                              _adError!,
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
                                _adError = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
