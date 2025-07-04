import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  Timer? _connectionCheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  bool get isConnected => _isConnected;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Initialize network monitoring
  Future<void> initialize() async {
    try {
      // Check initial connection status
      await _checkConnectionStatus();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (results) async {
          final result =
              results.isNotEmpty ? results.first : ConnectivityResult.none;
          await _handleConnectivityChange(result);
        },
      );

      // Start periodic connection check
      _startPeriodicConnectionCheck();

    } catch (e) {
    }
  }

  // Check current connection status
  Future<void> _checkConnectionStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      await _handleConnectivityChange(result);
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  // Handle connectivity changes
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    bool isConnected = false;
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        isConnected = await _canReachInternet();
        break;
      case ConnectivityResult.none:
      default:
        isConnected = false;
    }
    _updateConnectionStatus(isConnected);
  }

  // Check if we can actually reach the internet
  Future<bool> _canReachInternet() async {
    try {
      if (kIsWeb) {
        // For web, we'll assume connection is available
        return true;
      }

      // Try to reach a reliable host
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update connection status and notify listeners
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(isConnected);

    }
  }

  // Start periodic connection check
  void _startPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkConnectionStatus();
    });
  }

  // Force check connection status
  Future<bool> checkConnection() async {
    await _checkConnectionStatus();
    return _isConnected;
  }

  // Get connection type
  Future<String> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.none:
          return 'No Connection';
        default:
          return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionCheckTimer?.cancel();
    _connectionStatusController.close();
  }
}
