class User {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String dob;
  final double walletBalance;
  final String status; // Active, Suspended, etc.
  final String? referralCode;
  final List<String> referrals;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.dob,
    required this.walletBalance,
    required this.status,
    this.referralCode,
    required this.referrals,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      status: json['isActive'] == true ? 'Active' : 'Inactive',
      referralCode: json['referralCode'],
      referrals: List<String>.from(json['referrals'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone': phone,
        'dob': dob,
        'walletBalance': walletBalance,
        'isActive': status == 'Active',
        'referralCode': referralCode,
        'referrals': referrals,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };
} 