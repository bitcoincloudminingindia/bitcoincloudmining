import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../services/ad_service.dart';
import '../utils/color_constants.dart';
import '../widgets/custom_app_bar.dart';

class FlipCoinGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const FlipCoinGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  State<FlipCoinGameScreen> createState() => _FlipCoinGameScreenState();
}

class _FlipCoinGameScreenState extends State<FlipCoinGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipping = false;
  bool? _userChoice; // true for heads, false for tails
  bool? _result;
  bool _showResult = false;
  bool _showCongratulations = false;
  final Random _random = Random();
  final Decimal _winAmount = Decimal.parse('0.000000000000001');
  final Decimal _penaltyAmount = Decimal.parse('0.000000000000000010');
  int _totalFlips = 0;
  int _wins = 0;
  Decimal _gameWalletBalance = Decimal.zero;
  bool _isTransferring = false;
  Decimal _pendingReward = Decimal.zero;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFlipping = false;
          _showResult = true;
          if (_userChoice != null && _result != null) {
            final bool isCorrect = _userChoice == _result;
            _totalFlips++;
            if (isCorrect) {
              _wins++;
              _pendingReward = _winAmount;
              _showCongratulations = true;
              _loadRewardedAd();
            } else {
              _gameWalletBalance -= _penaltyAmount;
              _showInterstitialAd();
            }
          }
        });
      }
    });

    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _loadInterstitialAd();
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load interstitial ad: $error');
        },
      ),
    );
  }

  Future<void> _collectReward() async {
    if (_rewardedAd == null) {
      _addRewardToWallet();
      return;
    }

    setState(() {
      _isAdLoading = true;
    });

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        _addRewardToWallet();
      },
    );

    setState(() {
      _isAdLoading = false;
    });

    _loadRewardedAd();
  }

  void _addRewardToWallet() {
    setState(() {
      _gameWalletBalance += _pendingReward;
      _pendingReward = Decimal.zero;
      _showCongratulations = false;
    });
  }

  Future<void> _transferToMainWallet() async {
    if (_gameWalletBalance <= Decimal.zero) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isTransferring = true;
    });

    try {
      debugPrint(
          '💾 Transferring Flip Coin earnings: ${_gameWalletBalance.toString()} BTC');

      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.addEarning(
        _gameWalletBalance.toDouble(),
        type: 'game',
        description: 'Flip Coin Game Earnings',
      );

      debugPrint('✅ Flip Coin earnings transferred successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ${_gameWalletBalance.toStringAsFixed(18)} BTC added to wallet!',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: ColorConstants.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error transferring Flip Coin earnings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error transferring earnings: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE53935), // Error color
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
        Navigator.pop(context);
      }
    }
  }

  void _flipCoin(bool isHeads) {
    if (_isFlipping) return;

    // Generate random result before starting animation
    final bool randomResult = _random.nextBool();

    setState(() {
      _isFlipping = true;
      _userChoice = isHeads;
      _result = randomResult;
      _showResult = false;
    });

    debugPrint(
        'Starting flip - User chose: [1m${isHeads ? "Heads" : "Tails"}[0m');
    debugPrint('Random result: [1m${randomResult ? "Heads" : "Tails"}[0m');

    // Start animation
    _controller.reset();
    _controller.forward();
  }

  int get _winRate =>
      _totalFlips > 0 ? ((_wins / _totalFlips) * 100).round() : 0;

  Future<void> _handleBackButton() async {
    if (_isTransferring) return;

    // Show confirmation dialog if there are earnings
    if (_gameWalletBalance > Decimal.zero) {
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
            'You have ${_gameWalletBalance.toString()} BTC earnings!\n\nDo you want to save and exit?',
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

    // Transfer earnings to main wallet
    await _transferToMainWallet();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackButton();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Flip the Coin',
          titleTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleBackButton,
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorConstants.primaryColor,
                    ColorConstants.secondaryColor,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total Flips', '$_totalFlips'),
                          _buildStatItem('Wins', '$_wins'),
                          _buildStatItem('Win Rate', '$_winRate%'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Game Wallet: ${_gameWalletBalance.toString()} BTC',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final transform = Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(_animation.value * pi);
                        return Transform(
                          transform: transform,
                          alignment: Alignment.center,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.amber.shade300,
                                  Colors.amber.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withAlpha(77),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: Colors.black.withAlpha(77),
                                  blurRadius: 8,
                                  spreadRadius: -3,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.amber.shade200,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: _result == null || _animation.value < 0.5
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.amber.shade200
                                                .withAlpha(77),
                                          ),
                                          child: const Icon(
                                            Icons.currency_bitcoin,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade200
                                                .withAlpha(77),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: const Text(
                                            'HEADS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
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
                                      ],
                                    )
                                  : Transform(
                                      transform: Matrix4.identity()
                                        ..rotateX(pi),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.amber.shade200
                                                  .withAlpha(77),
                                            ),
                                            child: const Icon(
                                              Icons.currency_bitcoin,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade200
                                                  .withAlpha(77),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              _result! ? 'HEADS' : 'TAILS',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
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
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildChoiceButton(true),
                          _buildChoiceButton(false),
                        ],
                      ),
                    ),
                    if (_showResult && _userChoice != null && _result != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _userChoice == _result
                                ? ColorConstants.successColor.withAlpha(77)
                                : ColorConstants.errorColor.withAlpha(77),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _userChoice == _result
                                  ? ColorConstants.successColor
                                  : ColorConstants.errorColor,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _userChoice == _result
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _userChoice == _result
                                      ? 'Correct! You earned ${_winAmount.toString()} BTC'
                                      : 'Wrong! Penalty: ${_penaltyAmount.toString()} BTC',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (_bannerAd != null)
                      Container(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        alignment: Alignment.center,
                        child: AdWidget(ad: _bannerAd!),
                      ),
                  ],
                ),
              ),
            ),
            if (_showCongratulations)
              Container(
                color: Colors.black.withAlpha(128),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(50),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration,
                          color: Colors.amber,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Congratulations!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You won ${_pendingReward.toString()} BTC!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isAdLoading ? null : _collectReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isAdLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Collect Reward',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isTransferring)
              Container(
                color: Colors.black.withAlpha(128),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Transferring earnings to your wallet...',
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
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(bool isHeads) {
    return ElevatedButton(
      onPressed: _isFlipping ? null : () => _flipCoin(isHeads),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: ColorConstants.accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: ColorConstants.accentColor.withAlpha(77),
      ),
      child: Text(
        isHeads ? '🪙 Heads' : '🎯 Tails',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Save any pending earnings before disposing
    if (_gameWalletBalance > Decimal.zero) {
      try {
        Provider.of<WalletProvider>(context, listen: false).addEarning(
          _gameWalletBalance.toDouble(),
          type: 'game',
          description: 'Flip Coin Game Earnings (Auto-saved)',
        );
        debugPrint(
            '💾 Auto-saved Flip Coin earnings on dispose: ${_gameWalletBalance.toString()} BTC');
      } catch (e) {
        debugPrint('❌ Error auto-saving Flip Coin earnings: $e');
      }
    }

    _controller.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}
