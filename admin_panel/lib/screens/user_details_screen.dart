import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_drawer.dart';

class UserDetailsScreen extends StatefulWidget {
  static const String routeName = '/user-details';

  const UserDetailsScreen({super.key});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  User? _user;
  String _errorMessage = '';
  List<Map<String, dynamic>> _userTransactions = [];
  bool _loadingTransactions = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = ModalRoute.of(context)?.settings.arguments as String?;
    if (userId != null) {
      _loadUserDetails(userId);
    } else {
      setState(() {
        _errorMessage = 'User ID not provided';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDetails(String userId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await _apiService.getUserDetails(userId);

      if (result['success']) {
        setState(() {
          _user = User.fromJson(result['data']['user']);
          _isLoading = false;
        });

        // Load user transactions
        _loadUserTransactions(userId);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load user details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserTransactions(String userId) async {
    try {
      setState(() {
        _loadingTransactions = true;
      });

      final result = await _apiService.get('/admin/users/$userId/transactions');

      if (result['success']) {
        setState(() {
          _userTransactions = List<Map<String, dynamic>>.from(
              result['data']['transactions'] ?? []);
          _loadingTransactions = false;
        });
      } else {
        setState(() {
          _loadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingTransactions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.username ?? 'User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_user != null) {
                _loadUserDetails(_user!.id);
              }
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_user != null) {
                  _loadUserDetails(_user!.id);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(_user != null ? 'Retry' : 'Go Back'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('User not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          const SizedBox(height: 24),
          _buildUserInfo(),
          const SizedBox(height: 24),
          _buildWalletInfo(),
          const SizedBox(height: 24),
          _buildReferralInfo(),
          const SizedBox(height: 24),
          _buildTransactionsSection(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    final statusColor = _user!.status == 'Active' ? Colors.green : Colors.red;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
              radius: 40,
              child: Text(
                _user!.username.isNotEmpty
                    ? _user!.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _user!.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${_user!.id}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', _user!.email),
            const Divider(),
            _buildInfoRow(Icons.phone, 'Phone', _user!.phone),
            const Divider(),
            _buildInfoRow(Icons.cake, 'Date of Birth', _user!.dob),
            const Divider(),
            _buildInfoRow(
              Icons.calendar_today,
              'Created At',
              _formatDate(_user!.createdAt),
            ),
            if (_user!.lastLogin != null) ...[
              const Divider(),
              _buildInfoRow(
                Icons.login,
                'Last Login',
                _formatDate(_user!.lastLogin!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWalletInfo() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Balance:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_user!.walletBalance.toStringAsFixed(18)} BTC',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralInfo() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referral Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.code,
              'Referral Code',
              _user!.referralCode ?? 'Not available',
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Referrals:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_user!.referrals.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_user!.referrals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Referred Users:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user!.referrals.map((userId) {
                  return Chip(
                    label: Text(userId),
                    backgroundColor: Colors.blue.shade100,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full transactions history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingTransactions)
              const Center(child: CircularProgressIndicator())
            else if (_userTransactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No transactions found'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    _userTransactions.length > 5 ? 5 : _userTransactions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final transaction = _userTransactions[index];
                  return ListTile(
                    leading: _getTransactionIcon(transaction['type']),
                    title: Text(transaction['type'] ?? 'Unknown'),
                    subtitle: Text(
                      _formatTimestamp(transaction['createdAt']),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '${transaction['amount']} ${transaction['currency'] ?? 'BTC'}',
                      style: TextStyle(
                        color: transaction['type'] == 'Withdrawal'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTransactionIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'withdrawal':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          radius: 16,
          child: Icon(Icons.arrow_upward, color: Colors.white, size: 16),
        );
      case 'deposit':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 16,
          child: Icon(Icons.arrow_downward, color: Colors.white, size: 16),
        );
      case 'mining':
        return const CircleAvatar(
          backgroundColor: Colors.amber,
          radius: 16,
          child: Icon(Icons.bolt, color: Colors.white, size: 16),
        );
      case 'referral':
        return const CircleAvatar(
          backgroundColor: Colors.purple,
          radius: 16,
          child: Icon(Icons.people, color: Colors.white, size: 16),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 16,
          child: Icon(Icons.swap_horiz, color: Colors.white, size: 16),
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
