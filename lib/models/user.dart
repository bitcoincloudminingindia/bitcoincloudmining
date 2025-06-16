import 'wallet.dart';

class Transaction {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String status;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: json['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}

class Notification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class User {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String fullName;
  final String role;
  final bool isVerified;
  final bool isEmailVerified;
  final String? profilePicture;
  final String? avatar;
  final String referralCode;
  final int referralCount;
  final double referralEarnings;
  final double totalRewardsClaimed;
  final double todayRewardsClaimed;
  final bool isActive;
  final String status;
  final DateTime lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Wallet? wallet;

  User({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.isEmailVerified,
    this.profilePicture,
    this.avatar,
    required this.referralCode,
    required this.referralCount,
    required this.referralEarnings,
    required this.totalRewardsClaimed,
    required this.todayRewardsClaimed,
    required this.isActive,
    required this.status,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.wallet,
  });

  // Computed getter for wallet balance
  double get walletBalance {
    if (wallet != null) {
      return wallet!.balance;
    }
    return 0.0;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isVerified: json['isVerified'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      profilePicture: json['profilePicture']?.toString(),
      avatar: json['avatar']?.toString(),
      referralCode: json['referralCode']?.toString() ?? '',
      referralCount: (json['referralCount'] as num?)?.toInt() ?? 0,
      referralEarnings: (json['referralEarnings'] as num?)?.toDouble() ?? 0.0,
      totalRewardsClaimed:
          double.tryParse(json['totalRewardsClaimed']?.toString() ?? '0') ??
              0.0,
      todayRewardsClaimed:
          double.tryParse(json['todayRewardsClaimed']?.toString() ?? '0') ??
              0.0,
      isActive: json['isActive'] as bool? ?? true,
      status: json['status']?.toString() ?? 'active',
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      wallet: json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'fullName': fullName,
      'role': role,
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'profilePicture': profilePicture,
      'avatar': avatar,
      'referralCode': referralCode,
      'referralCount': referralCount,
      'referralEarnings': referralEarnings,
      'totalRewardsClaimed': totalRewardsClaimed,
      'todayRewardsClaimed': todayRewardsClaimed,
      'isActive': isActive,
      'status': status,
      'lastLogin': lastLogin.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'wallet': wallet?.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? fullName,
    String? role,
    bool? isVerified,
    bool? isEmailVerified,
    String? profilePicture,
    String? avatar,
    String? referralCode,
    int? referralCount,
    double? referralEarnings,
    double? totalRewardsClaimed,
    double? todayRewardsClaimed,
    bool? isActive,
    String? status,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    Wallet? wallet,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profilePicture: profilePicture ?? this.profilePicture,
      avatar: avatar ?? this.avatar,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      totalRewardsClaimed: totalRewardsClaimed ?? this.totalRewardsClaimed,
      todayRewardsClaimed: todayRewardsClaimed ?? this.todayRewardsClaimed,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wallet: wallet ?? this.wallet,
    );
  }
}
