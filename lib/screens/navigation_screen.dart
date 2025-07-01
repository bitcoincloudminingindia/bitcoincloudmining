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

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _rgbController;

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
    _rgbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rgbController.dispose();
    super.dispose();
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
    // RGB line ko tap par animate karne ke liye
    _rgbController.forward(from: 0);
  }

  void _showNetworkStatusDialog(NetworkProvider networkProvider,
      {String? server, int? ping}) {
    // Network level badge logic
    final int actualPing = ping ?? 42;
    String networkLevel = 'Excellent';
    Color badgeColor = Colors.greenAccent;
    IconData badgeIcon = Icons.emoji_events_rounded;
    if (actualPing > 80) {
      networkLevel = 'Poor';
      badgeColor = Colors.redAccent;
      badgeIcon = Icons.warning_amber_rounded;
    } else if (actualPing > 60) {
      networkLevel = 'Average';
      badgeColor = Colors.orangeAccent;
      badgeIcon = Icons.network_check_rounded;
    } else if (actualPing > 50) {
      networkLevel = 'Good';
      badgeColor = Colors.lightGreen;
      badgeIcon = Icons.thumb_up_alt_rounded;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((255 * 0.5).toInt()),
      builder: (context) => Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          child: Dialog(
            backgroundColor: Colors.white.withAlpha((255 * 0.12).toInt()),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha((255 * 0.18).toInt()),
                    Colors.blue.withAlpha((255 * 0.10).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withAlpha((255 * 0.25).toInt()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha((255 * 0.18).toInt()),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
                backgroundBlendMode: BlendMode.overlay,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Network status icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: networkProvider.isConnected
                          ? Colors.green.withAlpha((255 * 0.2).toInt())
                          : Colors.red.withAlpha((255 * 0.2).toInt()),
                      boxShadow: [
                        BoxShadow(
                          color: networkProvider.isConnected
                              ? Colors.green.withAlpha((255 * 0.5).toInt())
                              : Colors.red.withAlpha((255 * 0.5).toInt()),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getConnectionIcon(networkProvider),
                      size: 48,
                      color: networkProvider.isConnected
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title: Solvex Network
                  const Text(
                    'Solvex Network',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status message
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getNetworkIcon(networkProvider, showNetworkIcon: true),
                      const SizedBox(width: 8),
                      Text(
                        networkProvider.getNetworkStatusMessage(),
                        style: TextStyle(
                          color: networkProvider.isConnected
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Connection type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cable_rounded,
                          color: Colors.cyan, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Connection: ${networkProvider.connectionType}',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Server info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_rounded,
                          color: Colors.cyan, size: 24),
                      const SizedBox(width: 8),
                      Text('Server:',
                          style: TextStyle(
                              color: Colors.cyan[200],
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(server ?? networkProvider.currentServer,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ping info + animated bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded,
                          color: Colors.greenAccent, size: 24),
                      const SizedBox(width: 8),
                      const Text('Ping:',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('${ping ?? 42} ms',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Animated RGB ping bar
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: (ping ?? 42) / 120),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Stack(
                        children: [
                          Container(
                            width: 220,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  Colors.white.withAlpha((255 * 0.08).toInt()),
                            ),
                          ),
                          Container(
                            width: 220 * value,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Colors.yellowAccent,
                                  Colors.orangeAccent,
                                  Colors.redAccent,
                                ],
                                stops: [0.0, 0.5, 0.8, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent
                                      .withAlpha((255 * 0.2).toInt()),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Network level badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha((255 * 0.18).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: badgeColor, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: badgeColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Network Level: $networkLevel',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Location info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.orangeAccent, size: 24),
                      const SizedBox(width: 8),
                      const Text('Location:',
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          networkProvider.userLocation ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Close & Retry buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            const Icon(Icons.check_circle, color: Colors.amber),
                        label: const Text('Close',
                            style: TextStyle(color: Colors.amber)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.black.withAlpha((255 * 0.7).toInt()),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!networkProvider.isConnected)
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final isConnected =
                                await networkProvider.checkConnection();
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
                          icon: const Icon(Icons.refresh,
                              color: Colors.greenAccent),
                          label: const Text('Retry',
                              style: TextStyle(color: Colors.greenAccent)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.black.withAlpha((255 * 0.7).toInt()),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
                  // RGB running line
                  AnimatedBuilder(
                    animation: _rgbController,
                    builder: (context, child) {
                      // RGB gradient animation
                      return CustomPaint(
                        painter: _RGBLinePainter(
                          tabCount: 5,
                          activeTab: _getTabIndex(_selectedIndex),
                          progress: _rgbController.value,
                        ),
                        child: const SizedBox(
                          height: 60,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
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
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.home_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.home_rounded),
                        ),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.article_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.article_rounded),
                        ),
                        label: 'Contract',
                      ),
                      // Network status indicator between contract and wallet
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(0),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                AssetImage('assets/images/app_logo.png'),
                          ),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(0),
                          child: const CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                AssetImage('assets/images/app_logo.png'),
                          ),
                        ),
                        label: '', // Empty label
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              const Icon(Icons.account_balance_wallet_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              const Icon(Icons.account_balance_wallet_rounded),
                        ),
                        label: 'Wallet',
                      ),
                      // रिवॉर्ड्स आइटम को हटा दिया
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.settings_rounded),
                        ),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(4), // Chhota kiya
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
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
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: networkProvider.isConnected
                        ? Colors.green.withAlpha(60)
                        : Colors.red.withAlpha(60),
                    boxShadow: [
                      BoxShadow(
                        color: networkProvider.isConnected
                            ? Colors.green.withAlpha(60)
                            : Colors.red.withAlpha(60),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getConnectionIcon(networkProvider),
                    color:
                        networkProvider.isConnected ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
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

  // Helper function to get connection icon based on connection type
  IconData _getConnectionIcon(NetworkProvider networkProvider) {
    if (!networkProvider.isConnected) {
      return Icons.wifi_off;
    }

    switch (networkProvider.connectionType) {
      case 'WiFi':
        return Icons.wifi;
      case 'Mobile Data':
        return Icons.signal_cellular_4_bar;
      case 'Ethernet':
        return Icons.cable;
      default:
        return Icons.wifi;
    }
  }

  Widget _getNetworkIcon(NetworkProvider networkProvider,
      {bool showNetworkIcon = false}) {
    // अगर showNetworkIcon true है तो network icon दिखाओ, वरना app logo
    if (showNetworkIcon) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: networkProvider.isConnected
              ? Colors.green.withAlpha(60)
              : Colors.red.withAlpha(60),
          boxShadow: [
            BoxShadow(
              color: networkProvider.isConnected
                  ? Colors.green.withAlpha(60)
                  : Colors.red.withAlpha(60),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          _getConnectionIcon(networkProvider),
          color: networkProvider.isConnected ? Colors.green : Colors.red,
          size: 20,
        ),
      );
    } else {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: const CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: AssetImage('assets/images/app_logo.png'),
        ),
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

// RGB line painter
class _RGBLinePainter extends CustomPainter {
  final int tabCount;
  final int activeTab;
  final double progress;
  _RGBLinePainter(
      {required this.tabCount,
      required this.activeTab,
      required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const double barHeight = 4;
    const double y = 0;
    final double tabWidth = size.width / tabCount;
    // RGB gradient
    final gradient = LinearGradient(
      colors: const [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
        Colors.red,
      ],
      stops: const [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0, 1.0],
      begin: Alignment(-1 + 2 * progress, 0),
      end: Alignment(1 - 2 * progress, 0),
    );
    final paint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, y, size.width, barHeight));
    // Draw full bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, size.width, barHeight),
        const Radius.circular(2),
      ),
      paint,
    );
    // Draw highlight under active tab
    final highlightPaint = Paint()
      ..shader = gradient.createShader(
          Rect.fromLTWH(tabWidth * activeTab, y, tabWidth, barHeight))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tabWidth * activeTab, y, tabWidth, barHeight),
        const Radius.circular(2),
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RGBLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeTab != activeTab;
  }
}
