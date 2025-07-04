import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SoundNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Initialize the service
  static Future<void> initialize() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap - navigate to notification screen
          // Navigation will be handled by the main app's notification listener
        },
      );

      // Create notification channels
      await _createNotificationChannels();

    } catch (e) {
    }
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Mining notification channel
      const miningChannel = AndroidNotificationChannel(
        'mining_channel',
        'Mining Status',
        description: 'Shows current mining stats and status',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Reward notification channel
      const rewardChannel = AndroidNotificationChannel(
        'reward_channel',
        'Rewards',
        description: 'Notifications for rewards and earnings',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Withdrawal notification channel
      const withdrawalChannel = AndroidNotificationChannel(
        'withdrawal_channel',
        'Withdrawals',
        description: 'Notifications for withdrawals',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Alert notification channel
      const alertChannel = AndroidNotificationChannel(
        'alert_channel',
        'Alerts',
        description: 'General app alerts and notifications',
        importance: Importance.low,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(miningChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(rewardChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(withdrawalChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alertChannel);
    }
  }

  // Play notification sound
  static Future<void> playNotificationSound(String soundType) async {
    try {
      String soundPath;
      switch (soundType) {
        case 'mining':
          soundPath = 'sounds/mining_notification.mp3';
          break;
        case 'reward':
          soundPath = 'sounds/reward_notification.mp3';
          break;
        case 'withdrawal':
          soundPath = 'sounds/withdrawal_notification.mp3';
          break;
        case 'alert':
          soundPath = 'sounds/notification_alert.mp3';
          break;
        case 'earning':
          soundPath = 'sounds/earning_notification.mp3';
          break;
        case 'success_chime':
          soundPath = 'sounds/success_chime.mp3';
          break;
        default:
          soundPath = 'sounds/notification_alert.mp3';
      }

      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
    }
  }

  // Play earning notification sound specifically
  static Future<void> playEarningSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/earning_notification.mp3'));
    } catch (e) {
      // Fallback to success chime
      try {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      } catch (e2) {
      }
    }
  }

  // Play sci-fi power up sound
  static Future<void> playSciFiPowerUpSound() async {
    try {
      // Use a different existing sound for power up effect
      await _audioPlayer.play(AssetSource('sounds/earning_notification.mp3'));
    } catch (e) {
      // Fallback to success chime
      try {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      } catch (e2) {
      }
    }
  }

  // Play sci-fi achievement sound
  static Future<void> playSciFiAchievementSound() async {
    try {
      // Use notification alert for achievement sound (more dramatic)
      await _audioPlayer.play(AssetSource('sounds/notification_alert.mp3'));
    } catch (e) {
      // Fallback to success chime
      try {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      } catch (e2) {
      }
    }
  }

  // Play success chime for achievements
  static Future<void> playSuccessChime() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
    } catch (e) {
    }
  }

  // Show notification with sound
  static Future<void> showNotification({
    required String title,
    required String body,
    String? soundType,
    String channelId = 'alert_channel',
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Play sound if specified
      if (soundType != null) {
        await playNotificationSound(soundType);
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        color: const Color(0xFFFFC107), // Gold/Yellow (brand color)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Bitcoin Cloud Mining',
        ),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload?.toString(),
      );

    } catch (e) {
    }
  }

  // Get channel name
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'mining_channel':
        return 'Mining Status';
      case 'reward_channel':
        return 'Rewards';
      case 'withdrawal_channel':
        return 'Withdrawals';
      case 'alert_channel':
      default:
        return 'Alerts';
    }
  }

  // Get channel description
  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'mining_channel':
        return 'Shows current mining stats and status';
      case 'reward_channel':
        return 'Notifications for rewards and earnings';
      case 'withdrawal_channel':
        return 'Notifications for withdrawals';
      case 'alert_channel':
      default:
        return 'General app alerts and notifications';
    }
  }

  // Show mining reward notification
  static Future<void> showRewardNotification({
    required double amount,
    required String type,
  }) async {
    await showNotification(
      title: '🎉 Reward Earned!',
      body: 'You earned ${amount.toStringAsFixed(18)} BTC from $type!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'reward',
        'amount': amount,
        'reward_type': type,
      },
    );
  }

  // Show withdrawal notification
  static Future<void> showWithdrawalNotification({
    required double amount,
    required String method,
  }) async {
    await showNotification(
      title: '💰 Withdrawal Successful!',
      body: '${amount.toStringAsFixed(18)} BTC withdrawn via $method',
      soundType: 'withdrawal',
      channelId: 'withdrawal_channel',
      payload: {
        'type': 'withdrawal',
        'amount': amount,
        'method': method,
      },
    );
  }

  // Show mining status notification
  static Future<void> showMiningNotification({
    required String balance,
    required String hashRate,
    required String duration,
  }) async {
    await showNotification(
      title: '⛏️ Mining Update',
      body:
          'Balance: $balance BTC | Hashrate: $hashRate H/s | Duration: $duration',
      soundType: 'mining',
      channelId: 'mining_channel',
      payload: {
        'type': 'mining_update',
        'balance': balance,
        'hashrate': hashRate,
        'duration': duration,
      },
    );
  }

  // Show general alert notification
  static Future<void> showAlertNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      title: title,
      body: message,
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'alert',
        'title': title,
        'message': message,
      },
    );
  }

  // Show welcome notification
  static Future<void> showWelcomeNotification() async {
    await showNotification(
      title: '🚀 Welcome to Bitcoin Cloud Mining!',
      body:
          'Start mining and earn Bitcoin rewards. Your journey to crypto wealth begins now!',
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'welcome',
      },
    );
  }

  // Show level up notification
  static Future<void> showLevelUpNotification({
    required int level,
    required double bonus,
  }) async {
    await showNotification(
      title: '🎯 Level Up!',
      body:
          'Congratulations! You reached level $level and earned ${bonus.toStringAsFixed(18)} BTC bonus!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'level_up',
        'level': level,
        'bonus': bonus,
      },
    );
  }

  // Show daily bonus notification
  static Future<void> showDailyBonusNotification({
    required double amount,
  }) async {
    await showNotification(
      title: '🎁 Daily Bonus Available!',
      body: 'Claim your daily bonus of ${amount.toStringAsFixed(18)} BTC now!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'daily_bonus',
        'amount': amount,
      },
    );
  }

  // Show referral bonus notification
  static Future<void> showReferralBonusNotification({
    required String referrerName,
    required double amount,
  }) async {
    await showNotification(
      title: '👥 Referral Bonus!',
      body:
          '$referrerName joined using your code! You earned ${amount.toStringAsFixed(18)} BTC bonus!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'referral_bonus',
        'referrer_name': referrerName,
        'amount': amount,
      },
    );
  }

  // Show network error notification
  static Future<void> showNetworkErrorNotification() async {
    await showNotification(
      title: '⚠️ Network Error',
      body: 'Please check your internet connection and try again.',
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'network_error',
      },
    );
  }

  // Show maintenance notification
  static Future<void> showMaintenanceNotification({
    required String message,
  }) async {
    await showNotification(
      title: '🔧 Maintenance Notice',
      body: message,
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'maintenance',
        'message': message,
      },
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
    }
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
    }
  }

  // Dispose resources
  static void dispose() {
    _audioPlayer.dispose();
  }
}
