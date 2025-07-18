import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';

class ReferralAnalyticsScreen extends StatefulWidget {
  const ReferralAnalyticsScreen({super.key});

  @override
  State<ReferralAnalyticsScreen> createState() =>
      _ReferralAnalyticsScreenState();
}

class _ReferralAnalyticsScreenState extends State<ReferralAnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedPeriod = 'Weekly';
  String _selectedChartType = 'Rewards';

  // Referral settings fields
  final _settingsFormKey = GlobalKey<FormState>();
  double? _percent;
  int? _days;
  bool _settingsLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      await provider.fetchReferralStats();
      await provider.fetchReferralList();
      await provider.fetchReferralSettings();
      setState(() {
        _percent =
            provider.referralSettings['referralDailyPercent']?.toDouble() ??
            1.0;
        _days = provider.referralSettings['referralEarningDays']?.toInt() ?? 30;
      });
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildOverviewCards(),
                const SizedBox(height: 32),
                _buildChartSection(),
                const SizedBox(height: 32),
                _buildTopReferrers(),
                const SizedBox(height: 32),
                _buildRewardsHistory(),
                const SizedBox(height: 32),
                _buildActionsSection(),
                const SizedBox(height: 32),
                _buildReferralSettingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 22,
          ),
          padding: const EdgeInsets.only(right: 8),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Referrals & Rewards',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Track referral performance and manage rewards',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Consumer<AdminApiProvider>(
            builder: (context, provider, child) {
              final stats = provider.referralStats;
              return Container(
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
                    Icon(Icons.trending_up, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+${stats['weeklyGrowth']?.toStringAsFixed(1) ?? '0'}% This Week',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 700) crossAxisCount = 2;
        return Consumer<AdminApiProvider>(
          builder: (context, provider, child) {
            final stats = provider.referralStats;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: [
                _buildOverviewCard(
                  icon: Icons.share,
                  title: 'Total Referrals',
                  value: '${stats['totalReferrals'] ?? 0}',
                  subtitle: 'All time referrals',
                  color: const Color(0xFF3B82F6),
                  trend: '${stats['weeklyGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  trendUp: (stats['weeklyGrowth'] ?? 0) >= 0,
                ),
                _buildOverviewCard(
                  icon: Icons.currency_bitcoin,
                  title: 'Total Rewards',
                  value:
                      '${stats['totalRewards'] ?? '0.000000000000000000'} BTC',
                  subtitle: 'Distributed rewards',
                  color: const Color(0xFF10B981),
                  trend:
                      '${stats['monthlyGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  trendUp: (stats['monthlyGrowth'] ?? 0) >= 0,
                ),
                _buildOverviewCard(
                  icon: Icons.people,
                  title: 'Active Referrers',
                  value: '${stats['activeReferrers'] ?? 0}',
                  subtitle: 'This month',
                  color: const Color(0xFFF59E0B),
                  trend:
                      '${stats['referralGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  trendUp: (stats['referralGrowth'] ?? 0) >= 0,
                ),
                _buildOverviewCard(
                  icon: Icons.trending_up,
                  title: 'Conversion Rate',
                  value:
                      '${stats['conversionRate']?.toStringAsFixed(1) ?? '0'}%',
                  subtitle: 'Referral success',
                  color: const Color(0xFF8B5CF6),
                  trend: '${stats['weeklyGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  trendUp: (stats['weeklyGrowth'] ?? 0) >= 0,
                ),
              ],
            );
          },
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              trend,
                              style: GoogleFonts.poppins(
                                color: trendUp ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                _buildModernDropdown(
                  label: 'Type',
                  value: _selectedChartType,
                  items: const ['Rewards', 'Referrals'],
                  onChanged: (val) {
                    setState(() {
                      _selectedChartType = val!;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildModernDropdown(
                  label: 'Period',
                  value: _selectedPeriod,
                  items: const ['Weekly', 'Monthly'],
                  onChanged: (val) {
                    setState(() {
                      _selectedPeriod = val!;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: _buildReferralChart(),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white,
            size: 18,
          ),
          borderRadius: BorderRadius.circular(10),
          isDense: true,
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Text(item, style: GoogleFonts.poppins(fontSize: 12)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildReferralChart() {
    final provider = Provider.of<AdminApiProvider>(context);
    final chartData = provider.getReferralChartData(
      type: _selectedChartType,
      period: _selectedPeriod,
    );
    final labels = chartData['labels'] as List<String>;
    final values = chartData['values'] as List<double>;

    // Check if all values are zero or list is empty
    final bool isEmpty = values.isEmpty || values.every((v) => v == 0);
    if (isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16, color: Colors.white54),
        ),
      );
    }

    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );
    final maxY =
        (values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1) * 1.2;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5 == 0 ? 1 : maxY / 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                final label = (idx >= 0 && idx < labels.length)
                    ? labels[idx]
                    : '';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5 == 0 ? 1 : maxY / 5,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        minX: 0,
        maxX: (spots.isNotEmpty ? spots.length - 1 : 6).toDouble(),
        minY: 0,
        maxY: maxY > 0 ? maxY : 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF3B82F6),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopReferrers() {
    return Consumer<AdminApiProvider>(
      builder: (context, provider, child) {
        final referrals = provider.referralList;
        final displayCount = referrals.length > 5 ? 5 : referrals.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Top Referrers',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                FittedBox(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All (${referrals.length})',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
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
              child: referrals.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No referrals found',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayCount,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      itemBuilder: (context, index) {
                        return _buildReferrerItem(index + 1, referrals[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReferrerItem(int rank, Map<String, dynamic> item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: rank <= 3
              ? Colors.amber.withOpacity(0.1)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: GoogleFonts.poppins(
              color: rank <= 3 ? Colors.amber : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Text(
        item['name'] as String? ?? '',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item['referrals']} referrals',
        style: GoogleFonts.poppins(color: Colors.white70),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${item['earnings'] ?? '0'} BTC',
            style: GoogleFonts.poppins(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Total Earnings',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsHistory() {
    // TODO: Real rewards history API integration
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Rewards',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No rewards history found',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Trigger Payouts',
                'Manually trigger reward payouts',
                Icons.payment,
                Colors.green,
                () => _showPayoutDialog(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Export Data',
                'Export referral data to CSV/JSON',
                Icons.download,
                Colors.blue,
                () => _exportData(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Settings',
                'Configure referral settings',
                Icons.settings,
                Colors.orange,
                () => _openSettings(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Trigger Reward Payouts',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'This will process all pending reward payouts. Are you sure?',
          style: GoogleFonts.poppins(color: Colors.white70),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payouts triggered successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting referral data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening referral settings...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildReferralSettingsSection() {
    final provider = Provider.of<AdminApiProvider>(context);
    final currentPercent =
        provider.referralSettings['referralDailyPercent']?.toString() ?? '1.0';
    final currentDays =
        provider.referralSettings['referralEarningDays']?.toString() ?? '30';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Form(
        key: _settingsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referral Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _percent?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Referral Daily Earning Percentage (%)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (val) {
                final v = double.tryParse(val ?? '');
                if (v == null || v < 0 || v > 100) {
                  return 'Enter a valid percent (0-100)';
                }
                return null;
              },
              onChanged: (val) => _percent = double.tryParse(val),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Current: $currentPercent%',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _days?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Referral Earning Duration (days)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                final v = int.tryParse(val ?? '');
                if (v == null || v < 1 || v > 365) {
                  return 'Enter days (1-365)';
                }
                return null;
              },
              onChanged: (val) => _days = int.tryParse(val),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Current: $currentDays days',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _settingsLoading
                    ? null
                    : () async {
                        if (_settingsFormKey.currentState?.validate() ??
                            false) {
                          setState(() => _settingsLoading = true);
                          await provider.updateReferralSettings(
                            _percent ?? 1.0,
                            _days ?? 30,
                          );
                          setState(() => _settingsLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral settings updated!'),
                            ),
                          );
                        }
                      },
                child: _settingsLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
