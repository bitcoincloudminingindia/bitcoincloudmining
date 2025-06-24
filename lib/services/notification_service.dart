import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

  NotificationService({
    required this.baseUrl,
    required ApiService apiService,
  }) : _apiService = apiService;

  Future<void> initialize() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();

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
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    required String id,
    required String status,
    required DateTime timestamp,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wallet_channel',
      'Wallet Notifications',
      channelDescription: 'Notifications for wallet updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
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
      print('Error getting notifications: $e');
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
    } catch (e) {
      print('Error marking notification as read: $e');
    }
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
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> sendLoginNotification(
      String userId, String email, String username) async {
    try {
      final token = await StorageUtils.getToken();
      if (token == null) {
        print('No token available for login notification');
        return;
      }

      final deviceInfo = {
        'appName': 'bitcoin_cloud_mining',
        'appVersion': '1.0.0',
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

      print('Sending login notification with data: $data');

      final response = await ApiService.post(
        '/auth/login-notification',
        data,
      );

      print('Login notification response: $response');
      if (!response['success']) {
        print('Failed to send login notification: ${response['message']}');
      }
    } catch (e) {
      print('Error sending login notification: $e');
    }
  }

  void dispose() {
    selectNotificationSubject.close();
  }
}
