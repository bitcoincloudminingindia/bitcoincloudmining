import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    } catch (e) {}
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
      // Try to reach a reliable host with timeout
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
      // Dusra host try karo agar pehla fail ho jaye
      try {
        final result2 = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 3));
        if (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
      // Dono fail ho gaye
      return false;
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

  /// Utility: Check internet (multi-host) + backend health with timeout & retry
  Future<bool> checkInternetAndBackendHealth({int retries = 2}) async {
    final hosts = ['google.com', 'cloudflare.com', 'example.com'];
    bool internetOk = false;
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          internetOk = true;
          break;
        }
      } catch (_) {}
    }
    if (!internetOk) return false;
    // Backend health check
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('https://bitcoincloudmining.onrender.com/health'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) return true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionCheckTimer?.cancel();
    _connectionStatusController.close();
  }
}
