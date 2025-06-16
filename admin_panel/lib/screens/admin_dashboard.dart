import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/admin_drawer.dart';
import 'admin_withdraw_screen.dart';
import 'admin_notifications_screen.dart';
import 'users_screen.dart';

class AdminDashboard extends StatefulWidget {
  static const String routeName = '/admin-dashboard';

  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await _apiService.getAdminDashboard();

      if (result['success']) {
        setState(() {
          _dashboardData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load dashboard data';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
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
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDashboardSummary(),
            const SizedBox(height: 30),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 30),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSummary() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        DashboardCard(
          title: 'Total Users',
          value: _dashboardData['totalUsers']?.toString() ?? '0',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, UsersScreen.routeName),
        ),
        DashboardCard(
          title: 'Pending Withdrawals',
          value: _dashboardData['pendingWithdrawals']?.toString() ?? '0',
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
          onTap: () =>
              Navigator.pushNamed(context, AdminWithdrawScreen.routeName),
        ),
        DashboardCard(
          title: 'Active Mining',
          value: _dashboardData['activeMining']?.toString() ?? '0',
          icon: Icons.bolt,
          color: Colors.green,
          onTap: () {},
        ),
        DashboardCard(
          title: 'New Notifications',
          value: _dashboardData['newNotifications']?.toString() ?? '0',
          icon: Icons.notifications,
          color: Colors.purple,
          onTap: () =>
              Navigator.pushNamed(context, AdminNotificationsScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.people,
          label: 'Users',
          onTap: () => Navigator.pushNamed(context, UsersScreen.routeName),
        ),
        _buildActionButton(
          icon: Icons.account_balance_wallet,
          label: 'Withdrawals',
          onTap: () =>
              Navigator.pushNamed(context, AdminWithdrawScreen.routeName),
        ),
        _buildActionButton(
          icon: Icons.notifications,
          label: 'Notifications',
          onTap: () =>
              Navigator.pushNamed(context, AdminNotificationsScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(128, 128, 128, 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Color.fromRGBO(255, 255, 255, 0.1),
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentActivities = _dashboardData['recentActivities'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentActivities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent activities'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                recentActivities.length > 5 ? 5 : recentActivities.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activity = recentActivities[index];
              return ListTile(
                leading: _getActivityIcon(activity['type']),
                title: Text(activity['title'] ?? 'Unknown activity'),
                subtitle: Text(activity['description'] ?? ''),
                trailing: Text(
                  _formatDate(activity['timestamp'] ?? ''),
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _getActivityIcon(String? type) {
    switch (type) {
      case 'withdrawal':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.account_balance_wallet, color: Colors.white),
        );
      case 'registration':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.person_add, color: Colors.white),
        );
      case 'login':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.login, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.event, color: Colors.white),
        );
    }
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
