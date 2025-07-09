import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/wallet_provider.dart';
import '../services/ad_service.dart';
import '../services/sound_notification_service.dart';

class MinerMadnessGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const MinerMadnessGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  State<MinerMadnessGameScreen> createState() => _MinerMadnessGameScreenState();
}

class _MinerMadnessGameScreenState extends State<MinerMadnessGameScreen>
    with TickerProviderStateMixin {
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  final bool _isMuted = false;

  // Animation controllers
  late AnimationController _spinController;
  late AnimationController _winAnimationController;

  // Wheel state
  bool _isSpinning = false;
  double _currentAngle = 0;
  double _endAngle = 0;

  // BTC reward data
  final List<double> _rewards = [];
  double _wonAmount = 0;
  bool _showReward = false;

  // Confetti controller
  late AnimationController _confettiController;

  // Add these variables to the state class
  int _spinCount = 0;
  static const int SPINS_FOR_BONUS = 1000;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // Ad service
  final AdService _adService = AdService();
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  String? _adError;

  // Add loading state
  bool _isCollecting = false;

  @override
  void initState() {
    super.initState();
    _loadSpinCount();
    _initializeAudio();
    _initializeAds();

    // Initialize animation controllers
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _winAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Generate 10 random BTC rewards
    _generateRandomRewards();

    // Setup animation listeners
    _setupAnimationListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _spinController.dispose();
    _winAnimationController.dispose();
    _confettiController.dispose();
    _adService.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (e) {}
  }

  Future<void> _initializeAds() async {
    setState(() {
      _isAdLoading = true;
      _adError = null;
    });

    try {
      _adService.loadBannerAd(); // No await, as this is a void method
      await _adService.loadRewardedAd();

      if (mounted) {
        setState(() {
          _isAdLoaded = _adService.isBannerAdLoaded;
          _isAdLoading = false;
        });
      }
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

  Future<void> _showRewardedAd(VoidCallback onRewarded) async {
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
      if (!_adService.isRewardedAdLoaded) {
        await _adService.loadRewardedAd();
      }

      if (mounted) {
        await _adService.showRewardedAd(
          onRewarded: (amount) {
            onRewarded();
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
          _isAdLoading = false;
        });
      }
    }
  }

  // Replace the existing _generateRandomRewards method
  void _generateRandomRewards() {
    final Random random = Random();
    _rewards.clear();

    // Sabhi rewards ek hi range me honge
    const double minReward = 0.000000000000001000;
    const double maxReward = 0.000000000000010000;

    for (int i = 0; i < 10; i++) {
      final double randomValue =
          minReward + (random.nextDouble() * (maxReward - minReward));
      _rewards.add(randomValue);
    }

    // Shuffle the rewards
    _rewards.shuffle();
  }

  // Remove the unused _addBtcToWallet method and update _setupAnimationListeners
  void _setupAnimationListeners() {
    _spinController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });

        // Play win sound
        if (!_isMuted) {
          _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        }

        // Show the reward display
        setState(() {
          _showReward = true;
        });

        // Start win animations
        _winAnimationController.forward(from: 0);
        _confettiController.forward(from: 0);
      }
    });
  }

  void _spinWheel() {
    if (_isSpinning || _cooldownSeconds > 0) return;

    setState(() {
      _isSpinning = true;
      _showReward = false;
      _spinCount++;
    });

    // हर 5 spin के बाद cooldown शुरू करें
    if (_spinCount % 5 == 0) {
      _startCooldown();
    }

    final Random random = Random();
    final int numRotations = 7 + random.nextInt(5); // Increased base rotations
    const double segmentAngle = 2 * pi / 10; // Angle of each segment

    // Choose a random segment index where the wheel will stop (0-9)
    final int stoppingSegmentIndex = random.nextInt(10);

    // Calculate the angle of the middle of the stopping segment from the right (angle 0)
    final double segmentMiddleAngleFromRight =
        stoppingSegmentIndex * segmentAngle + segmentAngle / 2;

    // Calculate the total required rotation angle (from the initial drawing orientation where segment 0 middle is at pi/2)
    // We want the final orientation (pi/2 + _endAngle) to align with segmentMiddleAngleFromRight + N * 2 * pi.
    // So, _endAngle = segmentMiddleAngleFromRight - pi/2 + N * 2 * pi.
    // Let N be numRotations.
    _endAngle = segmentMiddleAngleFromRight - pi / 2 + numRotations * 2 * pi;

    // Ensure the end angle is positive
    _endAngle = (_endAngle + 2 * pi) % (2 * pi) +
        numRotations *
            2 *
            pi; // Re-calculate to ensure positive angle and desired rotations

    // Set the won amount to the exact value of the stopping segment
    _wonAmount = _rewards[stoppingSegmentIndex];

    // Start spinning animation
    _spinController.forward(from: 0);

    // Handle spin count and bonus
    SharedPreferences.getInstance().then((preferences) {
      preferences.setInt('wheelSpinCount', _spinCount);
      if (_spinCount >= SPINS_FOR_BONUS) {
        _awardBaseBonus();
        setState(() => _spinCount = 0);
        preferences.setInt('wheelSpinCount', 0);
      }
    });
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60 * 60; // 60 मिनट
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Add this method to load saved spin count
  Future<void> _loadSpinCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _spinCount = prefs.getInt('wheelSpinCount') ?? 0;
    });
  }

  // Add method to award base bonus
  Future<void> _awardBaseBonus() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    try {
      await walletProvider.addEarning(widget.baseWinAmount,
          type: 'game', description: 'Miner Madness - 1000 Spins Bonus');

      // Play success chime for achievement
      await SoundNotificationService.playSuccessChime();

      // Show bonus notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Achievement Unlocked! 1000 Spins Completed - Bonus ${widget.baseWinAmount.toStringAsFixed(18)} BTC Added!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWalletBalance(),
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildSpinningWheel(),
                          if (_showReward)
                            Positioned(
                              top: 0,
                              child: _buildWinDisplay(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildSpinButton(),
                      const SizedBox(height: 20),
                      _buildGameInstructions(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (_isAdLoaded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 50,
                    child: _adService.getBannerAd(),
                  ),
                ),
              if (_isAdLoading)
                Container(
                  color: Colors.black.withAlpha(128),
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
    );
  }

  Widget _buildGameInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.shade400,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Spin the wheel and win BTC rewards! Each spin can reward you with 0.000000000001 to 0.00000000009 BTC.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue.shade100,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spins until bonus: ${SPINS_FOR_BONUS - _spinCount}',
            style: TextStyle(
              color: Colors.green.shade300,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinningWheel() {
    final size = MediaQuery.of(context).size;
    final wheelSize = size.width * 0.8;
    const maxWheelSize = 300.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: min(wheelSize + 20, maxWheelSize + 20),
          height: min(wheelSize + 20, maxWheelSize + 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.blue.shade400, Colors.transparent],
              stops: const [0.9, 1.0],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            final double animationValue = _spinController.value;
            // Apply easeOutQuart curve to the animation value
            final double curvedValue =
                Curves.easeOutQuart.transform(animationValue);
            // Animate _currentAngle from 0 to _endAngle using the curved value
            _currentAngle = _endAngle * curvedValue;

            // The total rotation applied to the wheel is the initial pi/2 offset plus the animated angle
            final double totalRotation = pi / 2 + _currentAngle;

            return Transform.rotate(
              angle: totalRotation,
              child: child,
            );
          },
          child: Container(
            width: min(wheelSize, maxWheelSize),
            height: min(wheelSize, maxWheelSize),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: CustomPaint(
              painter: WheelPainter(
                segments: 10,
                rewards: _rewards,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 20,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(255, 255, 255, 0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTap: _isSpinning || _showReward || _cooldownSeconds > 0
          ? null
          : _spinWheel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: 180,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: _isSpinning || _showReward || _cooldownSeconds > 0
                ? [Colors.grey, Colors.grey.shade400]
                : [Colors.orange, Colors.deepOrange],
          ),
        ),
        child: Center(
          child: _cooldownSeconds > 0
              ? Text(
                  'Cooldown: ${(_cooldownSeconds ~/ 60).toString().padLeft(2, '0')}:${(_cooldownSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  _isSpinning
                      ? 'Spinning...'
                      : (_showReward ? 'Collect Reward First!' : 'Spin Now!'),
                  style: GoogleFonts.poppins(
                    color: Colors.white
                        .withAlpha(_isSpinning || _showReward ? 179 : 255),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWinDisplay() {
    return AnimatedBuilder(
      animation: _winAnimationController,
      builder: (context, child) {
        final scale =
            Curves.elasticOut.transform(_winAnimationController.value);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.withAlpha(51),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withAlpha(26),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(76),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.shade400.withAlpha(77),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '🎉 Congratulations! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.amber,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withAlpha(38),
                        Colors.amber.withAlpha(13),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue.shade400.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'You Won',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_wonAmount.toStringAsFixed(18)} BTC',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.amber,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isCollecting
                      ? null
                      : () async {
                          // Show rewarded ad first
                          await _showRewardedAd(() async {
                            // This callback is executed after the rewarded ad is watched
                            setState(() {
                              _isCollecting =
                                  true; // Set collecting state while adding to wallet
                            });

                            try {
                              final walletProvider =
                                  Provider.of<WalletProvider>(context,
                                      listen: false);

                              await walletProvider.addEarning(
                                _wonAmount,
                                type: 'game',
                                description: 'Miner Madness Wheel Spin Reward',
                              );

                              if (mounted) {
                                setState(() {
                                  _showReward = false; // Hide the win display
                                  _isCollecting =
                                      false; // Reset collecting state
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Added ${_wonAmount.toStringAsFixed(18)} BTC to wallet',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _isCollecting = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Failed to add reward to wallet'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    shadowColor: Colors.amber.withAlpha(51),
                  ),
                  child: _isCollecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Collect Reward',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletBalance() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue.shade400,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 255, 255, 0.9),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.blue.shade400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${walletProvider.btcBalance.toStringAsFixed(18)} BTC',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WheelPainter extends CustomPainter {
  final int segments;
  final List<double> rewards;

  WheelPainter({
    required this.segments,
    required this.rewards,
  });

  String _formatBtcValue(double value) {
    // Custom formatting to match the image as closely as possible
    String valueString = value.toStringAsFixed(18).replaceFirst('0.', '');
    // Remove trailing zeros
    while (valueString.endsWith('0')) {
      valueString = valueString.substring(0, valueString.length - 1);
    }

    // Use simple \n for newlines within string literals
    if (valueString.length <= 7) {
      return '0.\n$valueString\nBTC';
    } else if (valueString.length <= 15) {
      return '0.\n${valueString.substring(0, 7)}\n${valueString.substring(7)}\nBTC';
    } else {
      return '0.\n${valueString.substring(0, 10)}\n${valueString.substring(10)}\nBTC';
    }
  }

  Color _getSegmentColor(int index) {
    // Mapping index to colors based on the image
    final List<Color> textColors = [
      Colors.cyanAccent, // Index 0
      Colors.pinkAccent, // Index 1
      Colors.redAccent, // Index 2
      Colors.deepOrangeAccent, // Index 3
      Colors.yellowAccent, // Index 4
      Colors.limeAccent, // Index 5
      Colors.tealAccent, // Index 6
      Colors.blueAccent, // Index 7
      Colors.purpleAccent, // Index 8
      Colors.pink, // Index 9
    ];
    return textColors[index % textColors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final List<Color> colors = [
      Colors.blue.shade800,
      Colors.blue.shade600,
    ];

    final double anglePerSegment = 2 * pi / segments;

    for (int i = 0; i < segments; i++) {
      final double startAngle = i * anglePerSegment;

      final Paint segmentPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        anglePerSegment,
        true,
        segmentPaint,
      );

      final Paint strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        anglePerSegment,
        true,
        strokePaint,
      );

      final String formattedText = _formatBtcValue(rewards[i]);
      final Color textColor = _getSegmentColor(i);

      final double textAngle = startAngle + (anglePerSegment / 2);
      // Adjust text position further inward to ensure it stays within the segment
      final double textRadius =
          radius * 0.7; // Adjusted position further inward
      final Offset textPosition = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: formattedText,
          style: TextStyle(
            color: textColor,
            fontSize: 9, // Maintain font size
            fontWeight: FontWeight.bold,
            height: 1.1, // Maintain height for multiple lines
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(76),
                offset: const Offset(1, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      canvas.save();
      canvas.translate(textPosition.dx, textPosition.dy);
      // Rotate text to be perpendicular to the radius
      canvas.rotate(textAngle + pi / 2); // Rotate to be perpendicular

      // Paint text without background
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    final Paint innerCirclePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blue.shade400, Colors.blue.shade900],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.15))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius * 0.15,
      innerCirclePaint,
    );

    final Paint outerGlowPaint = Paint()
      ..color = Colors.blue.shade400.withAlpha(77)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      center,
      radius - 4,
      outerGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final Random random = Random();
  final List<Confetti> confetti = [];

  ConfettiPainter({required this.animation}) {
    for (int i = 0; i < 50; i++) {
      confetti.add(Confetti(
        position: Offset(
          -50 + random.nextDouble() * 400,
          -50 + random.nextDouble() * 400,
        ),
        color: _getRandomColor(),
        size: 5 + random.nextDouble() * 10,
        speed: 100 + random.nextDouble() * 200,
        angle: random.nextDouble() * pi * 2,
      ));
    }
  }

  Color _getRandomColor() {
    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];

    return colors[random.nextInt(colors.length)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final Offset currentPosition = Offset(
        piece.position.dx + cos(piece.angle) * piece.speed * animation.value,
        piece.position.dy +
            sin(piece.angle) * piece.speed * animation.value +
            100 * animation.value * animation.value,
      );

      final Paint paint = Paint()..color = piece.color;

      canvas.drawCircle(currentPosition, piece.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Confetti {
  final Offset position;
  final Color color;
  final double size;
  final double speed;
  final double angle;

  Confetti({
    required this.position,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
  });
}
