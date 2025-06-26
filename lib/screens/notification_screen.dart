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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          automaticallyImplyLeading: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(26, 35, 126, 0.95),
                  Color.fromRGBO(13, 71, 161, 0.95),
                  Color.fromRGBO(2, 119, 189, 0.95),
                ],
              ),
            ),
          ),
          elevation: 0,
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  context.read<NotificationProvider>().loadNotifications(),
            ),
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: () =>
                  context.read<NotificationProvider>().markAllAsRead(),
            ),
          ],
          backgroundColor: Colors.transparent,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.amber));
            }

            if (provider.notifications.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              );
            }

            return RefreshIndicator(
              color: Colors.amber,
              backgroundColor: Colors.white,
              onRefresh: () => provider.loadNotifications(),
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Notification notification) {
    final isUnread = !notification.isRead;
    return Card(
      elevation: isUnread ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isUnread
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      color: isUnread ? Colors.white : Colors.white.withAlpha(235),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        leading: _buildNotificationIcon(notification.category),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 18,
            color: isUnread ? Colors.indigo[900] : Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                color: isUnread ? Colors.black : Colors.grey[700],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.mark_email_read, color: Colors.amber),
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
