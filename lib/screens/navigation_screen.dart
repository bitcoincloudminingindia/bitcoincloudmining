import 'package:bitcoin_cloud_mining/providers/network_provider.dart';
import 'package:bitcoin_cloud_mining/screens/home_screen.dart'; // Import HomeScreen
// import 'package:bitcoin_cloud_mining/screens/rewards_screen.dart'; // रिवॉर्ड्स स्क्रीन को हटा दिया
import 'package:bitcoin_cloud_mining/screens/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'contract_screen.dart';
import 'wallet_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const HomeScreen(),
    const ContractScreen(),
    const WalletScreen(),
    // const RewardsScreen(), // रिवॉर्ड्स स्क्रीन को हटा दिया
    const SettingScreen(),
  ];

  // Get the actual screen index based on tab index
  int _getActualScreenIndex(int tabIndex) {
    if (tabIndex == 2)
      return _selectedIndex; // Network indicator - stay on current screen
    if (tabIndex > 2) return tabIndex - 1; // Adjust for network indicator
    return tabIndex; // Home and Contract tabs
  }

  // Get the tab index based on actual screen index
  int _getTabIndex(int screenIndex) {
    if (screenIndex >= 2) return screenIndex + 1; // Wallet and Settings tabs
    return screenIndex; // Home and Contract tabs
  }

  @override
  void initState() {
    super.initState();
    // Initialize network provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider =
          Provider.of<NetworkProvider>(context, listen: false);
      networkProvider.initialize();
    });
  }

  void _onItemTapped(int index) {
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    // Handle network indicator tab (index 2)
    if (index == 2) {
      // Show network status info or retry connection
      _showNetworkStatusDialog(networkProvider);
      return;
    }

    // Get actual screen index
    final int actualIndex = _getActualScreenIndex(index);

    // Prevent navigation if offline
    if (!networkProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(networkProvider.getOfflineMessage()),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = actualIndex;
    });
  }

  void _showNetworkStatusDialog(NetworkProvider networkProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getNetworkIcon(networkProvider),
            const SizedBox(width: 8),
            const Text('Network Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${networkProvider.getNetworkStatusMessage()}'),
            const SizedBox(height: 8),
            Text('Connection Type: ${networkProvider.connectionType}'),
            if (!networkProvider.isConnected) ...[
              const SizedBox(height: 16),
              const Text(
                'Please check your internet connection and try again.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!networkProvider.isConnected)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final isConnected = await networkProvider.checkConnection();
                if (isConnected && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.wifi, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Internet connection restored!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Main content
              IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),

              // Offline overlay
              if (!networkProvider.isConnected)
                _buildOfflineOverlay(networkProvider),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A90E2),
                  Color(0xFF357ABD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(74, 144, 226, 0.3),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: networkProvider.isConnected
                        ? const Color(0xFFFFD700)
                        : Colors.grey,
                    unselectedItemColor: networkProvider.isConnected
                        ? const Color(0xFFE0E0E0)
                        : Colors.grey,
                    selectedLabelStyle: TextStyle(
                      color: networkProvider.isConnected
                          ? const Color(0xFFFFD700)
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: TextStyle(
                      color: networkProvider.isConnected
                          ? const Color(0xFFE0E0E0)
                          : Colors.grey,
                      fontSize: 12,
                    ),
                    type: BottomNavigationBarType.fixed,
                    items: [
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home_rounded),
                        ),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.article_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.article_rounded),
                        ),
                        label: 'Contract',
                      ),
                      // Network status indicator between contract and wallet
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _getNetworkIcon(networkProvider),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _getNetworkIcon(networkProvider),
                        ),
                        label: '', // Empty label
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              const Icon(Icons.account_balance_wallet_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              const Icon(Icons.account_balance_wallet_rounded),
                        ),
                        label: 'Wallet',
                      ),
                      // रिवॉर्ड्स आइटम को हटा दिया
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings_rounded),
                        ),
                        label: 'Settings',
                      ),
                    ],
                    currentIndex: _getTabIndex(_selectedIndex),
                    onTap: _onItemTapped,
                  ),
                  // Network status indicator overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildNetworkStatusIndicator(networkProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetworkStatusIndicator(NetworkProvider networkProvider) {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          // Half round circle background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: Color(networkProvider.getNetworkStatusColor())
                    .withAlpha(230),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),
          // Network icon and text
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getNetworkIcon(networkProvider),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    networkProvider.getNetworkStatusMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getNetworkIcon(NetworkProvider networkProvider) {
    // App logo as network indicator (small, circular)
    return GestureDetector(
      onTap: () => _showGamifiedNetworkDialog(networkProvider),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(31),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(60),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child:
              Image.asset('assets/images/app_logo.png', width: 24, height: 24),
        ),
      ),
    );
  }

  void _showGamifiedNetworkDialog(NetworkProvider networkProvider) async {
    // HomeScreen ka current server fetch karo
    final String server = networkProvider.currentServer;
    final ping = 42 + (DateTime.now().second % 10); // Mock ping
    String userLocation = 'Unknown';
    try {
      final Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      userLocation =
          'Lat: \\${pos.latitude.toStringAsFixed(2)}, Long: \\${pos.longitude.toStringAsFixed(2)}';
    } catch (e) {
      userLocation = 'Location permission denied';
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/app_logo.png',
                      width: 48, height: 48),
                  const SizedBox(width: 12),
                  const Text('Network Gamification',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _gamifiedInfoRow('🌐 Server', server, Colors.cyan),
              const SizedBox(height: 12),
              _gamifiedInfoRow('⚡ Ping', '$ping ms', Colors.green),
              const SizedBox(height: 12),
              _gamifiedInfoRow('📍 Location', userLocation, Colors.orange),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                width: 120 + (ping % 20).toDouble(),
                height: 12,
                decoration: BoxDecoration(
                  color: ping < 60 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withAlpha(60),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Live Network Status',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle, color: Colors.amber),
                label:
                    const Text('Close', style: TextStyle(color: Colors.amber)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gamifiedInfoRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildOfflineOverlay(NetworkProvider networkProvider) {
    return Container(
      color: Colors.black.withAlpha(179),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                networkProvider.getOfflineMessage(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final isConnected = await networkProvider.checkConnection();
                  if (isConnected) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.wifi, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Internet connection restored!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
