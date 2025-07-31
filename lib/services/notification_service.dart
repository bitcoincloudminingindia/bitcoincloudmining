import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';

// Conditional web import

import '../services/api_service.dart';
import '../utils/storage_utils.dart';

class NotificationService {
  final String baseUrl;
  final ApiService _apiService;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String?> selectNotificationSubject =
      BehaviorSubject<String?>();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Timer? _updateTimer;
  static bool _isNotificationActive = false;
  static const int _notificationId = 1001; // Unique ID for mining notification

  // Mining stats
  static String _currentBalance = '0.00000000';
  static String _currentHashRate = '0.0';
  static String _miningStatus = '⛏️ Mining in progress...';
  static DateTime? _miningStartTime;

  NotificationService({
    required this.baseUrl,
    required ApiService apiService,
  }) : _apiService = apiService;

  Future<void> initialize() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectNotificationSubject.add(response.payload);
      },
    );

    // Create notification channels for Android 8.0+
    await _createNotificationChannels();

    // Initialize mining notification
    await _initializeMiningNotification();
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Wallet notifications channel
      const walletChannel = AndroidNotificationChannel(
        'wallet_channel',
        'Wallet Notifications',
        description: 'Notifications for wallet updates and transactions',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Game notifications channel
      const gameChannel = AndroidNotificationChannel(
        'game_channel',
        'Game Notifications',
        description: 'Notifications for game rewards and updates',
        importance: Importance.defaultImportance,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // System notifications channel
      const systemChannel = AndroidNotificationChannel(
        'system_channel',
        'System Notifications',
        description: 'General system notifications',
        importance: Importance.low,
        enableVibration: false,
        enableLights: false,
        playSound: false,
      );

      // Create channels
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(walletChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(gameChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(systemChannel);
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    required String id,
    required String status,
    required DateTime timestamp,
    String channelId = 'wallet_channel',
  }) async {
    AndroidNotificationDetails androidDetails;

    switch (channelId) {
      case 'wallet_channel':
        androidDetails = const AndroidNotificationDetails(
          'wallet_channel',
          'Wallet Notifications',
          channelDescription: 'Notifications for wallet updates',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          color: Color(0xFF2196F3),
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(''),
        );
        break;
      case 'game_channel':
        androidDetails = const AndroidNotificationDetails(
          'game_channel',
          'Game Notifications',
          channelDescription: 'Notifications for game rewards',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          color: Color(0xFF9C27B0),
        );
        break;
      default:
        androidDetails = const AndroidNotificationDetails(
          'system_channel',
          'System Notifications',
          channelDescription: 'General system notifications',
          importance: Importance.low,
          priority: Priority.low,
          enableVibration: false,
          enableLights: false,
          playSound: false,
        );
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      int.parse(id),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications']);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) throw Exception('No token found');

      await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) throw Exception('No token found');

      await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {}
  }

  Future<void> sendLoginNotification(
      String userId, String email, String username) async {
    try {
      final token = await StorageUtils.getToken();
      if (token == null) {
        return;
      }

      final deviceInfo = {
        'appName': 'bitcoin_cloud_mining',
        'appVersion': '1.0.4',
        'browser': 'BrowserName.chrome',
        'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
        'userAgent': 'Unknown', // Simplified for non-web platforms
      };

      final data = {
        'action': 'login',
        'userId': userId,
        'email': email,
        'username': username,
        'deviceInfo': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post(
        '/auth/login-notification',
        data,
      );

      if (!response['success']) {}
    } catch (e) {}
  }

  void dispose() {
    selectNotificationSubject.close();
    _audioPlayer.dispose();
  }

  Future<void> _initializeMiningNotification() async {
    try {
      // Create mining notification channel
      await _createMiningChannel();

      // Show initial notification
      await _showMiningNotification();

      // Start periodic updates
      _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _updateMiningNotification();
      });
    } catch (e) {}
  }

  Future<void> _createMiningChannel() async {
    if (Platform.isAndroid) {
      const miningChannel = AndroidNotificationChannel(
        'mining_channel',
        'Mining Status',
        description: 'Shows current mining stats and status',
        importance: Importance.max,
        enableVibration: false,
        enableLights: true,
        playSound: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('mining_notification'),
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(miningChannel);
    }
  }

  Future<void> _showMiningNotification() async {
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
        playSound: true,
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
    } catch (e) {}
  }

  Future<void> _updateMiningNotification() async {
    if (!_isNotificationActive) return;

    try {
      // Update stats (in real app, these would come from your mining service)
      await _showMiningNotification();
    } catch (e) {}
  }

  Future<void> updateMiningStats({
    String? balance,
    String? hashRate,
    String? status,
  }) async {
    if (balance != null) _currentBalance = balance;
    if (hashRate != null) _currentHashRate = hashRate;
    if (status != null) _miningStatus = status;

    if (_isNotificationActive) {
      await _showMiningNotification();
    }
  }

  String _buildNotificationContent(String duration) {
    return '''
💰 Balance: $_currentBalance BTC
⚡ Hashrate: $_currentHashRate H/s
⏱️ Duration: $duration
🔒 App is running in background''';
  }

  String _getMiningDuration() {
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

  Future<void> stopMiningNotification() async {
    try {
      _isNotificationActive = false;
      _updateTimer?.cancel();
      _updateTimer = null;
      _miningStartTime = null;

      // Remove the notification
      await _notifications.cancel(_notificationId);
    } catch (e) {}
  }

  bool get isActive => _isNotificationActive;

  Map<String, String> get currentStats => {
        'balance': _currentBalance,
        'hashRate': _currentHashRate,
        'status': _miningStatus,
        'duration': _getMiningDuration(),
      };
}
