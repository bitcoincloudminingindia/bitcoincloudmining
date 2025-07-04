import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/version_check_service.dart';
import '../widgets/withdrawal_disclaimer_dialog.dart';

class LoadingUserDataScreen extends StatefulWidget {
  const LoadingUserDataScreen({super.key});

  @override
  State<LoadingUserDataScreen> createState() => _LoadingUserDataScreenState();
}

class _LoadingUserDataScreenState extends State<LoadingUserDataScreen> {
  bool _isLoading = true;
  String _loadingMessage = 'Loading user data...';
  String? _errorMessage;
  bool _disclaimerShown = false;

  @override
  void initState() {
    super.initState();
    VersionCheckService.checkForUpdate(context);
    // Pehle sirf disclaimer show karo, permission check baad me
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disclaimerShown) {
        _disclaimerShown = true;
        showWithdrawalDisclaimerDialog(
          context: context,
          onContinue: _checkAndRequestPermissions,
        );
      }
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _loadingMessage = 'Checking permissions...';
    });
    // 1. Location permission
    bool locationGranted = false;
    LocationPermission locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied ||
        locPerm == LocationPermission.deniedForever) {
      locPerm = await Geolocator.requestPermission();
    }
    locationGranted = locPerm == LocationPermission.always ||
        locPerm == LocationPermission.whileInUse;

    // 2. Notification permission
    bool notificationGranted = false;
    if (await Permission.notification.isGranted) {
      notificationGranted = true;
    } else {
      final notifStatus = await Permission.notification.request();
      notificationGranted = notifStatus.isGranted;
    }

    if (!locationGranted || !notificationGranted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Permissions required. Please allow location and notification permissions.';
      });
      return;
    }

    // Location granted, now fetch current location and set in NetworkProvider
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final networkProvider =
          Provider.of<NetworkProvider>(context, listen: false);
      await networkProvider.setUserLocationFromCoordinates(
          position.latitude, position.longitude);
    } catch (e) {
      // If location can't be fetched, ignore, will show as Unknown
    }

    // All permissions granted, now load user data
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
      }

      // 3. Load wallet balance from server
      await walletProvider.loadWallet();

      if (!mounted) return;

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
                    _checkAndRequestPermissions();
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
