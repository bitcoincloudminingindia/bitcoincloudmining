import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';

class ReferralManagementScreen extends StatefulWidget {
  const ReferralManagementScreen({super.key});

  @override
  State<ReferralManagementScreen> createState() =>
      _ReferralManagementScreenState();
}

class _ReferralManagementScreenState extends State<ReferralManagementScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      provider.fetchReferralList();
    });
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
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              Expanded(child: _buildReferralList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  'Referral Management',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and track all referral activities',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
          ),
          Consumer<AdminApiProvider>(
            builder: (context, provider, child) {
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
                    Icon(Icons.people, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.referralList.length} Referrers',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search referrers...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.poppins(color: Colors.white),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralList() {
    return Consumer<AdminApiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final referrals = provider.referralList;
        if (referrals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  'No referrals found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Referrals will appear here once users start referring others',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filter referrals based on search and status
        final filteredReferrals = referrals.where((referral) {
          final name = (referral['name'] ?? '').toString().toLowerCase();
          final email = (referral['email'] ?? '').toString().toLowerCase();
          final searchMatch =
              name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());

          final statusMatch =
              _statusFilter == 'all' ||
              (referral['status'] ?? '').toString() == _statusFilter;

          return searchMatch && statusMatch;
        }).toList();

        // Pagination
        final totalPages = (filteredReferrals.length / _itemsPerPage).ceil();
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;
        final paginatedReferrals = filteredReferrals.sublist(
          startIndex,
          endIndex > filteredReferrals.length
              ? filteredReferrals.length
              : endIndex,
        );

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: paginatedReferrals.length,
                itemBuilder: (context, index) {
                  return _buildReferralCard(paginatedReferrals[index]);
                },
              ),
            ),
            if (totalPages > 1) _buildPagination(totalPages),
          ],
        );
      },
    );
  }

  Widget _buildReferralCard(Map<String, dynamic> referral) {
    final name = referral['name'] ?? 'Unknown User';
    final email = referral['email'] ?? 'No Email';
    final referrals = referral['referrals'] ?? 0;
    final earnings = referral['earnings'] ?? '0';
    final pendingEarnings = referral['pendingEarnings'] ?? '0';
    final status = referral['status'] ?? 'active';
    final lastReferral = referral['lastReferral'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Referrals',
                    referrals.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Earnings',
                    '$earnings BTC',
                    Icons.currency_bitcoin,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    '$pendingEarnings BTC',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (lastReferral != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Last referral: ${_formatDate(lastReferral)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewReferralDetails(referral),
                    icon: Icon(Icons.visibility, color: Colors.blue),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(color: Colors.blue),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageReferral(referral),
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text(
                      'Manage',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 1 ? Colors.white : Colors.white38,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Page $_currentPage of $totalPages',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < totalPages ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _viewReferralDetails(Map<String, dynamic> referral) {
    // TODO: Implement referral details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${referral['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _manageReferral(Map<String, dynamic> referral) {
    // TODO: Implement referral management
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Managing referral for ${referral['name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
