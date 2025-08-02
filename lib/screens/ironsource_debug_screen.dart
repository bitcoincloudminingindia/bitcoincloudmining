import 'package:flutter/material.dart';
import '../services/ironsource_service.dart';
import '../utils/color_constants.dart';

class IronSourceDebugScreen extends StatefulWidget {
  const IronSourceDebugScreen({Key? key}) : super(key: key);

  @override
  State<IronSourceDebugScreen> createState() => _IronSourceDebugScreenState();
}

class _IronSourceDebugScreenState extends State<IronSourceDebugScreen> {
  final IronSourceService _ironSourceService = IronSourceService();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _isInterstitialReady = await _ironSourceService.isInterstitialAdLoaded;
      _isRewardedReady = await _ironSourceService.isRewardedAdLoaded;
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeIronSource() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.initIronSource('2314651cd');
      _isInitialized = true;
      await _checkStatus();
      _showSnackBar('IronSource initialized successfully', isError: false);
    } catch (e) {
      _showSnackBar('IronSource initialization failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInterstitialAd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.loadInterstitialAd();
      await _checkStatus();
      _showSnackBar('Interstitial ad loaded', isError: false);
    } catch (e) {
      _showSnackBar('Interstitial ad load failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showInterstitialAd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.showInterstitialAd();
      _showSnackBar('Interstitial ad shown successfully', isError: false);
      await _checkStatus();
    } catch (e) {
      _showSnackBar('Interstitial ad show error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showRewardedAd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.showRewardedAd();
      _showSnackBar('Rewarded ad shown successfully', isError: false);
      await _checkStatus();
    } catch (e) {
      _showSnackBar('Rewarded ad show error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IronSource Debug'),
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  _buildControlSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusItem('Initialized', _isInitialized),
            _buildStatusItem('Interstitial Ad Ready', _isInterstitialReady),
            _buildStatusItem('Rewarded Ad Ready', _isRewardedReady),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            status ? 'Ready' : 'Not Ready',
            style: TextStyle(
              color: status ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildControlButton('Initialize', _initializeIronSource),
                _buildControlButton('Load Interstitial', _loadInterstitialAd),
                _buildControlButton('Show Interstitial', _showInterstitialAd),
                _buildControlButton('Show Rewarded', _showRewardedAd),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}