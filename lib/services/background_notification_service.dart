import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _backgroundTaskName = 'backgroundNotificationTask';
  static const String _notificationChannelId = 'background_channel';
  static const int _notificationId =
      2001; // Unique ID for background notifications

  // Notification messages pool
  static const List<String> _notificationTitles = [
    '🚀 Bitcoin Mining Update!',
    '⛏️ Mining in Progress!',
    '💰 Earnings Update!',
    '🎯 Mining Status!',
    '⚡ Hash Rate Update!',
    '💎 Crypto Mining Alert!',
    '🔧 Mining Operation Active!',
    '🌟 Bitcoin Cloud Mining!',
  ];

  static const List<String> _notificationBodies = [
    'Your Bitcoin mining is running smoothly! Keep earning! 💰',
    'Mining operation is active. Your rewards are accumulating! ⛏️',
    'Great news! Your mining earnings are growing! 🎉',
    'Mining status: Active ✅ Your Bitcoin rewards await!',
    'Hash rate is optimal! Your mining efficiency is excellent! ⚡',
    'Crypto mining alert: Your account is earning Bitcoin! 💎',
    'Mining operation is running in background. Don\'t stop now! 🔧',
    'Bitcoin Cloud Mining is working perfectly! Your wealth is growing! 🌟',
  ];

  // Initialize the service
  static Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create notification channel
      await _createNotificationChannel();

      // Initialize WorkManager
      await _initializeWorkManager();

      // Start background task
      await _startBackgroundTask();
    } catch (e) {
      print('Background notification service initialization error: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(initSettings);
    } catch (e) {
      print('Local notifications initialization error: $e');
    }
  }

  // Create notification channel
  static Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const backgroundChannel = AndroidNotificationChannel(
        _notificationChannelId,
        'Background Mining',
        description: 'Notifications for background mining operations',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(backgroundChannel);
    }
  }

  // Initialize WorkManager
  static Future<void> _initializeWorkManager() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );
    } catch (e) {
      print('WorkManager initialization error: $e');
    }
  }

  // Start background task
  static Future<void> _startBackgroundTask() async {
    try {
      // Cancel existing task if any
      await Workmanager().cancelAll();

      // Register periodic task (60 minutes = 3600 seconds)
      await Workmanager().registerPeriodicTask(
        _backgroundTaskName,
        _backgroundTaskName,
        frequency: const Duration(minutes: 60), // 60 minutes
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: const Duration(minutes: 1), // Start after 1 minute
      );

      print('Background notification task started successfully');
    } catch (e) {
      print('Background task start error: $e');
    }
  }

  // Stop background task
  static Future<void> stopBackgroundTask() async {
    try {
      await Workmanager().cancelAll();
      print('Background notification task stopped');
    } catch (e) {
      print('Background task stop error: $e');
    }
  }

  // Show background notification
  static Future<void> showBackgroundNotification() async {
    try {
      // Get random notification content
      final random = Random();
      final titleIndex = random.nextInt(_notificationTitles.length);
      final bodyIndex = random.nextInt(_notificationBodies.length);

      final title = _notificationTitles[titleIndex];
      final body = _notificationBodies[bodyIndex];

      // Get user's current balance from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final balance = prefs.getString('wallet_balance') ?? '0.00000000';
      final hashRate = prefs.getString('hash_rate') ?? '0.0';

      // Create enhanced notification body with stats
      final enhancedBody =
          '$body\n\n💰 Balance: $balance BTC | ⚡ Hash Rate: $hashRate H/s';

      final androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        'Background Mining',
        channelDescription: 'Notifications for background mining operations',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        color: const Color(0xFFFFC107), // Gold/Yellow (brand color)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          enhancedBody,
          contentTitle: title,
          summaryText: 'Bitcoin Cloud Mining - Background Update',
        ),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        _notificationId +
            DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        null, // body is handled by BigTextStyleInformation
        notificationDetails,
        payload: 'background_mining_update',
      );

      print('Background notification sent: $title');
    } catch (e) {
      print('Background notification error: $e');
    }
  }

  // Update user stats for notifications
  static Future<void> updateUserStats({
    String? balance,
    String? hashRate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (balance != null) {
        await prefs.setString('wallet_balance', balance);
      }
      if (hashRate != null) {
        await prefs.setString('hash_rate', hashRate);
      }
    } catch (e) {
      print('Update user stats error: $e');
    }
  }

  // Check if background notifications are enabled
  static Future<bool> isBackgroundNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('background_notifications_enabled') ?? true;
    } catch (e) {
      return true; // Default to enabled
    }
  }

  // Enable/disable background notifications
  static Future<void> setBackgroundNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_notifications_enabled', enabled);

      if (enabled) {
        await _startBackgroundTask();
      } else {
        await stopBackgroundTask();
      }
    } catch (e) {
      print('Set background notifications error: $e');
    }
  }

  // Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalNotifications =
          prefs.getInt('total_background_notifications') ?? 0;
      final lastNotificationTime =
          prefs.getString('last_background_notification_time');

      return {
        'total_notifications': totalNotifications,
        'last_notification_time': lastNotificationTime,
        'is_enabled': await isBackgroundNotificationsEnabled(),
      };
    } catch (e) {
      return {
        'total_notifications': 0,
        'last_notification_time': null,
        'is_enabled': true,
      };
    }
  }

  // Increment notification counter
  static Future<void> _incrementNotificationCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('total_background_notifications') ?? 0;
      await prefs.setInt('total_background_notifications', currentCount + 1);
      await prefs.setString('last_background_notification_time',
          DateTime.now().toIso8601String());
    } catch (e) {
      print('Increment notification counter error: $e');
    }
  }

  // Dispose resources
  static void dispose() {
    // WorkManager doesn't need explicit disposal
  }
}

// Background task callback (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Check if background notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final isEnabled =
          prefs.getBool('background_notifications_enabled') ?? true;

      if (!isEnabled) {
        return Future.value(true);
      }

      // Show background notification
      await BackgroundNotificationService.showBackgroundNotification();

      // Increment notification counter
      await BackgroundNotificationService._incrementNotificationCounter();

      return Future.value(true);
    } catch (e) {
      print('Background task execution error: $e');
      return Future.value(false);
    }
  });
}
