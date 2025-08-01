import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../services/ironsource_service.dart';
import '../utils/ironsource_debug_helper.dart';

class IronSourceDebugScreen extends StatefulWidget {
  const IronSourceDebugScreen({super.key});

  @override
  State<IronSourceDebugScreen> createState() => _IronSourceDebugScreenState();
}

class _IronSourceDebugScreenState extends State<IronSourceDebugScreen> {
  final IronSourceService _ironSourceService = IronSourceService.instance;
  Map<String, dynamic> _debugReport = {};
  bool _isLoading = false;
  String _status = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _runDebugReport();
  }

  Future<void> _runDebugReport() async {
    setState(() {
      _isLoading = true;
      _status = 'Running debug report...';
    });

    try {
      final report = await IronSourceDebugHelper.checkConfiguration();
      setState(() {
        _debugReport = report;
        _status = 'Debug report completed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testIronSourceInitialization() async {
    setState(() {
      _status = 'Testing IronSource initialization...';
    });

    try {
      await _ironSourceService.initialize();
      
      setState(() {
        _status = _ironSourceService.isInitialized 
            ? '✅ IronSource initialized successfully'
            : '❌ IronSource initialization failed';
      });
    } catch (e) {
      setState(() {
        _status = '❌ IronSource initialization error: $e';
      });
    }
  }

  Future<void> _testNativeAd() async {
    setState(() {
      _status = 'Testing native ad...';
    });

    try {
      final widget = _ironSourceService.getNativeAdWidget();
      
      setState(() {
        _status = widget != null 
            ? '✅ Native ad widget created successfully'
            : '❌ Native ad widget creation failed';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Native ad test error: $e';
      });
    }
  }

  Future<void> _testRewardedAd() async {
    setState(() {
      _status = 'Testing rewarded ad...';
    });

    try {
      final success = await _ironSourceService.showRewardedAd();
      
      setState(() {
        _status = success 
            ? '✅ Rewarded ad shown successfully'
            : '❌ Rewarded ad show failed';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Rewarded ad test error: $e';
      });
    }
  }

  Future<void> _printDebugReport() async {
    await IronSourceDebugHelper.printDebugReport();
    setState(() {
      _status = 'Debug report printed to console';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IronSource Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔍 Debug Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Test Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testIronSourceInitialization,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Initialization'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testNativeAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Native Ad'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testRewardedAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Rewarded Ad'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _printDebugReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Print Debug Report'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _runDebugReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Refresh Report'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug Report
            if (_debugReport.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Debug Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // App Keys Section
                      if (_debugReport['app_keys'] != null) ...[
                        _buildSection(
                          '📱 App Keys',
                          _debugReport['app_keys'] as Map<String, dynamic>,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Ad Unit IDs Section
                      if (_debugReport['ad_unit_ids'] != null) ...[
                        _buildSection(
                          '🎯 Ad Unit IDs',
                          _debugReport['ad_unit_ids'] as Map<String, dynamic>,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Platform Section
                      if (_debugReport['platform'] != null) ...[
                        _buildSection(
                          '📱 Platform',
                          _debugReport['platform'] as Map<String, dynamic>,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // SDK Section
                      if (_debugReport['sdk'] != null) ...[
                        _buildSection(
                          '🔧 SDK',
                          _debugReport['sdk'] as Map<String, dynamic>,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Ad Loading Section
                      if (_debugReport['ad_loading'] != null) ...[
                        _buildSection(
                          '📺 Ad Loading',
                          _debugReport['ad_loading'] as Map<String, dynamic>,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // IronSource Service Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚙️ IronSource Service Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStatusItem(
                      'Initialized',
                      _ironSourceService.isInitialized,
                    ),
                    _buildStatusItem(
                      'Native Ad Loaded',
                      _ironSourceService.isNativeAdLoaded,
                    ),
                    _buildStatusItem(
                      'Rewarded Ad Loaded',
                      _ironSourceService.isRewardedAdLoaded,
                    ),
                    _buildStatusItem(
                      'Interstitial Ad Loaded',
                      _ironSourceService.isInterstitialAdLoaded,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Troubleshooting Tips
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Troubleshooting Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      '1. Check your IronSource dashboard for correct app keys',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2. Verify ad unit IDs are properly configured',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '3. Ensure your app is approved in IronSource console',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '4. Check network connectivity',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '5. Verify you\'re using production keys, not test keys',
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

  Widget _buildSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...data.entries.map((entry) {
          if (entry.key == 'recommendation') {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.value.toString(),
                style: TextStyle(
                  color: entry.value.toString().contains('❌') 
                      ? Colors.red 
                      : entry.value.toString().contains('⚠️') 
                          ? Colors.orange 
                          : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          
          if (entry.value is Map<String, dynamic>) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  ...(entry.value as Map<String, dynamic>).entries.map((subEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text('  ${subEntry.key}: ${subEntry.value}'),
                    );
                  }),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text('${entry.key}: ${entry.value}'),
          );
        }),
      ],
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            status ? 'Yes' : 'No',
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