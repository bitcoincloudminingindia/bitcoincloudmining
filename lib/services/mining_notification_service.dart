import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;

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
      _miningStatus = '⛏️ Mining in progress...';

      // Show initial notification
      await _showMiningNotification();

      // Start periodic updates (every 1s for live timer)
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateMiningNotification();
      });

      debugPrint('✅ Mining notification started');
    } catch (e) {
      debugPrint('❌ Failed to start mining notification: $e');
    }
  }

  // Complete mining notification (status update, don't remove notification)
  static Future<void> completeMiningNotification() async {
    try {
      _isNotificationActive = true; // notification bar me rahe
      _miningStatus = '✅ Mining completed!';
      await _showMiningNotification(
          statusOverride: '✅ Mining completed!', timeOverride: '-');
      _updateTimer?.cancel();
      _updateTimer = null;
      debugPrint('✅ Mining notification completed (status updated)');
    } catch (e) {
      debugPrint('❌ Failed to complete mining notification: $e');
    }
  }

  // Show mining notification (with optional override)
  static Future<void> _showMiningNotification(
      {String? statusOverride, String? timeOverride}) async {
    if (!_isNotificationActive) return;

    try {
      final duration = timeOverride ?? _getMiningDuration();
      final status = statusOverride ?? _miningStatus;

      final content =
          '💰 Balance: ${_formatBalanceTo18Decimals(_currentBalance)} BTC\n'
          '⚡ Hashrate: $_currentHashRate H/s\n'
          '⏱️ Duration: $duration\n'
          '📊 Status: $status';

      final androidDetails = AndroidNotificationDetails(
        'mining_channel',
        'Mining Status',
        channelDescription: 'Shows current mining stats and status',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true, // 🔒 Makes it non-dismissible
        autoCancel: false, // User forcefully bhi remove nahi kar sakta
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
    await _showMiningNotification();
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

  // Stop mining notification (now only stops timer, does not remove notification)
  static Future<void> stopMiningNotification() async {
    try {
      _isNotificationActive = false;
      _updateTimer?.cancel();
      _updateTimer = null;
      // Notification ko remove nahi karenge, bas timer band karenge
      debugPrint('✅ Mining notification timer stopped (notification remains)');
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

  // Android floating bubble (show)
  static Future<void> showFloatingBubble() async {
    if (Platform.isAndroid) {
      if (!await overlay.FlutterOverlayWindow.isPermissionGranted()) {
        await overlay.FlutterOverlayWindow.requestPermission();
      }
      await overlay.FlutterOverlayWindow.showOverlay(
        height: 80,
        width: 80,
        alignment: overlay.OverlayAlignment.centerLeft,
        flag: overlay.OverlayFlag.defaultFlag,
        visibility: overlay.NotificationVisibility.visibilityPublic,
      );
    }
  }

  // Android floating bubble (hide)
  static Future<void> hideFloatingBubble() async {
    if (Platform.isAndroid) {
      await overlay.FlutterOverlayWindow.closeOverlay();
    }
  }
}
