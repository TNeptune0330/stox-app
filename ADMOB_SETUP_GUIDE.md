# 💰 AdMob Revenue Setup Guide

Complete guide to set up real AdMob revenue in your Stox app.

## 📋 **Step 1: Create AdMob Account**

### **Sign Up for AdMob**
1. Visit: https://admob.google.com
2. Sign in with your Google account
3. Accept Terms & Conditions
4. Complete account verification

### **Add Your App**
```
In AdMob Console:
1. Click "Apps" → "Add App"
2. Choose "iOS" 
3. App Name: "Stox - Trading Simulator"
4. Choose "No" for "Is this app published?" (for now)
5. Complete app creation
```

## 🎯 **Step 2: Create Ad Units**

### **Create These Ad Units:**

**1. Banner Ad Unit**
```
- Ad format: Banner
- Ad unit name: "Stox Banner - Main Navigation"
- Ad unit ID: (copy this - you'll need it)
```

**2. Interstitial Ad Unit**
```
- Ad format: Interstitial
- Ad unit name: "Stox Interstitial - Between Trades"
- Ad unit ID: (copy this - you'll need it)
```

**3. Rewarded Ad Unit**
```
- Ad format: Rewarded
- Ad unit name: "Stox Rewarded - Bonus Cash"
- Ad unit name: (copy this - you'll need it)
```

## 🔧 **Step 3: Update Your App**

### **Replace Test IDs with Real IDs**

In `/lib/services/revenue_admob_service.dart`, replace these lines:

```dart
// REPLACE THESE WITH YOUR REAL ADMOB IDS FROM ADMOB CONSOLE
static const String _iosAppId = 'YOUR_REAL_IOS_APP_ID';

// iOS Ad Unit IDs (REPLACE WITH YOUR REAL IDS)
static const String _iosBannerAdUnitId = 'YOUR_REAL_BANNER_AD_UNIT_ID';
static const String _iosInterstitialAdUnitId = 'YOUR_REAL_INTERSTITIAL_AD_UNIT_ID';
static const String _iosRewardedAdUnitId = 'YOUR_REAL_REWARDED_AD_UNIT_ID';
```

### **Update iOS Info.plist**

In `/ios/Runner/Info.plist`, replace:
```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_REAL_IOS_APP_ID</string>
```

## 💵 **Step 4: Revenue Optimization**

### **Strategic Ad Placement**

**Banner Ads (Continuous Revenue):**
- Bottom of market screen ✅ (already placed)
- Bottom of portfolio screen ✅ (already placed)
- Settings screen

**Interstitial Ads (High Revenue):**
- After completing 5 trades
- When switching between major sections
- After unlocking achievements

**Rewarded Ads (Best Engagement):**
- "Watch ad for $500 bonus cash"
- "Watch ad to unlock premium theme"
- "Watch ad for trading tips"

### **Revenue Maximization Tips**

**1. Optimal Ad Frequency:**
```dart
// Show interstitial every 3-5 minutes of active use
// Show rewarded ads on user request only
// Keep banner ads always visible (but not intrusive)
```

**2. User Experience Balance:**
```dart
// Never interrupt active trading
// Show ads during natural breaks
// Offer value for rewarded ads
```

## 📊 **Step 5: Revenue Tracking**

### **Monitor Performance**
```
AdMob Console → Apps → Your App → View Reports
- Impressions (ad views)
- Clicks (user interactions)
- Estimated Earnings
- eCPM (earnings per 1000 impressions)
```

### **Revenue Analytics**
Your app now tracks:
- Ad clicks and revenue events
- User engagement with ads
- Ad performance by type

## 💰 **Expected Revenue**

### **Realistic Estimates (US users):**
```
Banner Ads: $0.50 - $2.00 per 1000 impressions
Interstitial Ads: $1.00 - $5.00 per 1000 impressions  
Rewarded Ads: $3.00 - $10.00 per 1000 impressions
```

### **Monthly Revenue Calculation:**
```
1000 active users × 10 sessions/month × 2 ads/session = 20,000 ad impressions
20,000 impressions × $2 average eCPM = $40/month

10,000 active users = $400/month potential
100,000 active users = $4,000/month potential
```

## 🚀 **Step 6: Advanced Monetization**

### **Rewarded Features to Add:**
```dart
// Bonus cash for watching ads
static void offerBonusCash() {
  RevenueAdMobService.showRewardedAd(
    onReward: (reward) {
      // Give user $500 bonus cash
      UserService.addBonusCash(500);
    }
  );
}

// Premium themes via ads
static void unlockPremiumTheme() {
  RevenueAdMobService.showRewardedAd(
    onReward: (reward) {
      // Unlock premium theme
      ThemeService.unlockPremiumTheme();
    }
  );
}
```

### **A/B Testing Ideas:**
- Different ad frequencies
- Various reward amounts
- Ad placement optimization
- Theme unlock strategies

## ⚠️ **Important Notes**

### **AdMob Policies:**
- Never click your own ads (you'll be banned)
- Don't ask users to click ads
- Ensure ads don't interfere with app functionality
- Follow content guidelines

### **App Store Approval:**
- Ads must be clearly marked as advertisements
- Rewarded ads should provide real value
- No misleading ad content

### **Testing:**
- Use test device IDs during development
- Switch to production IDs only for release
- Test ad loading on different network conditions

## 📱 **Implementation Commands**

```bash
# Install dependencies
flutter pub get

# Test with your real AdMob IDs
flutter run --release

# Build for App Store (with real ads)
flutter build ios --release
```

## 💡 **Pro Tips for Maximum Revenue**

1. **User Retention = More Revenue**
   - Great app experience = more ad views
   - Engaged users watch more rewarded ads

2. **Optimize Ad Placement**
   - Natural break points work best
   - Don't interrupt core functionality

3. **Rewarded Ads = Highest Revenue**
   - Offer meaningful rewards
   - Make ads feel optional, not forced

4. **Monitor Performance**
   - Track which ads perform best
   - Adjust frequency based on user feedback

Your Stox app is now ready to generate real AdMob revenue! 🎉

Start with the test setup, then switch to production IDs when you're ready to go live.