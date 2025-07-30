import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/consent_service.dart';

/// Updated Ad Usage Example
/// यह example दिखाता है कि updated ad service को कैसे use करें
/// with proper consent management और safe ad placement

class UpdatedAdUsageExample extends StatefulWidget {
  const UpdatedAdUsageExample({super.key});

  @override
  State<UpdatedAdUsageExample> createState() => _UpdatedAdUsageExampleState();
}

class _UpdatedAdUsageExampleState extends State<UpdatedAdUsageExample> {
  final AdService _adService = AdService();
  final ConsentService _consentService = ConsentService();

  @override
  void initState() {
    super.initState();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    // Initialize consent service first
    await _consentService.initialize();
    
    // Initialize ad service (will check consent automatically)
    await _adService.initialize();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updated Ad Usage Example'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConsentSection(),
            const SizedBox(height: 20),
            _buildBannerAdSection(),
            const SizedBox(height: 20),
            _buildRewardedAdSection(),
            const SizedBox(height: 20),
            _buildNativeAdSection(),
            const SizedBox(height: 20),
            _buildAdMetricsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Consent Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_consentService.isInitialized) ...[
              _buildStatusIndicator(
                'Consent Required',
                _consentService.isConsentRequired ? 'हां' : 'नहीं',
                _consentService.isConsentRequired ? Colors.orange : Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(
                'User Consent',
                _consentService.hasUserConsent ? 'दिया गया' : 'नहीं दिया',
                _consentService.hasUserConsent ? Colors.green : Colors.red,
              ),
            ] else
              const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _consentService.showConsentDialog(context);
                      setState(() {});
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Show Consent Dialog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _consentService.revokeConsent();
                      setState(() {});
                    },
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Revoke Consent'),
                  ),
                ),
              ],
            ),
            // Consent Management Widget
            const SizedBox(height: 16),
            const ConsentManagementWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAdSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.view_headline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Banner Ad (30s Auto-Refresh)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusIndicator(
              'Banner Ad Status',
              _adService.isBannerAdLoaded ? 'Loaded' : 'Not Loaded',
              _adService.isBannerAdLoaded ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            // Safe Banner Ad with Protection
            if (_consentService.hasUserConsent)
              FutureBuilder<Widget?>(
                future: _adService.getBannerAdWidget(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return snapshot.data!;
                  }
                  return Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Text(
                        'Banner Ad Loading...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'Consent Required for Ads',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (await _adService.ensureConsentAndShowAds(context)) {
                  await _adService.loadBannerAd();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reload Banner Ad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardedAdSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Rewarded Ad (Complete View Required)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusIndicator(
              'Rewarded Ad Status',
              _adService.isRewardedAdLoaded ? 'Ready' : 'Loading',
              _adService.isRewardedAdLoaded ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _adService.isRewardedAdLoaded
                        ? () async {
                            if (await _adService.ensureConsentAndShowAds(context)) {
                              final success = await _adService.showRewardedAd(
                                onRewarded: (reward) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Reward Earned: ${reward.toStringAsFixed(1)} coins!',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.green[600],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                onAdDismissed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ad dismissed without reward',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                              
                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ad failed to load',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              
                              setState(() {});
                            }
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Show Rewarded Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (await _adService.ensureConsentAndShowAds(context)) {
                        await _adService.loadRewardedAd();
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAdSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.view_module,
                  color: Colors.purple[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Native Ad (Auto-Refresh)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusIndicator(
              'Native Ad Status',
              _adService.isNativeAdLoaded ? 'Loaded' : 'Loading',
              _adService.isNativeAdLoaded ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            // Native Ad Display
            if (_consentService.hasUserConsent)
              _adService.getNativeAd()
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'Consent Required for Native Ads',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (await _adService.ensureConsentAndShowAds(context)) {
                  await _adService.refreshNativeAd();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Native Ad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdMetricsSection() {
    final metrics = _adService.adMetrics;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.indigo[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ad Performance Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricRow('Total Shows', metrics['total_shows'].toString()),
            _buildMetricRow('Successful Shows', metrics['successful_shows'].toString()),
            _buildMetricRow('Failed Shows', metrics['failed_shows'].toString()),
            _buildMetricRow(
              'Success Rate',
              '${metrics['success_rate'].toStringAsFixed(1)}%',
            ),
            _buildMetricRow(
              'Average Load Time',
              '${metrics['average_load_time'].toStringAsFixed(0)}ms',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }
}

/// Usage Instructions:
/// 
/// 1. Banner Ad Auto-Refresh:
///    - अब 30 seconds में auto-refresh होता है (minimum requirement)
///    - Accidental clicks से बचाव के लिए padding और border
/// 
/// 2. Rewarded Ad:
///    - Complete viewing validation (minimum 15 seconds)
///    - Reward तभी मिलेगा जब पूरा ad देखा हो
/// 
/// 3. Ad Placement:
///    - Safe margins और padding
///    - Clear ad labels ("विज्ञापन")
///    - Error boundaries के साथ
/// 
/// 4. Consent Management:
///    - GDPR/CCPA compliance
///    - User को choice देना
///    - Settings में manage करने का option
/// 
/// Example Integration:
/// ```dart
/// // In your main app:
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: FutureBuilder(
///         future: _initializeServices(),
///         builder: (context, snapshot) {
///           if (snapshot.connectionState == ConnectionState.done) {
///             return HomePage();
///           }
///           return SplashScreen();
///         },
///       ),
///     );
///   }
/// 
///   Future<void> _initializeServices() async {
///     final adService = AdService();
///     await adService.initialize(); // Will handle consent automatically
///   }
/// }
/// ```