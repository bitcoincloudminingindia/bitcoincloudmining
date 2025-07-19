import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';
import '../providers/chart_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  int _selectedTimeRange = 0; // 0: Daily, 1: Weekly, 2: Monthly

  // Server status variables
  final Map<String, bool> _serverStatus = {
    'Mining Server': true,
    'Database': true,
    'API Gateway': true,
    'Payment Gateway': true,
    'AdMob Integration': true,
  };
  bool _isCheckingStatus = false;

  // Mining chart toggle state
  bool showEarning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);

      // Fetch users first (this will also update totalUserCount)
      await provider.fetchUsers();

      // Then fetch other data in parallel for better performance
      await Future.wait([
        provider.fetchTotalUserCount(),
        provider.fetchActiveUserCount(),
        provider.fetchTotalWithdrawals(),
        provider.fetchWithdrawalStats(),
        provider.fetchLatestWithdrawals(),
        provider.fetchDashboardAnalytics(),
        provider.fetchUserActiveHours(),
        provider.fetchReferralStats(),
        provider.fetchWalletTransactions(), // <-- yeh line add ki
        provider.fetchPlatformUserActivityHours(), // <-- yeh line add ki
      ]);

      _checkServerStatus();
      if (mounted) {
        _animationController.forward();
        _chartAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  // Server status checking
  Future<void> _checkServerStatus() async {
    if (_isCheckingStatus) return;

    if (!mounted) return;
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      // Simulate server status check
      await Future.delayed(const Duration(seconds: 2));

      // Random status changes for demo
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      if (!mounted) return;
      setState(() {
        _serverStatus['Mining Server'] = random > 10;
        _serverStatus['Database'] = random > 5;
        _serverStatus['API Gateway'] = random > 15;
        _serverStatus['Payment Gateway'] = random > 20;
        _serverStatus['AdMob Integration'] = random > 25;
      });
    } catch (e) {
      print('Server status check failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
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
            colors: [
              Color(0xFF0F172A), // Dark blue
              Color(0xFF1E293B), // Slate
              Color(0xFF334155), // Slate 700
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),
                const SizedBox(height: 32),

                // Overview Cards
                _buildOverviewCards(provider),
                const SizedBox(height: 32),

                // Charts Section
                _buildChartsSection(provider),
                const SizedBox(height: 32),

                // Server Status & Quick Actions
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 600;

                    if (isMobile) {
                      return Column(
                        children: [
                          _buildServerStatus(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: _buildServerStatus()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildQuickActions()),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Latest Withdrawals
                _buildLatestWithdrawals(provider),
                const SizedBox(height: 32),

                // User Activity Chart
                _buildUserActivityChart(provider),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Send notification action
        },
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.notifications, color: Colors.white),
        label: Text(
          'Send Notification',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Text(
                'Admin Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bitcoin Cloud Mining Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'System Online',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bitcoin Cloud Mining Analytics',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'System Online',
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOverviewCards(AdminApiProvider provider) {
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
              icon: Icons.people,
              title: 'Total Users',
              value: provider.totalUserCount.toString(),
              subtitle: 'Registered users',
              color: const Color(0xFF3B82F6),
              trend: provider.dashboardStats['userGrowth']?.toString() ?? '+0%',
              trendUp: (provider.dashboardStats['userGrowth'] ?? 0) >= 0,
            ),
            _buildOverviewCard(
              icon: Icons.person,
              title: 'Active Users',
              value: provider.activeUserCount.toString(),
              subtitle: 'Currently online',
              color: const Color(0xFF10B981),
              trend:
                  provider.dashboardStats['activeUserGrowth']?.toString() ??
                  '+0%',
              trendUp: (provider.dashboardStats['activeUserGrowth'] ?? 0) >= 0,
            ),
            _buildOverviewCard(
              icon: Icons.currency_bitcoin,
              title: 'Total Earnings',
              value:
                  '${provider.users.fold<double>(0.0, (sum, user) {
                    if (user is Map && user['wallet'] != null && user['wallet'] is Map && user['wallet']['balance'] != null) {
                      final bal = user['wallet']['balance'];
                      double balance = 0.0;
                      if (bal is num) {
                        balance = bal.toDouble();
                      } else if (bal is String) {
                        balance = double.tryParse(bal) ?? 0.0;
                      }
                      return sum + balance;
                    } else if (user is Map && user['wallet'] != null && user['wallet'] is num) {
                      return sum + (user['wallet'] as num).toDouble();
                    } else if (user is Map && user['wallet'] != null && user['wallet'] is String) {
                      return sum + (double.tryParse(user['wallet']) ?? 0.0);
                    } else if (user is Map && user['wallet'] == null) {
                      return sum;
                    } else if (user is! Map && user.wallet != null) {
                      final bal = user.wallet.balance;
                      double balance = 0.0;
                      if (bal is num) {
                        balance = bal.toDouble();
                      } else if (bal is String) {
                        balance = double.tryParse(bal) ?? 0.0;
                      }
                      return sum + balance;
                    } else {
                      return sum;
                    }
                  }).toStringAsFixed(18)} BTC',
              subtitle: 'Platform revenue',
              color: const Color(0xFFF59E0B),
              trend:
                  provider.dashboardStats['earningsGrowth']?.toString() ??
                  '+0%',
              trendUp: (provider.dashboardStats['earningsGrowth'] ?? 0) >= 0,
            ),
            _buildOverviewCard(
              icon: Icons.swap_horiz,
              title: 'Pending Withdrawals',
              value: provider.pendingWithdrawalsList.length.toString(),
              subtitle: 'Awaiting approval',
              color: const Color(0xFFEF4444),
              trend:
                  provider.withdrawalStats['pendingGrowth']?.toString() ??
                  '+0%',
              trendUp: (provider.withdrawalStats['pendingGrowth'] ?? 0) >= 0,
            ),
            _buildOverviewCard(
              icon: Icons.trending_up,
              title: 'Daily Mining',
              value:
                  '${provider.walletTransactions.where((tx) => tx['type'] == 'mining').fold<Decimal>(Decimal.zero, (sum, tx) {
                    final amountStr = tx['amount']?.toString() ?? '0';
                    final amount = Decimal.tryParse(amountStr) ?? Decimal.zero;
                    return sum + amount;
                  }).toStringAsFixed(18)} BTC',
              subtitle: 'Total mining earnings',
              color: const Color(0xFF8B5CF6),
              trend:
                  provider.dashboardStats['miningGrowth']?.toString() ?? '+0%',
              trendUp: (provider.dashboardStats['miningGrowth'] ?? 0) >= 0,
            ),
            _buildOverviewCard(
              icon: Icons.share,
              title: 'Referrals',
              value:
                  provider.referralStats['activeReferrers']?.toString() ?? '0',
              subtitle: 'Active referrers',
              color: const Color(0xFFEC4899),
              trend:
                  provider.referralStats['referralGrowth']?.toString() ?? '+0%',
              trendUp: (provider.referralStats['referralGrowth'] ?? 0) >= 0,
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      Container(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trendUp ? Icons.trending_up : Icons.trending_down,
                              color: trendUp ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trend,
                              style: GoogleFonts.poppins(
                                color: trendUp ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: title == 'Total Earnings' ? 15 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
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

  Widget _buildChartsSection(AdminApiProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimeRangeButton('Daily', 0),
                      _buildTimeRangeButton('Weekly', 1),
                      _buildTimeRangeButton('Monthly', 2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isMobile) ...[
              _buildRevenueChart(provider),
              const SizedBox(height: 24),
              _buildMiningChartContainer(provider),
              const SizedBox(height: 24),
              _buildUserActivityChart(provider),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildRevenueChart(provider)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMiningChartContainer(provider)),
                ],
              ),
              const SizedBox(height: 24),
              _buildUserActivityChart(provider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTimeRangeButton(String label, int value) {
    final isSelected = _selectedTimeRange == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeRange = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMiningChartContainer(AdminApiProvider provider) {
    final chartProvider = Provider.of<ChartProvider>(context);
    final miningChartData = chartProvider.getMiningChartData(
      provider.walletTransactions,
    );
    final labels = miningChartData['labels'] as List<String>;
    final counts = miningChartData['counts'] as List<int>;
    final earnings = miningChartData['earnings'] as List<double>;
    final earningsStr = miningChartData['earningsStr'] as List<String>;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mining Performance',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  const Text('Count', style: TextStyle(color: Colors.white70)),
                  Switch(
                    value: showEarning,
                    onChanged: (val) {
                      setState(() {
                        showEarning = val;
                      });
                    },
                  ),
                  const Text(
                    'Earning',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return Container();
                        return Text(
                          labels[idx],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      labels.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        showEarning ? earnings[i] : counts[i].toDouble(),
                      ),
                    ),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                    ),
                  ),
                ],
                // Tooltip for 18 decimal earning
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        int idx = spot.x.toInt();
                        if (showEarning) {
                          return LineTooltipItem(
                            '${earningsStr[idx]} BTC',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        } else {
                          return LineTooltipItem(
                            counts[idx].toString(),
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AdminApiProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Chart',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        provider.dashboardStats['revenueData']?.map<FlSpot>((
                          value,
                        ) {
                          return FlSpot(
                            value['x'].toDouble(),
                            value['y'].toDouble(),
                          );
                        }).toList() ??
                        [
                          const FlSpot(0, 3),
                          const FlSpot(2.6, 2),
                          const FlSpot(4.9, 5),
                          const FlSpot(6.8, 3.1),
                          const FlSpot(8, 4),
                          const FlSpot(9.5, 3),
                          const FlSpot(11, 4),
                        ],
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.dns, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Server Status',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_isCheckingStatus)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              else
                IconButton(
                  onPressed: _checkServerStatus,
                  icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                  tooltip: 'Refresh Status',
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatusItem(
            'Mining Server',
            _serverStatus['Mining Server'] ?? true,
          ),
          _buildStatusItem('Database', _serverStatus['Database'] ?? true),
          _buildStatusItem('API Gateway', _serverStatus['API Gateway'] ?? true),
          _buildStatusItem(
            'Payment Gateway',
            _serverStatus['Payment Gateway'] ?? true,
          ),
          _buildStatusItem(
            'AdMob Integration',
            _serverStatus['AdMob Integration'] ?? true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last checked: ${DateTime.now().toString().substring(11, 19)}',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String name, bool isOnline) {
    final status = isOnline ? 'Online' : 'Offline';
    final statusColor = isOnline ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: GoogleFonts.poppins(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            'Send Notification',
            Icons.notifications,
            Colors.blue,
            () => _showNotificationDialog(),
          ),
          _buildActionButton(
            'Export Data',
            Icons.download,
            Colors.green,
            () => _showExportDialog(),
          ),
          _buildActionButton(
            'System Settings',
            Icons.settings,
            Colors.orange,
            () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildActionButton(
            'View Logs',
            Icons.analytics,
            Colors.purple,
            () => _showLogsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Quick Action Methods
  void _showNotificationDialog() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Send Notification',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send a notification to all users',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter notification message...',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
          ],
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
            onPressed: () async {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final provider = Provider.of<AdminApiProvider>(
                  context,
                  listen: false,
                );
                await provider.sendNotification(messageController.text.trim());
                if (provider.error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification sent successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to send notification: ${provider.error}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(
              'Send',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Export Data',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose what data to export:',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              'Users Data',
              Icons.people,
              () => _exportUsers(),
            ),
            _buildExportOption(
              'Wallet Data',
              Icons.account_balance_wallet,
              () => _exportWallets(),
            ),
            _buildExportOption(
              'Transaction Data',
              Icons.receipt_long,
              () => _exportTransactions(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.poppins(color: Colors.white)),
                const Spacer(),
                const Icon(Icons.download, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportUsers() async {
    final provider = Provider.of<AdminApiProvider>(context, listen: false);
    try {
      await provider.exportUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Users data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export users data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportWallets() async {
    final provider = Provider.of<AdminApiProvider>(context, listen: false);
    try {
      await provider.exportWallets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export wallet data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportTransactions() async {
    final provider = Provider.of<AdminApiProvider>(context, listen: false);
    try {
      await provider.exportTransactions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export transaction data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'System Logs',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogEntry(
                          'INFO',
                          'Server started successfully',
                          '2024-01-15 10:30:00',
                        ),
                        _buildLogEntry(
                          'INFO',
                          'Database connection established',
                          '2024-01-15 10:30:05',
                        ),
                        _buildLogEntry(
                          'INFO',
                          'API Gateway initialized',
                          '2024-01-15 10:30:10',
                        ),
                        _buildLogEntry(
                          'WARN',
                          'High memory usage detected',
                          '2024-01-15 10:35:00',
                        ),
                        _buildLogEntry(
                          'INFO',
                          'Memory usage normalized',
                          '2024-01-15 10:36:00',
                        ),
                        _buildLogEntry(
                          'INFO',
                          'User login: admin@example.com',
                          '2024-01-15 10:40:00',
                        ),
                        _buildLogEntry(
                          'INFO',
                          'Data export completed',
                          '2024-01-15 10:45:00',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement refresh logs
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs refreshed'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(
              'Refresh',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String level, String message, String timestamp) {
    Color levelColor = Colors.green;
    if (level == 'WARN') levelColor = Colors.orange;
    if (level == 'ERROR') levelColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              level,
              style: GoogleFonts.poppins(
                color: levelColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),
          Text(
            timestamp,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestWithdrawals(AdminApiProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest Withdrawals',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: provider.latestWithdrawals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No withdrawals found',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.latestWithdrawals.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  itemBuilder: (context, index) {
                    final wd = provider.latestWithdrawals[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        wd['userEmail'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Amount: ${wd['amount'] ?? '-'} BTC',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: wd['status'] == 'completed'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (wd['status'] ?? '').toString().toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: wd['status'] == 'completed'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            wd['timestamp'] != null
                                ? wd['timestamp'].toString().substring(0, 16)
                                : '',
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserActivityChart(AdminApiProvider provider) {
    final hours = provider.platformUserActiveHours;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Activity (Hourly)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx % 2 != 0 || idx < 0 || idx > 23)
                          return Container();
                        return Text(
                          '$idx',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      24,
                      (i) => FlSpot(
                        i.toDouble(),
                        hours.length > i ? hours[i].toDouble() : 0.0,
                      ),
                    ),
                    isCurved: true,
                    color: const Color(0xFF06B6D4),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF06B6D4).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
