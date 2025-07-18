import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class ChartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _transactions = [];

  // Sabhi users ke transactions set karo
  void setAllTransactions(List<Map<String, dynamic>> transactions) {
    _transactions = transactions;
    notifyListeners();
  }

  // Transactions set karo (wallet se ya kahin se bhi)
  void setTransactions(List<Map<String, dynamic>> transactions) {
    _transactions = transactions;
    notifyListeners();
  }

  // Total transaction count
  int get transactionCount => _transactions.length;

  // Total transaction volume (amount sum)
  double get transactionVolume {
    double total = 0;
    for (var tx in _transactions) {
      if (tx['amount'] != null) {
        total += double.tryParse(tx['amount'].toString()) ?? 0;
      }
    }
    return total;
  }

  // Transactions getter (for chart)
  List<Map<String, dynamic>> get transactions => _transactions;

  /// Mining chart data (last 7 days)
  Map<String, dynamic> getMiningChartData(List<dynamic> transactions) {
    final today = DateTime.now();
    List<String> labels = [];
    List<int> miningCounts = [];
    List<Decimal> miningEarnings = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      labels.add('${date.day}/${date.month}');
      final dayTxs = transactions.where((tx) {
        if (tx['type'] != 'mining') return false;
        final ts = tx['timestamp'];
        final txDate = ts is String ? DateTime.tryParse(ts) : ts;
        return txDate != null &&
            txDate.year == date.year &&
            txDate.month == date.month &&
            txDate.day == date.day;
      }).toList();
      miningCounts.add(dayTxs.length);
      miningEarnings.add(
        dayTxs.fold<Decimal>(Decimal.zero, (sum, tx) {
          final amountStr = tx['amount']?.toString() ?? '0';
          final amount = Decimal.tryParse(amountStr) ?? Decimal.zero;
          return sum + amount;
        }),
      );
    }
    return {
      'labels': labels,
      'counts': miningCounts,
      'earnings': miningEarnings
          .map((e) => double.tryParse(e.toString()) ?? 0.0)
          .toList(),
      'earningsStr': miningEarnings.map((e) => e.toStringAsFixed(18)).toList(),
    };
  }
}
