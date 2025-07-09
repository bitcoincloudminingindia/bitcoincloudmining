import 'dart:async';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/wallet_provider.dart';
import '../services/ad_service.dart';
import '../services/sound_notification_service.dart';
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
  Future<Widget?>? _bannerAdFuture;
  final AdService _adService = AdService();
  bool _isAdLoading = false;
  int _headsTapCount = 0;
  int _tailsTapCount = 0;
  bool _isRewardedAdRequired = false;

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
            } else {
              _gameWalletBalance -= _penaltyAmount;
            }
          }
        });
      }
    });

    _bannerAdFuture = _adService.getBannerAdWidget();
    _loadAdRequiredState();
  }

  Future<void> _loadAdRequiredState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRewardedAdRequired = prefs.getBool('flipcoin_ad_required') ?? false;
    });
  }

  Future<void> _saveAdRequiredState(bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flipcoin_ad_required', required);
  }

  Future<void> _collectReward() async {
    setState(() {
      _isAdLoading = true;
    });
    await _adService.showRewardedAd(
      onRewarded: (amount) {
        _addRewardToWallet();
      },
      onAdDismissed: () {
        setState(() {
          _isAdLoading = false;
          _showCongratulations = false;
        });
      },
    );
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
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.addEarning(
        _gameWalletBalance.toDouble(),
        type: 'game',
        description: 'Flip Coin Game Earnings',
      );

      // Play earning sound for game completion
      await SoundNotificationService.playEarningSound();

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
    if (_isFlipping || _isRewardedAdRequired || _isAdLoading) return;

    // Tap count logic
    if (isHeads) {
      _headsTapCount++;
      if (_headsTapCount % 10 == 0) {
        setState(() {
          _isRewardedAdRequired = true;
        });
        _saveAdRequiredState(true);
        _showAdForTap();
        return;
      }
    } else {
      _tailsTapCount++;
      if (_tailsTapCount % 10 == 0) {
        setState(() {
          _isRewardedAdRequired = true;
        });
        _saveAdRequiredState(true);
        _showAdForTap();
        return;
      }
    }

    // Generate random result before starting animation
    final bool randomResult = _random.nextBool();

    setState(() {
      _isFlipping = true;
      _userChoice = isHeads;
      _result = randomResult;
      _showResult = false;
    });

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
                    _buildAdRequiredLabel(),
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
                    FutureBuilder<Widget?>(
                      future: _bannerAdFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return snapshot.data ?? const SizedBox.shrink();
                        }
                        return const SizedBox(height: 50);
                      },
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isAdLoading ? null : _collectReward,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstants.accentColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Collect Reward',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isAdLoading ? null : _watchAdFor2x,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstants.accentColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Watch Ad for 2x',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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
      onPressed: (_isFlipping || _isRewardedAdRequired || _isAdLoading)
          ? null
          : () => _flipCoin(isHeads),
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
      } catch (e) {}
    }
    _saveAdRequiredState(_isRewardedAdRequired);
    _controller.dispose();
    super.dispose();
  }

  void _watchAdFor2x() async {
    setState(() {
      _isAdLoading = true;
    });
    await _adService.showRewardedAd(
      onRewarded: (amount) {
        _add2xRewardToWallet();
      },
      onAdDismissed: () {
        setState(() {
          _isAdLoading = false;
          _showCongratulations = false;
        });
      },
    );
  }

  void _add2xRewardToWallet() {
    setState(() {
      _gameWalletBalance += _pendingReward * Decimal.fromInt(2);
      _pendingReward = Decimal.zero;
      _showCongratulations = false;
      _isAdLoading = false;
    });
  }

  void _showAdForTap() async {
    setState(() {
      _isAdLoading = true;
    });
    await _adService.showRewardedAd(
      onRewarded: (amount) {
        setState(() {
          _isRewardedAdRequired = false;
          _isAdLoading = false;
        });
        _saveAdRequiredState(false);
      },
      onAdDismissed: () {
        setState(() {
          _isRewardedAdRequired = false;
          _isAdLoading = false;
        });
        _saveAdRequiredState(false);
      },
    );
  }

  // UI में Ad Required label दिखाएं
  Widget _buildAdRequiredLabel() {
    if (_isRewardedAdRequired || _isAdLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          'Ad Required! Please watch ad to continue.',
          style: TextStyle(
            color: Colors.red.shade300,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
