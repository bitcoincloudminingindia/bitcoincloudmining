import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sound_notification_service.dart';
import 'wallet_provider.dart';

class RewardProvider with ChangeNotifier {
  final int _adsWatched = 0;
  double _pendingRewards = 0.0;

  bool followInstagram = false;
  bool followTwitter = false;
  bool followTelegram = false;
  bool followFacebook = false;
  bool _subscribeYouTube = false;

  // Wallet balance tracked locally and persisted.
  double _balance = 0.0;
  double get balance => _balance;

  bool get subscribeYouTube => _subscribeYouTube;
  double get pendingRewards => _pendingRewards;

  // Social media verification states
  final Map<String, bool> _socialMediaVerified = {
    'instagram': false,
    'twitter': false,
    'telegram': false,
    'facebook': false,
    'youtube': false,
    'tiktok': false,
  };

  // Getter for verification states
  bool isSocialMediaVerified(String platform) =>
      _socialMediaVerified[platform] ?? false;

  // Getter for social media platforms
  List<Map<String, dynamic>> get socialMediaPlatforms => _socialMediaPlatforms;

  // Social media platforms with default values
  List<Map<String, dynamic>> _socialMediaPlatforms = [
    {
      'platform': 'instagram',
      'handle': '@bitcoincloudmining',
      'url': 'https://www.instagram.com/bitcoincloudmining/',
      'rewardAmount': '0.000000000000010000'
    },
    {
      'platform': 'whatsapp',
      'handle': 'Bitcoin Cloud Mining',
      'url': 'https://chat.whatsapp.com/InL9NrT9gtuKpXRJ3Gu5A5',
      'rewardAmount': '0.000000000000010000'
    },
    {
      'platform': 'telegram',
      'handle': '@bitcoin_cloud_mining',
      'url': 'https://t.me/+v6K5Agkb5r8wMjhl',
      'rewardAmount': '0.000000000000010000'
    },
    {
      'platform': 'facebook',
      'handle': 'Bitcoin Cloud Mining',
      'url': 'https://www.facebook.com/groups/1743859249846928',
      'rewardAmount': '0.000000000000010000'
    },
    {
      'platform': 'youtube',
      'handle': 'Bitcoin Cloud Mining',
      'url': 'https://www.youtube.com/channel/UC1V43aMm3KYUJu_J9Lx2DAw',
      'rewardAmount': '0.000000000000010000'
    },
    {
      'platform': 'twitter',
      'handle': '@bitcoin_cloudmining',
      'url': 'https://twitter.com/bitcoincloudmining',
      'rewardAmount': '0.000000000000010000'
    }
  ];

  // New fields for rewards tracking

  // Comment out API URL for now
  // static const String _baseUrl = 'YOUR_BACKEND_API_URL';

  final bool _claimedStreakBonus = false;

  bool get canClaimStreakBonus => !_claimedStreakBonus;

  // Add verification attempt tracking
  final Map<String, DateTime> _verificationAttempts = {};
  final Map<String, bool> _verificationInProgress = {};

  // Add reward amount getters

  double get adReward => 0.000000000000005000;
  double get referralReward => 0.000000000000005000;
  double get socialMediaReward => 0.000000000000010000;

  // Social media reward claim status cache
  final Map<String, bool> _socialMediaRewardClaimed = {};

