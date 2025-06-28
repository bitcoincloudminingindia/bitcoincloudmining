import 'package:bitcoin_cloud_mining/providers/network_provider.dart';
import 'package:bitcoin_cloud_mining/screens/home_screen.dart'; // Import HomeScreen
// import 'package:bitcoin_cloud_mining/screens/rewards_screen.dart'; // रिवॉर्ड्स स्क्रीन को हटा दिया
import 'package:bitcoin_cloud_mining/screens/setting_screen.dart';
import 'package:flutter/material.dart';
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
      _selectedIndex = index;
    });
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

              // Network status indicator at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildNetworkStatusIndicator(networkProvider),
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
              child: BottomNavigationBar(
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
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded),
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
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetworkStatusIndicator(NetworkProvider networkProvider) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Color(networkProvider.getNetworkStatusColor()).withAlpha(204),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getNetworkIcon(networkProvider),
          const SizedBox(width: 4),
          Text(
            networkProvider.getNetworkStatusMessage(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getNetworkIcon(NetworkProvider networkProvider) {
    if (!networkProvider.isConnected) {
      return const Icon(
        Icons.wifi_off,
        color: Colors.white,
        size: 16,
      );
    }

    switch (networkProvider.connectionType) {
      case 'WiFi':
        return const Icon(
          Icons.wifi,
          color: Colors.white,
          size: 16,
        );
      case 'Mobile Data':
        return const Icon(
          Icons.signal_cellular_4_bar,
          color: Colors.white,
          size: 16,
        );
      case 'Ethernet':
        return const Icon(
          Icons.cable,
          color: Colors.white,
          size: 16,
        );
      default:
        return const Icon(
          Icons.wifi,
          color: Colors.white,
          size: 16,
        );
    }
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
