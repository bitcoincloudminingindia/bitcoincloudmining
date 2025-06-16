import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_drawer.dart';

class AdminWithdrawScreen extends StatefulWidget {
  static const String routeName = '/admin-withdrawals';

  const AdminWithdrawScreen({super.key});

  @override
  _AdminWithdrawScreenState createState() => _AdminWithdrawScreenState();
}

class _AdminWithdrawScreenState extends State<AdminWithdrawScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Transaction> _withdrawals = [];
  String _errorMessage = '';
  String _filterStatus = 'All'; // 'All', 'Pending', 'Completed', 'Rejected'

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await _apiService.getWithdrawals();

      if (result['success']) {
        final List<dynamic> withdrawalData =
            result['data']['withdrawals'] ?? [];

        setState(() {
          _withdrawals =
              withdrawalData.map((item) => Transaction.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load withdrawals';
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

  List<Transaction> get _filteredWithdrawals {
    if (_filterStatus == 'All') {
      return _withdrawals;
    }
    return _withdrawals.where((tx) => tx.status == _filterStatus).toList();
  }

  Future<void> _updateTransactionStatus(
      String transactionId, String status, String? note) async {
    try {
      final result = await _apiService.updateTransactionStatus(
        transactionId: transactionId,
        status: status,
        adminNote: note,
      );

      if (result['success']) {
        // Refresh the list
        _loadWithdrawals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWithdrawals,
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
              onPressed: _loadWithdrawals,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStatusFilter(),
        Expanded(
          child: _filteredWithdrawals.isEmpty
              ? const Center(child: Text('No withdrawal requests found'))
              : RefreshIndicator(
                  onRefresh: _loadWithdrawals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredWithdrawals.length,
                    itemBuilder: (context, index) {
                      final withdrawal = _filteredWithdrawals[index];
                      return _buildWithdrawalCard(withdrawal);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text('Filter by status: '),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filterStatus,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filterStatus = value;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(Transaction withdrawal) {
    final statusColor = _getStatusColor(withdrawal.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  withdrawal.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
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
                    withdrawal.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Amount: ${withdrawal.amount.toStringAsFixed(2)} ${withdrawal.currency}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.currency_bitcoin,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'BTC: ${formatBTCAmount(withdrawal.btcAmount)} BTC',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Payment Method: ${withdrawal.paymentMethod ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.send, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Destination: ${withdrawal.destination ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.numbers, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transaction ID: ${withdrawal.id}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Date: ${_formatDate(withdrawal.createdAt)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            if (withdrawal.adminNote != null &&
                withdrawal.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Admin Note: ${withdrawal.adminNote}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (withdrawal.status == 'Pending') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showStatusUpdateDialog(withdrawal, 'Completed'),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showStatusUpdateDialog(withdrawal, 'Rejected'),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(Transaction transaction, String newStatus) {
    final TextEditingController noteController = TextEditingController();
    noteController.text = transaction.adminNote ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${newStatus == 'Completed' ? 'Approve' : 'Reject'} Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${newStatus == 'Completed' ? 'approve' : 'reject'} '
              'this withdrawal request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Admin Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTransactionStatus(
                transaction.id,
                newStatus,
                noteController.text.isEmpty ? null : noteController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'Completed' ? Colors.green : Colors.red,
            ),
            child: Text(
              newStatus == 'Completed' ? 'Approve' : 'Reject',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String formatBTCAmount(double amount) {
    return amount.toStringAsFixed(18);
  }
}
