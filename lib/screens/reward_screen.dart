import 'dart:async';

import 'package:bitcoin_cloud_mining/providers/reward_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/screens/referral_screen.dart';
import 'package:bitcoin_cloud_mining/services/custom_ad_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  _RewardScreenState createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CustomAdService _adService = CustomAdService();
  late ConfettiController _confettiController;
  late RewardClaimHandler _rewardClaimHandler;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adService.loadRewardedAd();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadSocialMediaPlatforms();
    _startCountdownTimer();
    Future.microtask(() {
      Provider.of<RewardProvider>(context, listen: false).syncRewards();
    });
    _rewardClaimHandler = RewardClaimHandler(
      context: context,
      rewardProvider: Provider.of<RewardProvider>(context, listen: false),
      walletProvider: Provider.of<WalletProvider>(context, listen: false),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewardClaimHandler = RewardClaimHandler(
      context: context,
      rewardProvider: Provider.of<RewardProvider>(context, listen: false),
      walletProvider: Provider.of<WalletProvider>(context, listen: false),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                      // Info button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.white),
                          onPressed: () {
                            _showRewardInfoDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance Card
                const BalanceDisplay(),

                // Tab Bar
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(204),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white,
                    ),
                    labelColor: Colors.blue[900],
                    unselectedLabelColor: Colors.white,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Daily Rewards'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time),
                            SizedBox(width: 8),
                            Text('Hourly Rewards'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        child: DailyRewardSection(
                            rewardClaimHandler: _rewardClaimHandler),
                      ),
                      SingleChildScrollView(
                        child: HourlyRewardSection(
                            rewardClaimHandler: _rewardClaimHandler),
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

  void _showRewardInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rewards Information'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Rewards:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Complete daily tasks to earn rewards'),
              Text('• Follow social media for bonus rewards'),
              Text('• Watch ads to double your rewards'),
              SizedBox(height: 16),
              Text(
                'Hourly Rewards:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Claim rewards every hour'),
              Text('• Maintain your streak for bonus rewards'),
              Text('• Higher rewards for active users'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class RewardClaimHandler {
  final BuildContext context;
  final RewardProvider rewardProvider;
  final WalletProvider walletProvider;
  final CustomAdService adService;

  RewardClaimHandler({
    required this.context,
    required this.rewardProvider,
    required this.walletProvider,
  }) : adService = CustomAdService();

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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _claimReward(String rewardType) async {
    switch (rewardType) {
      case 'daily_reward':
        await rewardProvider.claimDailyPlay(walletProvider);
        break;
      case 'daily_mine_reward':
        await rewardProvider.claimDailyMine(walletProvider);
        break;
      case 'social_media_reward':
        // Social media rewards are handled separately
        break;
      case 'ad_reward':
        await rewardProvider.claimAdReward(walletProvider);
        break;
      case 'hourly_reward':
        await rewardProvider.claimHourly(walletProvider);
        break;
      case 'streak_reward':
        await rewardProvider.claimStreakBonus(walletProvider);
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

class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardProvider = Provider.of<RewardProvider>(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Rewards Claimed',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.currency_bitcoin,
                color: Colors.amber,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '${rewardProvider.lifetimeRewards.toStringAsFixed(16)} BTC',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                context,
                'Today Claimed',
                '${rewardProvider.todayRewards.toStringAsFixed(16)} BTC',
                Icons.today,
              ),
              _buildStatItem(
                context,
                'Streak',
                '${rewardProvider.streakCount} days',
                Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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

class DailyRewardSection extends StatelessWidget {
  final RewardClaimHandler rewardClaimHandler;

  const DailyRewardSection({
    super.key,
    required this.rewardClaimHandler,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        return Column(
          children: [
            RewardCard(
              icon: Icons.play_arrow,
              title: 'Daily Play Reward',
              subtitle: 'Complete your daily gaming session',
              rewardAmount:
                  '${rewardProvider.dailyPlayReward.toStringAsFixed(16)} BTC',
              canClaim: rewardProvider.canClaimDailyPlay,
              onClaim: () async {
                await rewardClaimHandler.handleRewardClaim(
                  rewardType: 'daily_reward',
                  amount: rewardProvider.dailyPlayReward,
                  requiresAd:
                      rewardProvider.requiresAdForReward('daily_reward'),
                  onSuccess: () {
                    // No additional action needed after claiming
                  },
                );
              },
              gradientStart: const Color(0xFF00B4DB),
              gradientEnd: const Color(0xFF0083B0),
            ),
            RewardCard(
              icon: Icons.work,
              title: 'Daily Mining Reward',
              subtitle: 'Complete your daily mining session',
              rewardAmount:
                  '${rewardProvider.dailyMineReward.toStringAsFixed(16)} BTC',
              canClaim: rewardProvider.canClaimDailyMine,
              onClaim: () async {
                await rewardClaimHandler.handleRewardClaim(
                  rewardType: 'daily_reward',
                  amount: rewardProvider.dailyMineReward,
                  requiresAd:
                      rewardProvider.requiresAdForReward('daily_reward'),
                  onSuccess: () {
                    // No additional action needed after claiming
                  },
                );
              },
              gradientStart: const Color(0xFF4B79A1),
              gradientEnd: const Color(0xFF283E51),
            ),

            // Social Media Section
            const SectionHeader(title: 'Social Media Rewards'),
            ...rewardProvider.socialMediaPlatforms.map((platform) => RewardCard(
                  icon: _getPlatformIcon(platform['platform']),
                  title: 'Follow ${platform['platform'].toUpperCase()}',
                  subtitle:
                      'Follow us on ${platform['platform'].toUpperCase()} for rewards',
                  rewardAmount:
                      '${rewardProvider.socialMediaReward.toStringAsFixed(16)} BTC',
                  canClaim: !rewardProvider
                      .isSocialMediaVerified(platform['platform']),
                  onClaim: () async {
                    // First verify social media action
                    final isVerified =
                        await rewardProvider.verifySocialMediaAction(
                      platform['platform'],
                      platform['platform'] == 'youtube'
                          ? 'subscribe'
                          : 'follow',
                    );

                    if (isVerified) {
                      // If verified, claim reward directly without ad
                      await rewardClaimHandler.handleRewardClaim(
                        rewardType: 'social_media_reward',
                        amount: rewardProvider.socialMediaReward,
                        requiresAd: false, // Set to false to skip ad
                        onSuccess: () {
                          // No additional action needed after claiming
                        },
                      );
                    }
                  },
                  gradientStart:
                      _getPlatformGradientStart(platform['platform']),
                  gradientEnd: _getPlatformGradientEnd(platform['platform']),
                )),

            // Other Rewards Section
            const SectionHeader(title: 'Other Rewards'),
            RewardCard(
              icon: Icons.video_library,
              title: 'Watch Ad Reward',
              subtitle: 'Watch a short ad to earn rewards',
              rewardAmount:
                  '${rewardProvider.adReward.toStringAsFixed(16)} BTC',
              canClaim: true,
              onClaim: () async {
                await rewardClaimHandler.handleRewardClaim(
                  rewardType: 'ad_reward',
                  amount: rewardProvider.adReward,
                  requiresAd: true,
                  onSuccess: () {
                    // No additional action needed after claiming
                  },
                );
              },
              gradientStart: const Color(0xFFF09819),
              gradientEnd: const Color(0xFFEDDE5D),
            ),
            RewardCard(
              icon: Icons.share,
              title: 'Refer a Friend',
              subtitle: 'Invite friends and earn bonus rewards',
              rewardAmount:
                  '${rewardProvider.referralReward.toStringAsFixed(16)} BTC',
              canClaim: true,
              onClaim: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReferralScreen()),
                );
              },
              gradientStart: const Color(0xFF11998e),
              gradientEnd: const Color(0xFF38ef7d),
            ),
          ],
        );
      },
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.alternate_email;
      case 'telegram':
        return Icons.send;
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.video_library;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.link;
    }
  }

  Color _getPlatformGradientStart(String platform) {
    switch (platform) {
      case 'instagram':
        return const Color(0xFF833AB4);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'telegram':
        return const Color(0xFF0088cc);
      case 'facebook':
        return const Color(0xFF4267B2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF000000);
      default:
        return const Color(0xFF6A11CB);
    }
  }

  Color _getPlatformGradientEnd(String platform) {
    switch (platform) {
      case 'instagram':
        return const Color(0xFFFD1D1D);
      case 'twitter':
        return const Color(0xFF14171A);
      case 'telegram':
        return const Color(0xFF2AABEE);
      case 'facebook':
        return const Color(0xFF898F9C);
      case 'youtube':
        return const Color(0xFF282828);
      case 'tiktok':
        return const Color(0xFF25F4EE);
      default:
        return const Color(0xFF2575FC);
    }
  }
}

class HourlyRewardSection extends StatefulWidget {
  final RewardClaimHandler rewardClaimHandler;

  const HourlyRewardSection({
    super.key,
    required this.rewardClaimHandler,
  });

  @override
  State<HourlyRewardSection> createState() => _HourlyRewardSectionState();
}

class _HourlyRewardSectionState extends State<HourlyRewardSection> {
  late Timer _timer;
  String _countdownText = '';
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update immediately
    _updateCountdown();

    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    final rewardProvider = Provider.of<RewardProvider>(context, listen: false);
    final remainingSeconds = rewardProvider.getHourlyRemainingSeconds();

    if (remainingSeconds <= 0) {
      if (mounted) {
        setState(() {
          _countdownText = 'Ready to Claim!';
          _isReady = true;
        });
      }
      return;
    }

    final hours = (remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _countdownText = '$hours:$minutes:$seconds';
        _isReady = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        return Column(
          children: [
            const SectionHeader(title: 'Hourly Rewards'),
            RewardCard(
              icon: Icons.access_time,
              title: 'Hourly Mining Reward',
              subtitle: _isReady
                  ? 'Claim your hourly mining bonus'
                  : 'Next reward available in:',
              rewardAmount:
                  '${rewardProvider.hourlyReward.toStringAsFixed(16)} BTC',
              canClaim: rewardProvider.canClaimHourly && _isReady,
              onClaim: () async {
                await widget.rewardClaimHandler.handleRewardClaim(
                  rewardType: 'hourly_reward',
                  amount: rewardProvider.hourlyReward,
                  requiresAd: rewardProvider.canClaimHourly && _isReady,
                  onSuccess: () {
                    // No additional action needed after claiming
                  },
                );
              },
              gradientStart: const Color(0xFF4B79A1),
              gradientEnd: const Color(0xFF283E51),
              customWidget: !_isReady
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer,
                              color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _countdownText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            RewardCard(
              icon: Icons.local_fire_department,
              title: 'Streak Bonus',
              subtitle: 'Current streak: ${rewardProvider.streakCount} days',
              rewardAmount:
                  '${rewardProvider.streakBonusReward.toStringAsFixed(16)} BTC',
              canClaim: rewardProvider.canClaimStreakBonus,
              onClaim: () async {
                await widget.rewardClaimHandler.handleRewardClaim(
                  rewardType: 'streak_reward',
                  amount: rewardProvider.streakBonusReward,
                  requiresAd: rewardProvider.canClaimStreakBonus,
                  onSuccess: () {
                    // No additional action needed after claiming
                  },
                );
              },
              gradientStart: const Color(0xFFf46b45),
              gradientEnd: const Color(0xFFeea849),
            ),
          ],
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
