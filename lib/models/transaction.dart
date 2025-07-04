
class Transaction {
  final String id;
  final String transactionId;
  final double amount;
  final double netAmount;
  final String type;
  final String status;
  final DateTime date;
  final String currency;
  final DateTime timestamp;
  final String? planName;
  final String? source;
  final String? destination;
  final String? adminNote;
  final String description;
  final String? withdrawalId;
  final double? balanceBefore;
  final double? balanceAfter;
  final Map<String, dynamic>? details;
  final double? localAmount;
  final double? exchangeRate;
  final bool isClaimed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    String? transactionId,
    required this.amount,
    double? netAmount,
    required this.type,
    required this.status,
    DateTime? date,
    String? currency,
    DateTime? timestamp,
    this.planName,
    this.source,
    this.destination,
    this.adminNote,
    this.description = '',
    this.withdrawalId,
    this.balanceBefore,
    this.balanceAfter,
    this.details,
    this.localAmount,
    this.exchangeRate,
    this.isClaimed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : transactionId = transactionId ?? id,
        date = date ?? (timestamp ?? DateTime.now()),
        currency = currency ?? 'BTC',
        netAmount = netAmount ?? amount,
        createdAt = createdAt ?? (timestamp ?? DateTime.now()),
        updatedAt = updatedAt ?? (timestamp ?? DateTime.now()),
        timestamp = timestamp ?? DateTime.now();

  Transaction copyWith({
    String? id,
    String? transactionId,
    double? amount,
    double? netAmount,
    String? type,
    String? status,
    DateTime? date,
    String? currency,
    DateTime? timestamp,
    String? planName,
    String? source,
    String? destination,
    String? adminNote,
    String? description,
    String? withdrawalId,
    double? balanceBefore,
    double? balanceAfter,
    Map<String, dynamic>? details,
    double? localAmount,
    double? exchangeRate,
    bool? isClaimed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      netAmount: netAmount ?? this.netAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      planName: planName ?? this.planName,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      adminNote: adminNote ?? this.adminNote,
      description: description ?? this.description,
      withdrawalId: withdrawalId ?? this.withdrawalId,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      details: details ?? this.details,
      localAmount: localAmount ?? this.localAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isClaimed: isClaimed ?? this.isClaimed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'type': type,
      'amount': amount.toString(),
      'netAmount': netAmount.toString(),
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'date': date.toIso8601String(),
      'description': description,
      'currency': currency,
      'destination': destination,
      'withdrawalId': withdrawalId,
      'adminNote': adminNote,
      'balanceBefore': balanceBefore?.toString() ?? '0',
      'balanceAfter': balanceAfter?.toString() ?? '0',
      'details': details ?? {},
      'localAmount': localAmount?.toString(),
      'exchangeRate': exchangeRate?.toString(),
      'isClaimed': isClaimed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse amount
      double amount = 0.0;
      if (json['amount'] != null) {
        if (json['amount'] is String) {
          amount = double.tryParse(json['amount']) ?? 0.0;
        } else if (json['amount'] is num) {
          amount = (json['amount'] as num).toDouble();
        }
      }

      // Safely parse netAmount
      double netAmount = 0.0;
      if (json['netAmount'] != null) {
        if (json['netAmount'] is String) {
          netAmount = double.tryParse(json['netAmount']) ?? 0.0;
        } else if (json['netAmount'] is num) {
          netAmount = (json['netAmount'] as num).toDouble();
        }
      }

      // Parse timestamp
      DateTime timestamp = DateTime.now();
      if (json['timestamp'] != null) {
        try {
          timestamp = DateTime.parse(json['timestamp'].toString());
        } catch (e) {
        }
      }

      // Parse details map
      Map<String, dynamic> details = {};
      if (json['details'] != null && json['details'] is Map) {
        details = Map<String, dynamic>.from(json['details']);
      }

      return Transaction(
        id: json['_id']?.toString() ??
            json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        transactionId: json['transactionId']?.toString() ??
            json['_id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: json['type']?.toString() ?? 'unknown',
        amount: amount,
        netAmount: netAmount,
        status: json['status']?.toString() ?? 'pending',
        timestamp: timestamp,
        currency: json['currency']?.toString() ?? 'BTC',
        description: json['description']?.toString() ?? '',
        adminNote: json['adminNote']?.toString(),
        withdrawalId: json['withdrawalId']?.toString(),
        details: details,
        isClaimed: json['isClaimed'] ?? false,
      );
    } catch (e) {
      rethrow;
    }
  }
}
