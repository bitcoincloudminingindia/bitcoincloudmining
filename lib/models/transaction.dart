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

  factory Transaction.fromJson(dynamic json) {
    try {
      // Convert LinkedMap to Map<String, dynamic>
      final Map<String, dynamic> data = json is Map
          ? Map<String, dynamic>.from(json)
          : throw Exception('Invalid transaction data format');

      // Safely parse amount
      double amount = 0.0;
      if (data['amount'] is String) {
        amount = double.tryParse(data['amount']) ?? 0.0;
      } else if (data['amount'] is num) {
        amount = data['amount'].toDouble();
      }

      // Safely parse netAmount
      double netAmount = 0.0;
      if (data['netAmount'] is String) {
        netAmount = double.tryParse(data['netAmount']) ?? 0.0;
      } else if (data['netAmount'] is num) {
        netAmount = data['netAmount'].toDouble();
      }

      // Safely parse timestamp and date
      DateTime timestamp = DateTime.now();
      if (data['timestamp'] != null) {
        try {
          timestamp = DateTime.parse(data['timestamp'].toString());
        } catch (e) {
          print('⚠️ Error parsing timestamp: $e');
        }
      }

      DateTime date = DateTime.now();
      if (data['date'] != null) {
        try {
          date = DateTime.parse(data['date'].toString());
        } catch (e) {
          print('⚠️ Error parsing date: $e');
        }
      }

      // Parse createdAt and updatedAt
      DateTime createdAt = DateTime.now();
      if (data['createdAt'] != null) {
        try {
          createdAt = DateTime.parse(data['createdAt'].toString());
        } catch (e) {
          print('⚠️ Error parsing createdAt: $e');
        }
      }

      DateTime updatedAt = DateTime.now();
      if (data['updatedAt'] != null) {
        try {
          updatedAt = DateTime.parse(data['updatedAt'].toString());
        } catch (e) {
          print('⚠️ Error parsing updatedAt: $e');
        }
      }

      // Parse balanceBefore and balanceAfter
      double? balanceBefore;
      if (data['balanceBefore'] != null) {
        if (data['balanceBefore'] is String) {
          balanceBefore = double.tryParse(data['balanceBefore']);
        } else if (data['balanceBefore'] is num) {
          balanceBefore = data['balanceBefore'].toDouble();
        }
      }

      double? balanceAfter;
      if (data['balanceAfter'] != null) {
        if (data['balanceAfter'] is String) {
          balanceAfter = double.tryParse(data['balanceAfter']);
        } else if (data['balanceAfter'] is num) {
          balanceAfter = data['balanceAfter'].toDouble();
        }
      }

      // Parse localAmount and exchangeRate
      double? localAmount;
      if (data['localAmount'] != null) {
        if (data['localAmount'] is String) {
          localAmount = double.tryParse(data['localAmount']);
        } else if (data['localAmount'] is num) {
          localAmount = data['localAmount'].toDouble();
        }
      }

      double? exchangeRate;
      if (data['exchangeRate'] != null) {
        if (data['exchangeRate'] is String) {
          exchangeRate = double.tryParse(data['exchangeRate']);
        } else if (data['exchangeRate'] is num) {
          exchangeRate = data['exchangeRate'].toDouble();
        }
      }

      // Parse details map
      Map<String, dynamic>? details;
      if (data['details'] != null) {
        if (data['details'] is Map) {
          details = Map<String, dynamic>.from(data['details']);
        }
      }

      return Transaction(
        id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
        transactionId: data['transactionId']?.toString(),
        amount: amount,
        netAmount: netAmount,
        type: data['type']?.toString() ?? '',
        status: data['status']?.toString() ?? 'pending',
        date: date,
        currency: data['currency']?.toString() ?? 'BTC',
        timestamp: timestamp,
        planName: data['planName']?.toString(),
        source: data['source']?.toString(),
        destination: data['destination']?.toString(),
        adminNote: data['adminNote']?.toString(),
        description: data['description']?.toString() ?? '',
        withdrawalId: data['withdrawalId']?.toString(),
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        details: details,
        localAmount: localAmount,
        exchangeRate: exchangeRate,
        isClaimed: data['isClaimed'] ?? false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('❌ Error parsing transaction: $e');
      rethrow;
    }
  }
}
