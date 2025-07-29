# Mediation Setup Guide

## Overview
This app now supports AdMob mediation with multiple ad networks for better fill rate and revenue optimization.

## Supported Mediation Networks
- ✅ Unity Ads (Already configured)
- 🔧 Facebook Audience Network
- 🔧 AppLovin
- 🔧 IronSource

## Current Configuration

### 1. Android Dependencies (Already Added)
```kotlin
// android/app/build.gradle.kts
implementation("com.google.android.gms:play-services-ads:24.4.0")
implementation("com.unity3d.ads:unity-ads:4.15.1")
implementation("com.google.ads.mediation:unity:4.15.1.0")
```

### 2. AdMob App ID (Already Configured)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3537329799200606~9074161734" />
```

### 3. Ad Unit IDs (Production Ready)
```dart
// lib/services/ad_service.dart
'banner': 'ca-app-pub-3537329799200606/2028008282'   // Home_Banner_Ad
'rewarded': 'ca-app-pub-3537329799200606/7827129874' // Rewarded_BTC_Ad  
'native': 'ca-app-pub-3537329799200606/2260507229'   // Native_Contract_Card
// 'rewarded_interstitial': 'ca-app-pub-3537329799200606/4519239988' // Game Reward Interstitial (Available for future use)
```

## Next Steps for Full Mediation

### Step 1: AdMob Console Configuration
1. Go to [AdMob Console](https://admob.google.com/)
2. Navigate to **Mediation** section
3. Add mediation groups for each ad format:
   - Rewarded Video Mediation Group
   - Banner Mediation Group
   - Native Mediation Group

### Step 2: Configure Unity Ads
1. In AdMob Console, add Unity Ads as a mediation source
2. Configure Unity Ads settings:
   - Game ID for Android
   - Game ID for iOS
   - Ad Unit IDs for each format

### Step 3: Add Additional Networks (Optional)
To add more mediation networks, update `lib/config/mediation_config.dart`:

```dart
// Facebook Audience Network
static const Map<String, dynamic> facebookConfig = {
  'enabled': true,
  'app_id_android': 'YOUR_FACEBOOK_APP_ID_ANDROID',
  'app_id_ios': 'YOUR_FACEBOOK_APP_ID_IOS',
  'test_mode': kDebugMode,
};

// AppLovin
static const Map<String, dynamic> appLovinConfig = {
  'enabled': true,
  'sdk_key_android': 'YOUR_APPLOVIN_SDK_KEY_ANDROID',
  'sdk_key_ios': 'YOUR_APPLOVIN_SDK_KEY_IOS',
  'test_mode': kDebugMode,
};
```

### Step 4: Add Dependencies (If Adding New Networks)
```kotlin
// android/app/build.gradle.kts
// Facebook Audience Network
implementation("com.google.ads.mediation:facebook:6.14.0.0")

// AppLovin
implementation("com.google.ads.mediation:applovin:12.4.2.0")

// IronSource
implementation("com.google.ads.mediation:ironsource:8.1.0.0")
```

## Mediation Features

### ✅ Already Implemented
- Mediation initialization
- Network status tracking
- Performance metrics
- Error handling
- Auto-retry mechanism

### 📊 Mediation Metrics
The app tracks:
- Ad shows per network
- Ad failures per network
- Revenue per network
- Network initialization status

### 🔧 Configuration Options
```dart
// lib/config/mediation_config.dart
static const bool enabled = true;           // Enable/disable mediation
static const int waterfallTimeout = 30;     // Timeout in seconds
static const int retryAttempts = 2;         // Retry attempts
static const bool preloadMediationAds = true; // Preload ads
```

## Testing Mediation

### Debug Mode
In debug mode, the app will log:
- ✅ Mediation initialization status
- ✅ Network initialization status
- ❌ Failed network initializations
- 📊 Mediation metrics

### Production Mode
In production mode, mediation works silently with:
- Automatic network selection
- Fallback mechanisms
- Performance optimization

## Troubleshooting

### Common Issues
1. **Mediation not working**: Check AdMob Console configuration
2. **Low fill rate**: Add more mediation networks
3. **High latency**: Adjust waterfall timeout
4. **Network failures**: Check network-specific configurations

### Debug Commands
```dart
// Check mediation status
final adService = AdService();
print(adService.mediationStatus);

// Reset metrics
await adService.resetMetrics();
```

## Revenue Optimization Tips

1. **Waterfall Configuration**: Set optimal eCPM floors
2. **Network Priority**: Order networks by performance
3. **Geographic Targeting**: Use different networks for different regions
4. **Ad Format Optimization**: Optimize each ad format separately

## Support
For mediation-related issues:
1. Check AdMob Console logs
2. Review network-specific documentation
3. Monitor mediation metrics in the app
4. Contact network support if needed

---

**Note**: This setup provides a solid foundation for mediation. For maximum revenue, consider adding more networks and optimizing waterfall configurations in AdMob Console. 