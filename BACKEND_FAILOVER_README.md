# Backend Failover System for Flutter

This document describes the intelligent backend failover system implemented for the Bitcoin Cloud Mining Flutter app. The system automatically switches between primary (Render) and secondary (Railway) backends based on availability and performance.

## 🎯 Features

- **Automatic Backend Selection**: Intelligently chooses between primary and secondary backends
- **Health Checking**: Pings `/health`, `/api/health`, and `/status` endpoints with 3-second timeout
- **Smart Caching**: Caches the selected backend for 5 minutes to avoid repeated health checks
- **Persistent Storage**: Remembers the last working backend across app restarts
- **Retry Logic**: Automatic retry with exponential backoff on failures
- **Development Mode Support**: Uses local servers during development, production servers in release builds
- **Zero Configuration**: Works out of the box with existing API calls

## 🔧 System Architecture

### Primary Components

1. **BackendFailoverManager** (`lib/services/backend_failover_manager.dart`)
   - Singleton class managing backend selection and health checks
   - Handles caching, storage, and failover logic

2. **Updated ApiConfig** (`lib/config/api_config.dart`)
   - Integrates with BackendFailoverManager for production builds
   - Maintains existing local development URLs

3. **Updated ApiService** (`lib/services/api_service.dart`)
   - Uses failover manager for production API calls
   - Maintains existing functionality for development

### Backend URLs

- **Primary**: `https://bitcoincloudmining.onrender.com` (Render)
- **Secondary**: `https://bitcoincloudmining-production.up.railway.app` (Railway)
- **Development**: Local servers (`localhost:5000` or `10.0.2.2:5000`)

## 🚀 Quick Start

### 1. Initialize During App Startup

Add this to your `main.dart`:

```dart
import 'package:your_app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the failover system
  await ApiService.initializeFailover();
  
  runApp(MyApp());
}
```

### 2. Use Existing API Calls (No Changes Required!)

Your existing API calls automatically use the failover system in production:

```dart
// This already uses failover in production builds
final response = await ApiService().login(email, password);

// All existing methods work the same
final balance = await ApiService().getWalletBalance();
final transactions = await ApiService().getTransactions();
```

### 3. Optional: Monitor Backend Status

```dart
import 'package:your_app/services/backend_failover_manager.dart';

// Check current backend
final currentBackend = BackendFailoverManager().getCachedBackendUrl();
print('Using backend: $currentBackend');

// Get detailed status
final status = BackendFailoverManager().getStatus();
print('Status: $status');

// Force refresh backend selection
final newBackend = await BackendFailoverManager().forceRefresh();
print('New backend: $newBackend');
```

## 📋 How It Works

### Health Check Process

1. **Primary Check**: Tests Render backend health (`/health`, `/api/health`, `/status`)
2. **Fallback**: If primary fails, tests Railway backend
3. **Caching**: Successful backend is cached for 5 minutes
4. **Storage**: Selected backend is persisted for next app launch
5. **Timeout**: Each health check has a 3-second timeout

### Request Flow

```
API Call → Environment Check → Backend Selection → HTTP Request
    ↓
Production Build?
    ↓ YES                    ↓ NO
BackendFailoverManager → Local Development Server
    ↓
Cached Backend Available?
    ↓ YES                    ↓ NO
Use Cached Backend → Perform Health Check
    ↓                        ↓
Make Request ← Select Best Backend
```

### Error Handling

- **Network Errors**: Automatic failover to secondary backend
- **Timeouts**: Switch backends after 3-second timeout
- **Server Errors** (5xx): Retry with secondary backend
- **DNS Issues**: Automatic backend switching
- **All Backends Down**: Falls back to stored/default backend

## 🛠️ Configuration

### Timeouts and Retries

```dart
// In BackendFailoverManager
static const Duration _healthCheckTimeout = Duration(seconds: 3);
static const Duration _cacheValidityDuration = Duration(minutes: 5);
static const int _maxRetries = 2;
static const Duration _retryDelay = Duration(seconds: 1);
```

### Backend URLs

To add more backends or change URLs, modify `BackendFailoverManager`:

```dart
// Add more backends
static const String _primaryBackend = 'https://your-primary.com';
static const String _secondaryBackend = 'https://your-secondary.com';
static const String _tertiaryBackend = 'https://your-tertiary.com';
```

## 🧪 Testing

### Manual Testing

```dart
import 'package:your_app/examples/failover_usage_example.dart';

// Test backend status
await FailoverUsageExample.checkBackendStatus();

// Reset cache for testing
await FailoverUsageExample.resetFailoverCache();

// Test login with failover
final result = await FailoverUsageExample.loginWithFailover(
  'test@example.com', 
  'password'
);
```

