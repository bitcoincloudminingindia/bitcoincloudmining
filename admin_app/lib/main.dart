import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/admin_api_provider.dart';
import 'providers/chart_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/referral_analytics_screen.dart';
import 'screens/referral_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/withdrawal_screen.dart';
import 'widgets/admin_drawer.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (context) => AdminApiProvider()),
      ],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminApiProvider(),
      child: MaterialApp(
        title: 'Bitcoin Cloud Mining Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.poppins().fontFamily,
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const ResponsiveWrapper(child: AdminHome()),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) =>
              const ResponsiveWrapper(child: AdminHome()),
          '/admin-dashboard': (context) =>
              const ResponsiveWrapper(child: AdminHome()),
          '/admin-users': (context) =>
              const ResponsiveWrapper(child: AdminHome()),
          '/admin-referral-analytics': (context) =>
              const ResponsiveWrapper(child: ReferralAnalyticsScreen()),
          '/admin-referral-management': (context) =>
              const ResponsiveWrapper(child: ReferralManagementScreen()),
          '/admin-settings': (context) =>
              const ResponsiveWrapper(child: AdminHome()),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const ResponsiveWrapper(child: AdminHome()),
          );
        },
      ),
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).size.width < 600 ? 0.9 : 1.0,
        ),
      ),
      child: child,
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<AdminApiProvider>(context, listen: false);
    await provider.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminApiProvider>(context);

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.token == null) {
      return const LoginScreen();
    }

    return const AdminHomeScreen();
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const DashboardScreen(),
    const UserListScreen(),
    const WithdrawalScreen(),
    const WalletScreen(),
    const SettingsScreen(),
  ];

  static final List<String> _screenTitles = [
    'Dashboard',
    'Users',
    'Withdrawals',
    'Wallets',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(
        onLogout: () {
          final provider = Provider.of<AdminApiProvider>(
            context,
            listen: false,
          );
          provider.logout();
          Navigator.of(context).pushReplacementNamed('/');
        },
      ),
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReferralAnalyticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Withdrawals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
