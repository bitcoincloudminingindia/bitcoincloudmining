import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../providers/wallet_provider.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  UserProfile? userProfile;
  final Random _random = Random();
  StreamSubscription? _balanceSubscription;
  late WalletProvider _walletProvider;

  final Map<String, List<String>> quickRepliesCategories = {
    'Wallet & Transactions': [
      'Check balance',
      'Recent transactions',
      'Mining earnings',
    ],
    'Withdrawals': [
      'Start withdrawal',
      'Check status',
      'Withdrawal history',
    ],
    'Mining': [
      'Mining speed',
      'Power-ups',
      'Boost mining',
    ],
    'Help': [
      'How it works',
      'Support',
      'FAQ',
    ],
  };

  final List<String> acknowledgements = [
    'I understand.',
    'Got it!',
    'I see.',
    'Alright!',
    'Sure thing!',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeUserProfile();
    await _loadChatHistory();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _setupBalanceListener();
  }

  void _setupBalanceListener() {
    if (_balanceSubscription != null) {
      _balanceSubscription!.cancel();
    }

    // Update user profile when wallet balance changes
    _balanceSubscription =
        Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted && userProfile != null) {
        setState(() {
          userProfile!.walletBalance = _walletProvider.btcBalance;
          userProfile!.totalMined = _walletProvider.totalEarned;
          userProfile!.totalWithdrawn = _walletProvider.totalWithdrawn;
          userProfile!.miningRate =
              _calculateMiningRate(userProfile!.totalMined);
          _saveUserProfile();
        });
      }
    });
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _calculateMiningRate(double totalMined) {
    final days = userProfile?.getDaysActive() ?? 1;
    if (days <= 0) return 0.00001;
    return totalMined / (days * 24); // BTC per hour
  }

  String _formatBTC(double amount) {
    return amount.toStringAsFixed(18);
  }

  Future<void> _saveUserProfile() async {
    if (userProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(userProfile!.toJson()));
    }
  }

  Future<void> _loadChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('chat_history') ?? [];
    setState(() {
      messages.clear();
      for (var entry in history) {
        final parts = entry.split('::');
        if (parts.length == 2) {
          messages.add({'sender': parts[0], 'text': parts[1]});
        }
      }
    });
  }

  Future<void> _saveChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final history =
        messages.map((m) => "${m['sender']}::${m['text']}").toList();
    await prefs.setStringList('chat_history', history);
  }

  void _setTypingStatus(bool isTyping) {
    if (mounted) {
      setState(() {
        _isTyping = isTyping;
      });
    }
  }

  Future<String> _getBotResponse(String userInput) async {
    if (userProfile == null) return 'Still initializing...';

    _setTypingStatus(true);
    userInput = userInput.toLowerCase();
    final name = userProfile!.getDisplayName();

    // Add a random delay to simulate thinking
    final delay = Duration(milliseconds: _random.nextInt(500) + 500);
    await Future.delayed(delay);
    _setTypingStatus(false);

    if (_isGreeting(userInput)) {
      final greetings = _getContextualGreeting();
      return '${greetings[_random.nextInt(greetings.length)]}\n\n'
          '${_getWalletSummary()}';
    }

    if (_isBalanceQuery(userInput)) {
      return 'Hey $name! Here\'s your up-to-date mining status:\n\n'
          '${_getWalletSummary()}\n\n'
          'Would you like some tips on increasing your mining speed?';
    }

    if (_isTransactionQuery(userInput)) {
      return _handleTransactionQuery(userInput);
    }

    if (_isWithdrawalQuery(userInput)) {
      return _handleWithdrawalQuery(userInput);
    }

    return '${acknowledgements[_random.nextInt(acknowledgements.length)]} '
        'I\'m here to help with your mining journey, $name!\n\n'
        'You can ask me about:\n'
        '• Your earnings and current balance\n'
        '• Withdrawal options and tracking\n'
        '• Boosting your mining speed\n'
        '• Transaction history and stats\n\n'
        'What would you like to know?';
  }

  String _getWalletSummary() {
    if (userProfile == null) return '';

    final btcPrice = _walletProvider.btcPrice;
    final usdBalance = userProfile!.walletBalance * btcPrice;

    return 'Your Mining Stats 📊\n\n'
        '• Current Balance: ${_formatBTC(userProfile!.walletBalance)} BTC '
        '(≈\$${usdBalance.toStringAsFixed(2)})\n'
        '• Total Mined: ${_formatBTC(userProfile!.totalMined)} BTC\n'
        '• Total Withdrawn: ${_formatBTC(userProfile!.totalWithdrawn)} BTC\n'
        '• Mining Rate: ${_formatBTC(userProfile!.miningRate)} BTC/hour\n'
        '• Days Mining: ${userProfile!.getDaysActive()} days\n\n'
        '${_getProgressMessage()}';
  }

  String _getProgressMessage() {
    if (userProfile == null) return '';
    final progress = userProfile!.walletBalance / 0.000000000000000001 * 100;
    if (progress < 25) {
      return 'Keep mining! You\'re making steady progress. 🌱';
    } else if (progress < 50) {
      return 'You\'re getting there! Keep up the great work! 🚀';
    } else if (progress < 75) {
      return 'Almost halfway to your first withdrawal! 💪';
    } else if (progress < 100) {
      return 'You\'re so close to reaching the withdrawal threshold! 🎯';
    } else {
      return 'Congratulations! You can withdraw your earnings now! 🎉';
    }
  }

  List<String> _getContextualGreeting() {
    if (userProfile == null) return ['Hello!'];

    final hour = DateTime.now().hour;
    final name = userProfile!.getDisplayName();

    if (hour < 12) {
      return [
        'Good morning, $name! How can I help you today?',
        'Morning, $name! Ready to check your mining progress?',
        'Rise and shine, $name! How\'s the mining going?'
      ];
    } else if (hour < 17) {
      return [
        'Good afternoon, $name! Need help with anything?',
        'Hey $name! How\'s your mining journey going?',
        'Afternoon, $name! Ready to check your earnings?'
      ];
    } else {
      return [
        'Good evening, $name! How can I assist you?',
        'Evening, $name! Let\'s check your mining progress!',
        'Hi $name! Need help with your evening mining?'
      ];
    }
  }

  bool _isGreeting(String input) {
    final greetingWords = ['hi', 'hello', 'hey', 'greetings', 'good'];
    return greetingWords.any((word) => input.contains(word));
  }

  bool _isBalanceQuery(String input) {
    final balanceWords = ['balance', 'wallet', 'amount', 'how much'];
    return balanceWords.any((word) => input.contains(word));
  }

  bool _isTransactionQuery(String input) {
    final transactionWords = ['transaction', 'history', 'recent', 'activity'];
    return transactionWords.any((word) => input.contains(word));
  }

  bool _isWithdrawalQuery(String input) {
    final withdrawalWords = [
      'withdraw',
      'withdrawal',
      'track#',
      'status#',
      'track withdrawal',
      'withdrawal status',
      'payment',
      'cash out',
      'pending withdrawals',
      'withdrawal history',
      'cancel withdrawal',
      'withdrawal limit',
      'withdrawal fee',
      'withdrawal address',
      'withdrawal info',
      'all withdrawals'
    ];
    return withdrawalWords
        .any((word) => input.toLowerCase().contains(word.toLowerCase()));
  }

  String _handleTransactionQuery(String input) {
    if (userProfile == null) return 'Still initializing...';
    final name = userProfile!.getDisplayName();

    final transactions = _walletProvider.transactions;
    if (transactions.isEmpty) {
      return 'Hey $name! I see you\'re new to mining!\n\n'
          'Start your journey by letting your miner run, and you\'ll see your earnings appear here.\n\n'
          'Need help getting started?';
    }

    final recentTransactions = transactions.take(5);
    var response = 'Here are your recent mining activities, $name:\n\n';

    for (var tx in recentTransactions) {
      response += '${tx.type.toUpperCase()}\n'
          '• Amount: ${_formatBTC(tx.amount.abs())} BTC\n'
          '• When: ${DateFormat('MMM dd, HH:mm').format(tx.timestamp)}\n'
          '• ${tx.description}\n\n';
    }

    response +=
        '${_getProgressMessage()}\n\nNeed help optimizing your mining, $name?';

    return response;
  }

  Future<String> _handleWithdrawalQuery(String userInput) async {
    if (userProfile == null) return 'Still initializing...';
    final name = userProfile!.getDisplayName();
    final balance = _walletProvider.btcBalance;

    // Check if this is a status check query
    if (userInput.toLowerCase().contains('status#') ||
        userInput.toLowerCase().contains('track#')) {
      // Extract withdrawal ID number
      final idMatch = RegExp(r'#(\d+)').firstMatch(userInput);
      if (idMatch != null) {
        final withdrawalId = idMatch.group(1);
        return _getWithdrawalStatus(withdrawalId!, name);
      }
    }

    if (userInput.toLowerCase().contains('track withdrawal') ||
        userInput.toLowerCase().contains('withdrawal status')) {
      return 'To check your withdrawal status, please provide your withdrawal ID in this format:\n'
          'status#123 or track#123\n\n'
          'For example: "status#1" to check withdrawal #1';
    }

    if (userInput.toLowerCase().startsWith('withdraw')) {
      if (balance < 0.000000000000000001) {
        return 'I\'m sorry, $name. Your balance is below the minimum withdrawal amount.\n\n'
            'Minimum needed: 0.000000000000000001 BTC\n'
            'Your balance: ${_formatBTC(balance)} BTC\n\n'
            '${_getProgressMessage()}\n'
            'Keep mining to reach the minimum withdrawal amount! 💪';
      }

      // Generate a new withdrawal ID
      final withdrawalId = _generateWithdrawalId();
      _saveWithdrawalRequest(withdrawalId);

      return 'Great news, $name! I\'ve initiated your withdrawal request.\n\n'
          '• Amount: ${_formatBTC(balance)} BTC\n'
          '• Withdrawal ID: #$withdrawalId\n\n'
          'Your withdrawal is now processing. This typically takes up to 48 hours.\n'
          'You can check the status anytime by sending:\n'
          'status#$withdrawalId\n\n'
          'Need anything else?';
    }
    if (userInput.toLowerCase().contains('withdrawal history') ||
        userInput.toLowerCase().contains('all withdrawals')) {
      return _getWithdrawalHistory(name);
    }

    if (userInput.toLowerCase().contains('pending withdrawals')) {
      return _getPendingWithdrawals(name);
    }

    if (userInput.toLowerCase().contains('withdrawal limit')) {
      return 'Here are the withdrawal limits, $name:\n\n'
          '• Minimum withdrawal: 0.000000000000000001 BTC\n'
          '• Maximum withdrawal: No limit\n'
          '• Daily withdrawal limit: No limit\n'
          '• Your available balance: ${_formatBTC(balance)} BTC\n\n'
          'Need help with making a withdrawal?';
    }

    if (userInput.toLowerCase().contains('withdrawal fee')) {
      return 'Good news, $name! We currently charge:\n\n'
          '• 0% withdrawal fee\n'
          '• No transaction fees\n'
          '• No hidden charges\n\n'
          'Would you like to make a withdrawal now?';
    }

    if (userInput.toLowerCase().contains('cancel withdrawal')) {
      return 'To cancel a withdrawal, please provide the withdrawal ID in this format:\n'
          'cancel#123\n\n'
          'Note: You can only cancel pending withdrawals that are less than 1 hour old.';
    }

    if (userInput.toLowerCase().contains('withdrawal info') ||
        userInput.toLowerCase().contains('withdrawal address')) {
      return 'Here\'s what you need to know about withdrawals, $name:\n\n'
          '• Minimum amount: 0.000000000000000001 BTC\n'
          '• Processing time: Up to 48 hours\n'
          '• Fee: 0%\n'
          '• Available balance: ${_formatBTC(balance)} BTC\n\n'
          'To withdraw:\n'
          '1. Type "withdraw" to start\n'
          '2. Enter your BTC address\n'
          '3. Confirm the transaction\n\n'
          'Would you like to start a withdrawal now?';
    }

    return 'Hi $name! How can I help you with withdrawals?\n\n'
        '• Type "withdraw" to start a new withdrawal\n'
        '• Type "status#ID" to check an existing withdrawal\n'
        '• Type "withdrawal history" to see all your withdrawals\n'
        '• Type "pending withdrawals" to see processing withdrawals\n'
        '• Type "withdrawal info" for fees and limits\n'
        '• Type "cancel withdrawal" to cancel a pending withdrawal\n\n'
        'Your current balance: ${_formatBTC(balance)} BTC\n\n'
        '${_getProgressMessage()}';
  }

  Future<String> _getWithdrawalStatus(String withdrawalId, String name) async {
    final status = await _retrieveWithdrawalStatus(withdrawalId);
    if (status == null) {
      return 'I\'m sorry, $name. I couldn\'t find a withdrawal with ID #$withdrawalId.\n'
          'Please make sure you\'ve entered the correct withdrawal ID.\n\n'
          'Need help with something else?';
    }

    final amount = double.tryParse(status['amount'] ?? '0') ?? 0.0;
    return 'Here\'s the status of your withdrawal #$withdrawalId, $name:\n\n'
        '• Status: ${status['status']}\n'
        '• Amount: ${_formatBTC(amount)} BTC\n'
        '• Requested: ${status['timestamp']}\n\n'
        'Please allow up to 48 hours for processing.\n'
        'Need anything else?';
  }

  int _generateWithdrawalId() {
    return DateTime.now().millisecondsSinceEpoch % 10000;
  }

  Future<void> _saveWithdrawalRequest(int withdrawalId) async {
    final prefs = await SharedPreferences.getInstance();
    final withdrawals = prefs.getStringList('withdrawals') ?? [];

    final withdrawal = {
      'id': withdrawalId.toString(),
      'amount': _walletProvider.btcBalance.toString(),
      'status': 'Processing',
      'timestamp': DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())
    };

    withdrawals.add(jsonEncode(withdrawal));
    await prefs.setStringList('withdrawals', withdrawals);
  }

  Future<Map<String, String>?> _retrieveWithdrawalStatus(
      String withdrawalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final withdrawals = prefs.getStringList('withdrawals') ?? [];

      for (var w in withdrawals) {
        final withdrawal = jsonDecode(w) as Map<String, dynamic>;
        if (withdrawal['id'] == withdrawalId) {
          return Map<String, String>.from(withdrawal);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleUserInput(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({'sender': 'user', 'text': text});
      _controller.clear();
    });

    final response = await _getBotResponse(text);
    if (mounted) {
      setState(() {
        messages.add({'sender': 'bot', 'text': response});
      });
      await _saveChatHistory();
    }
  }

  Future<void> _initializeUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');

    if (profileJson != null) {
      setState(() {
        userProfile = UserProfile.fromJson(jsonDecode(profileJson));
      });
    } else {
      // Initialize with default values
      setState(() {
        userProfile = UserProfile(
          name: 'User',
          walletBalance: _walletProvider.btcBalance,
          totalMined: _walletProvider.totalEarned,
          totalWithdrawn: _walletProvider.totalWithdrawn,
          miningRate: 0.00001,
        );
      });
      await _saveUserProfile();
    }
  }

  Future<String> _getWithdrawalHistory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final withdrawals = prefs.getStringList('withdrawals') ?? [];

    if (withdrawals.isEmpty) {
      return 'You haven\'t made any withdrawals yet, $name.\n\n'
          'Your current balance: ${_formatBTC(_walletProvider.btcBalance)} BTC\n'
          'Would you like to make your first withdrawal?';
    }

    var response = 'Here\'s your withdrawal history, $name:\n\n';
    final sortedWithdrawals = withdrawals
        .map((w) => jsonDecode(w) as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

    for (var withdrawal in sortedWithdrawals.take(5)) {
      final amount = double.tryParse(withdrawal['amount'] ?? '0') ?? 0.0;
      response += '📤 Withdrawal #${withdrawal['id']}\n'
          '• Amount: ${_formatBTC(amount)} BTC\n'
          '• Status: ${withdrawal['status']}\n'
          '• Date: ${withdrawal['timestamp']}\n\n';
    }

    if (sortedWithdrawals.length > 5) {
      response +=
          '... and ${sortedWithdrawals.length - 5} more withdrawals.\n\n';
    }

    response += 'Need help with anything else?';
    return response;
  }

  Future<String> _getPendingWithdrawals(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final withdrawals = prefs.getStringList('withdrawals') ?? [];

    final pendingWithdrawals = withdrawals
        .map((w) => jsonDecode(w) as Map<String, dynamic>)
        .where((w) => w['status'].toString().toLowerCase() == 'processing')
        .toList();

    if (pendingWithdrawals.isEmpty) {
      return 'You don\'t have any pending withdrawals, $name.\n\n'
          'Your current balance: ${_formatBTC(_walletProvider.btcBalance)} BTC\n'
          'Would you like to make a withdrawal?';
    }

    var response = 'Here are your pending withdrawals, $name:\n\n';

    for (var withdrawal in pendingWithdrawals) {
      final amount = double.tryParse(withdrawal['amount'] ?? '0') ?? 0.0;
      final timestamp = DateTime.parse(withdrawal['timestamp']);
      final hoursAgo = DateTime.now().difference(timestamp).inHours;

      response += '⏳ Withdrawal #${withdrawal['id']}\n'
          '• Amount: ${_formatBTC(amount)} BTC\n'
          '• Requested: ${withdrawal['timestamp']}\n'
          '• Time in processing: $hoursAgo hours\n'
          '• Estimated completion: ${48 - hoursAgo} hours remaining\n\n';
    }

    response += 'Withdrawals typically complete within 48 hours.\n'
        'You can check specific withdrawals using status#ID\n\n'
        'Need anything else?';

    return response;
  }

  Future<void> _clearChat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    if (mounted) {
      setState(messages.clear);
      // Add welcome message after clearing
      _handleUserInput('hi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mining Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text(
                      'Are you sure you want to clear all chat messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearChat();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleUserInput,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleUserInput(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
