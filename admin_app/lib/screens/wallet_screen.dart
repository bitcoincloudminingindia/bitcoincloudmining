import 'package:bitcoin_cloud_mining_admin/providers/chart_provider.dart';
import 'package:bitcoin_cloud_mining_admin/providers/wallet_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';
import '../utils/safe_overflow_fix.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedTimeRange = '7D';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Chart filter ke liye
  String _selectedChartFilter = 'Today'; // Today, Weekly, Monthly, Yearly

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      if (!mounted) return;
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      await provider.fetchWalletData();
      await provider.fetchWalletTransactions();
      await provider.fetchMarketRates();
      // ChartProvider me sabhi users ke transactions set karo
      if (!mounted) return;
      final chartProvider = Provider.of<ChartProvider>(context, listen: false);
      chartProvider.setAllTransactions(
        List<Map<String, dynamic>>.from(provider.walletTransactions),
      );
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Consumer<ChartProvider>(
                    builder: (context, chartProvider, child) {
                      final transactions = chartProvider.transactions;
                      final filteredTxs = _getFilteredTransactions(
                        transactions,
                      );
                      final filteredCount = filteredTxs.length;
                      final filteredAmount = filteredTxs.fold<double>(
                        0,
                        (sum, tx) =>
                            sum +
                            (double.tryParse(tx['amount'].toString()) ?? 0),
                      );
                      // Previous period amount calculation
                      final previousPeriodAmount = _getPreviousPeriodAmount(
                        chartProvider.transactions,
                      );
                      double growth = 0;
                      if (previousPeriodAmount > 0) {
                        growth =
                            ((filteredAmount - previousPeriodAmount) /
                                previousPeriodAmount) *
                            100;
                      } else if (filteredAmount > 0) {
                        growth = 100;
                      } else {
                        growth = 0;
                      }
                      return _buildWalletOverview(
                        provider,
                        filteredCount,
                        filteredAmount,
                        growth,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Consumer<ChartProvider>(
                    builder: (context, chartProvider, child) {
                      final transactions = chartProvider.transactions;
                      final filteredTxs = _getFilteredTransactions(
                        transactions,
                      );
                      final Map<String, double> dailyVolume = {};
                      for (var tx in filteredTxs) {
                        final date =
                            tx['timestamp']?.toString().substring(0, 10) ?? '';
                        final amount =
                            double.tryParse(tx['amount'].toString()) ?? 0;
                        dailyVolume[date] = (dailyVolume[date] ?? 0) + amount;
                      }
                      final sortedDates = dailyVolume.keys.toList()..sort();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildChartFilterButton('Today'),
                              const SizedBox(width: 8),
                              _buildChartFilterButton('Weekly'),
                              const SizedBox(width: 8),
                              _buildChartFilterButton('Monthly'),
                              const SizedBox(width: 8),
                              _buildChartFilterButton('Yearly'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionChart(
                            sortedDates: sortedDates,
                            dailyVolume: dailyVolume,
                            totalVolume: filteredTxs.fold<double>(
                              0,
                              (sum, tx) =>
                                  sum +
                                  (double.tryParse(tx['amount'].toString()) ??
                                      0),
                            ),
                            totalCount: filteredTxs.length,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildRecentTransactions(provider),
                  const SizedBox(height: 32),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 32),
                  _buildWalletList(provider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Management',
                style: GoogleFonts.poppins(
                  fontSize: 24, // पहले 32 था, अब 24
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor user wallets and transactions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Wallets',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletOverview(
    AdminApiProvider provider,
    int filteredCount,
    double filteredAmount,
    double growth,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double childAspectRatio = 1.2;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.0;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.1;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: constraints.maxWidth < 600 ? 12 : 20,
          mainAxisSpacing: constraints.maxWidth < 600 ? 12 : 20,
          childAspectRatio: childAspectRatio,
          children: [
            _buildOverviewCard(
              icon: Icons.account_balance_wallet,
              title: 'Total Wallets',
              value: '${provider.totalWallets}',
              subtitle: 'Active wallets',
              color: const Color(0xFF3B82F6),
              trend: '+8%',
              trendUp: true,
            ),
            _buildOverviewCard(
              icon: Icons.currency_bitcoin,
              title: 'Total Balance',
              value: '${filteredAmount.toStringAsFixed(18)} BTC',
              subtitle: 'Combined balance',
              color: const Color(0xFF10B981),
              trend: '+12%',
              trendUp: true,
            ),
            _buildOverviewCard(
              icon: Icons.trending_up,
              title: 'Daily Growth',
              value: '${growth.toStringAsFixed(2)}%',
              subtitle: 'Growth rate',
              color: const Color(0xFFF59E0B),
              trend: growth >= 0
                  ? '+${growth.toStringAsFixed(1)}%'
                  : '${growth.toStringAsFixed(1)}%',
              trendUp: growth >= 0,
            ),
            _buildOverviewCard(
              icon: Icons.receipt_long,
              title: 'Transactions',
              value: '$filteredCount',
              subtitle: 'Total transactions',
              color: const Color(0xFF8B5CF6),
              trend: '+15%',
              trendUp: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animationController.value),
          child: SafeOverflowFix.container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SafeOverflowFix.column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SafeOverflowFix.row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SafeOverflowFix.container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      Flexible(
                        child: SafeOverflowFix.container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: trendUp
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SafeOverflowFix.row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trendUp
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: trendUp ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: SafeOverflowFix.text(
                                  trend,
                                  style: GoogleFonts.poppins(
                                    color: trendUp ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SafeOverflowFix.text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14, // chhota size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SafeOverflowFix.text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SafeOverflowFix.text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    final provider = Provider.of<AdminApiProvider>(context);
    return SafeOverflowFix.row(
      children: [
        Expanded(
          child: SafeOverflowFix.container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}), // search realtime
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search wallets by user...',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterDropdown(
          'Filter',
          _selectedFilter,
          ['All', 'High Balance', 'Low Balance', 'Active', 'Inactive'],
          (value) {
            setState(() => _selectedFilter = value);
          },
        ),
        const SizedBox(width: 12),
        _buildFilterDropdown(
          'Time',
          _selectedTimeRange,
          ['1D', '7D', '30D', '90D'],
          (value) {
            setState(() => _selectedTimeRange = value);
          },
        ),
        const SizedBox(width: 12),
        // Currency dropdown
        SafeOverflowFix.container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: provider.selectedCurrency,
            onChanged: (newValue) {
              if (newValue != null) {
                provider.setSelectedCurrency(newValue);
              }
            },
            style: GoogleFonts.poppins(color: Colors.white),
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            items: provider.marketRates.keys.map((option) {
              return DropdownMenuItem(
                value: option,
                child: SafeOverflowFix.text(option),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return SafeOverflowFix.container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: (newValue) => onChanged(newValue!),
        style: GoogleFonts.poppins(color: Colors.white),
        dropdownColor: const Color(0xFF1E293B),
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: SafeOverflowFix.text(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWalletList(AdminApiProvider provider) {
    List<Map<String, dynamic>> wallets = List<Map<String, dynamic>>.from(
      provider.wallets,
    );
    // Search filter
    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isNotEmpty) {
      wallets = wallets.where((wallet) {
        final userId = (wallet['userId'] ?? wallet['id'] ?? '')
            .toString()
            .toLowerCase();
        final email = (wallet['userEmail'] ?? wallet['email'] ?? '')
            .toString()
            .toLowerCase();
        return userId.contains(searchText) || email.contains(searchText);
      }).toList();
    }
    // High/Low/Active/Inactive filter
    if (_selectedFilter == 'High Balance') {
      wallets.sort((a, b) {
        final aBal = double.tryParse(a['balance']?.toString() ?? '0') ?? 0;
        final bBal = double.tryParse(b['balance']?.toString() ?? '0') ?? 0;
        return bBal.compareTo(aBal);
      });
      wallets = wallets.take(10).toList(); // Top 10 high balance
    } else if (_selectedFilter == 'Low Balance') {
      wallets.sort((a, b) {
        final aBal = double.tryParse(a['balance']?.toString() ?? '0') ?? 0;
        final bBal = double.tryParse(b['balance']?.toString() ?? '0') ?? 0;
        return aBal.compareTo(bBal);
      });
      wallets = wallets.take(10).toList(); // Top 10 low balance
    } else if (_selectedFilter == 'Active') {
      wallets = wallets
          .where(
            (w) => (w['status'] ?? '').toString().toLowerCase() == 'active',
          )
          .toList();
    } else if (_selectedFilter == 'Inactive') {
      wallets = wallets
          .where(
            (w) => (w['status'] ?? '').toString().toLowerCase() != 'active',
          )
          .toList();
    }
    if (wallets.isEmpty) {
      return Center(
        child: SafeOverflowFix.column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            SafeOverflowFix.text(
              'No wallets found',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }
    return SafeOverflowFix.column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeOverflowFix.text(
          'User Wallets',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: wallets.length,
          itemBuilder: (context, index) {
            return _buildWalletCard(wallets[index]);
          },
        ),
      ],
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet) {
    final provider = Provider.of<AdminApiProvider>(context, listen: false);
    final userId = wallet['userId'] ?? wallet['id'] ?? '';
    final balanceStr = wallet['balance']?.toString() ?? '0';
    final btcBalance = double.tryParse(balanceStr) ?? 0.0;
    final selectedCurrency = provider.selectedCurrency;
    final marketRates = provider.marketRates;
    final localRate = marketRates[selectedCurrency] ?? 1.0;
    final localBalance = btcBalance * localRate;
    final transactionCount = (wallet['transactions'] as List?)?.length ?? 0;
    final isActive = wallet['status'] == 'active';

    return SafeOverflowFix.container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.all(24),
        leading: SafeOverflowFix.container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isActive
                ? Icons.account_balance_wallet
                : Icons.account_balance_wallet_outlined,
            color: isActive ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: SafeOverflowFix.column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeOverflowFix.row(
              children: [
                Expanded(
                  child: SafeOverflowFix.text(
                    'User ID: $userId',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                  tooltip: 'Copy User ID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: userId.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: SafeOverflowFix.text('User ID copied!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        subtitle: SafeOverflowFix.column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeOverflowFix.text(
              'BTC: $balanceStr BTC',
              style: GoogleFonts.poppins(
                color: Colors.green, // hamesha green
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
              softWrap: true,
            ),
            SafeOverflowFix.text(
              'Local: ${localBalance.toStringAsFixed(18)} $selectedCurrency',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: SafeOverflowFix.column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeOverflowFix.text(
              '$transactionCount txns',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        children: [
          _buildWalletDetails(wallet),
          const SizedBox(height: 16),
          _buildWalletActions(wallet),
        ],
      ),
    );
  }

  Widget _buildWalletDetails(Map<String, dynamic> wallet) {
    return SafeOverflowFix.column(
      children: [
        SafeOverflowFix.row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Current Balance',
                '${wallet['balance']?.toString() ?? '0'} BTC',
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Pending Balance',
                '${wallet['pendingBalance']?.toString() ?? '0'} BTC',
                Icons.hourglass_bottom,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SafeOverflowFix.row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Currency',
                wallet['currency']?.toString() ?? 'BTC',
                Icons.currency_bitcoin,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Last Updated',
                wallet['lastUpdated']?.toString().substring(0, 16) ?? 'N/A',
                Icons.access_time,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SafeOverflowFix.row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Transaction Count',
                '${(wallet['transactions'] as List?)?.length ?? 0}',
                Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Wallet ID',
                wallet['walletId']?.toString() ?? 'N/A',
                Icons.qr_code,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return SafeOverflowFix.container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SafeOverflowFix.column(
        children: [
          Icon(icon, color: Colors.white54, size: 12),
          const SizedBox(height: 8),
          SafeOverflowFix.text(
            label == 'Current Balance' ||
                    label == 'Total Earned' ||
                    label == 'Total Spent'
                ? value.replaceAll(
                    RegExp(r'\.0+$'),
                    '',
                  ) // agar trailing zeroes ho to hatao
                : value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.left,
            softWrap: true,
            // overflow: TextOverflow.ellipsis, // Hata diya
          ),
          SafeOverflowFix.text(
            label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletActions(Map<String, dynamic> wallet) {
    return SafeOverflowFix.row(
      children: [
        Expanded(
          child: _buildActionButton(
            'View Transactions',
            Icons.history,
            Colors.blue,
            () => _viewTransactions(wallet),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Add Balance',
            Icons.add,
            Colors.green,
            () => _addBalance(wallet),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Freeze Wallet',
            Icons.block,
            Colors.red,
            () => _freezeWallet(wallet),
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SafeOverflowFix.container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: SafeOverflowFix.column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              SafeOverflowFix.text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionChart({
    required List<String> sortedDates,
    required Map<String, double> dailyVolume,
    required double totalVolume,
    required int totalCount,
  }) {
    return SafeOverflowFix.column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeOverflowFix.text(
          'Transaction Volume',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        SafeOverflowFix.container(
          height: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: dailyVolume.values.isNotEmpty
                  ? (dailyVolume.values.reduce((a, b) => a > b ? a : b) * 1.2)
                  : 1,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    final date = idx < sortedDates.length
                        ? sortedDates[idx]
                        : '';
                    final amount = rod.toY;
                    return BarTooltipItem(
                      '$date\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Amount: ${amount.toStringAsFixed(18)}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final idx = value.toInt();
                      if (idx < sortedDates.length) {
                        return SafeOverflowFix.text(
                          sortedDates[idx],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        );
                      }
                      return SafeOverflowFix.text('');
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              barGroups: [
                for (int i = 0; i < sortedDates.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyVolume[sortedDates[i]] ?? 0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SafeOverflowFix.text(
          'Total Transaction Volume: ${totalVolume.toStringAsFixed(18)}',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        SafeOverflowFix.text(
          'Total Transactions: $totalCount',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(AdminApiProvider provider) {
    final transactions = provider.walletTransactions;
    final recentTransactions = transactions.take(10).toList(); // Sirf 10 latest
    return SafeOverflowFix.column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeOverflowFix.row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SafeOverflowFix.text(
              'Recent Transactions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: SafeOverflowFix.text(
                'View All',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SafeOverflowFix.container(
          height: 320, // Box ki height chhoti kar di
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
            itemBuilder: (context, index) {
              return _buildTransactionItem(recentTransactions[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    final amountValue = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    final isPositive = amountValue >= 0;
    final isCompleted = item['status'] == 'Completed';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      leading: SafeOverflowFix.container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPositive
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isPositive ? Icons.add : Icons.remove,
          color: isPositive ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: SafeOverflowFix.text(
        item['type'] ?? '',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: SafeOverflowFix.text(
        'Txn ID: ${item['transactionId'] ?? item['id'] ?? ''}',
        style: GoogleFonts.poppins(color: Colors.white70),
      ),
      trailing: SizedBox(
        width: 180,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SafeOverflowFix.column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SafeOverflowFix.text(
                item['amount']?.toString() ?? '0', // backend जैसा amount दिखाएं
                style: GoogleFonts.poppins(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              SafeOverflowFix.container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SafeOverflowFix.text(
                  item['status'] ?? '',
                  style: GoogleFonts.poppins(
                    color: isCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              SafeOverflowFix.text(
                item['timestamp'] ?? '',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action methods
  void _viewTransactions(Map<String, dynamic> wallet) async {
    final userId = wallet['userId'] ?? wallet['id'] ?? '';
    final provider = Provider.of<WalletProvider>(context, listen: false);
    // Agar provider.walletData ka userId wahi hai, to dobara load mat karo
    if (provider.walletData?['userId'] != userId) {
      await provider.loadWalletData(userId);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserTransactionsScreen(userId: userId),
      ),
    );
  }

  void _addBalance(Map<String, dynamic> wallet) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: SafeOverflowFix.text(
          'Add Balance',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SafeOverflowFix.column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeOverflowFix.text(
              'Add balance to ${wallet['userEmail']}',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (BTC)',
                labelStyle: GoogleFonts.poppins(color: Colors.white54),
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: SafeOverflowFix.text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              if (amount == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SafeOverflowFix.text(
                      'Please enter a valid amount',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final userId = wallet['userId'] ?? wallet['id'] ?? '';
              final provider = Provider.of<WalletProvider>(
                context,
                listen: false,
              );
              final success = await provider.apiService.adjustWallet(
                userId: userId,
                amount: amount,
                type: 'credit',
                note: 'Admin adjustment',
              );
              Navigator.pop(context);
              if (success) {
                provider.refresh(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SafeOverflowFix.text('Balance added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SafeOverflowFix.text('Failed to add balance'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: SafeOverflowFix.text(
              'Add',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _freezeWallet(Map<String, dynamic> wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: SafeOverflowFix.text(
          'Freeze Wallet',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SafeOverflowFix.text(
          'Are you sure you want to freeze ${wallet['userEmail']}\'s wallet?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: SafeOverflowFix.text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = wallet['userId'] ?? wallet['id'] ?? '';
              final provider = Provider.of<WalletProvider>(
                context,
                listen: false,
              );
              // Yahan freeze wallet ka API call lagana hai, yadi available ho
              final success = await provider.apiService.post(
                '/admin/users/$userId/wallet/freeze',
                {},
                auth: true,
              );
              Navigator.pop(context);
              if (success.statusCode == 200) {
                provider.refresh(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SafeOverflowFix.text('Wallet frozen successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SafeOverflowFix.text('Failed to freeze wallet'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: SafeOverflowFix.text(
              'Freeze',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Chart filter button widget
  Widget _buildChartFilterButton(String label) {
    final isSelected = _selectedChartFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartFilter = label;
        });
      },
      child: SafeOverflowFix.container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: SafeOverflowFix.text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Chart data filter logic
  List<Map<String, dynamic>> _getFilteredTransactions(
    List<Map<String, dynamic>> txs,
  ) {
    final now = DateTime.now();
    if (_selectedChartFilter == 'Today') {
      return txs.where((tx) {
        final date = DateTime.tryParse(tx['timestamp']?.toString() ?? '');
        return date != null &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    } else if (_selectedChartFilter == 'Weekly') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return txs.where((tx) {
        final date = DateTime.tryParse(tx['timestamp']?.toString() ?? '');
        return date != null && date.isAfter(weekAgo);
      }).toList();
    } else if (_selectedChartFilter == 'Monthly') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return txs.where((tx) {
        final date = DateTime.tryParse(tx['timestamp']?.toString() ?? '');
        return date != null && date.isAfter(monthAgo);
      }).toList();
    } else if (_selectedChartFilter == 'Yearly') {
      final yearAgo = now.subtract(const Duration(days: 365));
      return txs.where((tx) {
        final date = DateTime.tryParse(tx['timestamp']?.toString() ?? '');
        return date != null && date.isAfter(yearAgo);
      }).toList();
    }
    return txs;
  }

  // Helper function for previous period amount
  double _getPreviousPeriodAmount(List<Map<String, dynamic>> txs) {
    final now = DateTime.now();
    DateTime start, end;
    if (_selectedChartFilter == 'Today') {
      start = now.subtract(const Duration(days: 1));
      end = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(seconds: 1));
    } else if (_selectedChartFilter == 'Weekly') {
      start = now.subtract(const Duration(days: 14));
      end = now.subtract(const Duration(days: 7));
    } else if (_selectedChartFilter == 'Monthly') {
      start = now.subtract(const Duration(days: 60));
      end = now.subtract(const Duration(days: 30));
    } else if (_selectedChartFilter == 'Yearly') {
      start = now.subtract(const Duration(days: 730));
      end = now.subtract(const Duration(days: 365));
    } else {
      return 0;
    }
    return txs
        .where((tx) {
          final date = DateTime.tryParse(tx['timestamp']?.toString() ?? '');
          return date != null && date.isAfter(start) && date.isBefore(end);
        })
        .fold<double>(
          0,
          (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0),
        );
  }
}

// Naya screen: UserTransactionsScreen
class UserTransactionsScreen extends StatelessWidget {
  final String userId;
  const UserTransactionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SafeOverflowFix.text('Transactions: $userId'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          final txs = provider.transactions;
          if (txs.isEmpty) {
            return Center(
              child: SafeOverflowFix.text(
                'No transactions found',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            itemCount: txs.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white24, height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final amount =
                  double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
              final isPositive = amount >= 0;
              return ListTile(
                leading: Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                title: SafeOverflowFix.text(
                  'Txn ID: ${tx['transactionId'] ?? tx['id'] ?? ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: SafeOverflowFix.text(
                  'Type: ${tx['type'] ?? ''}\nStatus: ${tx['status'] ?? ''}',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                trailing: SafeOverflowFix.column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SafeOverflowFix.text(
                      amount.toStringAsFixed(18),
                      style: GoogleFonts.poppins(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SafeOverflowFix.text(
                      tx['timestamp']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFF1E293B),
    );
  }
}
