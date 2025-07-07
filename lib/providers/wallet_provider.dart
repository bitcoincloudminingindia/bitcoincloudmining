import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/sound_notification_service.dart';
import '../services/wallet_service.dart';
import '../utils/number_formatter.dart';
import '../utils/storage_utils.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WalletService _walletService = WalletService();
  double _btcBalance = 0.0;
  double _balance = 0.0;
  bool _isLoading = false;
  String? _error;
  List<Transaction> _transactions = [];
  final List<Transaction> _pendingTransactions = [];
  double _btcPrice = 30000.0; // Default BTC price in USD
  double _totalEarned = 0.0;
  double _totalWithdrawn = 0.0;
  String _filterType = 'All';
  String _selectedCurrency = 'USD';
  bool _isSyncing = false;

  // Default rates map
  static const Map<String, double> _defaultRates = {
    'USD': 1.0,
    'INR': 83.0,
    'EUR': 0.91,
    'GBP': 0.79,
    'JPY': 142.50,
    'AUD': 1.48,
    'CAD': 1.33,
  };

  // Currency rates map with default values
  Map<String, double> _currencyRates = Map.from(_defaultRates);

  // Track claimed transactions
  final Set<String> _claimedTransactions = {};

  // Getters
  double get btcBalance => _btcBalance;
  double get btcPrice => _btcPrice;
  Map<String, double> get currencyRates => Map.unmodifiable(_currencyRates);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  String get formattedBtcBalance =>
      NumberFormatter.formatBTCAmount(_btcBalance);
  Set<String> get claimedTransactions => _claimedTransactions;
  List<Transaction> get pendingTransactions =>
      List.unmodifiable(_pendingTransactions);
  String get selectedCurrency => _selectedCurrency;
  bool get isSyncing => _isSyncing;
  double get totalEarned => _totalEarned;
  double get totalWithdrawn => _totalWithdrawn;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Transaction> get filteredTransactions {
    if (_filterType == 'All') {
      return List.unmodifiable(_transactions
          .where((tx) =>
              tx.type.toLowerCase().contains('reward') ||
              tx.type.toLowerCase().contains('bonus') ||
              tx.type.toLowerCase().contains('withdrawal') ||
              tx.type.toLowerCase().contains('earnings'))
          .toList());
    }
    return _transactions.where((tx) => tx.type == _filterType).toList();
  }

  Future<void> initializeWallet() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final data = await _walletService.initializeWallet();

      if (data['balance'] != null) {
        _btcBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
        _balance = _btcBalance;
      } else {}

      // Save to local storage
      final formattedBalance = NumberFormatter.formatBTCAmount(_btcBalance);
      await StorageUtils.saveWalletBalance(formattedBalance);

      // Track wallet initialization
      AnalyticsService.trackCustomEvent(
        eventName: 'wallet_initialized',
        parameters: {
          'initial_balance': _btcBalance,
          'formatted_balance': formattedBalance,
        },
      );

      // Show welcome notification with sound
      SoundNotificationService.showWelcomeNotification();
    } catch (e) {
      _error = 'Failed to initialize wallet: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWallet() async {
    try {
      // FIX: Only load wallet balance from server, do not initialize
      final double serverBalance = await _walletService.getWalletBalance();
      _btcBalance = serverBalance;
      _balance = _btcBalance;

      // Save to local storage
      await StorageUtils.saveWalletBalance(
          NumberFormatter.formatBTCAmount(_btcBalance));

      notifyListeners();
    } catch (e) {
      // Check if it's a DNS error and provide better message
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('no address associated with hostname')) {
        _error =
            'Network connection issue. Please check your internet connection and try again.';
        notifyListeners();
        return;
      }

      // Try to load from local storage as fallback
      final String? localBalanceStr = await StorageUtils.getWalletBalance();
      if (localBalanceStr != null) {
        _btcBalance = double.parse(localBalanceStr);
        _balance = _btcBalance;
        _error =
            'Using cached balance due to network issues. Please check your connection.';
        notifyListeners();
      } else {
        _error = 'Failed to load wallet: ${e.toString()}';
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> updateBalance(double newBalance) async {
    try {
      // Validate balance
      if (newBalance < 0) {
        return;
      }

      // Update local balance immediately for better UX
      _btcBalance = newBalance;
      _balance = newBalance;
      notifyListeners();

      // Save to local storage first (fast operation)
      final formattedBalance = NumberFormatter.formatBTCAmount(newBalance);
      await StorageUtils.saveWalletBalance(formattedBalance);

      // Update balance on backend in background (non-blocking)
      _apiService.updateWalletBalance(newBalance).then((result) async {
        if (result['success']) {
          // Update with server response if different
          if (result['data'] != null && result['data']['balance'] != null) {
            final serverBalance =
                double.parse(result['data']['balance'] as String);
            if (serverBalance != newBalance) {
              _btcBalance = serverBalance;
              _balance = serverBalance;
              await StorageUtils.saveWalletBalance(
                  result['data']['balance'] as String);
              notifyListeners();
            }
          }
        } else {
          // If server update fails, keep local balance (already updated)
          print('Server balance update failed, keeping local balance');
        }
      }).catchError((e) {
        // If server update fails, keep local balance (already updated)
        print('Server balance update error: $e');
      });
    } catch (e) {
      // Try to recover from local storage
      final String? currentBalanceStr = await StorageUtils.getWalletBalance();
      if (currentBalanceStr != null) {
        final currentBalance = double.parse(currentBalanceStr);
        if (currentBalance != _btcBalance) {
          _btcBalance = currentBalance;
          _balance = currentBalance;
          notifyListeners();
        }
      }
    }
  }

  void updateTotalEarned(double amount) {
    _totalEarned += amount;
    notifyListeners();
  }

  void updateTotalWithdrawn(double amount) {
    _totalWithdrawn += amount;
    notifyListeners();
  }

  void setSelectedCurrency(String currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  Future<void> addEarning(double amount,
      {String type = 'earning',
      String? description,
      Map<String, dynamic>? details}) async {
    try {
      // Track earning event (non-blocking)
      AnalyticsService.trackTransaction(
        type: type,
        amount: amount,
        currency: 'BTC',
      );

      // Calculate new balance locally first for immediate UI update
      final currentBalance = _btcBalance;
      final newBalance = currentBalance + amount;

      // Update UI immediately for better user experience
      _btcBalance = newBalance;
      _balance = newBalance;
      updateTotalEarned(amount);
      notifyListeners();

      // Create transaction data
      final transactionData = {
        'type': type,
        'amount': NumberFormatter.formatBTCAmount(amount),
        'status': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
        'currency': 'BTC',
        'description': description ?? 'Earned from mining',
        if (details != null) 'details': details,
      };

      // Send to backend in background (non-blocking)
      _apiService.addTransaction(transactionData).then((result) async {
        if (result['success']) {
          // Update balance on server
          await updateBalance(newBalance);

          // Show reward notification with sound
          SoundNotificationService.showRewardNotification(
            amount: amount,
            type: type,
          );

          // Play earning sound for immediate feedback
          await SoundNotificationService.playEarningSound();
        } else {
          // If backend update fails, revert local balance
          _btcBalance = currentBalance;
          _balance = currentBalance;
          updateTotalEarned(-amount); // Revert the addition
          notifyListeners();

          throw Exception(result['message'] ?? 'Failed to add earning');
        }
      }).catchError((e) {
        // If backend update fails, revert local balance
        _btcBalance = currentBalance;
        _balance = currentBalance;
        updateTotalEarned(-amount); // Revert the addition
        notifyListeners();

        print('Background earning update failed: $e');
      });
    } catch (e) {
      rethrow;
    }
  }

  // Live price updates
  Timer? _priceUpdateTimer;
  final Duration _priceUpdateInterval = const Duration(seconds: 30);

  void startLivePriceUpdates() {
    _priceUpdateTimer?.cancel();
    _priceUpdateTimer = Timer.periodic(_priceUpdateInterval, (_) {
      _updateCurrencyRates();
    });
    // Initial update
    _updateCurrencyRates();
  }

  void stopLivePriceUpdates() {
    _priceUpdateTimer?.cancel();
    _priceUpdateTimer = null;
  }

  // Convert BTC to local currency value
  double getLocalCurrencyValue(String currency) {
    try {
      // Ensure we have a valid BTC balance
      if (_btcBalance < 0 || _btcBalance.isNaN) {
        return 0.0;
      }

      // Ensure we have a valid BTC price
      if (_btcPrice <= 0 || _btcPrice.isNaN) {
        _btcPrice = 30000.0; // Fallback price
      }

      // Get the currency rate with fallback values
      double rate;
      switch (currency.toUpperCase()) {
        case 'USD':
          rate = 1.0;
          break;
        case 'INR':
          rate = _currencyRates['INR'] ?? 83.0;
          break;
        case 'EUR':
          rate = _currencyRates['EUR'] ?? 0.91;
          break;
        case 'GBP':
          rate = _currencyRates['GBP'] ?? 0.79;
          break;
        default:
          rate = _currencyRates[currency] ?? 1.0;
      }

      // Calculate USD value first
      final usdValue = _btcBalance * _btcPrice;

      // Convert USD to target currency
      final localValue = usdValue * rate;

      return localValue.isFinite ? localValue : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _updateCurrencyRates() async {
    try {
      final result = await _apiService.getCurrencyRates();

      if (result['success']) {
        // Update BTC price first
        if (result['data']['btcPrice'] != null) {
          final newBtcPrice =
              double.tryParse(result['data']['btcPrice'].toString());
          if (newBtcPrice != null && newBtcPrice > 0) {
            _btcPrice = newBtcPrice;
          } else {}
        }

        // Update currency rates
        if (result['data']['rates'] != null) {
          final ratesRaw = result['data']['rates'] as Map<String, dynamic>;
          final newRates = <String, double>{};
          ratesRaw.forEach((key, value) {
            if (value is int) {
              newRates[key] = value.toDouble();
            } else if (value is double) {
              newRates[key] = value;
            } else if (value is String) {
              newRates[key] = double.tryParse(value) ?? 1.0;
            }
          });

          // Validate and update each rate
          _currencyRates.forEach((currency, oldRate) {
            final newRate = newRates[currency];
            if (newRate != null && newRate > 0) {
              _currencyRates[currency] = newRate;
            } else {}
          });

          _currencyRates.forEach((currency, rate) {});
        }

        notifyListeners();
      } else {
        // Ensure we have fallback rates
        _ensureFallbackRates();
      }
    } catch (e) {
      // Ensure we have fallback rates on error
      _ensureFallbackRates();
      // Use fallback rates if update fails
      _currencyRates.forEach((key, value) {
        if (value <= 0 || value.isNaN) {
          _currencyRates[key] = _defaultRates[key] ?? 1.0;
        }
      });

      // Use fallback BTC price if not set
      if (_btcPrice == 0.0) {
        _btcPrice = 30000.0; // Fallback BTC price in USD
      }

      notifyListeners();
    }
  }

  Future<void> refreshTransactions() async {
    try {
      final result = await _apiService.getTransactions();

      if (result['success'] && result['data'] != null) {
        // Handle both array and object responses
        final transactionData =
            result['data']['transactions'] ?? result['data'];
        if (transactionData is List) {
          _transactions = transactionData
              .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          _transactions = []; // Reset transactions if empty or invalid data
        }
        notifyListeners();
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  bool isTransactionClaimed(String transactionId) {
    return _claimedTransactions.contains(transactionId);
  }

  Future<bool> withdrawFunds({
    required String method,
    required String destination,
    required double amount,
    required String currency,
    required double btcAmount,
  }) async {
    try {
      // Track withdrawal event
      AnalyticsService.trackTransaction(
        type: 'withdrawal',
        amount: btcAmount,
        currency: 'BTC',
      );

      // Ensure wallet is initialized
      try {
        await initializeWallet();
      } catch (e) {
        throw Exception('Failed to initialize wallet: \\${e.toString()}');
      }

      // Validate withdrawal after initialization
      if (btcAmount > _btcBalance) {
        throw Exception('Insufficient balance');
      }

      // Convert scientific notation to decimal string
      final formattedAmount = NumberFormatter.fromScientific(btcAmount);

      // Prepare withdrawal data
      final Map<String, dynamic> withdrawalData = {
        'method': method,
        'destination': destination,
        'amount': formattedAmount,
        'currency': 'BTC', // Always use BTC for the backend
      };

      // Add localAmount and localCurrency for Paytm/Paypal
      if (method == 'Paytm' || method == 'Paypal') {
        final String localCurrency = method == 'Paytm' ? 'INR' : 'USD';
        double rate = 1.0;
        if (method == 'Paytm') {
          rate = _currencyRates['INR'] ?? 83.0;
        } else if (method == 'Paypal') {
          rate = _currencyRates['USD'] ?? 1.0;
        }
        final double localAmount = btcAmount * _btcPrice * rate;
        // Always show 10 decimals, even for very small values
        String formattedLocalAmount = localAmount.toStringAsFixed(10);
        if (!formattedLocalAmount.contains('.')) {
          formattedLocalAmount += '.0000000000';
        }
        withdrawalData['localAmount'] = formattedLocalAmount;
        withdrawalData['localCurrency'] = localCurrency;
        withdrawalData['exchangeRate'] = (_btcPrice * rate).toStringAsFixed(10);
      }

      final result = await _apiService.createWithdrawal(withdrawalData);

      if (result['success']) {
        // Update local balance immediately
        await updateBalance(_btcBalance - btcAmount);
        // Update total withdrawn
        updateTotalWithdrawn(btcAmount);
        // Refresh transactions to show the new withdrawal
        await refreshTransactions();

        // Show withdrawal notification with sound
        SoundNotificationService.showWithdrawalNotification(
          amount: btcAmount,
          method: method,
        );

        return true;
      } else {
        throw Exception(result['message'] ?? 'Withdrawal failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> claimRejectedTransaction(String transactionId) async {
    try {
      final result = await _apiService.claimTransaction(transactionId);

      if (result['success']) {
        // Mark transaction as claimed
        _claimedTransactions.add(transactionId);

        // Refresh transactions to get latest status
        await refreshTransactions();
      } else {
        throw Exception(result['message'] ?? 'Failed to claim transaction');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> onLogout() async {
    // Stop live price updates
    stopLivePriceUpdates();

    // Reset all wallet state
    _btcBalance = 0.0;
    _balance = 0.0;
    _transactions = [];
    _pendingTransactions.clear();
    _btcPrice = 0.0;
    _totalEarned = 0.0;
    _totalWithdrawn = 0.0;
    _filterType = 'All';
    _selectedCurrency = 'USD';
    _isSyncing = false;
    _error = null;
    _claimedTransactions.clear();

    // Reset currency rates to defaults
    _currencyRates.forEach((key, value) {
      _currencyRates[key] = _defaultRates[key] ?? 1.0;
    });

    // Clear any stored wallet data
    await StorageUtils.removeWalletBalance();

    // Notify listeners of the state reset
    notifyListeners();
  }

  Future<void> verifyBalance() async {
    try {
      // Get balance from server
      final double serverBalance = await _apiService.getWalletBalance();
      final String? localBalanceStr = await StorageUtils.getWalletBalance();
      final double localBalance =
          localBalanceStr != null ? double.parse(localBalanceStr) : 0.0;

      // If there's a mismatch, update to server balance
      if (localBalanceStr == null || localBalance != serverBalance) {
        _btcBalance = serverBalance;
        _balance = serverBalance;

        // Save correct balance to local storage
        await StorageUtils.saveWalletBalance(
            NumberFormatter.formatBTCAmount(serverBalance));

        notifyListeners();
      } else {}
    } catch (e) {
      // Do not update anything if verification fails
      rethrow;
    }
  }

  void _ensureFallbackRates() {
    // Ensure BTC price has a valid value
    if (_btcPrice <= 0 || _btcPrice.isNaN) {
      _btcPrice = 30000.0; // Default BTC price in USD
    }

    // Ensure all currency rates have valid values
    final updatedRates = Map<String, double>.from(_defaultRates);
    _defaultRates.forEach((currency, defaultRate) {
      final currentRate = _currencyRates[currency];
      if (currentRate != null && currentRate > 0 && !currentRate.isNaN) {
        updatedRates[currency] = currentRate;
      } else {}
    });

    _currencyRates = updatedRates;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLivePriceUpdates();
    _priceUpdateTimer?.cancel();
    super.dispose();
  }
}
