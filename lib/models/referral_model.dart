class Referral {
  final String id;
  final String referrerId;
  final String referredId;
  final String status;
  final double rewardAmount;
  final String rewardStatus;
  final DateTime createdAt;
  final DateTime? completedAt;

  Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.status,
    required this.rewardAmount,
    required this.rewardStatus,
    required this.createdAt,
    this.completedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['_id'] ?? '',
      referrerId: json['referrer'] ?? '',
      referredId: json['referred'] ?? '',
      status: json['status'] ?? 'pending',
      rewardAmount: (json['rewardAmount'] ?? 0).toDouble(),
      rewardStatus: json['rewardStatus'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'referrer': referrerId,
      'referred': referredId,
      'status': status,
      'rewardAmount': rewardAmount,
      'rewardStatus': rewardStatus,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Referral copyWith({
    String? id,
    String? referrerId,
    String? referredId,
    String? status,
    double? rewardAmount,
    String? rewardStatus,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Referral(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referredId: referredId ?? this.referredId,
      status: status ?? this.status,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardStatus: rewardStatus ?? this.rewardStatus,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
