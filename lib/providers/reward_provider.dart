import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sound_notification_service.dart';
import 'wallet_provider.dart';

class RewardProvider with ChangeNotifier {
  int _sciFiTaps = 0;
  int _adsWatched = 0;
  double _pendingRewards = 0.0;
  DateTime? _lastReset;
  DateTime? _lastHourlyClaim;

  bool _claimedDailyPlay = false;
  bool _claimedDailyMine = false;
  bool _claimedSciFiReward = false;

  bool followInstagram = false;
  bool followTwitter = false;
  bool followTelegram = false;
  bool followFacebook = false;
  bool _subscribeYouTube = false;
  bool _canDoubleReward = false;
  bool followTikTok = false;

  // Wallet balance tracked locally and persisted.
  double _balance = 0.0;
  double get balance => _balance;

  bool get subscribeYouTube => _subscribeYouTube;
  bool get canDoubleReward => _canDoubleReward;
  int get sciFiTaps => _sciFiTaps;
  int get adsWatched => _adsWatched;
  double get pendingRewards => _pendingRewards;
  bool get canClaimDailyPlay => !_claimedDailyPlay;
  bool get canClaimDailyMine => !_claimedDailyMine;
  bool get sciFiRewardClaimed => _claimedSciFiReward;
  bool get canClaimMilestone => _sciFiTaps >= 1000;
  bool get canClaimHourly =>
      _lastHourlyClaim == null ||
      DateTime.now().difference(_lastHourlyClaim!).inMinutes >= 60;
  int get hourlyCooldown => (_lastHourlyClaim == null ||
          DateTime.now().difference(_lastHourlyClaim!).inMinutes >= 60)
      ? 0
      : 60 - DateTime.now().difference(_lastHourlyClaim!).inMinutes;

