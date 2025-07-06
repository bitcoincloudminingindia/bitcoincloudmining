import 'package:bitcoin_cloud_mining/utils/network_optimizer.dart';
import 'package:flutter/material.dart';

class NetworkSpeedIndicator extends StatefulWidget {
  const NetworkSpeedIndicator({super.key});

  @override
  State<NetworkSpeedIndicator> createState() => _NetworkSpeedIndicatorState();
}

class _NetworkSpeedIndicatorState extends State<NetworkSpeedIndicator> {
  String _networkQuality = 'Unknown';
  Color _qualityColor = Colors.grey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateNetworkQuality();
  }

  void _updateNetworkQuality() {
    setState(() {
      _isLoading = true;
    });

    // Get network quality
    final quality = NetworkOptimizer.getNetworkQuality();
    Color color;

    switch (quality) {
      case 'Excellent':
        color = Colors.green;
        break;
      case 'Good':
        color = Colors.blue;
        break;
      case 'Fair':
        color = Colors.orange;
        break;
      case 'Poor':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    setState(() {
      _networkQuality = quality;
      _qualityColor = color;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _updateNetworkQuality,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _qualityColor.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _qualityColor.withAlpha(128),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              color: _qualityColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _networkQuality,
              style: TextStyle(
                color: _qualityColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
