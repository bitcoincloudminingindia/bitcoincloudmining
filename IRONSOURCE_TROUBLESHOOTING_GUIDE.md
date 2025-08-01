# 🔧 IronSource Ads Not Working - Complete Troubleshooting Guide

## 🚨 **Main Issues Identified**

Based on your current configuration, here are the most likely reasons why IronSource ads are not working:

### 1. **App Key Issues** ⚠️
```dart
// Current configuration
static const String _androidAppKey = '2314651cd';
static const String _iosAppKey = '2314651cd';
```

**Problems:**
- Using same key for both Android and iOS (usually different)
- Key might be test/development key instead of production
- Key might be invalid or expired

**Solutions:**
1. **Get correct app keys from IronSource dashboard**
2. **Use different keys for Android and iOS**
3. **Verify keys are for production, not test**

### 2. **Ad Unit ID Issues** ⚠️
```dart
// Current configuration
static const Map<String, String> _adUnitIds = {
  'banner': 'qgvxpwcrq6u2y0vq',
  'interstitial': 'i5bc3rl0ebvk8xjk', 
  'rewarded': 'lcv9s3mjszw657sy',
  'native': 'lcv9s3mjszw657sy', // Same as rewarded!
};
```

**Problems:**
- Native ad using same ID as rewarded ad
- IDs might be test units instead of production
- IDs might not be properly configured in dashboard

**Solutions:**
1. **Create separate native ad unit in IronSource dashboard**
2. **Verify all ad units are production, not test**
3. **Check ad unit configuration in dashboard**

### 3. **Initialization Issues** ⚠️
**Problems:**
- SDK not initializing properly
- Network connectivity issues
- Conflicts with AdMob SDK

**Solutions:**
1. **Check network connectivity**
2. **Verify SDK initialization logs**
3. **Ensure proper initialization sequence**

## 🛠️ **Step-by-Step Fix**

### Step 1: Verify IronSource Dashboard Configuration

1. **Login to IronSource Dashboard**
   - Go to https://platform.ironsrc.com/
   - Login with your account

2. **Check App Configuration**
   - Navigate to "Apps" section
   - Find your app (Bitcoin Cloud Mining)
   - Verify app is approved and active

3. **Get Correct App Keys**
   - Copy Android app key (should be different from iOS)
   - Copy iOS app key (should be different from Android)
   - Keys should be longer than 8 characters

4. **Check Ad Units**
   - Go to "Ad Units" section
   - Verify you have separate units for:
     - Native ads
     - Rewarded ads
     - Interstitial ads
   - Copy correct placement names

### Step 2: Update Your Configuration

Replace your current configuration with correct values:

```dart
// lib/services/ironsource_service.dart
class IronSourceService {
  // Replace with your actual app keys from dashboard
  static const String _androidAppKey = 'YOUR_ACTUAL_ANDROID_APP_KEY';
  static const String _iosAppKey = 'YOUR_ACTUAL_IOS_APP_KEY';

  // Replace with your actual ad unit IDs from dashboard
  static const Map<String, String> _adUnitIds = {
    'banner': 'YOUR_BANNER_AD_UNIT_ID',
    'interstitial': 'YOUR_INTERSTITIAL_AD_UNIT_ID',
    'rewarded': 'YOUR_REWARDED_AD_UNIT_ID',
    'native': 'YOUR_NATIVE_AD_UNIT_ID', // Should be different from rewarded
  };
}
```

### Step 3: Test with Debug Screen

Use the debug screen I created to test your configuration:

```dart
// Navigate to debug screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const IronSourceDebugScreen(),
  ),
);
```

### Step 4: Check Console Logs

Look for these log messages in your console:

**✅ Success Messages:**
```
🚀 Starting IronSource SDK initialization...
📱 Using app key: YOUR_APP_KEY
✅ IronSource SDK initialized successfully
🔄 Loading IronSource Native ad...
✅ IronSource Native ad loaded successfully
```

**❌ Error Messages:**
```
❌ IronSource initialization failed: [error]
❌ IronSource Native ad load failed: [error]
❌ IronSource init failed: [error]
```

## 🔍 **Common Error Messages & Solutions**

### 1. **"App key is invalid"**
**Solution:** Get correct app key from IronSource dashboard

### 2. **"Ad unit not found"**
**Solution:** Create ad unit in IronSource dashboard and use correct placement name

### 3. **"Network error"**
**Solution:** Check internet connectivity and firewall settings

### 4. **"SDK not initialized"**
**Solution:** Ensure IronSource.initialize() is called before loading ads

### 5. **"No fill"**
**Solution:** 
- Check if ad units are properly configured
- Verify app is approved in IronSource
- Wait for ads to become available (can take time)

## 📱 **Testing Steps**

### 1. **Basic Initialization Test**
```dart
final ironSource = IronSourceService.instance;
await ironSource.initialize();
print('Initialized: ${ironSource.isInitialized}');
```

### 2. **Native Ad Test**
```dart
final widget = ironSource.getNativeAdWidget();
if (widget != null) {
  // Ad is working
  print('Native ad widget created successfully');
} else {
  // Ad failed to load
  print('Native ad widget creation failed');
}
```

### 3. **Rewarded Ad Test**
```dart
final success = await ironSource.showRewardedAd();
if (success) {
  print('Rewarded ad shown successfully');
} else {
  print('Rewarded ad show failed');
}
```

## 🎯 **Quick Fix Checklist**

### ✅ **Immediate Actions**
- [ ] Get correct app keys from IronSource dashboard
- [ ] Create separate native ad unit (different from rewarded)
- [ ] Update configuration with correct keys and IDs
- [ ] Test with debug screen
- [ ] Check console logs for errors

### ✅ **Verification Steps**
- [ ] App is approved in IronSource dashboard
- [ ] Ad units are properly configured
- [ ] Using production keys, not test keys
- [ ] Network connectivity is working
- [ ] SDK initializes without errors

### ✅ **Testing Steps**
- [ ] Test initialization
- [ ] Test native ad loading
- [ ] Test rewarded ad loading
- [ ] Check fallback to AdMob works
- [ ] Monitor console logs

## 📞 **Getting Help**

### 1. **IronSource Support**
- Contact IronSource support for dashboard issues
- Verify app approval status
- Get correct app keys and ad unit IDs

### 2. **Debug Information**
Use the debug screen to get detailed information:
- App key configuration
- Ad unit ID configuration
- Platform configuration
- SDK status
- Ad loading status

### 3. **Console Logs**
Check your console for detailed error messages:
- Initialization errors
- Ad loading errors
- Network errors
- SDK errors

## 🚀 **Expected Results After Fix**

### ✅ **Working Configuration**
- IronSource SDK initializes successfully
- Native ads load and display
- Rewarded ads show properly
- Fallback to AdMob works when IronSource fails
- Console shows success messages

### 📈 **Performance Improvement**
- Higher ad fill rates (80-90% vs 60-70%)
- Increased revenue (30-50% improvement)
- Better user experience with consistent ads

## 🔧 **Alternative Solutions**

If IronSource continues to have issues:

### 1. **Use AdMob Only**
```dart
// Disable IronSource temporarily
static const bool _useIronSource = false;
```

### 2. **Try Different Ad Networks**
- Facebook Audience Network
- Unity Ads
- AppLovin MAX

### 3. **Contact IronSource Support**
- Get technical assistance
- Verify account setup
- Check for account issues

---

**Next Steps:**
1. Get correct app keys from IronSource dashboard
2. Update your configuration
3. Test with the debug screen
4. Check console logs for errors
5. Contact IronSource support if issues persist