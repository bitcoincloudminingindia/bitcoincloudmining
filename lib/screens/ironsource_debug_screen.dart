import 'package:flutter/material.dart';
import '../services/ironsource_service.dart';
import '../utils/color_constants.dart';

class IronSourceDebugScreen extends StatefulWidget {
  const IronSourceDebugScreen({Key? key}) : super(key: key);

  @override
  State<IronSourceDebugScreen> createState() => _IronSourceDebugScreenState();
}

class _IronSourceDebugScreenState extends State<IronSourceDebugScreen> {
  final IronSourceService _ironSourceService = IronSourceService.instance;
  bool _isLoading = false;
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _setupEventListeners();
  }

  void _loadMetrics() {
    setState(() {
      _metrics = _ironSourceService.metrics;
    });
  }

  void _setupEventListeners() {
    _ironSourceService.events.listen((event) {
      setState(() {
        _events.insert(0, {
          ...event,
          'timestamp': DateTime.now().toString(),
        });
        if (_events.length > 50) {
          _events = _events.take(50).toList();
        }
      });
    });
  }

  Future<void> _initializeIronSource() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.initialize();
      _loadMetrics();
      _showSnackBar('IronSource initialized successfully', isError: false);
    } catch (e) {
      _showSnackBar('IronSource initialization failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNativeAd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.reloadNativeAd();
      _loadMetrics();
      _showSnackBar('Native ad reloaded', isError: false);
    } catch (e) {
      _showSnackBar('Native ad reload failed: $e', isError: true);
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
      await _ironSourceService.reloadInterstitialAd();
      _loadMetrics();
      _showSnackBar('Interstitial ad reloaded', isError: false);
    } catch (e) {
      _showSnackBar('Interstitial ad reload failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRewardedAd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.reloadRewardedAd();
      _loadMetrics();
      _showSnackBar('Rewarded ad reloaded', isError: false);
    } catch (e) {
      _showSnackBar('Rewarded ad reload failed: $e', isError: true);
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
      final success = await _ironSourceService.showInterstitialAd();
      if (success) {
        _showSnackBar('Interstitial ad shown successfully', isError: false);
      } else {
        _showSnackBar('Interstitial ad show failed', isError: true);
      }
      _loadMetrics();
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
      final success = await _ironSourceService.showRewardedAd();
      if (success) {
        _showSnackBar('Rewarded ad shown successfully', isError: false);
      } else {
        _showSnackBar('Rewarded ad show failed', isError: true);
      }
      _loadMetrics();
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
                  const SizedBox(height: 20),
                  _buildMetricsSection(),
                  const SizedBox(height: 20),
                  _buildEventsSection(),
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
            _buildStatusItem('Initialized', _ironSourceService.isInitialized),
            _buildStatusItem('Native Ad Loaded', _ironSourceService.isNativeAdLoaded),
            _buildStatusItem('Interstitial Ad Loaded', _ironSourceService.isInterstitialAdLoaded),
            _buildStatusItem('Rewarded Ad Loaded', _ironSourceService.isRewardedAdLoaded),
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
                _buildControlButton('Load Native', _loadNativeAd),
                _buildControlButton('Load Interstitial', _loadInterstitialAd),
                _buildControlButton('Load Rewarded', _loadRewardedAd),
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

  Widget _buildMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildMetricsItem('Ad Shows', _metrics['ad_shows'] ?? {}),
            _buildMetricsItem('Ad Failures', _metrics['ad_failures'] ?? {}),
            _buildMetricsItem('Revenue', _metrics['revenue'] ?? {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsItem(String label, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (data.isEmpty)
            const Text('No data available')
          else
            ...data.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _events.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event['type'] ?? 'Unknown'} - ${event['timestamp'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (event['status'] != null)
                            Text('Status: ${event['status']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}