# AdMob Policy Compliance Guide

## 🚨 Critical Issues Fixed

### 1. Auto-Refresh Intervals
- **Fixed**: Banner ad refresh increased from 60s to 120s
- **Requirement**: Minimum 60s, recommended 120s+

### 2. Test vs Production Ad IDs
- **Fixed**: Added conditional test ID usage only when explicitly testing
- **Production**: Real ad IDs are used for all users by default
- **Testing**: Set `useTestAds = true` only when testing ad integration
- **Test IDs Available**:
  - Banner: `ca-app-pub-3940256099942544/6300978111`
  - Rewarded: `ca-app-pub-3940256099942544/5224354917`
  - Native: `ca-app-pub-3940256099942544/2247696110`

### 3. Web Platform Compliance
- **Fixed**: Removed fake rewards for web platform
- **Action**: Web users now get proper "no ads available" experience

### 4. Realistic Reward Amounts
- **Fixed**: Updated reward amounts to be more realistic
- **Old**: 0.000000000000005000 BTC (unrealistic)
- **New**: 0.000001 BTC (1 satoshi equivalent)

### 5. App Transparency
- **Added**: Clear disclaimer about simulation nature
- **Content**: Explains this is gaming/simulation, not real mining

## 📋 Compliance Checklist

### ✅ Ad Implementation
- [x] Proper ad refresh intervals
- [x] Test IDs for development
- [x] Production IDs for release
- [x] No forced clicks
- [x] Clear ad labeling

### ✅ User Experience
- [x] Realistic reward amounts
- [x] Clear app disclaimers
- [x] No misleading content
- [x] Proper error handling

### ⚠️ Areas to Monitor
- [ ] User engagement with ads (should be voluntary)
- [ ] Withdrawal minimum amounts (should be achievable)
- [ ] App store description accuracy
- [ ] User feedback about misleading content

## 🔧 Additional Recommendations

1. **Add Privacy Policy**: Implement comprehensive privacy policy
2. **GDPR Compliance**: Add consent management for EU users
3. **Age Rating**: Ensure proper age rating in app stores
4. **Clear Terms**: Make terms of service easily accessible
5. **Support System**: Implement responsive user support

## 🔧 Ad Testing Configuration

### For Development Testing:
```dart
// In lib/services/ad_service.dart
const bool useTestAds = true; // Enable only when testing ad integration
```

### For Production (Users):
```dart
// In lib/services/ad_service.dart  
const bool useTestAds = false; // Always keep false for real users
```

### Real Ad Units Used:
- **Android Banner**: `ca-app-pub-3537329799200606/2028008282`
- **Android Rewarded**: `ca-app-pub-3537329799200606/7827129874`
- **Android Native**: `ca-app-pub-3537329799200606/2260507229`
- **iOS**: Same ad units for both platforms

## 📝 Testing Protocol

1. **Development Testing**: 
   - Set `useTestAds = true` 
   - Test ad loading, display, and callbacks
   - Verify no crashes or errors

2. **Production Deployment**:
   - Set `useTestAds = false`
   - Real ads will show to actual users
   - Monitor ad performance in AdMob console

## 🚀 Deployment Checklist

- [x] Real ad IDs are used by default for users
- [x] Test ads only enabled when explicitly needed
- [ ] Verify all disclaimers are in place
- [ ] Test ad loading and display with real ads
- [ ] Check reward redemption flow
- [ ] Validate minimum withdrawal amounts
- [ ] Ensure privacy policy is accessible
- [ ] Monitor AdMob console for ad performance
- [ ] Check app store compliance