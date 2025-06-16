import 'package:flutter/material.dart' hide Notification;
import 'package:provider/provider.dart';

import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../utils/enums.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<NotificationProvider>().loadNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () =>
                context.read<NotificationProvider>().markAllAsRead(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Notification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildNotificationIcon(notification.category),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => context
                    .read<NotificationProvider>()
                    .markAsRead(notification.id),
              ),
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationProvider>().markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationIcon(NotificationCategory category) {
    IconData iconData;
    Color color;

    switch (category) {
      case NotificationCategory.wallet:
        iconData = Icons.account_balance_wallet;
        color = Colors.blue;
        break;
      case NotificationCategory.game:
        iconData = Icons.games;
        color = Colors.purple;
        break;
      case NotificationCategory.system:
        iconData = Icons.system_update;
        color = Colors.grey;
        break;
      case NotificationCategory.info:
        iconData = Icons.info;
        color = Colors.blue;
        break;
      case NotificationCategory.success:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationCategory.warning:
        iconData = Icons.warning;
        color = Colors.orange;
        break;
      case NotificationCategory.error:
        iconData = Icons.error;
        color = Colors.red;
        break;
    }

    return CircleAvatar(
      backgroundColor: Color.fromRGBO(
          color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.1),
      child: Icon(iconData, color: color),
    );
  }

  void _handleNotificationTap(Notification notification) {
    if (notification.payload == null) return;

    // Handle navigation based on notification category
    switch (notification.category) {
      case NotificationCategory.wallet:
        Navigator.pushNamed(context, '/wallet');
        break;
      case NotificationCategory.game:
        Navigator.pushNamed(context, '/game');
        break;
      default:
        // Do nothing for other categories
        break;
    }
  }
}
