import 'package:flutter/material.dart';
import '../services/ironsource_service.dart';

/// Simple IronSource Test Example
/// यह example IronSource integration को test करने के लिए है

class IronSourceTestExample extends StatefulWidget {
  const IronSourceTestExample({super.key});

  @override
  State<IronSourceTestExample> createState() => _IronSourceTestExampleState();
}

class _IronSourceTestExampleState extends State<IronSourceTestExample> {
  final IronSourceService _ironSourceService = IronSourceService.instance;
  bool _isInitialized = false;
  bool _isRewardedAdLoaded = false;
  bool _isBannerAdLoaded = false;
  bool _isNativeAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeIronSource();
  }

  Future<void> _initializeIronSource() async {
    try {
      await _ironSourceService.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = _ironSourceService.isInitialized;
          _isRewardedAdLoaded = _ironSourceService.isRewardedAdLoaded;
          _isBannerAdLoaded = _ironSourceService.isBannerAdLoaded;
          _isNativeAdLoaded = _ironSourceService.isNativeAdLoaded;
        });
      }
    } catch (e) {
      print('❌ IronSource initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IronSource Test'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildTestButtons(),
            const SizedBox(height: 20),
            _buildAdDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            _buildStatusRow('Initialized', _isInitialized),
            _buildStatusRow('Rewarded Ad Loaded', _isRewardedAdLoaded),
            _buildStatusRow('Banner Ad Loaded', _isBannerAdLoaded),
            _buildStatusRow('Native Ad Loaded', _isNativeAdLoaded),
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
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('$label: ${status ? 'Yes' : 'No'}'),
        ],
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRewardedAdLoaded
                        ? () async {
                            final success = await _ironSourceService.showRewardedAd(
                              onRewarded: (reward) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Reward earned: $reward'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              onAdDismissed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ad dismissed'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                            );
                            
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to show rewarded ad'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    child: const Text('Show Rewarded Ad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _ironSourceService.reloadRewardedAd();
                      setState(() {
                        _isRewardedAdLoaded = _ironSourceService.isRewardedAdLoaded;
                      });
                    },
                    child: const Text('Reload Rewarded'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _ironSourceService.reloadBannerAd();
                      setState(() {
                        _isBannerAdLoaded = _ironSourceService.isBannerAdLoaded;
                      });
                    },
                    child: const Text('Reload Banner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _ironSourceService.reloadNativeAd();
                      setState(() {
                        _isNativeAdLoaded = _ironSourceService.isNativeAdLoaded;
                      });
                    },
                    child: const Text('Reload Native'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdDisplay() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Display',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isBannerAdLoaded) ...[
              const Text('Banner Ad:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: _ironSourceService.getBannerAdWidget() ?? 
                  Container(
                    color: Colors.grey[200],
                    child: const Center(child: Text('Banner not available')),
                  ),
              ),
            ] else
              Container(
                height: 70,
                color: Colors.grey[200],
                child: const Center(child: Text('Banner Ad Not Loaded')),
              ),
            const SizedBox(height: 16),
            if (_isNativeAdLoaded) ...[
              const Text('Native Ad:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _ironSourceService.getNativeAdWidget() ?? 
                  Container(
                    color: Colors.grey[200],
                    child: const Center(child: Text('Native ad not available')),
                  ),
              ),
            ] else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: Text('Native Ad Not Loaded')),
              ),
          ],
        ),
      ),
    );
  }
}