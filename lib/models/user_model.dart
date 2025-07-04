import 'package:flutter/foundation.dart';

class User {
  final String? id;
  final String userId;
  final String? email;
  final String? username;
  final bool isVerified;
  final String? referralCode;
  final dynamic referredBy;
  final double walletBalance;
  final int referralCount;
  final String? profileImagePath;
  final String? token;

  User({
    this.id,
    required this.userId,
    this.email,
    this.username,
    this.isVerified = false,
    this.referralCode,
    this.referredBy,
    this.walletBalance = 0.0,
    this.referralCount = 0,
    this.profileImagePath,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Debug function to check required fields
    if (kDebugMode) {
      _debugRequiredFields(json);
    }

    // Handle both direct user data and nested user data
    final userData = json['data']?['user'] ?? json['user'] ?? json;
    final token = json['data']?['token'] ?? json['token'];

    // Get userId from various possible fields
    final userId = userData['userId']?.toString() ??
        userData['id']?.toString() ??
        userData['_id']?.toString() ??
        '';

    return User(
      id: userData['id']?.toString(),
      userId: userId,
      email: userData['email']?.toString(),
      username: userData['username']?.toString(),
      isVerified: userData['isVerified'] ?? false,
      referralCode: userData['referralCode']?.toString(),
      referredBy: userData['referredBy'],
      walletBalance: (userData['walletBalance'] ?? 0).toDouble(),
      referralCount: userData['referralCount'] ?? 0,
      profileImagePath: userData['profileImagePath']?.toString(),
      token: token?.toString(),
    );
  }

  static void _debugRequiredFields(Map<String, dynamic> json) {
    // Check data object first
    final data = json['data'];
    if (data != null) {}

    // Get user data from correct location
    // final userData = data?['user'] ?? json['user'] ?? json; // Unused, isliye hata diya
    // Check token in both locations
    // final token = data?['token'] ?? json['token']; // Unused, isliye hata diya
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'username': username,
      'isVerified': isVerified,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'walletBalance': walletBalance,
      'referralCount': referralCount,
      'profileImagePath': profileImagePath,
      'token': token,
    };
  }

  User copyWith({
    String? id,
    String? userId,
    String? email,
    String? username,
    bool? isVerified,
    String? referralCode,
    dynamic referredBy,
    double? walletBalance,
    int? referralCount,
    String? profileImagePath,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      walletBalance: walletBalance ?? this.walletBalance,
      referralCount: referralCount ?? this.referralCount,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      token: token ?? this.token,
    );
  }
}
