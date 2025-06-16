import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/api_service.dart';

class LoadingUserDataScreen extends StatefulWidget {
  const LoadingUserDataScreen({super.key});

  @override
  State<LoadingUserDataScreen> createState() => _LoadingUserDataScreenState();
}

class _LoadingUserDataScreenState extends State<LoadingUserDataScreen> {
  bool _isLoading = true;
  String _loadingMessage = 'Loading user data...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      // 1. Load user profile first
      setState(() {
        _loadingMessage = 'Loading user profile...';
      });

      await authProvider.loadUserProfile();
      if (!mounted) return;

      // 2. Load and sync wallet data
      setState(() {
        _loadingMessage = 'Loading wallet data...';
      });

      // The wallet data should already be in the user profile
      // Just need to sync it with the wallet provider
      if (authProvider.userData?['wallet'] != null) {
        final walletData = authProvider.userData!['wallet'];
        final balance =
            double.tryParse(walletData['balance']?.toString() ?? '0') ?? 0.0;
        await walletProvider.updateBalance(balance);
        debugPrint('✅ Wallet balance updated: $balance BTC');
      }

      // 3. Sync wallet balance with server
      await walletProvider.syncWalletBalance();

      if (!mounted) return;

      // 4. Load referral data (optional)
      try {
        setState(() {
          _loadingMessage = 'Loading referral data...';
        });

        final referralResult = await ApiService.get('/api/referral/statistics')
            .timeout(const Duration(seconds: 10));

        if (!mounted) return;

        if (referralResult['success'] != true) {
          debugPrint(
              '⚠️ Error loading referral data: ${referralResult['message']}');
        }
      } catch (e) {
        debugPrint('⚠️ Error loading referral data: $e');
        // Continue even if referral data fails to load
      }

      // 4. All data loaded, navigate to navigation screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading user data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(51),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                const SizedBox(height: 24),
                Text(
                  _loadingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please wait while we load your data...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadUserData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
