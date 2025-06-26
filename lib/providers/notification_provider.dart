import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import '../utils/enums.dart' show NotificationCategory;

const String walletUpdateTask = 'walletUpdateTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const walletDetails = AndroidNotificationDetails(
        'wallet_channel',
        'Wallet Updates',
        channelDescription:
            'Notifications related to your wallet and transactions.',
        importance: Importance.max,
        priority: Priority.high,
      );

      if (task == walletUpdateTask) {
        await notificationsPlugin.show(
          0,
          'Wallet Update',
          'Your wallet balance was refreshed.',
          const NotificationDetails(android: walletDetails),
        );
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  List<Notification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  NotificationProvider({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  List<Notification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Initialize notifications
  Future<void> initialize() async {
    await _notificationService.initialize();
    await loadNotifications();
  }

  // Load notifications from backend
  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      final notificationsData = await _notificationService.getNotifications();
      _notifications = notificationsData.map(Notification.fromJson).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new notification
  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    String? payload,
  }) async {
    try {
      final notification = Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        status: 'unread',
        timestamp: DateTime.now(),
        category: _getCategoryFromType(type),
        payload: payload,
      );

      await _notificationService.showNotification(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        status: notification.status,
        timestamp: notification.timestamp,
        payload: notification.payload,
      );

      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  // Add a notification from a local event (e.g., local notification callback)
  void addNotificationFromLocal(Notification notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(status: 'read');
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      _notifications =
          _notifications.map((n) => n.copyWith(status: 'read')).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  NotificationCategory _getCategoryFromType(String type) {
    switch (type.toLowerCase()) {
      case 'wallet':
        return NotificationCategory.wallet;
      case 'game':
        return NotificationCategory.game;
      case 'system':
        return NotificationCategory.system;
      case 'info':
        return NotificationCategory.info;
      case 'success':
        return NotificationCategory.success;
      case 'warning':
        return NotificationCategory.warning;
      case 'error':
        return NotificationCategory.error;
      default:
        return NotificationCategory.system;
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
