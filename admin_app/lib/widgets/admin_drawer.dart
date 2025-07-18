import 'package:flutter/material.dart';

import '../screens/referral_analytics_screen.dart';
import '../screens/referral_management_screen.dart';

class AdminDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  const AdminDrawer({required this.onLogout, super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Admin',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/admin-dashboard'),
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Users'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/admin-users'),
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Referral Analytics'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReferralAnalyticsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.manage_accounts),
            title: Text('Referral Management'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReferralManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.ads_click),
            title: Text('Ad Analytics'),
            onTap: () => Navigator.of(
              context,
            ).pushReplacementNamed('/admin-ad-analytics'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/admin-settings'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
