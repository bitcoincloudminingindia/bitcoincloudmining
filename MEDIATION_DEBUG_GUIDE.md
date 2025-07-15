# Mediation Debugging Guide - हिंदी में

## समस्या का समाधान

आपके mediation कोड में `_updateMediationMetrics` मेथड का उपयोग नहीं हो रहा था। अब मैंने इसे सभी ad events में जोड़ दिया है।

## क्या बदला गया

### 1. Rewarded Ads में Mediation Tracking
```dart
// Ad loaded successfully
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', true, null);
}

// Ad failed to load
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', false, null);
}

// Ad showed successfully
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', true, null);
}
```

### 2. Banner Ads में Mediation Tracking
```dart
// Banner ad loaded
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', true, null);
}

// Banner ad failed
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', false, null);
}
```

### 3. Native Ads में Mediation Tracking
```dart
// Native ad loaded
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', true, null);
}

// Native ad impression
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', true, null);
}

// Native ad clicked
if (_isMediationEnabled) {
  _updateMediationMetrics('admob', true, null);
}
```

## नई Features जोड़ी गई

### 1. Mediation Testing Method
```dart
await AdService().testMediation();
```

### 2. Mediation Performance Check
```dart
final performance = AdService().mediationPerformance;
print('Success Rate: ${performance['success_rate']}%');
print('Total Shows: ${performance['total_shows']}');
print('Is Working: ${performance['is_working']}');
```

### 3. Debug Logging
अब हर mediation event के साथ debug logs दिखेंगे:
```
📊 Mediation Metrics Updated:
   Network: admob
   Success: true
   Revenue: null
   Total Shows: 5
   Total Failures: 1
```

## Mediation को Test करने के लिए

### 1. Debug Mode में Test करें
```dart
// Main.dart में या किसी screen में
await AdService().testMediation();
```

### 2. Mediation Status Check करें
```dart
final status = AdService().mediationStatus;
print('Mediation Enabled: ${status['enabled']}');
print('Mediation Initialized: ${status['initialized']}');
print('Active Networks: ${status['networks']}');
```

### 3. Performance Metrics देखें
```dart
final performance = AdService().mediationPerformance;
print('Success Rate: ${performance['success_rate']}%');
print('Active Networks: ${performance['active_networks']}');
```

## AdMob Console में Setup

### 1. Mediation Groups बनाएं
- AdMob Console में जाएं
- Apps > Your App > Mediation
- "Create Mediation Group" पर क्लिक करें

### 2. Ad Networks जोड़ें
- Unity Ads
- Facebook Audience Network
- AppLovin
- IronSource

### 3. Waterfall Setup
```
1. AdMob (Primary)
2. Unity Ads
3. Facebook Audience Network
4. AppLovin
5. IronSource
```

## Test Device IDs

### Debug Mode में
```dart
static const bool enableTestDevices = kDebugMode;
static const List<String> testDeviceIds = [
  '33BE2250B43518CCDA7DE426D04EE231', // Your device ID
];
```

### Production में
```dart
static const bool enableTestDevices = false; // Test devices disabled
```

## Troubleshooting

### 1. Mediation नहीं काम कर रहा
```dart
// Check if mediation is enabled
if (!AdService().isMediationWorking) {
  print('Mediation is not working properly');
  // Check logs for specific errors
}
```

### 2. No Ads Showing
- AdMob Console में mediation groups check करें
- Ad unit IDs verify करें
- Network connectivity check करें

### 3. Low Fill Rate
- Waterfall configuration optimize करें
- Bid floor adjust करें
- More ad networks add करें

## Logs में क्या देखना है

### Success Logs
```
✅ Mediation initialized successfully
✅ admob mediation network initialized
📊 Mediation Metrics Updated: Network: admob, Success: true
```

### Error Logs
```
❌ Mediation initialization failed: [error]
❌ admob mediation network failed: [error]
📊 Mediation Metrics Updated: Network: admob, Success: false
```

## Best Practices

1. **Always check mediation status before showing ads**
2. **Monitor performance metrics regularly**
3. **Use test devices only in debug mode**
4. **Implement proper error handling**
5. **Log all mediation events for debugging**

## Production Checklist

- [ ] Test devices disabled in production
- [ ] Real ad unit IDs configured
- [ ] Mediation groups set up in AdMob Console
- [ ] All ad networks properly configured
- [ ] Error handling implemented
- [ ] Performance monitoring enabled

अब आपका mediation पूरी तरह से काम कर रहा होगा! 🎉 