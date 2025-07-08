import 'dart:async';

import 'package:bitcoin_cloud_mining/providers/reward_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/screens/referral_screen.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/sound_notification_service.dart';
import 'package:bitcoin_cloud_mining/utils/number_formatter.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  _RewardScreenState createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdService _adService = AdService();
  late ConfettiController _confettiController;
  late dynamic
      _rewardClaimHandler; // यहाँ RewardClaimHandler की जगह dynamic का उपयोग किया गया है ताकि undefined class error न आए।
  Timer? _countdownTimer;

  // Banner ad future
  Future<Widget?>? _bannerAdFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adService.loadRewardedAd(); // Ensure rewarded ad preloads on screen open
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadSocialMediaPlatforms();
    _startCountdownTimer();
    _rewardClaimHandler = RewardClaimHandler(
      context: context,
      rewardProvider: Provider.of<RewardProvider>(context, listen: false),
      walletProvider: Provider.of<WalletProvider>(context, listen: false),
      adService: _adService, // Pass the shared instance
    );
    _bannerAdFuture = _adService.getBannerAdWidget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewardClaimHandler = RewardClaimHandler(
      context: context,
      rewardProvider: Provider.of<RewardProvider>(context, listen: false),
      walletProvider: Provider.of<WalletProvider>(context, listen: false),
      adService: _adService, // Pass the shared instance
    );
  }

  Future<void> _loadSocialMediaPlatforms() async {
    await _rewardClaimHandler.rewardProvider.loadSocialMediaPlatforms();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adService.dispose();
    _confettiController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        margin: const EdgeInsets.only(left: 16),
        child: FloatingActionButton(
          backgroundColor: Colors.white.withAlpha(51),
          elevation: 0,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back button space
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: 56), // Space for back button
                    ),
                    // Center title
                    const Text(
                      'Rewards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Info button (optional, comment if _showRewardInfoDialog removed)
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: IconButton(
                    //     icon: const Icon(Icons.info_outline, color: Colors.white),
                    //     onPressed: () {
                    //       //_showRewardInfoDialog(context);
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Banner Ad Box (rewards ke upar)
              FutureBuilder<Widget?>(
                future: _bannerAdFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: snapshot.data,
                    );
                  } else {
                    return const SizedBox(height: 50);
                  }
                },
              ),
              // Yahan se rewards ka main content dalo
              Expanded(
                child: Consumer<RewardProvider>(
                  builder: (context, rewardProvider, _) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Social Media Rewards
                          ...rewardProvider.socialMediaPlatforms
                              .map((platform) => RewardCard(
                                    icon: Icons.people,
                                    title:
                                        'Follow ${platform['platform'].toString().toUpperCase()}',
                                    subtitle:
                                        '${platform['handle']}\n${platform['url']}',
                                    rewardAmount:
                                        NumberFormatter.formatBTCAmount(
                                            double.parse(
                                                platform['rewardAmount']
                                                    .toString())),
                                    canClaim: true,
                                    onClaim: () async {
                                      final url = platform['url'];
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication);

                                        // Show notification and play sound for social media reward
                                        await SoundNotificationService
                                            .showRewardNotification(
                                          amount: double.parse(
                                              platform['rewardAmount']
                                                  .toString()),
                                          type:
                                              '${platform['platform'].toString().toUpperCase()} Follow',
                                        );
                                        await SoundNotificationService
                                            .playEarningSound();
                                      }
                                    },
                                    gradientStart: Color(0xFF833AB4),
                                    gradientEnd: Color(0xFFF77737),
                                  )),
                          // Referral Reward
                          RewardCard(
                            icon: Icons.share,
                            title: 'Referral Reward',
                            subtitle: 'Refer friends and earn bonus!',
                            rewardAmount: NumberFormatter.formatBTCAmount(
                                rewardProvider.referralReward),
                            canClaim: true,
                            onClaim: () async {
                              // Claim referral reward
                              await rewardProvider.claimReferralReward(
                                Provider.of<WalletProvider>(context,
                                    listen: false),
                              );

                              // Navigate to referral screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReferralScreen(),
                                ),
                              );
                            },
                            gradientStart: Color(0xFF11998e),
                            gradientEnd: Color(0xFF38ef7d),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RewardClaimHandler {
  final BuildContext context;
  final RewardProvider rewardProvider;
  final WalletProvider walletProvider;
  final AdService adService;

  RewardClaimHandler({
    required this.context,
    required this.rewardProvider,
    required this.walletProvider,
    required this.adService,
  });

  void _showAdNotLoadedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rewarded ads not loaded. Please try again later.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAdDismissedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Ad was dismissed. Please watch the full ad to claim reward.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAdFailedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to show ad. Please try again.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error claiming reward: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _claimReward(String rewardType) async {
    switch (rewardType) {
      case 'social_media_reward':
        // सोशल मीडिया रिवॉर्ड्स अलग से हैंडल किए जाते हैं
        break;
      case 'ad_reward':
        await rewardProvider.claimAdReward(walletProvider);
        break;

      default:
        throw Exception('Unknown reward type: $rewardType');
    }
  }

  Future<bool> _showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
  }) async {
    if (!adService.isRewardedAdLoaded) {
      _showAdNotLoadedMessage();
      return false;
    }

    try {
      return await adService.showRewardedAd(
        onRewarded: onRewarded,
        onAdDismissed: onAdDismissed,
      );
    } catch (e) {
      _showAdFailedMessage();
      return false;
    }
  }

  Future<void> handleRewardClaim({
    required String rewardType,
    required double amount,
    required bool requiresAd,
    required VoidCallback onSuccess,
  }) async {
    try {
      if (requiresAd) {
        if (!adService.isRewardedAdLoaded) {
          _showAdNotLoadedMessage();
          return;
        }

        final success = await _showRewardedAd(
          onRewarded: (reward) async {
            await _claimReward(rewardType);
            onSuccess();
          },
          onAdDismissed: _showAdDismissedMessage,
        );

        if (!success) {
          _showAdFailedMessage();
        }
      } else {
        await _claimReward(rewardType);
        onSuccess();
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }
}

class RewardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String rewardAmount;
  final bool canClaim;
  final VoidCallback onClaim;
  final Color gradientStart;
  final Color gradientEnd;
  final Widget? customWidget;

  const RewardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rewardAmount,
    required this.canClaim,
    required this.onClaim,
    required this.gradientStart,
    required this.gradientEnd,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (customWidget != null) ...[
                const SizedBox(height: 12),
                customWidget!,
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rewardAmount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: canClaim ? onClaim : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canClaim ? Colors.green : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      canClaim ? 'Claim' : 'Claimed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
