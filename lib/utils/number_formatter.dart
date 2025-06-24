import 'package:intl/intl.dart';

class NumberFormatter {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 18,
  );

  static String formatBTCAmount(double amount) {
    // Convert scientific notation to regular decimal format
    final formatted = amount.toStringAsFixed(18);
    // Remove trailing zeros after decimal point
    final trimmed = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    // If the number is very small (less than 0.000001), keep all 18 decimal places
    if (amount < 0.000001) {
      return formatted;
    }
    return trimmed;
  }

  // Format balance string with exactly 18 decimal places
  static String formatBalanceString(String balance) {
    try {
      if (balance.isEmpty) return '0.000000000000000000';

      // Remove any existing formatting
      final cleanBalance = balance.replaceAll(RegExp(r'[^\d.-]'), '');

      // Parse as double
      final amount = double.tryParse(cleanBalance) ?? 0.0;

      // Format with exactly 18 decimal places
      return amount.toStringAsFixed(18);
    } catch (e) {
      print('❌ Error formatting balance: $e');
      return '0.000000000000000000';
    }
  }

  static String formatCrypto(double value) {
    if (value == 0) return '0.000000000000000000';
    return value.toStringAsFixed(18);
  }

  static String formatCryptoCompact(double value) {
    // Always show 18 decimal places for BTC
    return formatBTCAmount(value);
  }

  static String formatCurrency(double value) {
    try {
      if (value >= 1000000) {
        return '\$${(value / 1000000).toStringAsFixed(18)}M';
      } else if (value >= 1000) {
        return '\$${(value / 1000).toStringAsFixed(18)}K';
      }
      return _currencyFormat.format(value);
    } catch (e) {
      print('Error formatting currency value: $e');
      return '\$${value.toString()}';
    }
  }

  static String _handleFormattingError(
      String operation, dynamic error, double value) {
    print('Error in $operation: $error');
    return value.toString();
  }

  static String formatCompact(double value) {
    try {
      if (value >= 1000000000) {
        return '${(value / 1000000000).toStringAsFixed(18)}B';
      } else if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(18)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(18)}K';
      }
      return value.toStringAsFixed(18);
    } catch (e) {
      return _handleFormattingError('compact formatting', e, value);
    }
  }

  static String formatPercentage(double value) {
    try {
      if (value < 0.000001) {
        return '<0.0001%';
      }
      return '${(value * 100).toStringAsFixed(18)}%';
    } catch (e) {
      return _handleFormattingError('percentage formatting', e, value);
    }
  }

  // Convert string to double safely
  static double parseAmount(String amount) {
    try {
      return double.parse(amount);
    } catch (e) {
      print('Error parsing amount: $e');
      return 0.0;
    }
  }

  // Format based on amount size
  static String formatSmartCrypto(double value) {
    try {
      if (value >= 0.00000001) {
        return formatCryptoCompact(value);
      } else {
        return formatCrypto(value);
      }
    } catch (e) {
      return _handleFormattingError('smart crypto formatting', e, value);
    }
  }

  static String formatFiat(double amount) {
    return amount.toStringAsFixed(18);
  }

  static String formatNumber(double value) {
    try {
      if (value >= 1000000000) {
        return '${(value / 1000000000).toStringAsFixed(18)}B';
      } else if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(18)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(18)}K';
      }
      return value.toStringAsFixed(18);
    } catch (e) {
      return _handleFormattingError('number formatting', e, value);
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static double parseBTCAmount(String amount) {
    // Convert string to double and ensure 18 decimal places
    return double.parse(double.parse(amount).toStringAsFixed(18));
  }

  static String formatAmount(double amount) {
    // Format any amount to 18 decimal places
    return amount.toStringAsFixed(18);
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing string to double: $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  // Convert scientific notation to decimal string
  static String fromScientific(double value) {
    if (value == 0) return '0.000000000000000000';

    // Convert to string in scientific notation
    final String str = value.toString();

    // If not in scientific notation, pad with zeros to 18 decimal places
    if (!str.contains('e')) {
      final parts = str.split('.');
      final decimals = parts.length > 1 ? parts[1] : '';
      return '${parts[0]}.${decimals.padRight(18, '0')}';
    }

    // Parse scientific notation
    final parts = str.split('e');
    final base = double.parse(parts[0]);
    final exponent = int.parse(parts[1]);

    if (exponent > 0) {
      // Move decimal point right
      String result = base.abs().toString().replaceAll('.', '');
      result = result.padRight(exponent + 1, '0');
      return '${base < 0 ? '-' : ''}${result.substring(0, result.length - 18)}.${result.substring(result.length - 18)}';
    } else {
      // Move decimal point left
      final abs = exponent.abs();
      final baseStr = base.abs().toString().replaceAll('.', '');
      final String result = '0.${'0' * (abs - 1)}$baseStr';
      // Ensure 18 decimal places
      final parts = result.split('.');
      return '${base < 0 ? '-' : ''}${parts[0]}.${parts[1].padRight(18, '0')}';
    }
  }
}
