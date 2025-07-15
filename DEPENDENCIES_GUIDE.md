# Dependencies Guide for Mediation

## Current Dependencies Status

### ✅ Already Added (Required)

#### Flutter Dependencies
```yaml
# pubspec.yaml
google_mobile_ads: ^6.0.0  # Latest version with mediation support
```

#### Android Dependencies
```kotlin
// android/app/build.gradle.kts
implementation("com.google.android.gms:play-services-ads:24.4.0")  // AdMob SDK
implementation("com.unity3d.ads:unity-ads:4.15.1")                 // Unity Ads SDK
implementation("com.google.ads.mediation:unity:4.15.1.0")         // Unity AdMob adapter
```

## Optional Dependencies (Add as needed)

### 1. Facebook Audience Network
**When to add**: If you want Facebook ads in your mediation

#### Flutter Dependency
```yaml
# pubspec.yaml
facebook_audience_network: ^0.4.0
```

#### Android Dependency
```kotlin
// android/app/build.gradle.kts
implementation("com.google.ads.mediation:facebook:6.14.0.0")
```

#### iOS Dependency
```swift
// ios/Podfile
pod 'Google-Mobile-Ads-SDK'
pod 'FBAudienceNetwork'
```

### 2. AppLovin MAX
**When to add**: If you want AppLovin ads in your mediation

#### Flutter Dependency
```yaml
# pubspec.yaml
applovin_max: ^3.5.0
```

#### Android Dependency
```kotlin
// android/app/build.gradle.kts
implementation("com.google.ads.mediation:applovin:12.4.2.0")
```

#### iOS Dependency
```swift
// ios/Podfile
pod 'AppLovinSDK'
```

### 3. IronSource
**When to add**: If you want IronSource ads in your mediation

#### Flutter Dependency
```yaml
# pubspec.yaml
ironsource_mediation: ^7.0.0
```

#### Android Dependency
```kotlin
// android/app/build.gradle.kts
implementation("com.google.ads.mediation:ironsource:8.1.0.0")
```

#### iOS Dependency
```swift
// ios/Podfile
pod 'IronSourceSDK'
```

## How to Add Dependencies

### Step 1: Uncomment in pubspec.yaml
```yaml
# Uncomment the network you want to add
facebook_audience_network: ^0.4.0  # Facebook Audience Network
applovin_max: ^3.5.0              # AppLovin MAX
ironsource_mediation: ^7.0.0      # IronSource
```

### Step 2: Add Android Dependencies
```kotlin
// android/app/build.gradle.kts
dependencies {
    // Existing dependencies...
    
    // Add the mediation adapter you want
    implementation("com.google.ads.mediation:facebook:6.14.0.0")
    implementation("com.google.ads.mediation:applovin:12.4.2.0")
    implementation("com.google.ads.mediation:ironsource:8.1.0.0")
}
```

### Step 3: Update Configuration
```dart
// lib/config/mediation_config.dart
static const List<String> supportedNetworks = [
  'unity_ads',
  'facebook_audience_network',  // Add if using Facebook
  'applovin',                   // Add if using AppLovin
  'iron_source',                // Add if using IronSource
];
```

### Step 4: Run Commands
```bash
# Update dependencies
flutter pub get

# For Android
cd android && ./gradlew clean && cd ..

# For iOS
cd ios && pod install && cd ..
```

## Current Setup (Recommended)

### ✅ What's Working Now
- **AdMob**: Full support with mediation
- **Unity Ads**: Already configured
- **Mediation Framework**: Complete implementation
- **Performance Tracking**: Built-in metrics

### 🚀 Benefits of Current Setup
- **Good Fill Rate**: Unity Ads + AdMob
- **Stable Performance**: Tested configuration
- **Easy Maintenance**: Minimal dependencies
- **Production Ready**: Battle-tested

## When to Add More Networks

### Add Facebook Audience Network if:
- You want higher eCPM in certain regions
- Your app targets Facebook users
- You need better fill rate

### Add AppLovin if:
- You want gaming-focused ads
- You need high-quality video ads
- You want advanced targeting

### Add IronSource if:
- You want extensive ad network coverage
- You need advanced mediation features
- You want detailed analytics

## Performance Impact

### Dependencies Count
- **Current**: 3 mediation dependencies
- **With Facebook**: 4 dependencies
- **With AppLovin**: 5 dependencies
- **With IronSource**: 6 dependencies

### App Size Impact
- **Unity Ads**: ~2-3 MB
- **Facebook**: ~5-8 MB
- **AppLovin**: ~3-5 MB
- **IronSource**: ~4-6 MB

## Recommendations

### For Starters (Current Setup)
✅ **Keep current setup** - Unity Ads + AdMob is sufficient

### For Growth
🔄 **Add Facebook Audience Network** - Good for revenue optimization

### For Scale
🚀 **Add all networks** - Maximum fill rate and revenue

## Troubleshooting

### Common Issues
1. **Version conflicts**: Use compatible versions
2. **Build errors**: Clean and rebuild
3. **Ad loading issues**: Check network configurations

### Solutions
```bash
# Clean build
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

---

**Note**: Start with the current setup and add more networks only when needed for revenue optimization. 