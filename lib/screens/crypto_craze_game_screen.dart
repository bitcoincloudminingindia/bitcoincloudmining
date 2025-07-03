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
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  String? _adError;
  bool _isDoubleMiningActive = false;
  Timer? _doubleMiningTimer;

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _initializeAds();
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

    if (_sessionEarnings > 0) {
      debugPrint(
          '🔄 Adding game earnings to wallet: ${_sessionEarnings.toStringAsFixed(18)} BTC');
      try {
        _walletProvider
            .addEarning(
          _sessionEarnings,
          type: 'tap',
          description: 'Crypto Craze Game Earnings - Level $_currentLevel',
        )
            .then((_) {
          debugPrint('✅ Game earnings added to wallet successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Added ${_sessionEarnings.toStringAsFixed(18)} BTC to wallet'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }).catchError((error) {
          debugPrint('❌ Error adding game earnings to wallet: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add earnings to wallet'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } catch (error) {
        debugPrint('❌ Error adding game earnings to wallet: $error');
      }
    }

    super.dispose();
  }

  void _initializeCryptoPositions() {
    if (!mounted) return;
    _cryptoPositions = List.generate(
      6,
      (index) => Offset(
        _random.nextDouble() * (MediaQuery.of(context).size.width - 50),
        _random.nextDouble() * (MediaQuery.of(context).size.height - 200),
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
    setState(() {
      _tapCount++;
      const double earnedAmount = 0.00000000000000001;
      _btcScore += earnedAmount;
      _sessionEarnings += earnedAmount;
      _cryptoPositions[index] = Offset(
        _random.nextDouble() * (MediaQuery.of(context).size.width - 50),
        _random.nextDouble() * (MediaQuery.of(context).size.height - 200),
      );
    });

    _checkLevelUp();
  }

  void _checkLevelUp() {
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

  Future<void> _initializeAds() async {
    setState(() {
      _isAdLoading = true;
      _adError = null;
    });

    try {
      await _adService.loadBannerAd();
      await _adService.loadInterstitialAd();
      await _adService.loadRewardedAd();

      if (mounted) {
        setState(() {
          _isAdLoaded = _adService.isBannerAdLoaded;
          _isAdLoading = false;
        });
      }

      // Schedule interstitial ads
      _scheduleInterstitialAd();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
          _isAdLoading = false;
          _adError =
              'Failed to load ads. Please check your internet connection.';
        });
      }
    }
  }

  void _scheduleInterstitialAd() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _showInterstitialAd();
    });
  }

  Future<void> _showInterstitialAd() async {
    if (_isAdLoading) return;

    setState(() {
      _isAdLoading = true;
    });

    try {
      if (!_adService.isInterstitialAdLoaded) {
        await _adService.loadInterstitialAd();
      }

      if (mounted) {
        await _adService.showInterstitialAd();
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

  Future<void> _showDoubleMiningAd() async {
    if (_isDoubleMiningActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Double mining is already active!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isAdLoading) {
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
      _isAdLoading = true;
    });

    try {
      debugPrint('🎬 Showing rewarded ad for Crypto Craze...');

      if (!_adService.isRewardedAdLoaded) {
        await _adService.loadRewardedAd();
      }

      if (mounted) {
        await _adService.showRewardedAd(
          onRewarded: (amount) async {
            if (!mounted) return;

            try {
              // Add BTC reward (5x normal reward)
              const double adReward = 0.000000000000000050; // 5x normal reward

              setState(() {
                _isDoubleMiningActive = true;
                _btcScore += adReward;
                _sessionEarnings += adReward;
              });

              _startDoubleMiningTimer();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🎉 +${adReward.toStringAsFixed(18)} BTC earned! Double mining activated! ⚡',
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              debugPrint(
                  '✅ Crypto Craze ad reward earned: ${adReward.toStringAsFixed(18)} BTC');
            } catch (e) {
              debugPrint('❌ Error adding ad reward: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding reward: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onAdDismissed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Please watch the full ad to earn BTC and activate double mining.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error showing rewarded ad: $e');
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
          _isAdLoading = false;
        });
      }
    }
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
            content: Text('Double mining period ended!'),
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
        debugPrint(
            '💾 Saving Crypto Craze earnings: ${_sessionEarnings.toStringAsFixed(18)} BTC');

        await _walletProvider.addEarning(
          _sessionEarnings,
          type: 'game',
          description: 'Crypto Craze Game Earnings - Level $_currentLevel',
        );

        // Play earning sound for game completion
        await SoundNotificationService.playEarningSound();

        debugPrint('✅ Crypto Craze earnings saved successfully');

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
        debugPrint('❌ Error saving Crypto Craze earnings: $e');
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
    debugPrint('✅ Game data saved');

    // Navigate back
    if (mounted) {
      Navigator.pop(context);
    }
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
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    for (int i = 0; i < _cryptoPositions.length; i++)
                      Positioned(
                        left: _cryptoPositions[i].dx,
                        top: _cryptoPositions[i].dy,
                        child: GestureDetector(
                          onTap: () => _tapCrypto(i),
                          child: const Icon(
                            Icons.currency_bitcoin,
                            size: 50,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Level: $_currentLevel',
                            style: GoogleFonts.poppins(
                                color: Colors.greenAccent, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Taps: $_tapCount',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BTC: ${_btcScore.toStringAsFixed(18)}',
                            style: GoogleFonts.poppins(
                                color: Colors.yellowAccent, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 160,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: _showDoubleMiningAd,
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
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 20,
                      child: FloatingActionButton(
                        onPressed: _showLevelProgress,
                        backgroundColor: Colors.tealAccent,
                        child: const Icon(Icons.list),
                      ),
                    ),
                    if (_isAdLoaded)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _adService.getBannerAd(),
                        ),
                      ),
                    if (_isAdLoading)
                      Container(
                        color: Colors.black.withAlpha(179),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange),
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
                              const Icon(Icons.error_outline,
                                  color: Colors.white),
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
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }
}