  // Added streak count property.
  int _streakCount = 0;
  int get streakCount => _streakCount;

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
      'platform': 'tiktok',
      'handle': '@bitcoin_cloud_mining',
      'url': 'https://tiktok.com/@bitcoin_cloud_mining',
      'rewardAmount': '0.000000000000010000'
    }
  ];

  // New fields for rewards tracking
  double _lifetimeRewards = 0.0;
  double _todayRewards = 0.0;
  DateTime? _lastDailyReset;
  DateTime? _lastClaimDate;

  // Getters for rewards
  double get lifetimeRewards => _lifetimeRewards;
  double get todayRewards => _todayRewards;
  DateTime? get lastClaimDate => _lastClaimDate;

  // Comment out API URL for now
  // static const String _baseUrl = 'YOUR_BACKEND_API_URL';

  bool _claimedStreakBonus = false;

  bool get canClaimStreakBonus => !_claimedStreakBonus;

  // Add verification attempt tracking
  final Map<String, DateTime> _verificationAttempts = {};
  final Map<String, bool> _verificationInProgress = {};

  // Add reward amount getters
  double get dailyPlayReward => 0.000000000000010000;
  double get dailyMineReward => 0.000000000000005000;
  double get hourlyReward => 0.000000000000005000;
  double get streakBonusReward => 0.000000000000005000;
  double get adReward => 0.000000000000005000;
  double get referralReward => 0.000000000000005000;
  double get socialMediaReward => 0.000000000000010000;

  RewardProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _sciFiTaps = prefs.getInt('sciFiTaps') ?? 0;
    _adsWatched = prefs.getInt('adsWatched') ?? 0;
    _pendingRewards = prefs.getDouble('pendingRewards') ?? 0.0;
    _balance = prefs.getDouble('balance') ?? 0.0;

    // Load last reset time first
    _lastReset = DateTime.tryParse(prefs.getString('lastReset') ?? '');

    // Check if we need to reset daily rewards
    final now = DateTime.now();
    if (_lastReset == null ||
        now.difference(_lastReset!).inHours >= 24 ||
        now.day != _lastReset!.day) {
      debugPrint(
          'Resetting daily rewards - Last reset: $_lastReset, Now: $now');
      _claimedDailyPlay = false;
      _claimedDailyMine = false;
      _claimedSciFiReward = false;
      _canDoubleReward = false;

      // Reset today's rewards
      _todayRewards = 0.0;
      _lastDailyReset = now;

      // Update streak
      if (_lastReset != null && now.difference(_lastReset!).inHours >= 48) {
        // If more than 48 hours have passed, reset streak
        _streakCount = 0;
      }

      _lastReset = now;
      _claimedStreakBonus = false;

      // Save the reset time immediately
      _saveData();
      notifyListeners();
    } else {
      debugPrint(
          'Loading daily rewards state - Last reset: $_lastReset, Now: $now');
      _claimedDailyPlay = prefs.getBool('claimedDailyPlay') ?? false;
      _claimedDailyMine = prefs.getBool('claimedDailyMine') ?? false;
    }

    _claimedSciFiReward = prefs.getBool('claimedSciFiReward') ?? false;
    _subscribeYouTube = prefs.getBool('subscribeYouTube') ?? false;
    _canDoubleReward = prefs.getBool('canDoubleReward') ?? false;
    _streakCount = prefs.getInt('streak') ?? 0;
    _lastHourlyClaim =
        DateTime.tryParse(prefs.getString('lastHourlyClaim') ?? '');
    _todayRewards = prefs.getDouble('todayRewards') ?? 0.0;
    _lastDailyReset =
        DateTime.tryParse(prefs.getString('lastDailyReset') ?? '');

    // Load lifetime rewards from local storage first
    _lifetimeRewards = prefs.getDouble('lifetimeRewards') ?? 0.0;

    _claimedStreakBonus = prefs.getBool('claimedStreakBonus') ?? false;

    _resetDailyIfNeeded();

    // Load verification attempts
    for (var platform in _socialMediaPlatforms) {
      final attemptTimeStr =
          prefs.getString('verification_attempt_${platform['platform']}');
      if (attemptTimeStr != null) {
        _verificationAttempts[platform['platform']] =
            DateTime.parse(attemptTimeStr);
      }

      final inProgress =
          prefs.getBool('verification_in_progress_${platform['platform']}');
      if (inProgress != null) {
        _verificationInProgress[platform['platform']] = inProgress;
      }
    }

    notifyListeners();
  }

  void _resetDailyIfNeeded() {
    final now = DateTime.now();
    if (_lastReset == null ||
        now.difference(_lastReset!).inHours >= 24 ||
        now.day != _lastReset!.day) {
      debugPrint(
          'Resetting daily rewards - Last reset: $_lastReset, Now: $now');
      _claimedDailyPlay = false;
      _claimedDailyMine = false;
      _claimedSciFiReward = false;
      _canDoubleReward = false;

      // Reset today's rewards
      _todayRewards = 0.0;
      _lastDailyReset = now;

      // Update streak
      if (_lastReset != null && now.difference(_lastReset!).inHours >= 48) {
        // If more than 48 hours have passed, reset streak
        _streakCount = 0;
      }

      _lastReset = now;
      _claimedStreakBonus = false;

      // Save the reset time immediately
      _saveData();
      notifyListeners();
    }
  }

  void setSubscribeYouTube(bool value, WalletProvider wallet) {
    if (!_subscribeYouTube) {
      const double reward = 0.000000000000010000;
      _pendingRewards += reward;
      _subscribeYouTube = value;
      wallet.addEarning(
        reward,
        type: 'social_reward',
        description: 'YouTube Subscribe Bonus',
      );

      // Play earning sound for social media reward
      SoundNotificationService.playEarningSound();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
  }

  void tapSciFiObject(WalletProvider wallet, {String? source}) {
    _sciFiTaps++;
    if (_sciFiTaps >= 100 && !_claimedSciFiReward) {
      const double reward = 0.000000000000005000;
      _pendingRewards += reward;
      _claimedSciFiReward = true;
      wallet.addEarning(
        reward,
        type: 'tap_reward',
        description: '${source ?? 'Sci-Fi Objects'} - 100 Taps Bonus',
      );

      // Play success chime for tap milestone
      SoundNotificationService.playSuccessChime();

      _balance += reward;
    }
    _saveData();
    notifyListeners();
  }

  void watchAd() {
    _adsWatched++;
    _canDoubleReward = true;
    _saveData();
    notifyListeners();
  }

  void claimAdBonus(WalletProvider wallet) {
    if (_adsWatched >= 10) {
      const double reward = 0.000000000000001000;
      _pendingRewards += reward;
      _adsWatched = 0;
      wallet.addEarning(
        reward,
        type: 'ad_reward',
        description: 'Video Ads - 10 Ads Bonus',
      );

      // Play earning sound for ad bonus
      SoundNotificationService.playEarningSound();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
  }

  // Add helper method to check if reward requires ad
  bool requiresAdForReward(String rewardType) {
    // Social media and referral rewards don't require ads
    if (rewardType == 'social_reward' || rewardType == 'referral_reward') {
      return false;
    }
    // All other rewards require ads
    return true;
  }

  // Update claim methods to return whether ad is required
  Future<bool> claimDailyPlay(WalletProvider wallet) async {
    if (!_claimedDailyPlay) {
      if (requiresAdForReward('daily_reward')) {
        return true; // Ad required
      }

      const double reward = 0.000000000000005000;
      _pendingRewards += reward;
      _claimedDailyPlay = true;
      _lastReset = DateTime.now(); // Update last reset time when claiming
      _updateRewards(reward,
          type: 'daily_reward', description: 'Daily Gaming Reward');
      _updateStreak();
      wallet.addEarning(
        reward,
        type: 'daily_reward',
        description: 'Daily Gaming Reward',
      );

      // Play earning sound for daily reward
      SoundNotificationService.playEarningSound();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
    return false; // No ad required
  }

  Future<bool> claimDailyMine(WalletProvider wallet) async {
    if (!_claimedDailyMine) {
      if (requiresAdForReward('daily_reward')) {
        return true; // Ad required
      }

      const double reward =
          0.000000000000005000; // Fixed: was 0.0000000000000005000
      _pendingRewards += reward;
      _claimedDailyMine = true;
      _lastReset = DateTime.now(); // Update last reset time when claiming
      _updateRewards(reward,
          type: 'daily_reward', description: 'Daily Mining Reward');
      _updateStreak();
      wallet.addEarning(
        reward,
        type: 'daily_reward',
        description: 'Daily Mining Reward',
      );

      // Play earning sound for daily mining reward
      SoundNotificationService.playEarningSound();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
    return false; // No ad required
  }

  Future<bool> claimHourly(WalletProvider wallet) async {
    if (canClaimHourly) {
      if (requiresAdForReward('hourly_reward')) {
        return true; // Ad required
      }

      const double reward = 0.000000000000005000;
      _pendingRewards += reward;
      _lastHourlyClaim = DateTime.now();

      // Save the last claim time immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'lastHourlyClaim', _lastHourlyClaim!.toIso8601String());

      _updateRewards(reward,
          type: 'hourly_reward', description: 'Hourly Mining Bonus');
      _updateStreak();
      wallet.addEarning(
        reward,
        type: 'hourly_reward',
        description: 'Hourly Mining Bonus',
      );

      // Play earning sound for hourly reward
      SoundNotificationService.playEarningSound();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
    return false; // No ad required
  }

  Future<bool> claimMilestone(WalletProvider wallet) async {
    if (_sciFiTaps >= 1000) {
      if (requiresAdForReward('tap_reward')) {
        return true; // Ad required
      }

      const double reward = 0.000000000000005000;
      _pendingRewards += reward;
      _sciFiTaps = 0;
      _updateRewards(reward,
          type: 'tap_reward',
          description: 'Sci-Fi Objects - 1000 Taps Milestone');
      wallet.addEarning(
        reward,
        type: 'tap_reward',
        description: 'Sci-Fi Objects - 1000 Taps Milestone',
      );

      // Play success chime for milestone achievement
      SoundNotificationService.playSuccessChime();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
    return false; // No ad required
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

        // Play earning sound for social media reward
        SoundNotificationService.playEarningSound();

        _balance += reward;
        _saveData();
        notifyListeners();
      }
    }
  }

  void claimAllRewards(WalletProvider wallet) {
    wallet.addEarning(
      _pendingRewards,
      type: 'bulk_reward',
      description: 'All Rewards Bulk Claim',
    );

    // Play earning sound for bulk reward claim
    SoundNotificationService.playEarningSound();

    _balance += _pendingRewards;
    _pendingRewards = 0.0;
    _saveData();
    notifyListeners();
  }

  void claimDoubleReward(WalletProvider wallet) {
    if (_canDoubleReward) {
      final double additionalReward = _pendingRewards;
      _pendingRewards *= 2;
      wallet.addEarning(
        additionalReward,
        type: 'double_reward',
        description: 'Double Rewards Bonus',
      );

      // Play success chime for double reward
      SoundNotificationService.playSuccessChime();

      _balance += additionalReward;
      _canDoubleReward = false;
      _saveData();
      notifyListeners();
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

    // Play earning sound for ad reward
    SoundNotificationService.playEarningSound();

    _balance += reward;
    _saveData();
    notifyListeners();
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak') ?? 0;
  }

  // Update getHourlyRemainingSeconds to be more accurate
  int getHourlyRemainingSeconds() {
    if (_lastHourlyClaim == null) return 0;

    final now = DateTime.now();
    final difference = now.difference(_lastHourlyClaim!);
    final remainingSeconds = (3600 - difference.inSeconds).clamp(0, 3600);

    debugPrint('Last claim: $_lastHourlyClaim');
    debugPrint('Now: $now');
    debugPrint('Difference: ${difference.inSeconds} seconds');
    debugPrint('Remaining: $remainingSeconds seconds');

    return remainingSeconds;
  }

  Future<bool> claimStreakBonus(WalletProvider wallet) async {
    if (!_claimedStreakBonus) {
      if (requiresAdForReward('streak_reward')) {
        return true; // Ad required
      }

      const double reward = 0.000000000000005000;
      _pendingRewards += reward;
      _claimedStreakBonus = true;
      _updateRewards(reward,
          type: 'streak_reward', description: 'Daily Streak Bonus');
      wallet.addEarning(
        reward,
        type: 'streak_reward',
        description: 'Daily Streak Bonus',
      );

      // Play success chime for streak bonus
      SoundNotificationService.playSuccessChime();

      _balance += reward;
      _saveData();
      notifyListeners();
    }
    return false; // No ad required
  }

  // Added claimDailyBonus method for the daily bonus reward.
  Future<void> claimDailyBonus(WalletProvider wallet, {String? source}) async {
    const double reward = 0.000000000000005000;
    _pendingRewards += reward;
    wallet.addEarning(
      reward,
      type: 'daily_reward',
      description: '${source ?? 'Daily'} Login Bonus',
    );

    // Play earning sound for daily bonus
    SoundNotificationService.playEarningSound();

    _balance += reward;
    _saveData();
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pendingRewards', _pendingRewards);
    await prefs.setDouble('balance', _balance);
    await prefs.setInt('sciFiTaps', _sciFiTaps);
    await prefs.setInt('adsWatched', _adsWatched);
    await prefs.setBool('claimedDailyPlay', _claimedDailyPlay);
    await prefs.setBool('claimedDailyMine', _claimedDailyMine);
    await prefs.setBool('claimedSciFiReward', _claimedSciFiReward);
    await prefs.setBool('subscribeYouTube', _subscribeYouTube);
    await prefs.setBool('canDoubleReward', _canDoubleReward);
    await prefs.setInt('streak', _streakCount);
    await prefs.setString('lastReset', _lastReset?.toIso8601String() ?? '');
    await prefs.setString(
        'lastHourlyClaim', _lastHourlyClaim?.toIso8601String() ?? '');
    await prefs.setDouble('lifetimeRewards', _lifetimeRewards);
    await prefs.setDouble('todayRewards', _todayRewards);
    await prefs.setString(
        'lastDailyReset', _lastDailyReset?.toIso8601String() ?? '');
    await prefs.setBool('claimedStreakBonus', _claimedStreakBonus);

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

  // Update verifySocialMediaAction method
  Future<bool> verifySocialMediaAction(
      String platform, String actionType) async {
    try {
      // Check if verification is already in progress
      if (_verificationInProgress[platform] == true) {
        debugPrint('Verification already in progress for $platform');
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
            debugPrint(
                'User returned too quickly ($timeSpent seconds) for $platform');
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
      debugPrint('Social media verification error: $e');
      _verificationInProgress[platform] = false;
      return false;
    }
  }

  // Modified loadSocialMediaPlatforms to handle API errors better
  Future<void> loadSocialMediaPlatforms() async {
    try {
      // Using default values for now
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
    } catch (e) {
      debugPrint('Error loading social media platforms: $e');
      // Keep using default values if API fails
    }
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
  Future<void> _updateRewards(double amount,
      {String type = 'reward', String description = 'Reward claimed'}) async {
    try {
      // Update local state first
      _lifetimeRewards += amount;

      // Check if we need to reset today's rewards
      final now = DateTime.now();
      if (_lastDailyReset == null ||
          now.difference(_lastDailyReset!).inHours >= 24) {
        _todayRewards = 0.0;
        _lastDailyReset = now;
      }

      // Update today's rewards
      _todayRewards += amount;

      // No API call, just save local state
      _saveData();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating rewards: $e');
      // Keep local state even if something fails
      _saveData();
      notifyListeners();
    }
  }

  // Remove syncRewards, it is now a no-op
  Future<void> syncRewards() async {
    debugPrint('🔄 syncRewards() called (no-op, API removed)');
    // No API call, just notify
    notifyListeners();
  }

  // Add method to update streak
  void _updateStreak() {
    final now = DateTime.now();
    if (_lastReset == null) {
      // First claim ever
      _streakCount = 1;
    } else {
      final hoursSinceLastClaim = now.difference(_lastReset!).inHours;
      if (hoursSinceLastClaim <= 48) {
        // If claimed within 48 hours, increment streak
        _streakCount++;
      } else {
        // If more than 48 hours have passed, reset streak
        _streakCount = 1;
      }
    }
    _lastReset = now;
    _saveData();
    notifyListeners();
  }

  // Add method to reset verification state
  void resetVerificationState(String platform) {
    _verificationInProgress[platform] = false;
    _verificationAttempts.remove(platform);
    notifyListeners();
  }
}
