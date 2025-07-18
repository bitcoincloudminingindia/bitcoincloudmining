import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      provider.fetchWithdrawals();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminApiProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildStats(provider),
                _buildTabBar(),
                SizedBox(
                  height:
                      MediaQuery.of(context).size.height *
                      0.7, // TabBarView ko fixed height do
                  child: _buildTabBarView(provider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Container(
          margin: EdgeInsets.only(
            top: isMobile ? 12 : 24,
            bottom: isMobile ? 8 : 16,
          ),
          padding: EdgeInsets.all(isMobile ? 18 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.swap_horiz,
                color: Colors.blueAccent,
                size: isMobile ? 28 : 40,
              ),
              SizedBox(width: isMobile ? 12 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawal Requests',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 22 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage user withdrawal requests',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 13 : 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    onChanged: (value) =>
                        setState(() => _selectedFilter = value!),
                    style: GoogleFonts.poppins(color: Colors.white),
                    dropdownColor: const Color(0xFF1E293B),
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    items: ['All', 'High Priority', 'Low Amount', 'New Users']
                        .map(
                          (filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats(AdminApiProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      provider.pendingWithdrawalsList.length.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Approved',
                      provider.completedWithdrawals.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Rejected',
                      provider.rejectedWithdrawals.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Amount',
                      '${provider.totalWithdrawalAmount.toStringAsFixed(3)} BTC',
                      Icons.currency_bitcoin,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                provider.pendingWithdrawalsList.length.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Approved',
                provider.completedWithdrawals.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Rejected',
                provider.rejectedWithdrawals.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Amount',
                '${provider.totalWithdrawalAmount.toStringAsFixed(3)} BTC',
                Icons.currency_bitcoin,
                Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _animationController.value),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.13)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'label': 'Pending', 'icon': Icons.pending},
      {'label': 'Completed', 'icon': Icons.check_circle},
      {'label': 'Rejected', 'icon': Icons.cancel},
    ];
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tabs.length, (i) {
            final isSelected = _tabController.index == i;
            return GestureDetector(
              onTap: () => setState(() => _tabController.index = i),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 220),
                margin: EdgeInsets.symmetric(horizontal: 6),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.white24,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.18),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i]['label'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabBarView(AdminApiProvider provider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildWithdrawalList(provider, 'pending'),
        _buildWithdrawalList(provider, 'completed'),
        _buildWithdrawalList(provider, 'rejected'),
      ],
    );
  }

  Widget _buildWithdrawalList(AdminApiProvider provider, String status) {
    final withdrawals = provider.withdrawals
        .where((w) => w['status'] == status)
        .toList();

    if (withdrawals.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'pending'
                    ? Icons.pending
                    : status == 'completed'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: Colors.white54,
                size: 70,
              ),
              const SizedBox(height: 18),
              Text(
                'No ${status == 'completed' ? 'completed' : status} withdrawals',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        return _buildWithdrawalCard(withdrawals[index], status);
      },
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal, String status) {
    final amount = withdrawal['amount'] ?? '0';
    final userEmail = withdrawal['userEmail'] ?? 'N/A';
    final timestamp = withdrawal['timestamp'] ?? 'N/A';
    final id = withdrawal['id'] ?? 'N/A';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.10),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: statusColor.withOpacity(0.13)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          childrenPadding: const EdgeInsets.all(24),
          leading: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 26),
          ),
          title: Text(
            userEmail,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: $amount BTC',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'ID: $id',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (timestamp.toString().length >= 16
                    ? timestamp.toString().substring(0, 16)
                    : timestamp.toString()),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          children: [
            _buildWithdrawalDetails(withdrawal),
            const SizedBox(height: 16),
            if (status == 'pending') _buildPendingActions(withdrawal),
            if (status == 'completed') _buildCompletedActions(withdrawal),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalDetails(Map<String, dynamic> withdrawal) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Wallet Address',
                withdrawal['walletAddress'] ?? 'N/A',
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Amount',
                '${withdrawal['amount'] ?? '0'} BTC',
                Icons.currency_bitcoin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Request Date',
                withdrawal['timestamp']?.toString().substring(0, 16) ?? 'N/A',
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'User ID',
                withdrawal['userId'] ?? 'N/A',
                Icons.person,
              ),
            ),
          ],
        ),
        if (withdrawal['notes'] != null) ...[
          const SizedBox(height: 16),
          _buildDetailItem('Notes', withdrawal['notes'], Icons.note),
        ],
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(Map<String, dynamic> withdrawal) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Complete',
            Icons.check_circle,
            Colors.green,
            () => _showApproveDialog(withdrawal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Reject',
            Icons.cancel,
            Colors.red,
            () => _showRejectDialog(withdrawal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Pending',
            Icons.pause,
            Colors.orange,
            () => _holdWithdrawal(withdrawal),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedActions(Map<String, dynamic> withdrawal) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Mark as Paid',
            Icons.payment,
            Colors.blue,
            () => _markAsPaid(withdrawal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'View Details',
            Icons.visibility,
            Colors.grey,
            () => _viewDetails(withdrawal),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> withdrawal) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Complete Withdrawal',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to complete this withdrawal?',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  labelStyle: GoogleFonts.poppins(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeWithdrawal(withdrawal, notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              'Complete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> withdrawal) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Reject Withdrawal',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please provide a reason for rejection:',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: GoogleFonts.poppins(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectWithdrawal(withdrawal, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _completeWithdrawal(Map<String, dynamic> withdrawal, String notes) {
    // TODO: Implement completion logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Withdrawal completed successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectWithdrawal(Map<String, dynamic> withdrawal, String reason) {
    // TODO: Implement rejection logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Withdrawal rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _holdWithdrawal(Map<String, dynamic> withdrawal) {
    // TODO: Implement hold logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Withdrawal put on hold'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _markAsPaid(Map<String, dynamic> withdrawal) {
    // TODO: Implement mark as paid logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Withdrawal marked as paid'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> withdrawal) {
    // TODO: Navigate to detailed view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing withdrawal details'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}
