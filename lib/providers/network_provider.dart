import 'dart:async';

import 'package:bitcoin_cloud_mining/services/network_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkService _networkService = NetworkService();

  bool _isConnected = true;
  String _connectionType = 'Unknown';
  bool _isInitialized = false;
  String _currentServer = 'Singapore';
  String? _userLocation;

  // Getters
  bool get isConnected => _isConnected;
  String get connectionType => _connectionType;
  bool get isInitialized => _isInitialized;
  Stream<bool> get connectionStatus => _networkService.connectionStatus;
  String get currentServer => _currentServer;
  String? get userLocation => _userLocation;
  set currentServer(String value) {
    _currentServer = value;
    notifyListeners();
  }

  // Initialize network monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _networkService.initialize();

      // Get initial connection type
      _connectionType = await _networkService.getConnectionType();

      // Listen to connection status changes
      _networkService.connectionStatus.listen((isConnected) {
        _isConnected = isConnected;
        _updateConnectionType();
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {}
  }

  // Update connection type
  Future<void> _updateConnectionType() async {
    try {
      _connectionType = await _networkService.getConnectionType();
    } catch (e) {}
  }

  // Force check connection
  Future<bool> checkConnection() async {
    try {
      final isConnected = await _networkService.checkConnection();
      _isConnected = isConnected;
      await _updateConnectionType();
      notifyListeners();
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  // Get network status message
  String getNetworkStatusMessage() {
    if (!_isConnected) {
      return 'No internet connection';
    }

    switch (_connectionType) {
      case 'WiFi':
        return 'Connected via WiFi';
      case 'Mobile Data':
        return 'Connected via Mobile Data';
      case 'Ethernet':
        return 'Connected via Ethernet';
      default:
        return 'Connected';
    }
  }

  // Get network status icon
  String getNetworkStatusIcon() {
    if (!_isConnected) {
      return 'wifi_off';
    }

    switch (_connectionType) {
      case 'WiFi':
        return 'wifi';
      case 'Mobile Data':
        return 'signal_cellular_4_bar';
      case 'Ethernet':
        return 'ethernet';
      default:
        return 'wifi';
    }
  }

  // Get network status color
  int getNetworkStatusColor() {
    if (!_isConnected) {
      return 0xFFE53935; // Red
    }

    switch (_connectionType) {
      case 'WiFi':
        return 0xFF4CAF50; // Green
      case 'Mobile Data':
        return 0xFF2196F3; // Blue
      case 'Ethernet':
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF4CAF50; // Green
    }
  }

  // Check if app can function without internet
  bool canFunctionOffline() {
    // Define which features can work offline
    return false; // For now, all features require internet
  }

  // Get offline message
  String getOfflineMessage() {
    return 'This app requires an internet connection to function properly. Please check your connection and try again.';
  }

  // Set user location from coordinates (reverse geocode)
  Future<void> setUserLocationFromCoordinates(
      double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        _userLocation = [
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
          if (place.country != null && place.country!.isNotEmpty) place.country
        ].whereType<String>().join(', ');
      } else {
        _userLocation = 'Unknown';
      }
    } catch (e) {
      _userLocation = 'Unknown';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }
}
