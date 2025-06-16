import 'package:flutter/material.dart';
import '../utils/storage_utils.dart';
import '../screens/admin_dashboard.dart';
import '../screens/admin_withdraw_screen.dart';
import '../screens/admin_notifications_screen.dart';
import '../screens/users_screen.dart';
import '../screens/login_screen.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  _AdminDrawerState createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  Map<String, String?> _adminInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final adminInfo = await StorageUtils.getAdminInfo();
    setState(() {
      _adminInfo = adminInfo;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await StorageUtils.clearAll();
    // Navigate to login screen and clear all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          _buildDrawerItems(),
          const Spacer(),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.blue,
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _adminInfo['name'] ?? 'Admin User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _adminInfo['email'] ?? 'admin@example.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawerItems() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () {
            Navigator.pushReplacementNamed(context, AdminDashboard.routeName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Users'),
          onTap: () {
            Navigator.pushReplacementNamed(context, UsersScreen.routeName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet),
          title: const Text('Withdrawals'),
          onTap: () {
            Navigator.pushReplacementNamed(context, AdminWithdrawScreen.routeName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () {
            Navigator.pushReplacementNamed(context, AdminNotificationsScreen.routeName);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            // Navigate to settings screen
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.red),
        ),
        onTap: _logout,
      ),
    );
  }
}