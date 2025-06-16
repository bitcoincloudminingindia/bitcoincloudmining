class Transaction {
  final String id;
  final String userId;
  final String username;
  final String type; // Withdrawal, Referral, etc.
  final double amount;
  final double btcAmount;
  final String currency;
  final String status; // Pending, Completed, Rejected
  final String? paymentMethod;
  final String? destination;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.username,
    required this.type,
    required this.amount,
    required this.btcAmount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.destination,
    this.adminNote,
    required this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown User',
      type: json['type'] ?? 'Unknown',
      amount: (json['amount'] ?? 0.0).toDouble(),
      btcAmount: (json['btcAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'Pending',
      paymentMethod: json['paymentMethod'],
      destination: json['destination'],
      adminNote: json['adminNote'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'type': type,
        'amount': amount,
        'btcAmount': btcAmount,
        'currency': currency,
        'status': status,
        'paymentMethod': paymentMethod,
        'destination': destination,
        'adminNote': adminNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
} 