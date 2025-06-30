import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'services/audio_service.dart';

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isFirebaseInitialized = false;

  static Future<void> initializeFCM() async {
    try {
      // Firebase should already be initialized in main.dart
      _isFirebaseInitialized = true;
      await _initLocalNotifications();

      // Initialize audio service
      await AudioService.initialize();

      // Request notification permission
      await requestPermission();

      // Get FCM token
      final token = await getFcmToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
      }

      // Only set up background message handler if Firebase is available
      if (_isFirebaseInitialized) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }

      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('❌ FCM initialization failed: $e');
      _isFirebaseInitialized = false;
      // Still initialize local notifications even if Firebase fails
      await _initLocalNotifications();
    }
  }

  static Future<void> _initLocalNotifications() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: android);
      await _localNotifications.initialize(initSettings);
    } catch (e) {
      debugPrint('Local notifications initialization failed: $e');
    }
  }

  static Future<void> requestPermission() async {
    if (_isFirebaseInitialized) {
      try {
        final FirebaseMessaging messaging = FirebaseMessaging.instance;

        final NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint(
            '📱 Notification permission status: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('✅ Notification permission granted');
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          debugPrint('⚠️ Provisional notification permission granted');
        } else {
          debugPrint('❌ Notification permission denied');
        }
      } catch (e) {
        debugPrint('❌ Firebase messaging permission request failed: $e');
      }
    }
  }

  static Future<String?> getFcmToken() async {
    if (_isFirebaseInitialized) {
      try {
        return await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
        return null;
      }
    }
    return null;
  }

  static void listenFCM() {
    if (_isFirebaseInitialized) {
      try {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            _showLocalNotification(message);
          }
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          // Handle notification tap (background/terminated)
          debugPrint('Notification opened: ${message.notification?.title}');
        });
      } catch (e) {
        debugPrint('Firebase messaging listener setup failed: $e');
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Play custom notification sound
      await AudioService.playNotificationSound();

      final android = AndroidNotificationDetails(
        'default_channel',
        'General',
        channelDescription: 'General notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      );
      final details = NotificationDetails(android: android);
      await _localNotifications.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('Handling a background message: ${message.messageId}');
  } catch (e) {
    debugPrint('Background message handler failed: $e');
  }
}
