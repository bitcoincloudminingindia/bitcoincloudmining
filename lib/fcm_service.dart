import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

      // Get FCM token
      final token = await getFcmToken();
      if (token != null) {}

      // Only set up background message handler if Firebase is available
      if (_isFirebaseInitialized) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
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
    } catch (e) {}
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

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
        } else {}
      } catch (e) {}
    }
  }

  static Future<String?> getFcmToken() async {
    if (_isFirebaseInitialized) {
      try {
        return await FirebaseMessaging.instance.getToken();
      } catch (e) {
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
        });
      } catch (e) {}
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
    } catch (e) {}
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {}
}
