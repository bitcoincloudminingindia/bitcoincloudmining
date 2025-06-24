import 'dart:async';

import 'package:bitcoin_cloud_mining/constants/color_constants.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
import 'package:bitcoin_cloud_mining/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  Map<String, dynamic> _referralStats = {};
  List<Map<String, dynamic>> _referredUsers = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastClaimDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load referral statistics
      final statsResult = await ApiService.get('/api/referral/list')
          .timeout(const Duration(seconds: 10));

      // Load referred users
      final usersResult = await ApiService.get('/api/referral/earnings')
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (statsResult['success'] == true && usersResult['success'] == true) {
        setState(() {
          // Handle referral stats
          final statsData = statsResult['data'] ?? {};
          final statistics = statsData['statistics'] ?? {};

          _referralStats = {
            'referralCode': statsData['referralCode']?.toString() ?? '',
            'referralId': statsData['referralId']?.toString() ?? '',
            'totalEarnings': (statistics['totalEarnings'] ?? 0).toString(),
            'pendingEarnings': (statistics['pendingEarnings'] ?? 0).toString(),
            'claimedEarnings': (statistics['claimedEarnings'] ?? 0).toString(),
            'lastClaimDate': statistics['lastClaimDate'],
          };

          // Handle referred users
          final usersData = usersResult['data'] ?? {};
          final referredList = usersData['referrals'] ?? [];

          // Sum all pendingEarnings from referred users
          double totalPendingEarnings = 0;
          _referredUsers = referredList.map<Map<String, dynamic>>((user) {
            final pending =
                double.tryParse(user['pendingEarnings']?.toString() ?? '0') ??
                    0;
            totalPendingEarnings += pending;
            return {
              'fullName': user['username']?.toString() ?? 'Unknown User',
              'userName': user['email']?.toString() ?? '',
              'walletBalance':
                  (user['walletBalance'] ?? '0.000000000000000000').toString(),
              'isActive':
                  true, // You can add logic for active status if available
              'joinedAt': user['joinedAt']?.toString() ??
                  DateTime.now().toIso8601String(),
            };
          }).toList();

          // Use summed pending earnings for display
          _referralStats['pendingEarnings'] =
              totalPendingEarnings.toStringAsFixed(18);

          _lastClaimDate = statistics['lastClaimDate'] != null
              ? DateTime.tryParse(statistics['lastClaimDate'])
              : null;

          _error = null;
        });
      } else {
        throw Exception(statsResult['message'] ?? 'Failed to load data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load referral data: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareReferralCode() async {
    final referralCode = _referralStats['referralCode'] ?? '';
    final message =
        'Join me on Bitcoin Cloud Mining! Use my referral code: $referralCode';
    try {
      await Share.share(
        message,
        subject: 'Bitcoin Cloud Mining Referral',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyReferralCode() async {
    final referralCode = _referralStats['referralCode'] ?? '';
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _claimEarnings() async {
    // Confirmation dialog before claim
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Claim'),
        content: const Text(
            'You can only claim referral earnings once every 24 hours or after 1 AM daily. Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Check eligibility before sending claim request
    final now = DateTime.now();
    if (_lastClaimDate != null) {
      final next1AM = DateTime(now.year, now.month, now.day, 1);
      final after1AM = now.isAfter(next1AM);
      final hoursSinceLastClaim = now.difference(_lastClaimDate!).inHours;
      if (!after1AM && hoursSinceLastClaim < 24) {
        final nextClaim = _lastClaimDate!.add(const Duration(hours: 24));
        final nextClaimStr =
            '${nextClaim.hour.toString().padLeft(2, '0')}:${nextClaim.minute.toString().padLeft(2, '0')} on ${nextClaim.day}/${nextClaim.month}/${nextClaim.year}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'You can only claim once every 24 hours or after 1 AM. Next claim: $nextClaimStr'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    try {
      // Do not send referralId, backend does not use it
      final result = await ApiService.post(
        '/api/referral/claim',
        {},
      );
      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral rewards claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        throw Exception(result['message'] ?? 'Failed to claim rewards');
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.contains('once every 24 hours') ||
          errorMsg.contains('Next claim available after 1 AM')) {
        errorMsg =
            'You can only claim referral rewards once every 24 hours or after 1 AM. Please try again later.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to claim rewards: $errorMsg'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Referral Program',
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorConstants.primaryColor,
              ColorConstants.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading referral data...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoMessageBox(),
          _buildReferralCodeCard(),
          const SizedBox(height: 16),
          _buildStatsOverview(),
          const SizedBox(height: 16),
          _buildReferredUsersList(),
        ],
      ),
    );
  }

  Widget _buildInfoMessageBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withAlpha(38), // ~15% opacity
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.blueAccent.withAlpha(77)), // ~30% opacity
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Invite friends and earn! You will receive 1% of the daily income generated by each user you refer, automatically added to your pending earnings every day.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    final referralCode = _referralStats['referralCode'] ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Referral Code: ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SelectableText(
                referralCode,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: _copyReferralCode,
                icon: const Icon(Icons.copy, color: Colors.amber),
                tooltip: 'Copy Referral Code',
              ),
              IconButton(
                onPressed: _shareReferralCode,
                icon: const Icon(Icons.share, color: Colors.amber),
                tooltip: 'Share Referral Code',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _shareReferralCode,
            icon: const Icon(Icons.share),
            label: const Text('Share Referral Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referral Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_referralStats['referrerInfo'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Referred by: ${_referralStats['referrerInfo']['name']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Referrals',
                '${_referredUsers.length}',
                Icons.people,
              ),
              _buildStatItem(
                'Active Referrals',
                '${_referredUsers.where((u) => u['isActive'] == true).length}',
                Icons.person_outline,
              ),
              _buildStatItem(
                'Total Earnings',
                (_referralStats['totalEarnings'] ?? '0.000000000000000000')
                    .toString(),
                Icons.account_balance_wallet,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildClaimBox(),
        ],
      ),
    );
  }

  Widget _buildClaimBox() {
    final pendingEarnings =
        double.tryParse(_referralStats['pendingEarnings'] ?? '0') ?? 0;
    final canClaim = pendingEarnings > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      'Pending Earnings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pendingEarnings.toStringAsFixed(18)} BTC',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: ColorConstants.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canClaim ? _claimEarnings : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canClaim ? ColorConstants.primaryColor : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Claim Earnings',
                style: TextStyle(
                  color: canClaim ? Colors.white : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    // Convert value to double and format to 18 decimal places only for earnings
    final doubleValue = double.tryParse(value) ?? 0;
    final formattedValue = label.toLowerCase().contains('earnings')
        ? doubleValue.toStringAsFixed(18)
        : value;

    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferredUsersList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Referred Users',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: ${_referredUsers.length}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _referredUsers.length,
            itemBuilder: (context, index) {
              final user = _referredUsers[index];
              return _buildReferredUserItem(user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReferredUserItem(Map<String, dynamic> user) {
    final joinDate = DateTime.parse(user['joinedAt']);
    final formattedDate = '${joinDate.day}/${joinDate.month}/${joinDate.year}';
    final walletBalance = user['walletBalance'] ?? '0.000000000000000000';
    final isActive = user['isActive'] ?? false;
    final walletBalanceFormatted =
        double.tryParse(walletBalance)?.toStringAsFixed(18) ??
            '0.000000000000000000';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withAlpha(51)
                  : Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.person_outline,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['fullName'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user['userName'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Joined: $formattedDate',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Wallet: $walletBalanceFormatted BTC',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
