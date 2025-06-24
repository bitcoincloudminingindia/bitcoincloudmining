import 'transaction.dart';

class Wallet {
  final double balance;
  final double pendingBalance;
  final String currency;
  final List<Transaction> transactions;
  final DateTime lastUpdated;

  Wallet({
    required this.balance,
    required this.pendingBalance,
    required this.currency,
    required this.transactions,
    required this.lastUpdated,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      pendingBalance:
          double.tryParse(json['pendingBalance']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'BTC',
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((txJson) =>
                  Transaction.fromJson(txJson as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance.toString(),
      'pendingBalance': pendingBalance.toString(),
      'currency': currency,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
