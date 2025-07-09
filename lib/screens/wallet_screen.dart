import 'dart:async';

import 'package:bitcoin_cloud_mining/models/transaction.dart';
import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/processing_dialog.dart';
import '../screens/transaction_details_screen.dart';
import '../utils/number_formatter.dart';
import '../widgets/withdrawal_disclaimer_dialog.dart';
import '../widgets/withdrawal_eligibility_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isLoading = true;
  late WalletProvider _walletProvider;
  final ApiService _apiService = ApiService();
  String _selectedMethod = 'Bitcoin';
  final Map<String, double> _currencyRates = {
    'USD': 1.0,
    'INR': 83.0,
    'EUR': 0.91,
  };

  // Instance for local notifications.
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _statusCheckTimer;
  Timer? _currencyUpdateTimer;
  Timer? _refreshTimer;
  bool _isDisposed = false;
  double? lastCalculatedBtc;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String? _errorMessage;
  double _btcAmount = 0;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _loadData();
    _setupRealTimeUpdates();
    _checkPendingTransactions();
    _loadWalletBalance();
    _syncWalletBalance();
    _updateLocalCurrencyRates();
    _startRefreshTimer();
    _initializeLocalNotifications();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    await _adService.initialize();
    // Pre-load a rewarded ad
    await _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    amountController.dispose();
    _addressController.dispose();
    _destinationController.dispose();
    _isDisposed = true;
    _apiService.disposeSocket();
    _statusCheckTimer?.cancel();
    _currencyUpdateTimer?.cancel();
    _refreshTimer?.cancel();
    _walletProvider.stopLivePriceUpdates();
    _adService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _walletProvider.loadWallet();
      await _walletProvider.refreshTransactions();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load wallet data. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDisposed) {
      _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    }
  }

  void _setupRealTimeUpdates() {
    _walletProvider.addListener(() {
      if (mounted) {
        setState(() {
          _btcAmount = _walletProvider.btcBalance;
        });
      }
    });
  }

  Future<void> _checkPendingTransactions() async {
    try {
      final wallet = Provider.of<WalletProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Store current transaction statuses
      final oldTransactions = Map.fromEntries(
        wallet.transactions.map((tx) => MapEntry(tx.transactionId, tx.status)),
      );

      // Refresh transactions
      await wallet.refreshTransactions();

      // Update auth provider with new balance
      await authProvider.updateWalletBalance(wallet.btcBalance);

      // Compare old and new statuses to show notifications
      for (var tx in wallet.transactions) {
        final oldStatus = oldTransactions[tx.transactionId];
        if (oldStatus != null && oldStatus != tx.status) {
          // Status has changed, show notification
          String title = '✅ Transaction Completed';
          String message =
              '${tx.type} of ${tx.amount.toStringAsFixed(18)} BTC has been completed';

          switch (tx.status.toLowerCase()) {
            case 'completed':
              title = '✅ Transaction Completed';
              message =
                  '${tx.type} of ${tx.amount.toStringAsFixed(18)} BTC has been completed';
              break;
            case 'approved':
              title = '✅ Transaction Approved';
              message =
                  '${tx.type} of ${tx.amount.toStringAsFixed(18)} BTC has been approved';
              break;
            case 'rejected':
              title = '❌ Transaction Rejected';
              message =
                  '${tx.type} of ${tx.amount.toStringAsFixed(18)} BTC has been rejected';
              if (tx.adminNote != null) {
                message += '\nReason: ${tx.adminNote}';
              }
              break;
          }

          if (message.isNotEmpty && mounted && !_isDisposed) {
            await _showNotification(title, message);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: tx.status.toLowerCase() == 'rejected'
                    ? Colors.red
                    : tx.status.toLowerCase() == 'completed'
                        ? Colors.green
                        : Colors.blue,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () async {
                    // REMOVE: await _showNotificationsDialog();
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _loadWallet() async {
    try {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = true;
        });
      }

      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load wallet data from backend
      await walletProvider.loadWallet();

      // Update auth provider with new balance
      await authProvider.updateWalletBalance(walletProvider.btcBalance);

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallet: $e')),
        );
      }
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      await _walletProvider.loadWallet();
      if (mounted) {
        setState(() {
          _btcAmount = _walletProvider.btcBalance;
        });
      }
    } catch (e) {}
  }

  Future<void> _syncWalletBalance() async {
    try {
      final currentBalance = _walletProvider.btcBalance;
      if (currentBalance < 0) {
        // If balance is negative, reset it to 0
        await _walletProvider.updateBalance(0);
      }

      // Refresh transactions
      await _walletProvider.refreshTransactions();

      if (mounted) {
        setState(() {
          _btcAmount = _walletProvider.btcBalance;
        });
      }
    } catch (e) {}
  }

  String formatBTCAmount(double amount) {
    // Convert scientific notation to decimal string with 18 decimal places
    return NumberFormatter.formatBTCAmount(amount);
  }

  double convertLocalCurrencyToBtc(double localAmount) {
    final btcPrice = _walletProvider.btcPrice;
    double currencyRate = 1.0; // Default for USD (PayPal)

    if (_selectedMethod == 'Paytm') {
      currencyRate = _walletProvider.currencyRates['INR'] ?? 83.0;
    }

    // Convert local currency to BTC
    double btcAmount;
    if (_selectedMethod == 'Paypal') {
      // For PayPal, amount is in USD, so divide by BTC price
      btcAmount = localAmount / btcPrice;
    } else if (_selectedMethod == 'Paytm') {
      // For Paytm, amount is in INR, so divide by (BTC price * INR rate)
      btcAmount = localAmount / (btcPrice * currencyRate);
    } else {
      // For Bitcoin, amount is already in BTC
      btcAmount = localAmount;
    }

    // Ensure we don't exceed the available BTC balance
    if (btcAmount > _walletProvider.btcBalance) {
      throw Exception('Insufficient balance');
    }

    return double.parse(NumberFormatter.formatBTCAmount(btcAmount));
  }

  // Add method to calculate maximum withdrawal amount for different currencies based on BTC balance
  double getMaxWithdrawalAmount(
      String method, double btcPrice, Map<String, double> currencyRates) {
    final btcBalance =
        Provider.of<WalletProvider>(context, listen: false).btcBalance;

    if (method == 'Bitcoin') {
      return btcBalance;
    } else if (method == 'Paytm') {
      // Convert BTC to INR
      return btcBalance * btcPrice * currencyRates['INR']!;
    } else if (method == 'Paypal') {
      // Convert BTC to USD
      return btcBalance * btcPrice;
    }

    return 0.0; // Default if method not recognized
  }

  // Helper method to format fiat currency amount
  String formatFiatAmount(double amount) {
    // Show 2 decimals for fiat currencies
    return amount.toStringAsFixed(2);
  }

  void _showWithdrawalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 48,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Withdraw Funds',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  buildBalanceDisplay(),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Withdrawal Method',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: ['Bitcoin', 'Paytm', 'Paypal']
                            .map((method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method),
                                ))
                            .toList(),
                        onChanged: _isProcessing
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedMethod = value;
                                    amountController.clear();
                                    _addressController.clear();
                                    _destinationController.clear();
                                    lastCalculatedBtc = null;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        enabled: !_isProcessing,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (${getCurrencySymbol()})',
                          hintText: 'Enter amount to withdraw',
                          prefixIcon: Icon(_selectedMethod == 'Paytm'
                              ? Icons.currency_rupee
                              : Icons.attach_money),
                        ),
                        onChanged: updateBtcEquivalent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Maximum withdrawal: ${getCurrencySymbol()}${getLocalCurrencyBalance().toStringAsFixed(_selectedMethod == "Bitcoin" ? 18 : 10)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (_selectedMethod != 'Bitcoin' &&
                          lastCalculatedBtc != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'BTC Equivalent: ${lastCalculatedBtc!.toStringAsFixed(18)} BTC',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_selectedMethod == 'Bitcoin')
                        TextField(
                          controller: _addressController,
                          enabled: !_isProcessing,
                          decoration: const InputDecoration(
                            labelText: 'Bitcoin Address',
                            hintText: 'Enter your Bitcoin address',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                        )
                      else
                        TextField(
                          controller: _destinationController,
                          enabled: !_isProcessing,
                          decoration: InputDecoration(
                            labelText: _selectedMethod == 'Paytm'
                                ? 'Paytm Number'
                                : 'PayPal Email',
                            hintText: _selectedMethod == 'Paytm'
                                ? 'Enter your Paytm number'
                                : 'Enter your PayPal email',
                            prefixIcon: Icon(_selectedMethod == 'Paytm'
                                ? Icons.phone
                                : Icons.email),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          if (amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          await _processWithdrawal();
                        },
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Withdraw'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isValidBitcoinAddress(String address) {
    // Basic validation for Bitcoin address
    return address.startsWith('1') ||
        address.startsWith('3') ||
        address.startsWith('bc1');
  }

  Future<void> _showNotification(String title, String body) async {
    await _localNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'withdrawal_channel',
          'Withdrawal Notifications',
          channelDescription: 'Notifications for withdrawal updates',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.blue,
          enableLights: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Update local currency rates method
  void _updateLocalCurrencyRates() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // Start live price updates
    walletProvider.startLivePriceUpdates();

    // Update rates immediately
    walletProvider.currencyRates.forEach((key, value) {
      _currencyRates[key] = value;
    });

    // Update currency rates every 60 seconds
    _currencyUpdateTimer?.cancel();
    _currencyUpdateTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && !_isDisposed) {
        setState(() {
          walletProvider.currencyRates.forEach((key, value) {
            _currencyRates[key] = value;
          });
        });
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // Increase refresh interval to 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!_isDisposed && mounted) {
        _loadWallet();
      }
    });
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      default:
        return '\$';
    }
  }

  Widget _buildTransactionHistory() {
    final walletProvider = Provider.of<WalletProvider>(context);
    final transactions = walletProvider.transactions;

    if (transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Separate transactions by status
    final pendingTransactions = transactions
        .where((tx) => tx.status.toLowerCase() == 'pending')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final completedTransactions = transactions
        .where((tx) => tx.status.toLowerCase() == 'completed')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final rejectedTransactions = transactions
        .where((tx) => tx.status.toLowerCase() == 'rejected')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      constraints: const BoxConstraints(
        minHeight: 400,
        maxHeight: 600,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pending_actions, size: 18),
                      SizedBox(width: 4),
                      Text('Pending', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      SizedBox(width: 4),
                      Text('Completed', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, size: 18),
                      SizedBox(width: 4),
                      Text('Rejected', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTransactionList(pendingTransactions, 'pending'),
                  _buildTransactionList(completedTransactions, 'completed'),
                  _buildTransactionList(rejectedTransactions, 'rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions, String status) {
    if (transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: transactions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionItem(tx);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailsScreen(
                transaction: transaction,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getTransactionIcon(transaction.type),
                        color: _getTransactionColor(transaction.type),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        transaction.type.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTransactionColor(transaction.type),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(transaction.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${transaction.amount.toStringAsFixed(18)} ${transaction.currency}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (transaction.destination != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Destination: ${transaction.destination}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(transaction.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (transaction.status.toLowerCase() == 'rejected')
                    Consumer<WalletProvider>(
                      builder: (context, walletProvider, child) {
                        final isClaimed =
                            walletProvider.isTransactionClaimed(transaction.id);
                        return ElevatedButton(
                          onPressed: isClaimed
                              ? null
                              : () async {
                                  _handleClaim(transaction);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isClaimed ? Colors.grey : Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isClaimed ? 'Claimed' : 'Claim',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Main build method that assembles the screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Deep Blue
                Color(0xFF0D47A1), // Darker Blue
                Color(0xFF01579B), // Medium Blue
                Color(0xFF0277BD), // Light Blue
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBalanceCard(),
                                const SizedBox(height: 20),
                                _buildActionButtons(),
                                const SizedBox(height: 20),
                                _buildTransactionHistory(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Wallet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.currency_bitcoin,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${NumberFormatter.formatBTCAmount(walletProvider.btcBalance)} BTC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _showCurrencySelector(context, walletProvider),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withAlpha(51)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${walletProvider.selectedCurrency}: ${_getCurrencySymbol(walletProvider.selectedCurrency)}${NumberFormatter.formatBTCAmount(walletProvider.getLocalCurrencyValue(walletProvider.selectedCurrency))}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencySelector(
      BuildContext context, WalletProvider walletProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Currency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCurrencyOption(context, walletProvider, 'USD', '\$'),
                    _buildCurrencyOption(context, walletProvider, 'INR', '₹'),
                    _buildCurrencyOption(context, walletProvider, 'EUR', '€'),
                    _buildCurrencyOption(context, walletProvider, 'GBP', '£'),
                    _buildCurrencyOption(context, walletProvider, 'JPY', '¥'),
                    _buildCurrencyOption(context, walletProvider, 'AUD', 'A\$'),
                    _buildCurrencyOption(context, walletProvider, 'CAD', 'C\$'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(BuildContext context,
      WalletProvider walletProvider, String currency, String symbol) {
    final isSelected = walletProvider.selectedCurrency == currency;
    return ListTile(
      onTap: () {
        walletProvider.setSelectedCurrency(currency);
        Navigator.pop(context);
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        currency,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Text(
        '$symbol${NumberFormatter.formatBTCAmount(walletProvider.getLocalCurrencyValue(currency))}',
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildActionButton(
                icon: Icons.call_made,
                label: 'Withdraw',
                onTap: _startWithdrawalFlow,
                color: Colors.red,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildEligibilityActionButton(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildActionButton(
                icon: Icons.history,
                label: 'History',
                onTap: _showTransactionHistory,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityActionButton() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final eligible = walletProvider.btcBalance >= 0.00005;
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) {
                return Container(
                  color: Colors.blue[900], // Background blue kar diya
                  child: Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: WithdrawalEligibilityWidget(
                        btcBalance: walletProvider.btcBalance,
                        onNext: null, // Dialog me Next button disable rahega
                        onBack: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: eligible
                  ? Colors.green.withAlpha(51)
                  : Colors.red.withAlpha(51),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: eligible ? Colors.green : Colors.red, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  eligible ? Icons.check_circle : Icons.cancel,
                  color: eligible ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  eligible ? 'Eligible' : 'Not Eligible',
                  style: TextStyle(
                    color: eligible ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(51),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withAlpha(128)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap - navigate to actual notification screen
        if (mounted && !_isDisposed) {
          Navigator.of(context).pushNamed('/notifications');
        }
      },
    );

    // Request permissions for iOS
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod == 'Bitcoin' && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Bitcoin address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod == 'Bitcoin' &&
        !_isValidBitcoinAddress(_addressController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid Bitcoin address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod != 'Bitcoin' && _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Show processing popup
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ProcessingDialog(
          message: 'Processing withdrawal request...',
        ),
      );

      final destination = _selectedMethod == 'Bitcoin'
          ? _addressController.text
          : _destinationController.text;

      // Convert method to backend format
      String paymentMethod;
      if (_selectedMethod == 'Bitcoin') {
        paymentMethod =
            'Crypto'; // Changed from 'BTC' to 'Crypto' to match backend validation
      } else if (_selectedMethod == 'Paytm') {
        paymentMethod = 'Paytm';
      } else if (_selectedMethod == 'Paypal') {
        paymentMethod = 'Paypal';
      } else {
        paymentMethod = _selectedMethod;
      }

      // Calculate BTC amount based on local currency
      final localAmount = double.parse(amountController.text);
      final btcAmount = convertLocalCurrencyToBtc(localAmount);

      // Check if we have sufficient balance
      if (btcAmount > _walletProvider.btcBalance) {
        throw Exception('Insufficient balance');
      }

      // Initialize and sync wallet before withdrawal
      await _walletProvider.initializeWallet();
      await _syncWalletBalance();

      // Double check balance after initialization
      if (btcAmount > _walletProvider.btcBalance) {
        throw Exception('Insufficient balance after wallet sync');
      }

      final success = await _walletProvider.withdrawFunds(
        method: paymentMethod,
        destination: destination,
        amount: localAmount,
        currency: _selectedMethod == 'Bitcoin'
            ? 'BTC'
            : _selectedMethod == 'Paytm'
                ? 'INR'
                : 'USD',
        btcAmount: btcAmount,
      );

      // Close processing popup
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Withdrawal request submitted successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () async {
                // Get the latest transaction
                await _walletProvider.refreshTransactions();
                final latestTransaction =
                    _walletProvider.transactions.firstWhere(
                  (tx) =>
                      tx.type.toLowerCase().contains('withdrawal') &&
                      tx.amount == btcAmount &&
                      tx.timestamp.isAfter(
                          DateTime.now().subtract(const Duration(seconds: 5))),
                  orElse: () => Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: _selectedMethod == 'Bitcoin'
                        ? 'withdrawal_bitcoin'
                        : 'withdrawal_${_selectedMethod.toLowerCase()}',
                    amount: btcAmount,
                    status: 'pending',
                    timestamp: DateTime.now(),
                    currency: _selectedMethod == 'Bitcoin' ? 'BTC' : 'INR',
                    description: 'Withdrawal to $_selectedMethod',
                    details: {
                      'Method': _selectedMethod,
                      'Destination': destination,
                      'Amount': localAmount.toString(),
                      'BTC Amount': btcAmount.toString(),
                    },
                  ),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailsScreen(
                      transaction: latestTransaction,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Reset form
        amountController.clear();
        _addressController.clear();
        _destinationController.clear();
        setState(() {
          _btcAmount = 0;
          lastCalculatedBtc = null;
        });

        // Close withdrawal dialog
        Navigator.of(context).pop();

        // Refresh wallet balance and transactions
        await _walletProvider.loadWallet();
        await _walletProvider.refreshTransactions();
        await _syncWalletBalance(); // Add balance sync after withdrawal
      } else {
        // Show error message
        setState(() {
          _errorMessage = 'Withdrawal request failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Close processing popup if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_errorMessage!),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String getCurrencySymbol() {
    if (_selectedMethod == 'Bitcoin') return 'BTC';
    if (_selectedMethod == 'Paytm') return '₹';
    return '\$';
  }

  double getLocalCurrencyBalance() {
    if (_selectedMethod == 'Bitcoin') {
      return _walletProvider.btcBalance;
    }

    final btcPrice = _walletProvider.btcPrice;
    double currencyRate = 1.0; // Default USD rate

    if (_selectedMethod == 'Paytm') {
      currencyRate = _walletProvider.currencyRates['INR'] ?? 83.0;
    }

    final localBalance = _walletProvider.btcBalance * btcPrice * currencyRate;
    return localBalance;
  }

  void updateBtcEquivalent(String value) {
    if (value.isEmpty) {
      setState(() {
        lastCalculatedBtc = null;
        _btcAmount = 0;
      });
      return;
    }

    final amount = double.tryParse(value) ?? 0;
    if (amount > 0) {
      final btcAmount = convertLocalCurrencyToBtc(amount);
      setState(() {
        lastCalculatedBtc = btcAmount;
        _btcAmount = btcAmount;
      });
    }
  }

  Widget buildBalanceDisplay() {
    final balance = getLocalCurrencyBalance();
    final symbol = getCurrencySymbol();

    return Column(
      children: [
        Text(
          'Available: $symbol${_selectedMethod == "Bitcoin" ? NumberFormatter.formatBTCAmount(balance) : balance.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        if (_selectedMethod != 'Bitcoin' && _btcAmount > 0)
          Text(
            'BTC Equivalent: ${NumberFormatter.formatBTCAmount(_btcAmount)} BTC',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  void _showTransactionHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildTransactionHistory(),
            ),
          ],
        ),
      ),
    );
  }

  // Add pull to refresh functionality
  Future<void> _onRefresh() async {
    try {
      final wallet = Provider.of<WalletProvider>(context, listen: false);
      await wallet.refreshTransactions();
      await wallet.loadWallet();
      await _syncWalletBalance();
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e) {}
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Icons.arrow_downward;
      case 'withdrawal':
        return Icons.arrow_upward;
      case 'bonus':
        return Icons.card_giftcard;
      case 'claim':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Colors.green;
      case 'withdrawal':
        return Colors.red;
      case 'bonus':
        return Colors.orange;
      case 'claim':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleClaim(Transaction transaction) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Load rewarded ad if not loaded
      await _adService.loadRewardedAd();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show rewarded ad
      final bool adShown = await _adService.showRewardedAd(
        onRewarded: (double rewardAmount) async {
          try {
            // Show claiming progress
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => const ProcessingDialog(
                message: 'Claiming transaction...',
              ),
            );

            // Process the claim
            await _walletProvider.claimRejectedTransaction(transaction.id);

            // Close processing dialog
            if (context.mounted) {
              Navigator.of(context).pop();
            }

            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Transaction claimed successfully! Reward added to your balance.'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // Refresh wallet data
            await _loadData();
          } catch (e) {
            // Close processing dialog if open
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to claim transaction: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onAdDismissed: _adService.loadRewardedAd,
      );

      if (!adShown && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please watch the reward video to claim the transaction'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close any open dialogs
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startWithdrawalFlow() async {
    await showWithdrawalDisclaimerDialog(
      context: context,
      onContinue: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return Container(
              color: Colors.blue[900], // Background blue kar diya
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Consumer<WalletProvider>(
                  builder: (context, walletProvider, _) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: WithdrawalEligibilityWidget(
                        btcBalance: walletProvider.btcBalance,
                        onNext: walletProvider.btcBalance >= 0.00005
                            ? () {
                                Navigator.of(ctx).pop();
                                _showWithdrawalDialog();
                              }
                            : null,
                        onBack: () => Navigator.of(ctx).pop(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
