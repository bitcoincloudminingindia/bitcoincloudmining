import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../utils/color_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/game_timer_widget.dart';

class CryptoRunnerGameScreen extends StatefulWidget {
  final String gameTitle;
  final double baseWinAmount;

  const CryptoRunnerGameScreen({
    super.key,
    required this.gameTitle,
    required this.baseWinAmount,
  });

  @override
  State<CryptoRunnerGameScreen> createState() => _CryptoRunnerGameScreenState();
}

class _CryptoRunnerGameScreenState extends State<CryptoRunnerGameScreen>
    with TickerProviderStateMixin {
  final double playerSize = 50.0;
  double playerY = 0.0;
  double playerVelocity = 0.0;
  final double gravity = 0.6;
  final double jumpForce = -15.0;
  bool isJumping = false;
  int score = 0;
  bool isGameActive = false;
  Timer? gameTimer;
  int remainingTime = 180; // 3 minutes
  final audioPlayer = AudioPlayer();
  bool isMuted = false;
  List<GameObject> gameObjects = [];
  bool isGameOver = false;
  double gameSpeed = 5.0;
  int level = 1;

  // Power-ups
  bool hasShield = false;
  bool hasDoublePoints = false;
  bool hasMagnet = false;
  int scoreMultiplier = 1;

  @override
  void initState() {
    super.initState();
    _loadSoundEffects();
    _initializeGame();
  }

  Future<void> _loadSoundEffects() async {
    try {
      await audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
      await audioPlayer.setVolume(0.5);
    } catch (e) {
      print('Error loading sound effects: $e');
    }
  }

  void _initializeGame() {
    playerY = 0.0;
    playerVelocity = 0.0;
    score = 0;
    level = 1;
    gameSpeed = 5.0;
    isGameOver = false;
    gameObjects.clear();
  }

  void startGame() {
    setState(() {
      isGameActive = true;
      _initializeGame();
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          _endGame();
        }
      });
    });

    // Game loop
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameActive) {
        timer.cancel();
        return;
      }

      setState(() {
        // Update player position
        playerVelocity += gravity;
        playerY += playerVelocity;

        // Ground collision
        if (playerY > MediaQuery.of(context).size.height - playerSize) {
          playerY = MediaQuery.of(context).size.height - playerSize;
          playerVelocity = 0;
          isJumping = false;
        }

        // Update game objects
        for (var object in gameObjects) {
          object.x -= gameSpeed;
        }

        // Remove off-screen objects
        gameObjects.removeWhere((object) => object.x < -50);

        // Generate new objects
        if (Random().nextDouble() < 0.02) {
          _generateGameObject();
        }

        // Check collisions
        _checkCollisions();

        // Increase difficulty
        if (score > 0 && score % 100 == 0) {
          level++;
          gameSpeed += 0.5;
        }
      });
    });
  }

  void _generateGameObject() {
    final random = Random();
    final screenHeight = MediaQuery.of(context).size.height;
    final y = random.nextDouble() * (screenHeight - 100);

    if (random.nextDouble() < 0.7) {
      // Generate coin
      gameObjects.add(GameObject(
        x: MediaQuery.of(context).size.width,
        y: y,
        type: GameObjectType.coin,
        width: 30,
        height: 30,
      ));
    } else {
      // Generate obstacle
      gameObjects.add(GameObject(
        x: MediaQuery.of(context).size.width,
        y: y,
        type: GameObjectType.obstacle,
        width: 40,
        height: 40,
      ));
    }
  }

  void _checkCollisions() {
    final playerRect = Rect.fromLTWH(
      MediaQuery.of(context).size.width / 4,
      playerY,
      playerSize,
      playerSize,
    );

    for (var object in gameObjects) {
      final objectRect = Rect.fromLTWH(
        object.x,
        object.y,
        object.width,
        object.height,
      );

      if (playerRect.overlaps(objectRect)) {
        if (object.type == GameObjectType.coin) {
          // Collect coin
          gameObjects.remove(object);
          score += 10 * scoreMultiplier;
          _playSound();
        } else if (object.type == GameObjectType.obstacle) {
          if (hasShield) {
            // Shield protects from one obstacle
            gameObjects.remove(object);
            hasShield = false;
          } else {
            _endGame();
          }
        }
      }
    }
  }

  void _jump() {
    if (!isJumping) {
      setState(() {
        playerVelocity = jumpForce;
        isJumping = true;
      });
    }
  }

  void _activatePowerUp(PowerUpType type) {
    setState(() {
      switch (type) {
        case PowerUpType.shield:
          hasShield = true;
          Future.delayed(const Duration(seconds: 10), () {
            setState(() {
              hasShield = false;
            });
          });
          break;
        case PowerUpType.doublePoints:
          hasDoublePoints = true;
          scoreMultiplier = 2;
          Future.delayed(const Duration(seconds: 15), () {
            setState(() {
              hasDoublePoints = false;
              scoreMultiplier = 1;
            });
          });
          break;
        case PowerUpType.magnet:
          hasMagnet = true;
          Future.delayed(const Duration(seconds: 10), () {
            setState(() {
              hasMagnet = false;
            });
          });
          break;
      }
    });
  }

  void _endGame() {
    gameTimer?.cancel();
    setState(() {
      isGameActive = false;
      isGameOver = true;
    });

    // Calculate rewards based on score
    final double baseReward = (score / 1000) * widget.baseWinAmount;
    final double finalReward = baseReward.clamp(0.0, widget.baseWinAmount);

    if (score > 0) {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      walletProvider.addEarning(
        finalReward,
        type: 'game_reward',
        description: 'Crypto Runner',
      );
    }

    _showGameOverDialog(finalReward);
  }

  void _showGameOverDialog(double reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorConstants.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Game Over!',
          style: TextStyle(color: ColorConstants.primaryTextColor),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score',
              style: TextStyle(color: ColorConstants.primaryTextColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Level: $level',
              style: TextStyle(color: ColorConstants.primaryTextColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Reward: ${reward.toStringAsFixed(8)} BTC',
              style: TextStyle(color: ColorConstants.primaryTextColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _playSound() async {
    if (!isMuted) {
      try {
        await audioPlayer.seek(Duration.zero);
        await audioPlayer.resume();
      } catch (e) {
        print('Error playing sound: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Crypto Runner',
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      body: Container(
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score: $score',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryTextColor,
                          ),
                        ),
                        Text(
                          'Level: $level',
                          style: TextStyle(
                            fontSize: 18,
                            color: ColorConstants.primaryTextColor,
                          ),
                        ),
                        if (hasDoublePoints)
                          Text(
                            '2x Points Active!',
                            style: TextStyle(
                              fontSize: 16,
                              color: ColorConstants.successColor,
                            ),
                          ),
                      ],
                    ),
                    if (isGameActive)
                      GameTimerWidget(
                        remainingTime: remainingTime,
                        totalTime: 180,
                      ),
                  ],
                ),
              ),
              if (isGameActive) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildPowerUpButton(
                          PowerUpType.shield,
                          'Shield',
                          Icons.shield,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildPowerUpButton(
                          PowerUpType.doublePoints,
                          '2x Points',
                          Icons.stars,
                          Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        _buildPowerUpButton(
                          PowerUpType.magnet,
                          'Magnet',
                          Icons.attractions,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: isGameActive ? _jump : null,
                  child: Stack(
                    children: [
                      // Player
                      Positioned(
                        left: MediaQuery.of(context).size.width / 4,
                        top: playerY,
                        child: Container(
                          width: playerSize,
                          height: playerSize,
                          decoration: BoxDecoration(
                            color: hasShield ? Colors.blue : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(77),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.rocket,
                            color: hasShield ? Colors.white : Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),

                      // Game objects
                      ...gameObjects.map((object) {
                        return Positioned(
                          left: object.x,
                          top: object.y,
                          child: Container(
                            width: object.width,
                            height: object.height,
                            decoration: BoxDecoration(
                              color: object.type == GameObjectType.coin
                                  ? Colors.amber
                                  : Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (object.type == GameObjectType.coin
                                          ? Colors.amber
                                          : Colors.red)
                                      .withAlpha(77),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              object.type == GameObjectType.coin
                                  ? Icons.monetization_on
                                  : Icons.warning,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              if (isGameActive)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Tap to jump! Collect coins and avoid obstacles!',
                    style: TextStyle(
                      color: ColorConstants.primaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              if (!isGameActive && !isGameOver)
                Center(
                  child: ElevatedButton(
                    onPressed: startGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: ColorConstants.accentColor,
                    ),
                    child: const Text(
                      'Start Game',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpButton(
    PowerUpType type,
    String label,
    IconData icon,
    Color color,
  ) {
    bool isActive = false;
    switch (type) {
      case PowerUpType.shield:
        isActive = hasShield;
        break;
      case PowerUpType.doublePoints:
        isActive = hasDoublePoints;
        break;
      case PowerUpType.magnet:
        isActive = hasMagnet;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? null : () => _activatePowerUp(type),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.grey
                : Color.fromRGBO(
                    color.r.toInt(),
                    color.g.toInt(),
                    color.b.toInt(),
                    0.3,
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.grey.shade300 : color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.grey.shade300
                      : ColorConstants.primaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}

enum PowerUpType {
  shield,
  doublePoints,
  magnet,
}

enum GameObjectType {
  coin,
  obstacle,
}

class GameObject {
  double x;
  final double y;
  final GameObjectType type;
  final double width;
  final double height;

  GameObject({
    required this.x,
    required this.y,
    required this.type,
    required this.width,
    required this.height,
  });
}
