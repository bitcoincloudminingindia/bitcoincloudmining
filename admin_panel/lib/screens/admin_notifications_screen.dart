import 'package:flutter/material.dart';
// Create this model
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/user_selection_dialog.dart'; // Create this widget

class AdminNotificationsScreen extends StatefulWidget {
  static const String routeName = '/admin-notifications';

  const AdminNotificationsScreen({super.key});

  @override
  _AdminNotificationsScreenState createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String _errorMessage = '';

  // Add new state variables
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'INFO';
  String _targetType = 'ALL';
  List<String> _selectedUsers = [];
  final String _selectedGroup = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await _apiService.getAdminNotifications();

      if (result['success']) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
              result['data']['notifications'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showSendNotificationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text('No notifications found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'No Title';
    final message = notification['message'] ?? 'No Message';
    final timestamp = _formatTimestamp(notification['createdAt']);
    final type = notification['type'] ?? 'info';
    final isRead = notification['isRead'] ?? false;
    final userId = notification['userId'];
    final transactionId = notification['transactionId'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
            _getNotificationIcon(type)), // Fixed: Wrap IconData in Icon widget
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 8),
            Text(
              timestamp,
              style: const TextStyle(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                fontSize: 12,
              ),
            ),
            if (userId != null)
              TextButton(
                onPressed: () {
                  // Navigate to user details
                  // Example: Navigator.pushNamed(context, '/user-details', arguments: userId);
                },
                child: const Text('View User'),
              ),
            if (transactionId != null)
              TextButton(
                onPressed: () {
                  // Navigate to transaction details
                  // Example: Navigator.pushNamed(context, '/transaction-details', arguments: transactionId);
                },
                child: const Text('View Transaction'),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () {
                  // Mark as read functionality
                  // This would typically call an API to update the notification status
                  setState(() {
                    notification['isRead'] = true;
                  });
                },
              ),
        onTap: () {
          // View notification details
          _showNotificationDetails(notification);
        },
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'Notification Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification['message'] ?? ''),
              const SizedBox(height: 16),
              Text(
                'Received: ${_formatTimestamp(notification['createdAt'])}',
                style:
                    const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.1)),
              ),
              if (notification['userId'] != null) ...[
                const SizedBox(height: 16),
                Text('User ID: ${notification['userId']}'),
              ],
              if (notification['transactionId'] != null) ...[
                const SizedBox(height: 8),
                Text('Transaction ID: ${notification['transactionId']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!notification['isRead'])
            TextButton(
              onPressed: () {
                // Mark as read
                setState(() {
                  notification['isRead'] = true;
                });
                Navigator.pop(context);
              },
              child: const Text('Mark as Read'),
            ),
        ],
      ),
    );
  }

  void _showSendNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _targetType,
                  decoration: const InputDecoration(labelText: 'Send To'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Users')),
                    DropdownMenuItem(value: 'GROUP', child: Text('User Group')),
                    DropdownMenuItem(
                        value: 'SELECTED', child: Text('Selected Users')),
                  ],
                  onChanged: (value) {
                    setState(() => _targetType = value!);
                    if (value == 'SELECTED') {
                      _showUserSelectionDialog();
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Message is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'INFO', child: Text('Information')),
                    DropdownMenuItem(value: 'WARNING', child: Text('Warning')),
                    DropdownMenuItem(value: 'SUCCESS', child: Text('Success')),
                    DropdownMenuItem(value: 'ERROR', child: Text('Error')),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _sendNotification,
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await _apiService.sendBulkNotification({
        'title': _titleController.text,
        'message': _messageController.text,
        'type': _selectedType,
        'targetType': _targetType,
        'userIds': _targetType == 'SELECTED' ? _selectedUsers : null,
        'group': _targetType == 'GROUP' ? _selectedGroup : null,
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent to ${response['data']['count']} users'),
            backgroundColor: Theme.of(context).primaryColor.withValues(
                  alpha: 51.0,
                  red: Theme.of(context).primaryColor.r.toDouble(),
                  green: Theme.of(context).primaryColor.g.toDouble(),
                  blue: Theme.of(context).primaryColor.b.toDouble(),
                ),
          ),
        );
        Navigator.pop(context);
        _loadNotifications(); // Refresh list
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showUserSelectionDialog() async {
    final selectedUsers = await showDialog<List<String>>(
      context: context,
      builder: (context) => const UserSelectionDialog(),
    );

    if (selectedUsers != null) {
      setState(() => _selectedUsers = selectedUsers);
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'system':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }
}
