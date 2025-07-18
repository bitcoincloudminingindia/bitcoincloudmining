import 'package:bitcoin_cloud_mining_admin/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class UserTransactionsScreen extends StatefulWidget {
  final String userId;
  const UserTransactionsScreen({super.key, required this.userId});

  @override
  State<UserTransactionsScreen> createState() => _UserTransactionsScreenState();
}

class _UserTransactionsScreenState extends State<UserTransactionsScreen> {
  static const int pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions: ${widget.userId}'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          final txs = provider.transactions;
          final total = txs.length;
          final paginatedTxs = txs
              .skip(_currentPage * pageSize)
              .take(pageSize)
              .toList();

          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: paginatedTxs.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white24, height: 1),
                  itemBuilder: (context, index) {
                    final tx = paginatedTxs[index];
                    final amount =
                        double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
                    final isPositive = amount >= 0;
                    final isCompleted = tx['status'] == 'completed';
                    return Card(
                      color: const Color(0xFF232A3E),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isPositive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          child: Icon(
                            isPositive
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          'Txn ID: ${tx['transactionId'] ?? tx['id'] ?? ''}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type: ${tx['type'] ?? ''}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tx['status'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  color: Colors.white24,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tx['timestamp']?.toString() ?? '',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amount.toStringAsFixed(8),
                              style: GoogleFonts.poppins(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              isPositive ? Icons.south_west : Icons.north_east,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if ((_currentPage + 1) * pageSize < total)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _isLoadingMore
                        ? null
                        : () {
                            setState(() {
                              _isLoadingMore = true;
                              _currentPage++;
                            });
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                setState(() {
                                  _isLoadingMore = false;
                                });
                              },
                            );
                          },
                    icon: const Icon(Icons.expand_more),
                    label: _isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Load More'),
                  ),
                ),
            ],
          );
        },
      ),
      backgroundColor: const Color(0xFF1E293B),
    );
  }
}
