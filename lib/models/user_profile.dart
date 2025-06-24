import 'package:uuid/uuid.dart';

class UserProfile {
  final String userId;
  String name; // Remove final to allow updates
  String? email;
  DateTime lastActive;
  DateTime joinDate;
  double walletBalance;
  double totalMined;
  double totalWithdrawn;
  List<Transaction> transactions;
  List<WithdrawalRequest> withdrawals;
  double miningRate;
  int powerUps;
  Map<String, dynamic> preferences;

  UserProfile({
    String? userId,
    required this.name,
    this.email,
    DateTime? lastActive,
    DateTime? joinDate,
    this.walletBalance = 0.0,
    this.totalMined = 0.0,
    this.totalWithdrawn = 0.0,
    List<Transaction>? transactions,
    List<WithdrawalRequest>? withdrawals,
    this.miningRate = 0.00001,
    this.powerUps = 0,
    Map<String, dynamic>? preferences,
  })  : userId = userId ?? const Uuid().v4(),
        lastActive = lastActive ?? DateTime.now(),
        joinDate = joinDate ?? DateTime.now(),
        transactions = transactions ?? [],
        withdrawals = withdrawals ?? [],
        preferences = preferences ?? {};

  void updateWalletBalance(double amount, String type) {
    if (type == 'mining') {
      walletBalance += amount;
      totalMined += amount;
      transactions.add(Transaction(
        type: 'mining',
        amount: amount,
        description: 'Mining reward',
      ));
    } else if (type == 'withdrawal') {
      if (amount <= walletBalance) {
        walletBalance -= amount;
        totalWithdrawn += amount;
        transactions.add(Transaction(
          type: 'withdrawal',
          amount: -amount,
          description: 'Withdrawal',
        ));
      }
    }
  }

  String getDisplayName() {
    return name.split(' ')[0]; // Get first name for friendly display
  }

  int getDaysActive() {
    return DateTime.now().difference(joinDate).inDays;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'lastActive': lastActive.toIso8601String(),
        'joinDate': joinDate.toIso8601String(),
        'walletBalance': walletBalance,
        'totalMined': totalMined,
        'totalWithdrawn': totalWithdrawn,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'withdrawals': withdrawals.map((w) => w.toJson()).toList(),
        'miningRate': miningRate,
        'powerUps': powerUps,
        'preferences': preferences,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'],
        name: json['name'],
        email: json['email'],
        lastActive: DateTime.parse(json['lastActive']),
        joinDate: DateTime.parse(json['joinDate']),
        walletBalance: json['walletBalance'],
        totalMined: json['totalMined'] ?? 0.0,
        totalWithdrawn: json['totalWithdrawn'] ?? 0.0,
        transactions: (json['transactions'] as List?)
                ?.map((t) => Transaction.fromJson(t))
                .toList() ??
            [],
        withdrawals: (json['withdrawals'] as List?)
                ?.map((w) => WithdrawalRequest.fromJson(w))
                .toList() ??
            [],
        miningRate: json['miningRate'],
        powerUps: json['powerUps'],
        preferences: json['preferences'] ?? {},
      );

  // Helper method to update user's last active timestamp
  void updateLastActive() {
    lastActive = DateTime.now();
  }
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final DateTime timestamp;
  final String description;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    DateTime? timestamp,
    required this.description,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        type: json['type'],
        amount: json['amount'],
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'],
      );
}

class WithdrawalRequest {
  final String id;
  final double amount;
  String destinationAddress;
  final DateTime requestTime;
  String status;
  DateTime? completionTime;

  WithdrawalRequest({
    String? id,
    required this.amount,
    this.destinationAddress = 'pending',
    DateTime? requestTime,
    this.status = 'pending',
    this.completionTime,
  })  : id = id ?? const Uuid().v4(),
        requestTime = requestTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'destinationAddress': destinationAddress,
        'requestTime': requestTime.toIso8601String(),
        'status': status,
        'completionTime': completionTime?.toIso8601String(),
      };

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      WithdrawalRequest(
        id: json['id'],
        amount: json['amount'],
        destinationAddress: json['destinationAddress'],
        requestTime: DateTime.parse(json['requestTime']),
        status: json['status'],
        completionTime: json['completionTime'] != null
            ? DateTime.parse(json['completionTime'])
            : null,
      );
}
