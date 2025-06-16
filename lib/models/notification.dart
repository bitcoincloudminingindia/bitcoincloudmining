import '../utils/enums.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String status;
  final DateTime timestamp;
  final NotificationCategory category;
  final String? payload;

  bool get isRead => status == 'read';

  const Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.timestamp,
    required this.category,
    this.payload,
  });

  Notification copyWith({
    String? id,
    String? title,
    String? body,
    String? status,
    DateTime? timestamp,
    NotificationCategory? category,
    String? payload,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'type': category.toString().split('.').last,
      'payload': payload,
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: _getCategoryFromType(json['type'] as String),
      payload: json['payload'] as String?,
    );
  }

  static NotificationCategory _getCategoryFromType(String type) {
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

  // Get icon for notification type
  String get icon {
    switch (category) {
      case NotificationCategory.info:
        return 'assets/icons/info.png';
      case NotificationCategory.success:
        return 'assets/icons/success.png';
      case NotificationCategory.warning:
        return 'assets/icons/warning.png';
      case NotificationCategory.error:
        return 'assets/icons/error.png';
      default:
        return 'assets/icons/info.png';
    }
  }

  // Get color for notification type
  String get color {
    switch (category) {
      case NotificationCategory.info:
        return '#2196F3'; // Blue
      case NotificationCategory.success:
        return '#4CAF50'; // Green
      case NotificationCategory.warning:
        return '#FFC107'; // Amber
      case NotificationCategory.error:
        return '#F44336'; // Red
      default:
        return '#2196F3'; // Blue
    }
  }

  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}

class RelatedTo {
  final String model;
  final String id;

  RelatedTo({
    required this.model,
    required this.id,
  });

  factory RelatedTo.fromJson(Map<String, dynamic> json) {
    return RelatedTo(
      model: json['model'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'id': id,
    };
  }
}