### Debug Information

The system provides detailed debug logs:

```
🚀 Failover system initialized with backend: https://bitcoincloudmining.onrender.com
✅ Backend healthy: https://bitcoincloudmining.onrender.com/health (200)
🔄 Primary backend failed, switching to secondary...
🎯 Active backend: https://bitcoincloudmining-production.up.railway.app
⚠️ Both backends failed, using stored or default
```

## 🔍 Monitoring and Debugging

### Status Widget

Add a backend status indicator to your UI:

```dart
import 'package:your_app/examples/failover_usage_example.dart';

// In your AppBar or status bar
FailoverUsageExample.buildBackendStatusWidget()
```

### Status Information

```dart
final status = BackendFailoverManager().getStatus();
print('Current backend: ${status['cachedBackendUrl']}');
print('Last health check: ${status['lastHealthCheck']}');
print('Cache valid: ${status['isCacheValid']}');
print('Health checking: ${status['isHealthChecking']}');
```

## 🚨 Troubleshooting

### Common Issues

1. **No Backend Response**
   ```dart
   // Force refresh the backend selection
   await BackendFailoverManager().forceRefresh();
   ```

2. **Stuck on Wrong Backend**
   ```dart
   // Clear cache and reinitialize
   await BackendFailoverManager().clearCache();
   await ApiService.initializeFailover();
   ```

3. **Development Mode Not Working**
   - Ensure your local server is running on correct port
   - Check that `kDebugMode` is true in development builds

### Debug Steps

1. Check current backend: `BackendFailoverManager().getCachedBackendUrl()`
2. View status: `BackendFailoverManager().getStatus()`
3. Force health check: `BackendFailoverManager().forceRefresh()`
4. Clear cache: `BackendFailoverManager().clearCache()`

## 📊 Performance Impact

- **Cold Start**: ~100-500ms for initial backend selection
- **Cached Requests**: ~0ms additional overhead
- **Failover**: ~3-6 seconds for complete backend switch
- **Memory**: ~1KB for status and cache data
- **Storage**: ~50 bytes for backend URL persistence

## 🔄 Migration Guide

### From Existing API Implementation

**No code changes required!** The failover system is:

- ✅ **Backward Compatible**: All existing API calls work unchanged
- ✅ **Transparent**: Failover happens automatically
- ✅ **Optional**: Can be disabled by modifying environment checks
- ✅ **Development Friendly**: Uses local servers in debug mode

### Optional Enhancements

1. **Add Initialization**: Call `ApiService.initializeFailover()` in `main()`
2. **Add Monitoring**: Use status widgets for backend visibility
3. **Add Manual Controls**: Implement force refresh buttons for testing

## 🎛️ Advanced Usage

### Custom Health Check Endpoints

Modify the health check endpoints in `BackendFailoverManager`:

```dart
final healthEndpoints = ['/health', '/api/health', '/status', '/ping'];
```

### Custom Backend Selection Logic

Override the health check logic:

```dart
Future<bool> _isBackendHealthy(String baseUrl) async {
  // Your custom health check logic
  // Consider response time, custom headers, etc.
}
```

### Integration with Analytics

```dart
// Track backend switches
Analytics.track('backend_switched', {
  'from': oldBackend,
  'to': newBackend,
  'reason': 'health_check_failed',
});
```

## 🔐 Security Considerations

- ✅ **HTTPS Only**: Both backends use secure connections
- ✅ **Token Security**: Auth tokens are properly handled
- ✅ **Request Validation**: All requests maintain existing security headers
- ✅ **Error Handling**: No sensitive data leaked in error messages

## 📈 Monitoring Recommendations

1. **Backend Response Times**: Monitor health check durations
2. **Failover Frequency**: Track how often backends switch
3. **Error Rates**: Monitor failed requests per backend
4. **User Impact**: Track user experience during failovers

## 🤝 Contributing

When modifying the failover system:

1. Test with both backends available
2. Test with primary backend down
3. Test with both backends down
4. Test development mode functionality
5. Verify performance impact

## 📝 Changelog

### v1.0.0 (Current)
- ✅ Initial implementation with Render/Railway backends
- ✅ Health checking with 3-second timeout
- ✅ 5-minute caching system
- ✅ Persistent storage for backend selection
- ✅ Development mode support
- ✅ Comprehensive error handling
- ✅ Zero-configuration integration

---

**Need Help?** Check the example usage in `lib/examples/failover_usage_example.dart` or review the implementation in `lib/services/backend_failover_manager.dart`.