import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/storage_utils.dart';

/// Singleton class that manages backend failover logic
/// Automatically switches between primary (Render) and secondary (Railway) backends
class BackendFailoverManager {
  static final BackendFailoverManager _instance = BackendFailoverManager._internal();
  factory BackendFailoverManager() => _instance;
  BackendFailoverManager._internal();

  // Backend URLs
  static const String _primaryBackend = 'https://bitcoincloudmining.onrender.com';
  static const String _secondaryBackend = 'https://bitcoincloudmining-production.up.railway.app';
  
  // Configuration
  static const Duration _healthCheckTimeout = Duration(seconds: 3);
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 1);

  // Cache variables
  String? _cachedBackendUrl;
  DateTime? _lastHealthCheck;
  bool _isHealthChecking = false;

  // Storage key for persisting the selected backend
  static const String _storageKey = 'selected_backend_url';

  /// Get the currently active backend URL
  /// Returns cached URL if available and valid, otherwise performs health check
  Future<String> getActiveBackendUrl() async {
    // Return cached URL if it's still valid
    if (_isCacheValid()) {
      return _cachedBackendUrl!;
    }

    // Avoid concurrent health checks
    if (_isHealthChecking) {
      // Wait for ongoing health check to complete
      int attempts = 0;
      while (_isHealthChecking && attempts < 30) { // Max 3 seconds wait
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (_cachedBackendUrl != null) {
        return _cachedBackendUrl!;
      }
    }

    return await _performHealthCheck();
  }

  /// Perform health check on both backends and select the best one
  Future<String> _performHealthCheck() async {
    if (_isHealthChecking) return _cachedBackendUrl ?? _primaryBackend;
    
    _isHealthChecking = true;
    
    try {
      // Try to load previously successful backend from storage
      final storedBackend = await _loadStoredBackend();
      
      // Check primary backend first
      if (await _isBackendHealthy(_primaryBackend)) {
        await _updateCache(_primaryBackend);
        return _primaryBackend;
      }

      debugPrint('🔄 Primary backend failed, switching to secondary...');

      // If primary fails, try secondary
      if (await _isBackendHealthy(_secondaryBackend)) {
        await _updateCache(_secondaryBackend);
        return _secondaryBackend;
      }

      debugPrint('⚠️ Both backends failed, using stored or default');

      // If both fail, use stored backend or fall back to primary
      final fallbackUrl = storedBackend ?? _primaryBackend;
      await _updateCache(fallbackUrl);
      return fallbackUrl;

    } finally {
      _isHealthChecking = false;
    }
  }

  /// Check if a backend is healthy by hitting its health endpoint
  Future<bool> _isBackendHealthy(String baseUrl) async {
    try {
      final healthEndpoints = ['/health', '/api/health', '/status'];
      
      for (String endpoint in healthEndpoints) {
        try {
          final url = Uri.parse('$baseUrl$endpoint');
          final response = await http.get(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'User-Agent': 'BitcoinCloudMining-App/1.0',
            },
          ).timeout(_healthCheckTimeout);

          if (response.statusCode >= 200 && response.statusCode < 400) {
            debugPrint('✅ Backend healthy: $baseUrl$endpoint (${response.statusCode})');
            return true;
          }
        } catch (e) {
          // Try next endpoint
          continue;
        }
      }

      debugPrint('❌ Backend unhealthy: $baseUrl');
      return false;

    } on SocketException catch (e) {
      debugPrint('❌ Network error for $baseUrl: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout for $baseUrl: $e');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking $baseUrl: $e');
      return false;
    }
  }

  /// Update cache with new backend URL and persist to storage
  Future<void> _updateCache(String backendUrl) async {
    _cachedBackendUrl = backendUrl;
    _lastHealthCheck = DateTime.now();
    
    // Persist to storage for next app launch
    try {
      await StorageUtils.setValue(_storageKey, backendUrl);
    } catch (e) {
      debugPrint('Warning: Failed to persist backend URL: $e');
    }
    
    debugPrint('🎯 Active backend: $backendUrl');
  }

  /// Check if the cached backend URL is still valid
  bool _isCacheValid() {
    return _cachedBackendUrl != null &&
           _lastHealthCheck != null &&
           DateTime.now().difference(_lastHealthCheck!) < _cacheValidityDuration;
  }

  /// Load previously stored backend URL
  Future<String?> _loadStoredBackend() async {
    try {
      return await StorageUtils.getValue(_storageKey);
    } catch (e) {
      debugPrint('Warning: Failed to load stored backend URL: $e');
      return null;
    }
  }

  /// Force refresh the backend selection (useful for manual retry)
  Future<String> forceRefresh() async {
    _cachedBackendUrl = null;
    _lastHealthCheck = null;
    return await getActiveBackendUrl();
  }

  /// Get the current cached backend URL without performing health check
  String? getCachedBackendUrl() => _cachedBackendUrl;

  /// Check if the manager is currently performing a health check
  bool get isHealthChecking => _isHealthChecking;

  /// Make an HTTP request with automatic failover
  /// This is a helper method that combines failover logic with HTTP requests
  Future<http.Response> makeRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount <= _maxRetries) {
      try {
        final backendUrl = await getActiveBackendUrl();
        final url = Uri.parse('$backendUrl$endpoint');

        late http.Response response;
        final requestTimeout = timeout ?? const Duration(seconds: 30);

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(url, headers: headers).timeout(requestTimeout);
            break;
          case 'POST':
            response = await http.post(url, headers: headers, body: body).timeout(requestTimeout);
            break;
          case 'PUT':
            response = await http.put(url, headers: headers, body: body).timeout(requestTimeout);
            break;
          case 'DELETE':
            response = await http.delete(url, headers: headers).timeout(requestTimeout);
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }

        // If request succeeds, return response
        if (response.statusCode < 500) {
          return response;
        }

        // If server error, try failover
        throw HttpException('Server error: ${response.statusCode}');

      } on SocketException catch (e) {
        lastException = e;
        debugPrint('Network error on attempt ${retryCount + 1}: $e');
      } on TimeoutException catch (e) {
        lastException = e;
        debugPrint('Timeout on attempt ${retryCount + 1}: $e');
      } on HttpException catch (e) {
        lastException = e;
        debugPrint('HTTP error on attempt ${retryCount + 1}: $e');
      } catch (e) {
        lastException = Exception(e.toString());
        debugPrint('Unexpected error on attempt ${retryCount + 1}: $e');
      }

      retryCount++;

      if (retryCount <= _maxRetries) {
        // Force refresh backend selection and wait before retry
        await forceRefresh();
        await Future.delayed(_retryDelay * retryCount);
      }
    }

    // If all retries failed, throw the last exception
    throw lastException ?? Exception('All retry attempts failed');
  }

  /// Clear cache and stored backend (useful for testing or manual reset)
  Future<void> clearCache() async {
    _cachedBackendUrl = null;
    _lastHealthCheck = null;
    try {
      await StorageUtils.removeValue(_storageKey);
    } catch (e) {
      debugPrint('Warning: Failed to clear stored backend URL: $e');
    }
  }

  /// Get status information about the failover manager
  Map<String, dynamic> getStatus() {
    return {
      'cachedBackendUrl': _cachedBackendUrl,
      'lastHealthCheck': _lastHealthCheck?.toIso8601String(),
      'isCacheValid': _isCacheValid(),
      'isHealthChecking': _isHealthChecking,
      'primaryBackend': _primaryBackend,
      'secondaryBackend': _secondaryBackend,
    };
  }
}