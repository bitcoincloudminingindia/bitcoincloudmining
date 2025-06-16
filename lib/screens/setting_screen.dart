import 'dart:convert';

import 'package:bitcoin_cloud_mining/config/api_config.dart';
import 'package:bitcoin_cloud_mining/screens/about_us_screen.dart';
import 'package:bitcoin_cloud_mining/screens/contact_support_screen.dart';
import 'package:bitcoin_cloud_mining/screens/terms_condition_screen.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
import 'package:bitcoin_cloud_mining/utils/storage_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../constants/color_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../screens/notification_screen.dart';
import '../utils/number_formatter.dart';
import '../widgets/login_dialog.dart';

// Define your premium colors.
const Color primaryColor = Color(0xFF1E88E5); // Deep blue
const Color secondaryColor = Color(0xFF42A5F5); // Light blue
const Color accentColor = Color(0xFF64B5F6); // Lighter blue
const Color bgColorStart = Color(0xFFE3F2FD); // Very light blue background
const Color bgColorEnd = Color(0xFFBBDEFB); // Light blue background
const Color cardColor = Color(0xFFFFFFFF); // White background for cards

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        // First load local data immediately
        final localData = await StorageUtils.getUserData();
        if (localData != null && mounted) {
          _loadUserData();
        }

        // Then try to load from server without navigation
        if (mounted) {
          try {
            final apiService = ApiService();
            final response = await apiService.getUserProfile();
            if (response['status'] == 'success' && mounted) {
              final serverData = response['data'];
              await StorageUtils.saveUserData(serverData);
              if (mounted) {
                // Update AuthProvider with new data
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.updateUserData(serverData);
                _loadUserData();
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading profile: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading user data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _loadUserData() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _nameController.text = authProvider.fullName ?? '';
      _emailController.text = authProvider.email ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue[900],
        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your wallet balance will remain secure. Are you sure you want to logout?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);

        // Step 1: Get current balance and token
        final currentBalance = walletProvider.btcBalance;
        final formattedBalance =
            NumberFormatter.formatBTCAmount(currentBalance);
        final token = await StorageUtils.getToken();
        final userId = await StorageUtils.getUserId();

        if (token == null || userId == null) {
          throw Exception('Authentication data not found');
        }

        // Step 2: Send logout request with balance
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token'
              },
              body: jsonEncode(
                  {'userId': userId, 'walletBalance': formattedBalance}),
            )
            .timeout(const Duration(seconds: 10));

        // Check response status
        if (response.statusCode != 200) {
          print('⚠️ Server logout failed: ${response.body}');
          // Continue with local cleanup even if server logout fails
        }

        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Step 3: Clean up local data regardless of server response
        await Future.wait([
          walletProvider.onLogout(),
          StorageUtils.clearAll(),
        ]);

        // Step 4: Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Wait for snackbar to show
          await Future.delayed(const Duration(seconds: 1));

          // Close all dialogs and show login dialog
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const LoginDialog(),
            );
          }
        }
      } catch (e) {
        // Close loading indicator if open
        if (mounted) {
          Navigator.of(context).pop();
        }

        print('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _confirmLogout(context),
              ),
            ),
          );
        }
      }
    }
  }

  void _showNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
  }

  // ignore: unused_element
  void _showTerms(BuildContext context) {
    // Terms dialog implementation will be added later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms and conditions will be available soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        'Settings',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications, color: Colors.amber),
            onPressed: _showNotifications,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(51),
                  Colors.white.withAlpha(26),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withAlpha(51),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              final displayName =
                                  auth.fullName ?? _nameController.text;
                              return Text(
                                displayName.isNotEmpty
                                    ? displayName
                                    : 'Not set',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              return Text(
                                auth.email ?? 'No email set',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(179),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(26),
                        Colors.white.withAlpha(13),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<String?>(
                          future: StorageUtils.getUserId(),
                          builder: (context, snapshot) {
                            final userId = snapshot.data ??
                                Provider.of<AuthProvider>(context).userId;
                            return SelectableText(
                              userId ?? 'Loading...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(179),
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return _buildGradientCard(
      child: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(51),
                  Colors.white.withAlpha(26),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${wallet.btcBalance.toStringAsFixed(18)} BTC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildGradientCard(
      child: InkWell(
        onTap: _showNotifications,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(51),
                Colors.white.withAlpha(26),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withAlpha(179),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return _buildGradientCard(
      child: Column(
        children: [
          _buildSupportTile(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutUsScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildSupportTile(
            icon: Icons.contact_support_outlined,
            title: 'Contact Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ContactSupportScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildSupportTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TermsConditionScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withAlpha(51),
              Colors.white.withAlpha(26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withAlpha(179),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => _confirmLogout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withAlpha(204),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 16),
                    _buildProfileSection(),
                    const SizedBox(height: 16),
                    _buildWalletSection(),
                    const SizedBox(height: 16),
                    _buildNotificationsSection(),
                    const SizedBox(height: 16),
                    _buildSupportSection(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to create a slide transition route.
Route createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
