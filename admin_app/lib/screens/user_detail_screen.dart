import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? wallet;
  bool loadingWallet = false;
  String? walletError;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    setState(() {
      loadingWallet = true;
      walletError = null;
    });
    try {
      final userId =
          widget.user['userId'] ?? widget.user['id'] ?? widget.user['_id'];
      final walletData = await ApiService().fetchUserWallet(userId);
      if (walletData.isNotEmpty) {
        setState(() {
          wallet = walletData;
        });
      } else {
        setState(() {
          walletError = 'No wallet found';
        });
      }
    } catch (e) {
      setState(() {
        walletError = 'Error: $e';
      });
    } finally {
      setState(() {
        loadingWallet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final profilePicture =
        user['profilePicture'] ?? user['profileImage'] ?? user['avatar'];
    final imageUrl =
        (profilePicture != null && profilePicture.toString().isNotEmpty)
        ? ApiConfig.proxyImageBase +
              Uri.encodeComponent(profilePicture.toString())
        : null;
    final userEmail = user['userEmail'] ?? user['email'] ?? 'N/A';
    final userName = user['userName'] ?? user['name'] ?? 'N/A';
    final userId = user['_id'] ?? user['id'] ?? 'N/A';
    final balance = user['wallet']?['balance'] ?? user['balance'] ?? '0';
    final status = user['status'] ?? 'inactive';
    final fullName = user['fullName'] ?? '';
    final isActive = status == 'active';

    return Scaffold(
      appBar: AppBar(
        title: Text('User Details', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF1E293B),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.person,
                            color: isActive ? Colors.green : Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.person,
                        color: isActive ? Colors.green : Colors.red,
                        size: 40,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName.isNotEmpty ? fullName : userName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(userEmail, style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: GoogleFonts.poppins(
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Wallet Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Wallet Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (loadingWallet) Center(child: CircularProgressIndicator()),
            if (walletError != null)
              Text(walletError!, style: TextStyle(color: Colors.red)),
            if (wallet != null) ...[
              _buildDetailRow('Wallet ID', wallet!['walletId'] ?? ''),
              _buildDetailRow(
                'Balance',
                '${wallet!['balance']} ${wallet!['currency'] ?? ''}',
              ),
              _buildDetailRow(
                'Pending Balance',
                wallet!['pendingBalance'] ?? '',
              ),
              _buildDetailRow('Last Updated', wallet!['lastUpdated'] ?? ''),
              _buildDetailRow(
                'Transactions',
                (wallet!['transactions'] != null)
                    ? wallet!['transactions'].length.toString()
                    : '0',
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    (wallet!['transactions'] != null &&
                        wallet!['transactions'].isNotEmpty)
                    ? () => _showTransactions(context, wallet!['transactions'])
                    : null,
                child: Text('View Transactions'),
              ),
            ] else if (!loadingWallet && walletError == null) ...[
              _buildDetailRow('Wallet Balance', '$balance BTC'),
            ],
            const SizedBox(height: 24),
            // Details
            _buildDetailRow('User ID', userId),
            _buildDetailRow('Username', userName),
            _buildDetailRow('Full Name', fullName),
            _buildDetailRow('Email', userEmail),
            _buildDetailRow('Status', status),
            _buildDetailRow('Referral Code', user['referralCode'] ?? ''),
            _buildDetailRow('Total Rewards', user['totalRewardsClaimed'] ?? ''),
            _buildDetailRow('Today Rewards', user['todayRewardsClaimed'] ?? ''),
            _buildDetailRow('Created At', user['createdAt'] ?? ''),
            _buildDetailRow('Last Login', user['lastLogin']?.toString() ?? ''),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactions(BuildContext context, List<dynamic> transactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        // Local state for each transaction
        List<String> statuses = [
          'pending',
          'completed',
          'failed',
          'cancelled',
          'rejected',
        ];
        List<String> selectedStatuses = List.generate(
          transactions.length,
          (i) => transactions[i]['status'] ?? 'pending',
        );
        List<bool> isSaving = List.filled(transactions.length, false);
        List<bool> isSuccess = List.filled(transactions.length, false);
        List<bool> isError = List.filled(transactions.length, false);

        return StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, controller) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Transactions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return Card(
                              color: const Color(0xFF334155),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${tx['type'] ?? ''} - ${tx['amount'] ?? ''}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Status:',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        DropdownButton<String>(
                                          value: selectedStatuses[index],
                                          dropdownColor: Color(0xFF1E293B),
                                          style: TextStyle(color: Colors.white),
                                          items: statuses
                                              .map(
                                                (s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(
                                                    s,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: isSaving[index]
                                              ? null
                                              : (val) {
                                                  setModalState(() {
                                                    selectedStatuses[index] =
                                                        val!;
                                                    isSuccess[index] = false;
                                                    isError[index] = false;
                                                  });
                                                },
                                        ),
                                        const SizedBox(width: 8),
                                        if (isSaving[index])
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        if (isSuccess[index])
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                        if (isError[index])
                                          Icon(
                                            Icons.error,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.save,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Save Status',
                                          onPressed:
                                              (isSaving[index] ||
                                                  selectedStatuses[index] ==
                                                      (tx['status'] ?? ''))
                                              ? null
                                              : () async {
                                                  setModalState(() {
                                                    isSaving[index] = true;
                                                    isSuccess[index] = false;
                                                    isError[index] = false;
                                                  });
                                                  try {
                                                    final userId =
                                                        widget.user['userId'] ??
                                                        widget.user['id'] ??
                                                        widget.user['_id'];
                                                    final endpoint =
                                                        '/admin/users/$userId/wallet/transactions/${tx['transactionId'] ?? tx['_id'] ?? ''}/status';
                                                    final response =
                                                        await ApiService().put(
                                                          endpoint,
                                                          {
                                                            'status':
                                                                selectedStatuses[index],
                                                          },
                                                          auth: true,
                                                        );
                                                    if (response.statusCode ==
                                                        200) {
                                                      setModalState(() {
                                                        isSuccess[index] = true;
                                                        tx['status'] =
                                                            selectedStatuses[index];
                                                      });
                                                    } else {
                                                      setModalState(() {
                                                        isError[index] = true;
                                                      });
                                                    }
                                                  } catch (e) {
                                                    setModalState(() {
                                                      isError[index] = true;
                                                    });
                                                  } finally {
                                                    setModalState(() {
                                                      isSaving[index] = false;
                                                    });
                                                  }
                                                },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx['timestamp'] ?? ''}',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
