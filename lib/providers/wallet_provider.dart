import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/api_config.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../utils/number_formatter.dart';
import '../utils/storage_utils.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  double _btcBalance = 0.0;
  double _balance = 0.0;
  final bool _isLoading = false;
  String? _error;
  List<Transaction> _transactions = [];
  final List<Transaction> _pendingTransactions = [];
  Timer? _syncTimer;
  List<Map<String, dynamic>> _withdrawals = [];
  double _btcPrice = 0.0;
  double _totalEarned = 0.0;
  double _totalWithdrawn = 0.0;
  String _filterType = 'All';
  final Map<String, double> _currencyRates = {
    'USD': 1.0,
    'EUR': 0.85,
    'GBP': 0.73,
    'INR': 75.0,
  };
  String _selectedCurrency = 'USD';
  final bool _isTransactionInProgress = false;
  bool _is2FAEnabled = false;
  int _autoLockDuration = 5;
  Timer? _refreshTimer;
  Timer? _currencyUpdateTimer;
  double _referralEarnings = 0.0;
  DateTime? _lastPriceUpdate;
  final bool _isSyncing = false;

  // Add these endpoint constants
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _apiUrl = 'https://api.coingecko.com/api/v3/simple/price';
  static const Duration _currencyUpdateInterval = Duration(minutes: 1);

  // Add getter for price availability
  bool get isPriceAvailable => _btcPrice > 0;

  final Map<String, String> currencySymbols = const {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  // Cache management
  final Map<String, dynamic> _cache = {};

  // Track claimed transactions
  final Set<String> _claimedTransactions = {};

  // Getter for claimed transactions
  Set<String> get claimedTransactions => _claimedTransactions;

  // Check if a transaction is claimed
  bool isTransactionClaimed(String transactionId) {
    return _claimedTransactions.contains(transactionId);
  }

  // Add getters for pending transactions and selected currency
  List<Transaction> get pendingTransactions =>
      List.unmodifiable(_pendingTransactions);
  String get selectedCurrency => _selectedCurrency;
  bool get isSyncing => _isSyncing;

  WalletProvider() {
    _startCurrencyUpdateTimer();
    _loadFromLocalStorage(); // Add call to load data from local storage
    _startSyncTimer();
  }

  void _startCurrencyUpdateTimer() {
    _currencyUpdateTimer?.cancel();
    _currencyUpdateTimer = Timer.periodic(_currencyUpdateInterval, (_) {
      _updateCurrencyRatesFromServer();
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    const syncInterval = Duration(minutes: 1);
    _syncTimer = Timer.periodic(syncInterval, (_) async {
      if (!_isTransactionInProgress) {
        await syncWalletBalance().catchError((e) {
          print('Error in sync timer: $e');
        });
      }
    });
  }

  Future<void> _updateCurrencyRatesFromServer() async {
    try {
      if (_lastPriceUpdate != null &&
          DateTime.now().difference(_lastPriceUpdate!) <
              const Duration(seconds: 30)) {
        return; // Prevent too frequent updates
      }

      print('WalletProvider - Updating currency rates');
      print('WalletProvider - Current currency rates: $_currencyRates');

      final response = await http.get(
        Uri.parse(
            '$_apiUrl?ids=bitcoin&vs_currencies=usd,inr,eur,gbp,jpy,aud,cad'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['bitcoin'];
        print('WalletProvider - Rates received from API: $rates');

        if (rates != null) {
          final usdRate = rates['usd']?.toDouble() ?? _btcPrice;
          _btcPrice = usdRate;
          print('WalletProvider - Updated BTC Price: $_btcPrice');

          // Save current rates before updating with new ones
          final Map<String, double> oldRates = Map.from(_currencyRates);

          _currencyRates.clear();
          _currencyRates.addAll({
            'USD': 1.0,
            'INR':
                (rates['inr']?.toDouble() ?? oldRates['INR'] ?? 83.0) / usdRate,
            'EUR':
                (rates['eur']?.toDouble() ?? oldRates['EUR'] ?? 0.91) / usdRate,
            'GBP':
                (rates['gbp']?.toDouble() ?? oldRates['GBP'] ?? 0.79) / usdRate,
            'JPY': (rates['jpy']?.toDouble() ?? oldRates['JPY'] ?? 150.0) /
                usdRate,
            'AUD':
                (rates['aud']?.toDouble() ?? oldRates['AUD'] ?? 1.52) / usdRate,
            'CAD':
                (rates['cad']?.toDouble() ?? oldRates['CAD'] ?? 1.35) / usdRate,
          });

          // Ensure INR rate is set
          if (_currencyRates['INR'] == null || _currencyRates['INR']! <= 0) {
            _currencyRates['INR'] = 83.0 / usdRate; // Backup INR rate
            print(
                'WalletProvider - INR rate set to default: ${_currencyRates['INR']}');
          }

          print('WalletProvider - Updated currency rates: $_currencyRates');

          _lastPriceUpdate = DateTime.now();
          notifyListeners();
        } else {
          print('WalletProvider - No rates received from API');
        }
      } else {
        print(
            'WalletProvider - Failed to get rates from API, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('WalletProvider - Error updating currency rates: $e');
    }
  }

  // Start auto-update of BTC price
  void startLivePriceUpdates() {
    _currencyUpdateTimer?.cancel();
    _updateCurrencyRatesFromServer(); // Update immediately
    _currencyUpdateTimer = Timer.periodic(_currencyUpdateInterval, (_) {
      _updateCurrencyRatesFromServer();
    });
  }

  // Stop auto-update of BTC price
  void stopLivePriceUpdates() {
    _currencyUpdateTimer?.cancel();
  }

  // Getters
  double get btcBalance => _btcBalance;
  String get formattedBtcBalance => _btcBalance.toStringAsFixed(18);
  double get btcPrice => _btcPrice;
  String get filterType => _filterType;
  Map<String, double> get currencyRates => Map.unmodifiable(_currencyRates);
  bool get is2FAEnabled => _is2FAEnabled;
  int get autoLockDuration => _autoLockDuration;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  double get referralEarnings => _referralEarnings;
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

  Future<void> loadWallet() async {
    try {
      print('🔄 Loading wallet...');
      final localBalance = await StorageUtils.getWalletBalance();
      if (localBalance != null) {
        _balance = localBalance;
        print('✅ Loaded local balance: ${_balance.toStringAsFixed(18)}');
      }

      // Start background sync
      await syncWalletBalance();
    } catch (e) {
      print('❌ Error loading wallet: $e');
    }
  }

  Future<void> syncWalletBalance() async {
    try {
      print('🔄 Syncing wallet balance...');
      print('💰 Current balance: ${_btcBalance.toStringAsFixed(18)}');

      // Get token synchronously
      final token = await StorageUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Format balance to 18 decimal places
      final formattedBalance = NumberFormatter.formatBTCAmount(_btcBalance);
      print('💫 Formatted balance for sync: $formattedBalance');

      // Send balance and timestamp in the request body
      final response = await ApiService.post(
        '/api/wallet/sync-balance',
        {
          'balance': formattedBalance,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('📥 Sync response: $response');

      if (response['success'] == true) {
        // Update local balance
        if (response['data'] != null && response['data']['balance'] != null) {
          final newBalance =
              double.tryParse(response['data']['balance'].toString()) ?? 0.0;
          print(
              '💰 New balance from server: ${newBalance.toStringAsFixed(18)}');

          // Only update if balance has actually changed
          if (newBalance != _btcBalance) {
            _btcBalance = newBalance;
            _balance = newBalance;

            // Save to local storage
            await StorageUtils.saveWalletBalance(newBalance);
            print('💾 Balance saved to storage');

            notifyListeners();
            print('✅ Balance synced successfully');
          } else {
            print('ℹ️ Balance unchanged');
          }
        } else {
          print('⚠️ No balance data in response');
        }
      } else {
        print('❌ Failed to sync balance: ${response['message']}');
        throw Exception(response['message'] ?? 'Failed to sync balance');
      }
    } catch (e) {
      print('❌ Error syncing wallet balance: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(double newBalance) async {
    try {
      print('🔄 Updating wallet balance...');
      print('💰 New balance: ${NumberFormatter.formatBTCAmount(newBalance)}');
      print(
          '📊 Current balance: ${NumberFormatter.formatBTCAmount(_btcBalance)}');

      // Validate balance
      if (newBalance < 0) {
        print(
            '❌ Invalid balance update attempt: ${NumberFormatter.formatBTCAmount(newBalance)}');
        return;
      }

      // Format balance to 18 decimal places
      final formattedBalance = _formatBalance(newBalance);
      print('💫 Formatted balance: $formattedBalance');

      // Only update if balance has actually changed
      if (_btcBalance != newBalance) {
        _btcBalance = double.parse(formattedBalance);

        // Save to storage immediately
        await StorageUtils.saveWalletBalance(_btcBalance);
        print('💾 Balance saved to storage');

        // Only sync with server if this is not part of a transaction
        // if (!_isTransactionInProgress) {
        //   // Start server sync in background
        //   _syncWithServerInBackground(formattedBalance);
        //   print('🔄 Started background sync');
        // }

        print('✅ Wallet balance updated successfully');
        notifyListeners();
      } else {
        print('ℹ️ Balance unchanged');
      }
    } catch (e) {
      print('❌ Balance update error: $e');
      // Try to recover from error
      try {
        final currentBalance = await StorageUtils.getWalletBalance();
        if (currentBalance != _btcBalance) {
          _btcBalance = currentBalance ?? 0.0;
          notifyListeners();
          print('🔄 Recovered balance from storage: $_btcBalance');
        }
      } catch (recoveryError) {
        print('❌ Failed to recover balance: $recoveryError');
      }
      rethrow;
    }
  }

  Future<void> _saveData() async {
    try {
      final userData = {
        'balance': _balance.toString(),
        'btcBalance': _btcBalance.toString(),
        'transactions': _transactions.map((tx) => tx.toJson()).toList(),
      };
      await StorageUtils.saveUserData(userData);
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // Helper method to format balance to 18 decimal places
  String _formatBalance(double balance) {
    return NumberFormatter.formatBTCAmount(balance);
  }

  @override
  void dispose() {
    try {
      // Cancel all timers
      _refreshTimer?.cancel();
      _currencyUpdateTimer?.cancel();
      _syncTimer?.cancel();

      // Clear all data
      _transactions.clear();
      _withdrawals.clear();
      _cache.clear();

      // Disconnect and dispose socket
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;

      // Call super.dispose() last
      super.dispose();
    } catch (e) {
      print('Error in dispose: $e');
    }
  }

  Future<void> fetchBTCPrice() async {
    try {
      final response =
          await http.get(Uri.parse('$_apiUrl?ids=bitcoin&vs_currencies=usd'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _btcPrice = data['bitcoin']['usd'] ?? 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching BTC price: $e');
    }
  }

  // Improve withdrawal security
  Future<bool> withdrawFunds({
    required String method,
    required double amount,
    required String destination,
    required double btcAmount,
    required String currency,
  }) async {
    try {
      print('🔄 Processing withdrawal...');
      print('💰 Amount: ${NumberFormatter.formatBTCAmount(amount)} $currency');
      print('💎 BTC Amount: ${NumberFormatter.formatBTCAmount(btcAmount)} BTC');

      // Validate withdrawal amount
      if (amount <= 0) {
        throw Exception('Invalid withdrawal amount');
      }

      // Check if user has sufficient balance
      if (btcAmount > _btcBalance) {
        throw Exception('Insufficient balance');
      }

      // Format BTC amount to 18 decimal places
      final formattedBTCAmount =
          double.parse(NumberFormatter.formatBTCAmount(btcAmount));

      // Process withdrawal request
      final result = await _apiService.withdrawFunds(
        method: method,
        amount: amount,
        destination: destination,
        btcAmount: formattedBTCAmount,
        currency: currency,
      );

      if (result['success']) {
        // Update local balance
        final newBalance = _btcBalance - formattedBTCAmount;
        _btcBalance = newBalance;
        await StorageUtils.saveWalletBalance(_btcBalance);

        // Update total withdrawn amount
        updateTotalWithdrawn(formattedBTCAmount);

        // Refresh transactions to get the new transaction from backend
        await refreshTransactions();

        notifyListeners();
        return true;
      }

      throw Exception(result['message'] ?? 'Withdrawal failed');
    } catch (e) {
      print('Error processing withdrawal: $e');
      rethrow;
    }
  }

  void setFilterType(String type) {
    if (_filterType != type) {
      _filterType = type;
      notifyListeners();
    }
  }

  Future<bool> toggle2FA(bool value) async {
    try {
      _is2FAEnabled = value;
      await _saveData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling 2FA: $e');
      return false;
    }
  }

  Future<bool> setAutoLockDuration(int minutes) async {
    try {
      if (minutes < 1) return false;
      _autoLockDuration = minutes;
      await _saveData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting auto-lock duration: $e');
      return false;
    }
  }

  // Add addEarning method
  Future<void> addEarning(
    double amount, {
    String type = 'mining',
    String? description,
  }) async {
    try {
      print('🔄 Adding earning: $amount BTC');
      print('📝 Type: $type');
      print('📝 Description: $description');

      // Format amount to 18 decimal places
      final formattedAmount = double.parse(amount.toStringAsFixed(18));
      print('💰 Formatted amount: $formattedAmount');

      // Check for duplicate transaction
      final duplicateTransaction = _transactions.firstWhere(
        (tx) =>
            tx.type == type &&
            tx.amount == formattedAmount &&
            tx.timestamp
                .isAfter(DateTime.now().subtract(const Duration(seconds: 5))),
        orElse: () => Transaction(
          id: '',
          transactionId: '',
          type: '',
          amount: 0,
          status: '',
          timestamp: DateTime.now(),
          date: DateTime.now(),
        ),
      );

      if (duplicateTransaction.id.isNotEmpty) {
        print(
            '⚠️ Exact duplicate transaction detected within last 5 seconds, skipping...');
        return;
      }

      // Add transaction record
      await addTransaction(
        type: type,
        amount: formattedAmount,
        status: 'completed',
        description: description,
        details: {
          'balanceBefore': _btcBalance.toString(),
          'balanceAfter': (_btcBalance + formattedAmount).toString()
        },
      );

      // Update balance
      await updateBalance(_btcBalance + formattedAmount);

      print(
          '✅ Added earning: $formattedAmount BTC${description != null ? ' - $description' : ''}');
    } catch (e) {
      print('❌ Error adding earning: $e');
      rethrow;
    }
  }

  // Add formatting helpers
  String formatBTCAmount(double amount) {
    return NumberFormatter.formatBTCAmount(amount);
  }

  String formatLocalAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  double getValueInCurrency(String currency) {
    try {
      return _btcBalance * (_currencyRates[currency] ?? _btcPrice);
    } catch (e) {
      debugPrint('Error calculating currency value: $e');
      return 0.0;
    }
  }

  // Add getLocalCurrencyValue method
  double getLocalCurrencyValue(String currency) {
    try {
      return _btcBalance * _btcPrice * (_currencyRates[currency] ?? 1.0);
    } catch (e) {
      debugPrint('Error calculating local currency value: $e');
      return 0.0;
    }
  }

  void updateReferralEarnings(double amount) {
    _referralEarnings = amount;
    notifyListeners();
  }

  Future<bool> sendWalletBalanceToServer() async {
    try {
      print('🔄 Sending wallet balance to server...');
      final formattedBalance = _formatBalance(_btcBalance);
      final result =
          await _apiService.updateWalletBalance(double.parse(formattedBalance));
      return result['success'] == true;
    } catch (e) {
      print('❌ Error sending wallet balance: $e');
      return false;
    }
  }

  Future<void> checkPendingTransactions() async {
    try {
      final result = await _apiService.getPendingTransactions();

      if (result['success']) {
        final List<dynamic> pendingTxData = result['data']['transactions'];

        // Update local transactions with new status
        for (var txData in pendingTxData) {
          final int index = _transactions
              .indexWhere((t) => t.transactionId == txData['transactionId']);

          if (index != -1) {
            final oldStatus = _transactions[index].status;
            final newStatus = txData['status'];
            final adminNote = txData['adminNote'];

            if (oldStatus != newStatus) {
              _transactions[index] = Transaction(
                id: _transactions[index].transactionId,
                transactionId: _transactions[index].transactionId,
                type: _transactions[index].type,
                amount: _transactions[index].amount,
                status: newStatus,
                timestamp: _transactions[index].timestamp,
                date: _transactions[index].date,
                destination: _transactions[index].destination,
                adminNote: adminNote,
              );

              // If transaction is completed, update balance
              if (newStatus.toLowerCase() == 'completed') {
                if (txData['type']
                    .toString()
                    .toLowerCase()
                    .contains('withdrawal')) {
                  _btcBalance -= txData['amount'];
                } else {
                  _btcBalance += txData['amount'];
                }
                await _saveData();
              }
            }
          }
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error checking pending transactions: $e');
    }
  }

  // Add socket related fields
  static IO.Socket? _socket;
  Function(double)? onBalanceUpdate;

  // Add onLogout method
  Future<void> onLogout() async {
    try {
      print('🔄 Starting wallet cleanup...');

      // Save final balance before cleanup
      final finalBalance = _btcBalance;
      print('💰 Final balance before cleanup: $finalBalance');

      // Clear all transactions and withdrawals
      _transactions.clear();
      _withdrawals.clear();
      _cache.clear();

      // Reset all balances
      _btcBalance = 0.0;
      _btcPrice = 0.0;
      _referralEarnings = 0.0;

      // Disconnect and cleanup socket
      if (_socket != null) {
        try {
          _socket?.disconnect();
          _socket?.dispose();
        } catch (e) {
          print('⚠️ Socket cleanup error: $e');
        }
        _socket = null;
      }

      // Clear all storage data
      await StorageUtils.clearAll();

      // Reset balance update listener
      onBalanceUpdate = null;

      print('✅ Wallet cleanup completed');
      notifyListeners();
    } catch (e) {
      print('❌ Error during wallet cleanup: $e');
      // Even if there's an error, try to clear as much as possible
      _transactions.clear();
      _withdrawals.clear();
      _cache.clear();
      _btcBalance = 0.0;
      _btcPrice = 0.0;
      _referralEarnings = 0.0;
      notifyListeners();
      rethrow;
    }
  }

  // Add socket initialization method
  void initializeSocket(String userId) {
    try {
      print('🔄 Initializing socket connection...');

      // Use the correct socket.io URL
      final socketUrl = _baseUrl.replaceFirst('/api', '');
      print('📡 Socket URL: $socketUrl');

      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'timeout': 10000,
        'auth': {'userId': userId},
        'query': {
          'platform': kIsWeb
              ? 'web'
              : Platform.isAndroid
                  ? 'android'
                  : 'ios',
          'appVersion': '1.0.0'
        }
      });

      _setupSocketListeners();
      print('✅ Socket initialized successfully');
    } catch (e) {
      print('❌ Error initializing socket: $e');
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket?.onConnect((_) {
      print('✅ Socket Connected');
      loadWallet(); // Reload wallet data on connection
    });

    _socket?.onDisconnect((_) {
      print('❌ Socket Disconnected');
      // Try to reconnect after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_socket != null && !_socket!.connected) {
          print('🔄 Attempting to reconnect...');
          _socket?.connect();
        }
      });
    });

    _socket?.onConnectError((error) {
      print('❌ Socket Connection Error: $error');
      // Try to reconnect with exponential backoff
      Future.delayed(const Duration(seconds: 5), () {
        if (_socket != null && !_socket!.connected) {
          print('🔄 Attempting to reconnect after error...');
          _socket?.connect();
        }
      });
    });

    // Balance updates
    _socket?.on('balanceUpdate', (data) {
      try {
        print('💰 Received balance update: $data');
        final newBalance = (data['newBalance'] as num).toDouble();

        // Only update if balance has actually changed
        if (newBalance != _btcBalance) {
          _btcBalance = newBalance;
          notifyListeners();

          // Call optional callback if provided
          onBalanceUpdate?.call(newBalance);

          // Save to local storage
          StorageUtils.saveWalletBalance(_btcBalance);
        }
      } catch (e) {
        print('❌ Error processing balance update: $e');
      }
    });

    // Transaction updates
    _socket?.on('transactionStatus', (data) {
      try {
        print('📝 Received transaction update: $data');
        final transactionId = data['transactionId'];
        final status = data['status'];
        final adminNote = data['adminNote'];

        // Update transaction status
        final index =
            _transactions.indexWhere((tx) => tx.transactionId == transactionId);
        if (index != -1) {
          _transactions[index] = Transaction(
            id: _transactions[index].id,
            transactionId: _transactions[index].transactionId,
            type: _transactions[index].type,
            amount: _transactions[index].amount,
            status: status,
            timestamp: _transactions[index].timestamp,
            date: _transactions[index].date,
            destination: _transactions[index].destination,
            adminNote: adminNote,
            description: _transactions[index].description,
            withdrawalId: _transactions[index].withdrawalId,
            balanceBefore: _transactions[index].balanceBefore,
            balanceAfter: _transactions[index].balanceAfter,
            details: _transactions[index].details,
          );

          // Save updated transactions
          _saveData();
          notifyListeners();
        }
      } catch (e) {
        print('❌ Error processing transaction update: $e');
      }
    });

    // Withdrawal updates
    _socket?.on('withdrawalStatus', (data) {
      try {
        print('💸 Received withdrawal update: $data');
        final withdrawalId = data['withdrawalId'];
        final status = data['status'];
        final adminNote = data['adminNote'];

        // Update local withdrawal status
        final index = _withdrawals.indexWhere((w) => w['_id'] == withdrawalId);
        if (index != -1) {
          _withdrawals[index]['status'] = status;
          if (adminNote != null) {
            _withdrawals[index]['adminNote'] = adminNote;
          }

          // Also update transaction status
          final txIndex =
              _transactions.indexWhere((tx) => tx.withdrawalId == withdrawalId);
          if (txIndex != -1) {
            _transactions[txIndex] = Transaction(
              id: _transactions[txIndex].id,
              transactionId: _transactions[txIndex].transactionId,
              type: _transactions[txIndex].type,
              amount: _transactions[txIndex].amount,
              status: status,
              timestamp: _transactions[txIndex].timestamp,
              date: _transactions[txIndex].date,
              destination: _transactions[txIndex].destination,
              adminNote: adminNote,
              description: _transactions[txIndex].description,
              withdrawalId: withdrawalId,
              balanceBefore: _transactions[txIndex].balanceBefore,
              balanceAfter: _transactions[txIndex].balanceAfter,
              details: _transactions[txIndex].details,
            );
          }

          // Save updated data
          _saveData();
          notifyListeners();
        }
      } catch (e) {
        print('❌ Error processing withdrawal update: $e');
      }
    });

    // Error handling
    _socket?.onError((error) {
      print('❌ Socket Error: $error');
      // Try to reconnect on error
      Future.delayed(const Duration(seconds: 5), () {
        if (_socket != null && !_socket!.connected) {
          print('🔄 Attempting to reconnect after error...');
          _socket?.connect();
        }
      });
    });
  }

  // Add method to manually reconnect socket
  void reconnectSocket() {
    _socket?.connect();
  }

  List<Map<String, dynamic>> get withdrawals => List.unmodifiable(_withdrawals);

  Future<void> loadWithdrawals() async {
    try {
      final result = await _apiService.getWithdrawals();
      if (result['success']) {
        _withdrawals = List<Map<String, dynamic>>.from(result['data']);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading withdrawals: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      // Load balance
      final savedBalance = await StorageUtils.getWalletBalance();
      _btcBalance = (savedBalance ?? 0.0).toDouble();
      _balance = (savedBalance ?? 0.0).toDouble();
      print('✅ Loaded balance from storage: $_btcBalance BTC');

      // Load transactions
      final savedTransactions = await StorageUtils.getTransactions();
      _transactions = savedTransactions;
      print('✅ Loaded ${savedTransactions.length} transactions from storage');

      notifyListeners();
    } catch (e) {
      print('❌ Error loading from local storage: $e');
    }
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String status,
    String? description,
    Map<String, dynamic>? details,
  }) async {
    try {
      print('🔄 Adding new transaction...');
      print(
          '📝 Transaction details: type=$type, amount=$amount, status=$status');

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        amount: amount,
        status: status,
        timestamp: DateTime.now(),
        description: description ?? '',
        details: details,
        currency: 'BTC',
        destination: 'Wallet',
      );

      // Add to local transactions list
      _transactions.insert(0, transaction);
      print('✅ Added to local transactions list');

      // Save to local storage
      await StorageUtils.saveTransactions(_transactions);
      print('✅ Saved to local storage');

      // Save to backend
      try {
        final result = await _apiService.addTransaction(transaction.toJson());
        if (!result['success']) {
          print('❌ Failed to add transaction to backend: ${result['message']}');
          throw Exception(
              result['message'] ?? 'Failed to add transaction to backend');
        }
        print('✅ Transaction added to backend successfully');
      } catch (e) {
        print('❌ Error adding transaction to backend: $e');
        // Remove from local storage if backend save fails
        _transactions.removeAt(0);
        await StorageUtils.saveTransactions(_transactions);
        rethrow;
      }

      // Notify listeners
      notifyListeners();
      print('✅ Notified listeners');

      // If this is a claim transaction, force refresh the transactions
      if (type.toLowerCase() == 'claim') {
        print('🔄 Refreshing transactions after claim...');
        await refreshTransactions();
        // Force another UI update after refresh
        notifyListeners();
        print('✅ UI updated after refresh');
      }
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> claimRejectedTransaction(String transactionId) async {
    try {
      print('Processing claim for transaction: $transactionId');

      // Check if already claimed
      if (_claimedTransactions.contains(transactionId)) {
        throw Exception('Transaction already claimed');
      }

      // Process claim
      final response =
          await _apiService.claimRejectedTransaction(transactionId);

      if (response['success']) {
        print('Claim successful, updating wallet balance');

        // Update wallet balance
        print('🔄 Updating wallet balance...');
        final newBalance =
            double.parse(response['data']['newBalance'].toString());
        print('💰 New balance: $newBalance');
        print('📊 Current balance: $_btcBalance');

        // Update both balances
        _btcBalance = newBalance;
        _balance = newBalance;
        print('💫 Formatted balance: ${_btcBalance.toStringAsFixed(18)}');

        // Save to storage
        await StorageUtils.saveWalletBalance(_btcBalance);
        print('💾 Balance saved to storage');

        // Mark transaction as claimed
        print('Marking transaction as claimed');
        _claimedTransactions.add(transactionId);
        await StorageUtils.saveClaimedTransactions(_claimedTransactions);

        // Update backend balance using sync-balance endpoint
        print('Updating backend balance');
        await syncWalletBalance();

        notifyListeners();
        print('Claim process completed successfully');
      } else {
        throw Exception(response['message'] ?? 'Failed to claim transaction');
      }
    } catch (e) {
      print('Error in claimRejectedTransaction: $e');
      rethrow;
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

  Future<void> loadWalletBalance() async {
    try {
      final balance = await _apiService.getWalletBalance();
      // Format balance to 18 decimal places for consistency
      _btcBalance = double.parse(NumberFormatter.formatBTCAmount(balance));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wallet balance: $e');
      rethrow;
    }
  }

  // Add method to manually refresh transactions
  Future<void> refreshTransactions() async {
    try {
      print('🔄 Refreshing transactions...');
      final result = await _apiService.getTransactions();

      if (result['success'] == true) {
        print('✅ Transactions fetched successfully');
        print('📊 Response data: ${result['data']}');

        // Handle both direct transactions array and nested transactions
        List<dynamic> transactions;
        if (result['data'] is List) {
          // Handle direct array response
          transactions = result['data'] as List<dynamic>;
        } else if (result['data'] is Map<String, dynamic>) {
          // Handle nested transactions in data object
          final data = result['data'] as Map<String, dynamic>;
          transactions = data['transactions'] as List<dynamic>? ?? [];
        } else {
          // Default to empty list if neither format matches
          transactions = [];
        }

        print('📝 Processing ${transactions.length} transactions');
        final List<Transaction> parsedTransactions = [];

        for (final tx in transactions) {
          try {
            // Convert any type to Map<String, dynamic>
            final Map<String, dynamic> txMap =
                tx is Map ? Map<String, dynamic>.from(tx) : {};

            // Parse amount safely
            double amount = 0;
            if (txMap['amount'] != null) {
              if (txMap['amount'] is String) {
                amount = double.tryParse(txMap['amount']) ?? 0;
              } else if (txMap['amount'] is num) {
                amount = txMap['amount'].toDouble();
              }
            }

            // Parse netAmount safely
            double netAmount = amount;
            if (txMap['netAmount'] != null) {
              if (txMap['netAmount'] is String) {
                netAmount = double.tryParse(txMap['netAmount']) ?? amount;
              } else if (txMap['netAmount'] is num) {
                netAmount = txMap['netAmount'].toDouble();
              }
            }

            // Other parsing logic...
            final transaction = Transaction(
              id: txMap['_id']?.toString() ?? txMap['id']?.toString() ?? '',
              transactionId: txMap['transactionId']?.toString() ?? '',
              type: txMap['type']?.toString() ?? 'unknown',
              amount: amount,
              netAmount: netAmount,
              status: txMap['status']?.toString() ?? 'completed',
              description: txMap['description']?.toString() ?? '',
              currency: txMap['currency']?.toString() ?? 'BTC',
              timestamp: txMap['timestamp'] != null
                  ? DateTime.tryParse(txMap['timestamp'].toString()) ??
                      DateTime.now()
                  : DateTime.now(),
              date: txMap['date'] != null
                  ? DateTime.tryParse(txMap['date'].toString()) ??
                      DateTime.now()
                  : DateTime.now(),
              balanceBefore: _parseAmount(txMap['balanceBefore']),
              balanceAfter: _parseAmount(txMap['balanceAfter']),
              exchangeRate: _parseAmount(txMap['exchangeRate']),
              localAmount: _parseAmount(txMap['localAmount']),
              destination: txMap['destination']?.toString(),
              isClaimed: txMap['isClaimed'] == true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            parsedTransactions.add(transaction);
          } catch (e) {
            print('❌ Error parsing transaction: $e');
            continue;
          }
        }

        // Update transactions list
        _transactions = List.from(parsedTransactions);
        print(
            '✅ Updated transactions list with ${_transactions.length} transactions');
        notifyListeners();
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      print('❌ Error refreshing transactions: $e');
      rethrow;
    }
  }

  // Helper method to parse amounts safely
  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
