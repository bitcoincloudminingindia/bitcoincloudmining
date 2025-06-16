import 'package:bitcoin_cloud_mining/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isWithdrawal = transaction.type.toLowerCase().contains('withdrawal');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (transaction.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.blue.shade700;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending';
        break;
      case 'completed':
        statusColor = Colors.blue.shade600;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'rejected':
        statusColor = Colors.blue.shade900;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.blue.shade800;
        statusIcon = Icons.info;
        statusText = transaction.status;
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(transaction.timestamp),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${isWithdrawal ? '-' : '+'}${transaction.amount.toStringAsFixed(18)} ${transaction.currency}',
                    style: TextStyle(
                      color: isWithdrawal
                          ? Colors.blue.shade900
                          : Colors.blue.shade600,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    transaction.type.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Details Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDetailRow('Transaction ID', transaction.transactionId),
                  if (transaction.withdrawalId != null)
                    _buildDetailRow('Withdrawal ID', transaction.withdrawalId!),
                  if (transaction.destination != null &&
                      transaction.destination != 'Wallet')
                    _buildDetailRow('Destination', transaction.destination!),
                  if (transaction.description.isNotEmpty)
                    _buildDetailRow('Description', transaction.description),
                  if (transaction.status.toLowerCase() == 'rejected' &&
                      transaction.adminNote != null)
                    _buildDetailRow('Rejection Reason', transaction.adminNote!),
                  _buildDetailRow(
                      'Date',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(transaction.timestamp)),
                  _buildDetailRow('Status', transaction.status.toUpperCase()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