  // Load claimed status from shared preferences
  Future<void> loadSocialMediaRewardStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        _socialMediaPlatforms.map((p) => p['platform'] as String).toList();
    for (final platform in keys) {
      _socialMediaRewardClaimed[platform] =
          prefs.getBool('claimed_${platform}_reward') ?? false;
    }
    notifyListeners();
  }

  // Save claimed status to shared preferences
  Future<void> saveSocialMediaRewardStatus() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _socialMediaRewardClaimed.entries) {
      await prefs.setBool('claimed_${entry.key}_reward', entry.value);
    }
  }

  // Check if user has already claimed reward for a platform
  bool isSocialMediaRewardClaimed(String platform) {
    return _socialMediaRewardClaimed[platform] ?? false;
  }

  // Mark reward as claimed for a platform
  Future<void> markSocialMediaRewardClaimed(String platform) async {
    _socialMediaRewardClaimed[platform] = true;
    await saveSocialMediaRewardStatus();
    notifyListeners();
  }

  Future<void> setSubscribeYouTube(bool value, WalletProvider wallet) async {
    if (!_subscribeYouTube) {
      const double reward = 0.000000000000010000;
      _pendingRewards += reward;
      _subscribeYouTube = value;
      wallet.addEarning(
        reward,
        type: 'social_reward',
        description: 'YouTube Subscribe Bonus',
      );

      // Show notification and play sound for social media reward
      await SoundNotificationService.showRewardNotification(
        amount: reward,
        type: 'YouTube Subscribe',
      );
      await SoundNotificationService.playEarningSound();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
  }

  Future<void> claimSocialMediaReward(
      WalletProvider wallet, String platform) async {
    // Only claim if verified
    if (_socialMediaVerified[platform] == true) {
      double reward = 0;
      String platformName = '';

      switch (platform) {
        case 'instagram':
          reward = 0.000000000000010000;
          platformName = 'Instagram';
          break;
        case 'twitter':
          reward = 0.000000000000010000;
          platformName = 'Twitter';
          break;
        case 'telegram':
          reward = 0.000000000000010000;
          platformName = 'Telegram';
          break;
        case 'facebook':
          reward = 0.000000000000010000;
          platformName = 'Facebook';
          break;
        case 'youtube':
          reward = 0.000000000000010000;
          platformName = 'YouTube';
          break;
        case 'tiktok':
          reward = 0.000000000000010000;
          platformName = 'TikTok';
          break;
      }

      if (reward > 0) {
        _pendingRewards += reward;
        _updateRewards(reward,
            type: 'social_reward', description: '$platformName Follow Reward');
        wallet.addEarning(
          reward,
          type: 'social_reward',
          description: '$platformName Follow Reward',
        );

        // Show notification and play sound for social media reward
        await SoundNotificationService.showRewardNotification(
          amount: reward,
          type: '$platformName Follow',
        );
        await SoundNotificationService.playEarningSound();

        _balance += reward;
        _saveData();
        notifyListeners();
      }
    }
  }

  Future<void> claimAdReward(WalletProvider wallet, {String? source}) async {
    const double reward = 0.000000000000005000;
    _pendingRewards += reward;
    _updateRewards(reward,
        type: 'ad_reward', description: '${source ?? 'Video Ad'} View Reward');
    wallet.addEarning(
      reward,
      type: 'ad_reward',
      description: '${source ?? 'Video Ad'} View Reward',
    );

    // Show notification and play sound for ad reward
    await SoundNotificationService.showRewardNotification(
      amount: reward,
      type: source ?? 'Video Ad',
    );
    await SoundNotificationService.playEarningSound();

    _balance += reward;
    _saveData();
    notifyListeners();
  }

  // Update verifySocialMediaAction method
  Future<bool> verifySocialMediaAction(
      String platform, String actionType) async {
    try {
      // Check if verification is already in progress
      if (_verificationInProgress[platform] == true) {
        return false;
      }

      // Set verification in progress
      _verificationInProgress[platform] = true;
      _verificationAttempts[platform] = DateTime.now();

      // Get platform URL
      final url = getSocialMediaUrl(platform);
      if (url.isEmpty) {
        _verificationInProgress[platform] = false;
        return false;
      }

      // Launch social media app/website
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        // Wait for user to complete action (5 seconds)
        await Future.delayed(const Duration(seconds: 5));

        // Check if user returned too quickly (less than 10 seconds)
        final attemptTime = _verificationAttempts[platform];
        if (attemptTime != null) {
          final timeSpent = DateTime.now().difference(attemptTime).inSeconds;
          if (timeSpent < 10) {
            _verificationInProgress[platform] = false;
            return false;
          }
        }

        // For demo purposes, we'll verify based on time spent
        final timeSpent = DateTime.now()
            .difference(_verificationAttempts[platform]!)
            .inSeconds;
        final isVerified =
            timeSpent >= 15; // User must spend at least 15 seconds

        if (isVerified) {
          _socialMediaVerified[platform] = true;
          _saveData();
          notifyListeners();
        }

        _verificationInProgress[platform] = false;
        return isVerified;
      }

      _verificationInProgress[platform] = false;
      return false;
    } catch (e) {
      _verificationInProgress[platform] = false;
      return false;
    }
  }

  // Modified loadSocialMediaPlatforms to handle API errors better
  Future<void> loadSocialMediaPlatforms() async {
    // Remove any API/network call, use only default values
    _socialMediaPlatforms = [
      {
        'platform': 'instagram',
        'handle': '@bitcoincloudmining',
        'url': 'https://www.instagram.com/bitcoincloudmining/',
        'rewardAmount': '0.000000000000010000'
      },
      {
        'platform': 'twitter',
        'handle': '@bitcoinclmining',
        'url': 'https://x.com/bitcoinclmining',
        'rewardAmount': '0.000000000000010000'
      },
      {
        'platform': 'telegram',
        'handle': '@bitcoin_cloud_mining',
        'url': 'https://t.me/+v6K5Agkb5r8wMjhl',
        'rewardAmount': '0.000000000000010000'
      },
      {
        'platform': 'facebook',
        'handle': 'Bitcoin Cloud Mining',
        'url': 'https://www.facebook.com/groups/1743859249846928',
        'rewardAmount': '0.000000000000010000'
      },
      {
        'platform': 'youtube',
        'handle': 'Bitcoin Cloud Mining',
        'url': 'https://www.youtube.com/channel/UC1V43aMm3KYUJu_J9Lx2DAw',
        'rewardAmount': '0.000000000000010000'
      },
      {
        'platform': 'whatsapp',
        'handle': 'Bitcoin Cloud Mining',
        'url': 'https://chat.whatsapp.com/InL9NrT9gtuKpXRJ3Gu5A5',
        'rewardAmount': '0.000000000000010000'
      }
    ];
    notifyListeners();
  }

  // Get social media URL
  String getSocialMediaUrl(String platform) {
    final platformData = _socialMediaPlatforms.firstWhere(
      (p) => p['platform'] == platform,
      orElse: () => {'url': ''},
    );
    return platformData['url'] ?? '';
  }

  // Get social media reward amount
  String getSocialMediaReward(String platform) {
    final platformData = _socialMediaPlatforms.firstWhere(
      (p) => p['platform'] == platform,
      orElse: () => {'rewardAmount': '0.000000000000000000'},
    );
    return platformData['rewardAmount'] ?? '0.000000000000000000';
  }

  // Modified _updateRewards to only update local state, not call API
  void _updateRewards(double amount, {String? type, String? description}) {
    _pendingRewards += amount;
    _balance += amount;
    _saveData();
    notifyListeners();
  }

  // Add method to reset verification state
  void resetVerificationState(String platform) {
    _verificationInProgress[platform] = false;
    _verificationAttempts.remove(platform);
    notifyListeners();
  }

  // Claim referral reward method
  Future<void> claimReferralReward(WalletProvider wallet,
      {String? referrerName}) async {
    const double reward = 0.000000000000005000;
    _pendingRewards += reward;
    _updateRewards(reward,
        type: 'referral_reward', description: 'Referral Bonus Reward');
    wallet.addEarning(
      reward,
      type: 'referral_reward',
      description: 'Referral Bonus Reward',
    );

    // Show notification and play sound for referral reward
    await SoundNotificationService.showRewardNotification(
      amount: reward,
      type: 'Referral Bonus',
    );
    await SoundNotificationService.playEarningSound();

    _balance += reward;
    _saveData();
    notifyListeners();
  }

  // Add _saveData method
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pendingRewards', _pendingRewards);
    await prefs.setDouble('balance', _balance);
    await prefs.setInt('adsWatched', _adsWatched);
    await prefs.setBool('subscribeYouTube', _subscribeYouTube);
    // Save verification attempts
    for (var entry in _verificationAttempts.entries) {
      await prefs.setString(
          'verification_attempt_${entry.key}', entry.value.toIso8601String());
    }
    // Save verification in progress state
    for (var entry in _verificationInProgress.entries) {
      await prefs.setBool('verification_in_progress_${entry.key}', entry.value);
    }
  }
}
