import 'dart:async';
import 'dart:io';

class NetworkOptimizer {
  static final NetworkOptimizer _instance = NetworkOptimizer._internal();
  factory NetworkOptimizer() => _instance;
  NetworkOptimizer._internal();

  // Connection quality tracking
  static final List<Duration> _responseTimes = [];
  static const int _maxResponseTimes = 10;
  static bool _isOptimized = false;

  // Get average response time
  static Duration getAverageResponseTime() {
    if (_responseTimes.isEmpty) return const Duration(seconds: 5);

    final total = _responseTimes.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );
    return Duration(
        milliseconds: total.inMilliseconds ~/ _responseTimes.length);
  }

  // Track response time
  static void trackResponseTime(Duration responseTime) {
    _responseTimes.add(responseTime);
    if (_responseTimes.length > _maxResponseTimes) {
      _responseTimes.removeAt(0);
    }
  }

  // Get optimal timeout based on network performance
  static Duration getOptimalTimeout() {
    final avgResponseTime = getAverageResponseTime();
    final optimalTimeout = avgResponseTime * 3; // 3x average response time

    // Clamp between 5 and 30 seconds
    if (optimalTimeout.inSeconds < 5) {
      return const Duration(seconds: 5);
    } else if (optimalTimeout.inSeconds > 30) {
      return const Duration(seconds: 30);
    }

    return optimalTimeout;
  }

  // Check if network is slow
  static bool isNetworkSlow() {
    final avgResponseTime = getAverageResponseTime();
    return avgResponseTime.inSeconds > 10; // Consider slow if > 10 seconds
  }

  // Get network quality indicator
  static String getNetworkQuality() {
    final avgResponseTime = getAverageResponseTime();

    if (avgResponseTime.inSeconds < 3) {
      return 'Excellent';
    } else if (avgResponseTime.inSeconds < 7) {
      return 'Good';
    } else if (avgResponseTime.inSeconds < 15) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  // Initialize network optimizer
  static Future<void> initialize() async {
    try {
      await optimizeConnection();
    } catch (e) {
      // If initialization fails, continue with default settings
    }
  }

  // Optimize connection settings
  static Future<void> optimizeConnection() async {
    if (_isOptimized) return;

    try {
      // Test connection speed
      final stopwatch = Stopwatch()..start();

      // Try to reach a reliable host
      await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();
      trackResponseTime(stopwatch.elapsed);

      _isOptimized = true;
    } catch (e) {
      // If optimization fails, use default settings
      _isOptimized = false;
    }
  }

  // Get optimization recommendations
  static List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    final avgResponseTime = getAverageResponseTime();

    if (avgResponseTime.inSeconds > 10) {
      recommendations.add(
          'Your network connection is slow. Consider switching to a faster connection.');
    }

    if (_responseTimes.length < 3) {
      recommendations.add(
          'Network optimization is still learning your connection patterns.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Your network connection is performing well!');
    }

    return recommendations;
  }

  // Clear optimization data
  static void clearOptimizationData() {
    _responseTimes.clear();
    _isOptimized = false;
  }
}
