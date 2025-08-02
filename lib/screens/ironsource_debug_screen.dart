import 'package:flutter/material.dart';
import '../services/ironsource_service.dart';
import '../utils/color_constants.dart';

class IronSourceDebugScreen extends StatefulWidget {
  const IronSourceDebugScreen({super.key});

  @override
  State<IronSourceDebugScreen> createState() => _IronSourceDebugScreenState();
}

class _IronSourceDebugScreenState extends State<IronSourceDebugScreen> {
  final IronSourceService _ironSourceService = IronSourceService.instance;
  bool _isLoading = false;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() {
    setState(() {
      _metrics = _ironSourceService.metrics;
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

  Future<void> _launchTestSuite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ironSourceService.launchTestSuite();
      _showSnackBar('Test suite launched', isError: false);
    } catch (e) {
      _showSnackBar('Test suite launch failed: $e', isError: true);
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
          Text('$label: ${status ? 'Yes' : 'No'}'),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _ironSourceService.isInitialized ? null : _initializeIronSource,
                  child: const Text('Initialize'),
                ),
                ElevatedButton(
                  onPressed: _ironSourceService.isInitialized ? _loadNativeAd : null,
                  child: const Text('Load Native'),
                ),
                ElevatedButton(
                  onPressed: _ironSourceService.isInitialized ? _loadInterstitialAd : null,
                  child: const Text('Load Interstitial'),
                ),
                ElevatedButton(
                  onPressed: _ironSourceService.isInitialized ? _loadRewardedAd : null,
                  child: const Text('Load Rewarded'),
                ),
                ElevatedButton(
                  onPressed: _ironSourceService.isInterstitialAdLoaded ? _showInterstitialAd : null,
                  child: const Text('Show Interstitial'),
                ),
                ElevatedButton(
                  onPressed: _ironSourceService.isRewardedAdLoaded ? _showRewardedAd : null,
                  child: const Text('Show Rewarded'),
                ),
                ElevatedButton(
                  onPressed: _ironSourceService.isInitialized ? _launchTestSuite : null,
                  child: const Text('Test Suite'),
                ),
              ],
            ),
          ],
        ),
      ),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricsItem('Ad Shows', _metrics['ad_shows'] ?? {}),
            const SizedBox(height: 8),
            _buildMetricsItem('Ad Failures', _metrics['ad_failures'] ?? {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsItem(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        if (data.isEmpty)
          const Text('No data available', style: TextStyle(color: Colors.grey))
        else
          ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('${entry.key}: ${entry.value}'),
              )),
      ],
    );
  }
}