import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MiningNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Timer? _updateTimer;
  static bool _isNotificationActive = false;
  static const int _notificationId = 1001; // Unique ID for mining notification

  // Mining stats
  static String _currentBalance = '0.00000000';
  static String _currentHashRate = '0.0';
  static String _miningStatus = '⛏️ Mining in progress...';
  static DateTime? _miningStartTime;

  // Initialize the service
  static Future<void> initialize() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(initSettings);

      // Create mining notification channel
      await _createMiningChannel();

      debugPrint('✅ Mining notification service initialized');
    } catch (e) {
      debugPrint('❌ Mining notification service initialization failed: $e');
    }
  }

  // Create mining notification channel
  static Future<void> _createMiningChannel() async {
    if (Platform.isAndroid) {
      const miningChannel = AndroidNotificationChannel(
        'mining_channel',
        'Mining Status',
        description: 'Shows current mining stats and status',
        importance: Importance.max,
        enableVibration: false,
        enableLights: true,
        playSound: false,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(miningChannel);
    }
  }

  // Start persistent mining notification
  static Future<void> startMiningNotification({
    required String initialBalance,
    required String initialHashRate,
  }) async {
    try {
      _currentBalance = initialBalance;
      _currentHashRate = initialHashRate;
      _miningStartTime = DateTime.now();
      _isNotificationActive = true;

      // Show initial notification
      await _showMiningNotification();

      // Start periodic updates
      _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _updateMiningNotification();
      });

      debugPrint('✅ Mining notification started');
    } catch (e) {
      debugPrint('❌ Failed to start mining notification: $e');
    }
  }

  // Show mining notification
  static Future<void> _showMiningNotification() async {
    if (!_isNotificationActive) return;

    try {
      final duration = _getMiningDuration();

      final content = _buildNotificationContent(duration);

      final androidDetails = AndroidNotificationDetails(
        'mining_channel',
        'Mining Status',
        channelDescription: 'Shows current mining stats and status',
        importance: Importance.max,
        ongoing: true, // 🔒 Makes it non-dismissible
        showWhen: false,
        enableVibration: false,
        enableLights: true,
        playSound: false,
        color: const Color(0xFFFFC107), // Gold/Yellow (brand color)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          '$content\n\n🚀 Keep mining, keep earning! 💸',
          contentTitle: '⛏️ Bitcoin Cloud Mining - Mining in Progress',
          summaryText: 'Mining is active. Don\'t close the app!',
        ),
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        _notificationId,
        '⛏️ Bitcoin Cloud Mining - Mining in Progress',
        null, // body is handled by BigTextStyleInformation
        notificationDetails,
      );

      debugPrint('📱 Mining notification updated: $content');
    } catch (e) {
      debugPrint('❌ Failed to show mining notification: $e');
    }
  }

  // Update mining notification with new data
  static Future<void> _updateMiningNotification() async {
    if (!_isNotificationActive) return;

    try {
      final duration = _getMiningDuration();
      final content = _buildNotificationContent(duration);

      final androidDetails = AndroidNotificationDetails(
        'mining_channel',
        'Mining Status',
        channelDescription: 'Shows current mining stats and status',
        importance: Importance.max,
        ongoing: true,
        showWhen: false,
        enableVibration: false,
        enableLights: true,
        playSound: false,
        color: const Color(0xFFFFC107),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          '$content\n\n🚀 Keep mining, keep earning! 💸',
          contentTitle: '⛏️ Bitcoin Cloud Mining - Mining in Progress',
          summaryText: 'Mining is active. Don\'t close the app!',
        ),
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        _notificationId,
        '⛏️ Bitcoin Cloud Mining - Mining in Progress',
        '$content\n\n🚀 Keep mining, keep earning! 💸',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('❌ Failed to update mining notification: $e');
    }
  }

  // Update mining stats
  static void updateMiningStats({
    required String balance,
    required String hashRate,
    required String status,
  }) {
    _currentBalance = balance;
    _currentHashRate = hashRate;
    _miningStatus = status;

    // Update notification if active
    if (_isNotificationActive) {
      _updateMiningNotification();
    }
  }

  // Build notification content
  static String _buildNotificationContent(String duration) {
    // Format balance to 18 decimal places
    final formattedBalance = _formatBalanceTo18Decimals(_currentBalance);

    return '💰 Balance: $formattedBalance BTC\n'
        '⚡ Hashrate: $_currentHashRate H/s\n'
        '⏱️ Duration: $duration\n'
        '📊 Status: $_miningStatus';
  }

  // Format balance to exactly 18 decimal places
  static String _formatBalanceTo18Decimals(String balance) {
    try {
      final doubleValue = double.tryParse(balance) ?? 0.0;
      return doubleValue.toStringAsFixed(18);
    } catch (e) {
      debugPrint('❌ Error formatting balance: $e');
      return '0.000000000000000000';
    }
  }

  // Get mining duration
  static String _getMiningDuration() {
    if (_miningStartTime == null) return '0m 0s';

    final now = DateTime.now();
    final difference = now.difference(_miningStartTime!);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Stop mining notification
  static Future<void> stopMiningNotification() async {
    try {
      _isNotificationActive = false;
      _updateTimer?.cancel();
      _updateTimer = null;
      _miningStartTime = null;

      // Remove the notification
      await _notifications.cancel(_notificationId);

      debugPrint('✅ Mining notification stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop mining notification: $e');
    }
  }

  // Check if mining notification is active
  static bool get isActive => _isNotificationActive;

  // Get current mining stats
  static Map<String, String> get currentStats => {
        'balance': _currentBalance,
        'hashRate': _currentHashRate,
        'status': _miningStatus,
        'duration': _getMiningDuration(),
      };

  // Dispose resources
  static void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}
