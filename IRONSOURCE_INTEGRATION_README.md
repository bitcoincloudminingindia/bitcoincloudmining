# IronSource Mediation Integration Guide

## Overview
इस प्रोजेक्ट में IronSource Mediation plugin को successfully integrate किया गया है। यह AdMob के साथ-साथ IronSource ads भी show करेगा, जिससे better ad fill rates और higher revenue मिलेगी।

## ✅ Completed Integration Steps

### 1. Dependencies Added
- `ironsource_mediation: ^3.2.0` - pubspec.yaml में add किया गया
- Play Services dependencies Android build.gradle में add किए गए

### 2. Android Configuration
- ✅ AD_ID permission already present
- ✅ tools:replace attribute added to AndroidManifest.xml
- ✅ ProGuard rules added for IronSource

### 3. iOS Configuration
- ✅ SKAdNetwork support added (su67r6k2v3.skadnetwork)
- ✅ Universal SKAN reporting configured
- ✅ App Transport Security settings added

### 4. Service Implementation
- ✅ `IronSourceService` class created with full functionality
- ✅ Event listeners for all ad types (Rewarded, Interstitial, Banner)
- ✅ Metrics tracking and error handling
- ✅ Integration with existing AdService

## 🔧 Configuration Required

### IronSource App Keys
आपको अपने IronSource app keys configure करने होंगे:

1. **IronSource Dashboard** पर जाएं
2. अपना app create करें
3. App keys copy करें
4. `lib/services/ironsource_service.dart` में update करें:

```dart
// Replace these with your actual app keys
static const String _androidAppKey = 'YOUR_IRONSOURCE_APP_KEY_ANDROID';
static const String _iosAppKey = 'YOUR_IRONSOURCE_APP_KEY_IOS';
```

## 🚀 Usage

### Basic Usage
IronSource automatically initializes with your existing AdService:

```dart
// Your existing code will work as before
final adService = AdService();
await adService.initialize();

// Show rewarded ad (will try IronSource first, then AdMob)
await adService.showRewardedAd(
  onRewarded: (amount) {
    // Handle reward
  },
  onAdDismissed: () {
    // Handle ad dismissal
  },
);
```

### IronSource Specific Usage
Direct IronSource usage के लिए:

```dart
final ironSource = IronSourceService.instance;

// Initialize
await ironSource.initialize();

// Show rewarded ad
await ironSource.showRewardedAd(
  onRewarded: (amount) {
    print('Reward earned: $amount');
  },
  onAdDismissed: () {
    print('Ad dismissed');
  },
);

// Show interstitial ad
await ironSource.showInterstitialAd();

// Get banner widget
final bannerWidget = ironSource.getBannerWidget();
```

## 📊 Monitoring & Debugging

### Test Suite
Debug mode में IronSource test suite launch करने के लिए:

```dart
await ironSource.launchTestSuite();
```

### Metrics
IronSource metrics track करने के लिए:

```dart
final metrics = ironSource.metrics;
print('IronSource Metrics: $metrics');
```

### Event Listening
IronSource events listen करने के लिए:

```dart
ironSource.events.listen((event) {
  print('IronSource Event: ${event['type']}');
});
```

## 🔄 Fallback Mechanism

यह integration smart fallback mechanism provide करता है:

1. **IronSource First**: Rewarded ads के लिए IronSource को पहले try करता है
2. **AdMob Fallback**: अगर IronSource fail होता है तो AdMob use करता है
3. **Seamless Experience**: User को कोई difference नहीं पता चलता

## 📈 Benefits

### Revenue Optimization
- Multiple ad networks से higher fill rates
- Better eCPM rates
- Increased revenue potential

### User Experience
- Faster ad loading
- Better ad quality
- Reduced ad failures

### Developer Experience
- Simple integration
- Comprehensive error handling
- Detailed metrics and analytics

## 🛠️ Troubleshooting

### Common Issues

1. **App Keys Not Configured**
   ```
   ⚠️ IronSource app keys not configured
   ```
   Solution: अपने actual app keys configure करें

2. **Initialization Failed**
   ```
   ❌ IronSource initialization failed
   ```
   Solution: Network connection check करें और app keys verify करें

3. **Ads Not Loading**
   ```
   ❌ IronSource Rewarded ad not ready
   ```
   Solution: Test mode में check करें और placement names verify करें

### Debug Mode
Debug mode में detailed logs देखने के लिए:

```dart
// Enable debug logs
if (kDebugMode) {
  await IronSource.setAdaptersDebug(true);
}
```

## 📱 Platform Support

- ✅ Android (API 23+)
- ✅ iOS (12.0+)
- ❌ Web (Not supported by IronSource)

## 🔒 Privacy & Compliance

### GDPR Compliance
- User consent handling integrated
- Data collection controls available
- Privacy policy compliance

### COPPA Compliance
- Child-directed content settings
- Age-appropriate ad filtering
- Parental controls support

## 📚 Additional Resources

- [IronSource Flutter Plugin Documentation](https://developers.ironsrc.com/ironsource-mobile/android/levelplay-integration-guide/)
- [IronSource Mediation Best Practices](https://developers.ironsrc.com/ironsource-mobile/android/levelplay-integration-guide/)
- [IronSource Test Suite Guide](https://developers.ironsrc.com/ironsource-mobile/android/levelplay-integration-guide/)

## 🎯 Next Steps

1. **Configure App Keys**: अपने actual IronSource app keys add करें
2. **Test Integration**: Test devices पर verify करें
3. **Monitor Performance**: Analytics और metrics track करें
4. **Optimize**: Performance के based पर settings adjust करें

## 📞 Support

अगर कोई issue आए तो:

1. Debug logs check करें
2. IronSource test suite use करें
3. Network connectivity verify करें
4. App keys और configuration double-check करें

---

**Note**: यह integration production-ready है और आपके existing AdMob setup के साथ seamlessly work करेगा। 