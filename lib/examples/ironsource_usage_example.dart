import 'package:flutter/material.dart';
import '../services/ironsource_service.dart';

/// Example of how to use the updated IronSource service
class IronSourceUsageExample extends StatefulWidget {
  const IronSourceUsageExample({Key? key}) : super(key: key);

  @override
  State<IronSourceUsageExample> createState() => _IronSourceUsageExampleState();
}

class _IronSourceUsageExampleState extends State<IronSourceUsageExample> {
  final IronSourceService _ironSourceService = IronSourceService();
  bool _isInitialized = false;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  @override
  void initState() {
    super.initState();
    _initializeIronSource();
  }

  Future<void> _initializeIronSource() async {
    try {
      // Initialize IronSource with your app key
      await _ironSourceService.initIronSource('2314651cd');
      setState(() {
        _isInitialized = true;
      });
      
      // Load ads after initialization
      await _loadAds();
    } catch (e) {
      print('IronSource initialization failed: $e');
    }
  }

  Future<void> _loadAds() async {
    try {
      // Load interstitial ad
      await _ironSourceService.loadInterstitialAd();
      
      // Check ad availability
      _isInterstitialReady = await _ironSourceService.isInterstitialAdLoaded;
      _isRewardedReady = await _ironSourceService.isRewardedAdLoaded;
      
      setState(() {});
    } catch (e) {
      print('Ad loading failed: $e');
    }
  }

  Future<void> _showInterstitialAd() async {
    if (_isInterstitialReady) {
      try {
        await _ironSourceService.showInterstitialAd();
        print('Interstitial ad shown successfully');
        
        // Reload ad after showing
        await _ironSourceService.loadInterstitialAd();
        _isInterstitialReady = await _ironSourceService.isInterstitialAdLoaded;
        setState(() {});
      } catch (e) {
        print('Interstitial ad show failed: $e');
      }
    } else {
      print('Interstitial ad not ready');
    }
  }

  Future<void> _showRewardedAd() async {
    if (_isRewardedReady) {
      try {
        await _ironSourceService.showRewardedAd();
        print('Rewarded ad shown successfully');
        
        // Check availability after showing
        _isRewardedReady = await _ironSourceService.isRewardedAdLoaded;
        setState(() {});
      } catch (e) {
        print('Rewarded ad show failed: $e');
      }
    } else {
      print('Rewarded ad not ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IronSource Usage Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IronSource Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusRow('Initialized', _isInitialized),
                    _buildStatusRow('Interstitial Ready', _isInterstitialReady),
                    _buildStatusRow('Rewarded Ready', _isRewardedReady),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Controls Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ad Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInterstitialReady ? _showInterstitialAd : null,
                            child: const Text('Show Interstitial'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isRewardedReady ? _showRewardedAd : null,
                            child: const Text('Show Rewarded'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadAds,
                        child: const Text('Reload Ads'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usage Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. Initialize IronSource with your app key\n'
                      '2. Load ads using loadInterstitialAd()\n'
                      '3. Check ad availability with isInterstitialAdLoaded\n'
                      '4. Show ads using showInterstitialAd() or showRewardedAd()\n'
                      '5. Reload ads after showing them',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
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
}