# IronSource Integration Guide - Ad Loading Priority & Conflicts

## 🎯 Ad Loading Priority

### 1. **Native Ads**
```
1. AdMob Native Ad (primary)
2. Placeholder/Error UI (if fails)
```

### 2. **Rewarded Ads Priority**
```
1. IronSource Rewarded Ad (if available and loaded)
2. AdMob Rewarded Ad (fallback)
3. Error handling (if both fail)
```

### 3. **Banner Ads Priority**
```
1. AdMob Banner Ad (primary)
2. IronSource Banner Ad (future implementation)
3. Placeholder UI (if both fail)
```

## 🔄 Integration Flow

### Native Ads Integration
```dart
// In AdService.getNativeAd()
Widget getNativeAd() {
  // Use AdMob native ad
  if (_isNativeAdLoaded && _nativeAd != null) {
    return AdWidget(ad: _nativeAd!); // AdMob ad displayed
  }

  // Loading/Error state
  return Container(/* Loading UI */);
}
```

### Rewarded Ads Integration
```dart
// In AdService.showRewardedAd()
Future<bool> showRewardedAd({...}) async {
  // 1. Try IronSource first (when methods are available)
  if (_ironSourceService.isInitialized && _ironSourceService.isRewardedAdLoaded) {
    final success = await _ironSourceService.showRewardedAd(...);
    if (success) return true;
  }

  // 2. Fallback to AdMob
  if (_isRewardedAdLoaded && _rewardedAd != null) {
    await _rewardedAd!.show(...);
    return true;
  }

  // 3. Error handling
  return false;
}
```

## ⚠️ Potential Conflicts & Solutions

### 1. **SDK Initialization Conflicts**
**Problem**: Both IronSource and AdMob trying to initialize simultaneously
**Solution**: Sequential initialization
```dart
// Initialize AdMob first
await MobileAds.instance.initialize();

// Then initialize IronSource
await _ironSourceService.initialize();
```

### 2. **Ad Loading**
**Solution**: Load AdMob ads
```dart
// Load AdMob ads
await loadNativeAd(); // AdMob
```

### 3. **Memory Management**
**Solution**: Proper disposal
```dart
void dispose() {
  _nativeAd?.dispose(); // AdMob
  super.dispose();
}
```

### 4. **Event Handling**
**Solution**: AdMob event handling
```dart
// AdMob events (existing)
// ... existing AdMob event handling
```

## 📊 Performance Impact

### Memory Usage
- **AdMob**: ~10-15MB additional memory

### Network Requests
- **AdMob**: 1-2 requests per ad load

### Load Times
- **AdMob**: 1-3 seconds

## 🎯 Ad Loading Strategy

### 1. **AdMob Loading**
```dart
Future<void> loadAds() async {
  // Load AdMob ads
  await loadNativeAd(); // AdMob
}
```

## 🔧 Configuration Required

### 1. **AdMob Configuration**
```dart
// In ad_service.dart
// AdMob ad unit IDs are already configured
```

### 2. **AdMob Ad Unit IDs**
```dart
// In ad_service.dart
// Native ad unit IDs are already configured for Android and iOS
```

### 3. **Ad Unit IDs**
```dart
// Existing AdMob IDs (unchanged)
'banner': 'ca-app-pub-3537329799200606/2028008282',
'rewarded': 'ca-app-pub-3537329799200606/7827129874',
'native': 'ca-app-pub-3537329799200606/2260507229',
```

## 📈 Expected Results

### Fill Rate
- **Current**: 60-70% (AdMob)

### Revenue
- **Current**: $X per user (AdMob)

### User Experience
- **Current**: AdMob ads available
- **Fallback**: Loading/Error UI when ads unavailable

## 🛠️ Troubleshooting

### Common Issues

1. **AdMob not loading**
   - Check ad unit IDs
   - Verify AdMob account status
   - Check mediation settings

2. **Ads not loading**
   - Check internet connection
   - Verify consent settings
   - Check app permissions

### Debug Steps

1. **Check initialization status**
   ```dart
   print('AdMob: ${_isNativeAdLoaded}');
   ```

2. **Check ad service status**
   ```dart
   print('Ad Service: ${_adService.adMetrics}');
   ```

## 🎉 Benefits

### For Developers
- ✅ AdMob integration
- ✅ Fallback mechanism
- ✅ Detailed analytics

### For Users
- ✅ Ad availability
- ✅ Consistent experience
- ✅ Fast loading

### For Revenue
- ✅ AdMob revenue
- ✅ Optimized yield

---

**Note**: AdMob integration is complete with proper fallback mechanism. IronSource native ads have been removed. 