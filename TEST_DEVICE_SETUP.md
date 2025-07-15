# Test Device Setup Guide

## What are Test Devices?

Test devices are specific devices that show test ads instead of real ads during development and testing.

## Why Use Test Devices?

### ✅ Benefits:
- **Safe Testing**: No risk of violating AdMob policies
- **Consistent Behavior**: Predictable ad responses
- **Faster Development**: No need to wait for real ads
- **Cost Effective**: No charges for test ad impressions

### ⚠️ Important:
- **Production में**: Test devices automatically disabled होते हैं
- **Debug Mode में**: Test devices enabled होते हैं
- **Release Mode में**: Only real ads show होते हैं

## Current Configuration

### 1. Automatic Test Device Management
```dart
// lib/config/mediation_config.dart
static const bool enableTestDevices = kDebugMode;  // Only in debug mode
static const List<String> testDeviceIds = [
  // Add your device IDs here
];
```

### 2. How It Works
- **Debug Mode**: Test devices enabled
- **Release Mode**: Test devices disabled
- **Production**: Only real ads

## How to Get Your Test Device ID

### Method 1: From AdMob Console
1. Go to [AdMob Console](https://admob.google.com/)
2. Navigate to **Settings** → **Test Devices**
3. Add your device
4. Copy the device ID

### Method 2: From App Logs
1. Run app in debug mode
2. Check console logs for:
   ```
   🔧 Test devices enabled: [YOUR_DEVICE_ID]
   ```
3. Copy the device ID

### Method 3: Manual Method
1. Run app on your device
2. Look for log message: `"Use RequestConfiguration.Builder.setTestDeviceIds(Arrays.asList("YOUR_DEVICE_ID"))"`
3. Copy the device ID from the log

## Adding Your Test Device

### Step 1: Get Your Device ID
Run the app and check logs for your device ID.

### Step 2: Add to Configuration
```dart
// lib/config/mediation_config.dart
static const List<String> testDeviceIds = [
  'YOUR_DEVICE_ID_HERE',  // Replace with your actual device ID
  // Add more device IDs if needed
];
```

### Step 3: Test
1. Run app in debug mode
2. You should see test ads
3. Check logs: `🔧 Test devices enabled: [YOUR_DEVICE_ID]`

## Test Device IDs Format

### Android Device ID
```
Example: 33BE2250B43518CCDA7DE426D04EE231
Format: 32-character hexadecimal string
```

### iOS Device ID
```
Example: 2077ef9a63d2b398840261c8221a0c9b
Format: 32-character hexadecimal string
```

## Multiple Test Devices

You can add multiple test devices:

```dart
static const List<String> testDeviceIds = [
  'DEVICE_ID_1',  // Your Android device
  'DEVICE_ID_2',  // Your iOS device
  'DEVICE_ID_3',  // Emulator
];
```

## Production vs Development

### Development (Debug Mode)
```dart
enableTestDevices = true;  // Test ads shown
testDeviceIds = ['YOUR_DEVICE_ID'];
```

### Production (Release Mode)
```dart
enableTestDevices = false;  // Real ads shown
testDeviceIds = [];  // Ignored
```

## Troubleshooting

### Issue: Still seeing real ads
**Solution**: Check if you're in debug mode and device ID is correct

### Issue: No ads showing
**Solution**: 
1. Verify device ID format
2. Check network connection
3. Ensure AdMob App ID is correct

### Issue: Test device not working
**Solution**:
1. Restart app after adding device ID
2. Clear app cache
3. Check AdMob Console settings

## Best Practices

### ✅ Do's:
- Use test devices during development
- Add multiple team members' devices
- Test on both Android and iOS
- Use different ad formats for testing

### ❌ Don'ts:
- Don't use test devices in production
- Don't share test device IDs publicly
- Don't forget to remove test devices before release
- Don't rely only on test ads for final testing

## Security Note

⚠️ **Important**: Never commit real test device IDs to public repositories. Use environment variables or separate config files for sensitive data.

## Example Configuration

```dart
// lib/config/mediation_config.dart
static const bool enableTestDevices = kDebugMode;
static const List<String> testDeviceIds = [
  // Add your devices here
  // '33BE2250B43518CCDA7DE426D04EE231',  // Android device
  // '2077ef9a63d2b398840261c8221a0c9b',  // iOS device
];
```

---

**Note**: Test devices are essential for safe development but should never be used in production builds. 