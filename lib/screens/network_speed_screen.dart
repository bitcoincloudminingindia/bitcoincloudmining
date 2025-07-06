import 'package:bitcoin_cloud_mining/services/api_service.dart'; // Added import for ApiService
import 'package:bitcoin_cloud_mining/utils/color_constants.dart';
import 'package:bitcoin_cloud_mining/utils/network_optimizer.dart';
import 'package:flutter/material.dart';

class NetworkSpeedScreen extends StatefulWidget {
  const NetworkSpeedScreen({super.key});

  @override
  State<NetworkSpeedScreen> createState() => _NetworkSpeedScreenState();
}

class _NetworkSpeedScreenState extends State<NetworkSpeedScreen> {
  bool _isTesting = false;
  String _networkQuality = 'Unknown';
  String _averageResponseTime = 'Unknown';
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isTesting = true;
    });

    try {
      // Get network quality
      final quality = NetworkOptimizer.getNetworkQuality();
      final avgTime = NetworkOptimizer.getAverageResponseTime();
      final recommendations = NetworkOptimizer.getOptimizationRecommendations();

      setState(() {
        _networkQuality = quality;
        _averageResponseTime = '${avgTime.inMilliseconds}ms';
        _recommendations = recommendations;
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      _isTesting = true;
    });

    try {
      // Clear cache before running speed test
      ApiService.clearCache();

      // Run a quick speed test
      await NetworkOptimizer.optimizeConnection();

      // Reload network info
      await _loadNetworkInfo();
    } catch (e) {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Color _getQualityColor() {
    switch (_networkQuality) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('नेटवर्क स्पीड टेस्ट'),
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network Quality Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          color: _getQualityColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'नेटवर्क क्वालिटी',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _networkQuality,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _getQualityColor(),
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Response Time Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: ColorConstants.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'औसत रिस्पॉन्स टाइम',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _averageResponseTime,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: ColorConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations Card
            if (_recommendations.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'सुझाव',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._recommendations.map((recommendation) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.arrow_right,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recommendation,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _runSpeedTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isTesting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('टेस्टिंग...'),
                        ],
                      )
                    : const Text('स्पीड टेस्ट चलाएं'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
