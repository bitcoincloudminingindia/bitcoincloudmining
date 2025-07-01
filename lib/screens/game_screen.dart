import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/screens/bitcoin_blast_game_screen.dart';
import 'package:bitcoin_cloud_mining/screens/btc_slot_spin_game_screen.dart';
import 'package:bitcoin_cloud_mining/screens/crypto_craze_game_screen.dart';
import 'package:bitcoin_cloud_mining/screens/flip_coin_game_screen.dart';
import 'package:bitcoin_cloud_mining/screens/hash_rush_game_screen.dart';
import 'package:bitcoin_cloud_mining/screens/miner_madness_game_screen.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../utils/color_constants.dart';
import '../widgets/custom_app_bar.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AdService _adService = AdService();
  bool isAdLoaded = false;

  final List<Map<String, dynamic>> gameOptions = [
    {
      'title': 'Hash Rush',
      'icon': '⚡',
      'winAmount': 0.005,
      'color': Colors.purple
    },
    {
      'title': 'Crypto Craze',
      'icon': '💻',
      'winAmount': 0.010,
      'color': Colors.teal
    },
    {
      'title': 'Bitcoin Blast',
      'icon': '💥',
      'winAmount': 0.000000000000000100,
      'color': Colors.orange
    },
    {
      'title': 'Miner Madness',
      'icon': '⛏️',
      'winAmount': 0.003,
      'color': Colors.cyan
    },
    {
      'title': 'Flip the Coin',
      'icon': '🪙',
      'winAmount': 0.000000000000000100,
      'color': Colors.green
    },
    {
      'title': 'BTC Slot Spin',
      'icon': '🎰',
      'winAmount': 0.000000000000001000,
      'color': Colors.blue
    },
    {
      'title': 'Crypto Clash',
      'icon': '🎮',
      'winAmount': 0.006,
      'color': Colors.pink
    },
    {
      'title': 'Coin Quest',
      'icon': '💰',
      'winAmount': 0.009,
      'color': Colors.amber
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    _adService.loadBannerAd(); // No await, as this is a void method
    // Optionally, you can setState after a short delay to check if the ad loaded
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isAdLoaded = _adService.isBannerAdLoaded;
    });
  }

  void navigateToGameScreen(String title, double winAmount) async {
    Widget targetScreen;

    if (title == 'Crypto Craze') {
      targetScreen =
          CryptoCrazeGameScreen(gameTitle: title, baseWinAmount: winAmount);
    } else if (title == 'Bitcoin Blast') {
      targetScreen =
          BitcoinBlastGameScreen(gameTitle: title, baseWinAmount: winAmount);
    } else if (title == 'Miner Madness') {
      targetScreen =
          MinerMadnessGameScreen(gameTitle: title, baseWinAmount: winAmount);
    } else if (title == 'Flip the Coin') {
      targetScreen = const FlipCoinGameScreen(
        gameTitle: 'Flip the Coin',
        baseWinAmount: 0.000000000000000100,
      );
    } else if (title == 'BTC Slot Spin') {
      targetScreen = BTCSlotSpinGameScreen(
        gameTitle: title,
        baseWinAmount: winAmount,
      );
    } else {
      targetScreen =
          HashRushGameScreen(gameTitle: title, baseWinAmount: winAmount);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );

    if (result != null && result is double) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Congratulations! You earned ${result.toStringAsFixed(18)} BTC!')),
      );
    }
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double btcBalance = context.watch<WalletProvider>().btcBalance;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Games',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Wallet Balance: ${btcBalance.toStringAsFixed(18)} BTC',
                    style: GoogleFonts.poppins(
                        color: Colors.yellowAccent, fontSize: 20),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: gameOptions.length,
                    itemBuilder: (context, index) {
                      final game = gameOptions[index];
                      return GestureDetector(
                        onTap: () => navigateToGameScreen(
                            game['title'], game['winAmount']),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [game['color'], Colors.black],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(
                                    game['color'].red,
                                    game['color'].green,
                                    game['color'].blue,
                                    0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 28,
                                child: Text(
                                  game['icon'],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontFamily: 'Segoe UI Emoji',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                game['title'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Win up to: ${game['winAmount']} BTC',
                                style: GoogleFonts.poppins(
                                  color: Colors.yellowAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Remove banner ad from this screen
              ],
            ),
          ),
        ),
      ),
    );
  }
}
