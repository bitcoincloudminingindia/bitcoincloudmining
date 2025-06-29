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

      debugPrint('🔄 Initializing wallet...');

      final data = await _walletService.initializeWallet();

      if (data['balance'] != null) {
        _btcBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
        _balance = _btcBalance;
      } else {
        debugPrint('⚠️ No balance in wallet data');
      }

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

      debugPrint('✅ Wallet initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing wallet: $e');
      _error = 'Failed to initialize wallet: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWallet() async {
    try {
      debugPrint('🔄 Loading wallet...');

      // FIX: Only load wallet balance from server, do not initialize
      final double serverBalance = await _walletService.getWalletBalance();
      _btcBalance = serverBalance;
      _balance = _btcBalance;

      // Save to local storage
      await StorageUtils.saveWalletBalance(
          NumberFormatter.formatBTCAmount(_btcBalance));

      debugPrint(
          '✅ Wallet loaded: ${NumberFormatter.formatBTCAmount(_btcBalance)} BTC');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading wallet: $e');

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
      debugPrint('🔄 Updating wallet balance...');
      debugPrint(
          '💰 New balance: ${NumberFormatter.formatBTCAmount(newBalance)}');
      debugPrint(
          '📊 Current balance: ${NumberFormatter.formatBTCAmount(_btcBalance)}');

      // Validate balance
      if (newBalance < 0) {
        debugPrint(
            '❌ Invalid balance update attempt: ${NumberFormatter.formatBTCAmount(newBalance)}');
        return;
      }

      // Update balance on backend
      final result = await _apiService.updateWalletBalance(newBalance);

      if (result['success']) {
        final formattedBalance = result['data']['balance'] as String;
        _btcBalance = double.parse(formattedBalance);
        _balance = _btcBalance;

        // Save to local storage
        await StorageUtils.saveWalletBalance(formattedBalance);

        if (result['skipped'] == true) {
          debugPrint('ℹ️ ${result['message']}');
        } else {
          debugPrint('✅ Balance updated from server');
        }

        // Save to local storage
        await StorageUtils.saveWalletBalance(formattedBalance);
        debugPrint('💾 Balance saved successfully');

        notifyListeners();
        debugPrint('✅ Balance updated successfully');
      } else {
        debugPrint('❌ Failed to update balance on server');
      }
    } catch (e) {
      debugPrint('❌ Error updating balance: $e');
      // Try to recover
      final String? currentBalanceStr = await StorageUtils.getWalletBalance();
      if (currentBalanceStr != null) {
        final currentBalance = double.parse(currentBalanceStr);
        if (currentBalance != _btcBalance) {
          _btcBalance = currentBalance;
          notifyListeners();
          debugPrint('🔄 Recovered balance from storage: $_btcBalance');
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
      debugPrint('🔄 Adding earning: $amount BTC');
      debugPrint('Type: $type');
      debugPrint('Description: $description');

      // Track earning event
      AnalyticsService.trackTransaction(
        type: type,
        amount: amount,
        currency: 'BTC',
      );

      // Always fetch the latest balance from backend before adding
      await loadWallet();
      final latestBalance = _btcBalance;
      final newBalance = latestBalance + amount;

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

      // Send to backend
      final result = await _apiService.addTransaction(transactionData);

      if (result['success']) {
        await updateBalance(newBalance);
        // Add to total earned
        updateTotalEarned(amount);

        // Show reward notification with sound
        SoundNotificationService.showRewardNotification(
          amount: amount,
          type: type,
        );

        debugPrint('✅ Earning added successfully');
      } else {
        debugPrint('❌ Failed to add earning: ${result['message']}');
        throw Exception(result['message'] ?? 'Failed to add earning');
      }
    } catch (e) {
      debugPrint('❌ Error adding earning: $e');
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
        debugPrint('⚠️ Invalid BTC balance: $_btcBalance');
        return 0.0;
      }

      // Ensure we have a valid BTC price
      if (_btcPrice <= 0 || _btcPrice.isNaN) {
        debugPrint('⚠️ Invalid BTC price, using fallback: $_btcPrice');
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

      debugPrint('💱 Currency conversion details:');
      debugPrint(
          'BTC Balance: ${NumberFormatter.formatBTCAmount(_btcBalance)}');
      debugPrint('BTC Price (USD): \$${_btcPrice.toStringAsFixed(2)}');
      debugPrint('USD Value: \$${usdValue.toStringAsFixed(2)}');
      debugPrint('$currency Rate: $rate');
      debugPrint('$currency Value: ${localValue.toStringAsFixed(2)}');

      return localValue.isFinite ? localValue : 0.0;
    } catch (e) {
      debugPrint('❌ Error converting currency: $e');
      return 0.0;
    }
  }

  Future<void> _updateCurrencyRates() async {
    try {
      debugPrint('🔄 Updating currency rates...');
      final result = await _apiService.getCurrencyRates();

      if (result['success']) {
        // Update BTC price first
        if (result['data']['btcPrice'] != null) {
          final newBtcPrice =
              double.tryParse(result['data']['btcPrice'].toString());
          if (newBtcPrice != null && newBtcPrice > 0) {
            _btcPrice = newBtcPrice;
            debugPrint('📊 Updated BTC Price: \$$_btcPrice');
          } else {
            debugPrint(
                '⚠️ Invalid BTC price from API, keeping current price: \$$_btcPrice');
          }
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
            } else {
              debugPrint(
                  '⚠️ Invalid rate for $currency, keeping current rate: $oldRate');
            }
          });

          debugPrint('📊 Current Currency Rates:');
          _currencyRates.forEach((currency, rate) {
            debugPrint('$currency: $rate');
          });
        }

        notifyListeners();
        debugPrint('✅ Currency rates updated successfully');
      } else {
        debugPrint('⚠️ Failed to update rates: ${result['message']}');
        // Ensure we have fallback rates
        _ensureFallbackRates();
      }
    } catch (e) {
      debugPrint('❌ Error updating currency rates: $e');
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
      debugPrint('🔄 Refreshing transactions...');
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
        debugPrint('✅ Transactions refreshed successfully');
      } else {
        debugPrint('❌ Failed to refresh transactions: ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing transactions: $e');
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
      debugPrint('🔄 Processing withdrawal...');
      debugPrint('Method: $method');
      debugPrint('Amount: $amount $currency');
      debugPrint('BTC Amount: $btcAmount');

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
        debugPrint('❌ Failed to initialize wallet before withdrawal: $e');
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

        debugPrint('✅ Withdrawal processed successfully');
        return true;
      } else {
        debugPrint('❌ Withdrawal failed: \\${result['message']}');
        throw Exception(result['message'] ?? 'Withdrawal failed');
      }
    } catch (e) {
      debugPrint('❌ Error processing withdrawal: $e');
      rethrow;
    }
  }

  Future<void> claimRejectedTransaction(String transactionId) async {
    try {
      debugPrint('🔄 Claiming rejected transaction...');

      final result = await _apiService.claimTransaction(transactionId);

      if (result['success']) {
        // Mark transaction as claimed
        _claimedTransactions.add(transactionId);

        // Refresh transactions to get latest status
        await refreshTransactions();

        debugPrint('✅ Transaction claimed successfully');
      } else {
        debugPrint('❌ Failed to claim transaction: ${result['message']}');
        throw Exception(result['message'] ?? 'Failed to claim transaction');
      }
    } catch (e) {
      debugPrint('❌ Error claiming transaction: $e');
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
      debugPrint('🔄 Verifying wallet balance...');

      // Get balance from server
      final double serverBalance = await _apiService.getWalletBalance();
      final String? localBalanceStr = await StorageUtils.getWalletBalance();
      final double localBalance =
          localBalanceStr != null ? double.parse(localBalanceStr) : 0.0;

      debugPrint(
          '📊 Server balance: ${NumberFormatter.formatBTCAmount(serverBalance)}');
      debugPrint(
          '📊 Local balance: ${NumberFormatter.formatBTCAmount(localBalance)}');

      // If there's a mismatch, update to server balance
      if (localBalanceStr == null || localBalance != serverBalance) {
        debugPrint('⚠️ Balance mismatch detected, updating to server balance');
        _btcBalance = serverBalance;
        _balance = serverBalance;

        // Save correct balance to local storage
        await StorageUtils.saveWalletBalance(
            NumberFormatter.formatBTCAmount(serverBalance));

        notifyListeners();
        debugPrint('✅ Balance verified and updated');
      } else {
        debugPrint('✅ Balance verified - local and server in sync');
      }
    } catch (e) {
      debugPrint('❌ Error verifying balance: $e');
      // Do not update anything if verification fails
      rethrow;
    }
  }

  void _ensureFallbackRates() {
    // Ensure BTC price has a valid value
    if (_btcPrice <= 0 || _btcPrice.isNaN) {
      _btcPrice = 30000.0; // Default BTC price in USD
      debugPrint('📊 Using fallback BTC Price: \$$_btcPrice');
    }

    // Ensure all currency rates have valid values
    final updatedRates = Map<String, double>.from(_defaultRates);
    _defaultRates.forEach((currency, defaultRate) {
      final currentRate = _currencyRates[currency];
      if (currentRate != null && currentRate > 0 && !currentRate.isNaN) {
        updatedRates[currency] = currentRate;
      } else {
        debugPrint('📊 Using fallback rate for $currency: $defaultRate');
      }
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
