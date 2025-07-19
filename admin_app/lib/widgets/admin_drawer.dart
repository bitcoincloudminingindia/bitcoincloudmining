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
            decoration: const BoxDecoration(color: Colors.blue),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.asset(
                  'assets/Bitcoin Cloud Mining Logo.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/admin-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/admin-users'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Referral Analytics'),
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
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Referral Management'),
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
            leading: const Icon(Icons.ads_click),
            title: const Text('Ad Analytics'),
            onTap: () => Navigator.of(
              context,
            ).pushReplacementNamed('/admin-ad-analytics'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/admin-settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
