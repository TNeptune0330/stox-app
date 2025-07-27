# 🍎 iOS App Store Deployment Guide

Complete step-by-step guide to get your Stox app on the iOS App Store.

## 📋 Prerequisites

### Required
- **Mac computer** (required for iOS development)
- **Apple Developer Account** ($99/year) - https://developer.apple.com/programs/
- **Xcode** (latest version from Mac App Store)
- **Valid Apple ID** with 2FA enabled

### Accounts to Set Up
1. **Apple Developer Program** - For signing certificates
2. **App Store Connect** - For app management and distribution

---

## 🚀 Step-by-Step iOS Setup

### Step 1: Apple Developer Account

1. **Enroll in Apple Developer Program**
   ```
   Visit: https://developer.apple.com/programs/
   - Sign in with your Apple ID
   - Choose Individual or Organization
   - Pay $99 annual fee
   - Complete identity verification (can take 24-48 hours)
   ```

2. **Access Developer Portal**
   ```
   Once approved, visit: https://developer.apple.com/account/
   - You'll see Certificates, Identifiers & Profiles
   - This is where we'll create your app identifier
   ```

### Step 2: Create App Identifier

1. **Register Bundle ID**
   ```
   In Apple Developer Portal:
   1. Go to Identifiers → App IDs
   2. Click the "+" button
   3. Choose "App IDs"
   4. Select "App" type
   
   Bundle ID: com.yourcompany.stox (choose your company name)
   Description: Stox Trading Simulator
   
   Capabilities to enable:
   ✅ App Groups (for data sharing)
   ✅ Sign In with Apple (if you want this feature)
   ✅ Push Notifications (for future features)
   ```

### Step 3: Configure Xcode Project

1. **Open Project in Xcode**
   ```bash
   cd /Users/takshpradhan/stox-app/stox
   open ios/Runner.xcworkspace
   ```

2. **Update Project Settings**
   ```
   In Xcode:
   1. Select "Runner" project in navigator
   2. Select "Runner" target
   3. Go to "Signing & Capabilities" tab
   
   Update these settings:
   - Bundle Identifier: com.yourcompany.stox (match what you created)
   - Team: Select your Apple Developer team
   - Check "Automatically manage signing"
   ```

3. **Update Display Name and Version**
   ```
   Still in Xcode:
   1. Go to "General" tab
   2. Display Name: "Stox"
   3. Version: 1.0.0
   4. Build: 1
   ```

### Step 4: Test on Physical Device

1. **Connect Your iPhone/iPad**
   ```
   1. Connect device via USB
   2. Trust computer if prompted
   3. In Xcode, select your device from device menu
   4. Click Run (▶️) button
   ```

2. **Trust Developer Certificate**
   ```
   On your device:
   Settings → General → VPN & Device Management
   → Developer App → Trust "Your Name"
   ```

### Step 5: Build Release Version

1. **Archive for Distribution**
   ```
   In Xcode:
   1. Select "Any iOS Device (arm64)" as target
   2. Product → Archive
   3. Wait for archive to complete (5-10 minutes)
   4. Organizer window will open
   ```

2. **Validate Archive**
   ```
   In Organizer:
   1. Select your archive
   2. Click "Validate App"
   3. Choose "Automatically manage signing"
   4. Wait for validation to complete
   ```

### Step 6: App Store Connect Setup

1. **Create App in App Store Connect**
   ```
   Visit: https://appstoreconnect.apple.com
   1. Sign in with your Apple ID
   2. Click "My Apps"
   3. Click the "+" button → "New App"
   
   Fill out:
   - Platform: iOS
   - Name: Stox - Trading Simulator
   - Primary Language: English
   - Bundle ID: (select the one you created)
   - SKU: stox-trading-sim-001 (unique identifier)
   ```

2. **Complete App Information**
   ```
   In App Store Connect:
   
   App Information:
   - Name: Stox - Trading Simulator
   - Subtitle: Learn Stock Trading Risk-Free
   - Category: Education or Finance
   - Content Rights: Check if you own rights
   
   Pricing and Availability:
   - Price: Free
   - Availability: All territories (or select specific countries)
   ```

### Step 7: Upload to TestFlight

1. **Distribute from Xcode**
   ```
   In Xcode Organizer:
   1. Select your validated archive
   2. Click "Distribute App"
   3. Choose "App Store Connect"
   4. Choose "Upload"
   5. Select signing options (automatic)
   6. Click "Upload"
   ```

2. **Process in App Store Connect**
   ```
   In App Store Connect:
   1. Go to TestFlight tab
   2. Wait for build to process (10-30 minutes)
   3. Once processed, you can add testers
   ```

### Step 8: TestFlight Testing

1. **Add Internal Testers**
   ```
   In TestFlight:
   1. Select your build
   2. Go to "Internal Testing"
   3. Add testers (use their Apple ID emails)
   4. They'll get email invite to test
   ```

2. **Install TestFlight**
   ```
   Testers need to:
   1. Download TestFlight app from App Store
   2. Open email invite
   3. Install your app through TestFlight
   ```

---

## 📱 Required Assets for App Store

### App Icons (Already Done)
Your app should already have icons configured, but verify:
- Various sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Screenshots (You Need to Create These)

**Required Screenshot Sizes:**
1. **iPhone 6.7"** (iPhone 14 Pro Max, 15 Pro Max)
   - Size: 1290 × 2796 pixels
   - Take screenshots on iPhone 15 Pro Max or larger

2. **iPhone 6.5"** (iPhone 14 Plus, 15 Plus)
   - Size: 1242 × 2688 pixels
   - Take screenshots on iPhone 14 Plus or similar

3. **iPhone 5.5"** (iPhone 8 Plus)
   - Size: 1242 × 2208 pixels
   - Take screenshots on iPhone 8 Plus or simulator

4. **iPad Pro 12.9"** (3rd gen)
   - Size: 2048 × 2732 pixels
   - Take screenshots on iPad Pro 12.9" or simulator

**How to Take Screenshots:**
```bash
# Use iOS Simulator in Xcode
1. Open Simulator
2. Choose device size (iPhone 15 Pro Max, iPad Pro 12.9")
3. Run your app: flutter run -d simulator
4. Navigate to different screens
5. Take screenshots: Device → Screenshot (Cmd+S)
6. Save to Desktop
```

**Screens to Screenshot:**
1. **Market Screen** - showing stock list with weekend banner
2. **Portfolio Screen** - showing holdings and summary
3. **Achievements Screen** - showing progress and unlocked achievements
4. **Settings Screen** - showing themes and profile
5. **Trading Dialog** - showing buy/sell interface

---

## 📝 App Store Listing Content

### App Description
```
Stox - Trading Simulator

Learn stock trading without financial risk! Practice with real market data in a safe, educational environment.

KEY FEATURES:
• $10,000 virtual starting balance
• Real-time stock and cryptocurrency prices
• Portfolio tracking and performance analytics
• Achievement system with trading milestones
• Beautiful themes and customization options
• Offline functionality with data sync
• Educational focus - perfect for beginners

EDUCATIONAL BENEFITS:
• Understand market volatility without risk
• Practice different trading strategies
• Learn about portfolio diversification
• Track your virtual investment performance
• Gain confidence before real trading

IMPORTANT: This is a simulation app. No real money or actual securities are involved. All trading is virtual and for educational purposes only.

Perfect for students, beginners, or anyone wanting to learn about stock markets and trading strategies risk-free!
```

### Keywords (100 characters max)
```
stock trading, simulator, education, portfolio, investment, market, finance, learn
```

### App Store Review Notes
```
This is an educational stock trading simulator. All trading is virtual with no real money involved. The app uses real market data for educational purposes only. Google Sign-In is required for account creation and data sync across devices.

Test Account (if needed):
Email: testuser@stoxapp.com
Password: TestPass123

Demo Mode: App also works without sign-in for basic exploration.
```

---

## 🛡️ Pre-Submission Checklist

### Technical Requirements
- [ ] App builds and runs without crashes
- [ ] All features work as expected
- [ ] Google Sign-In authentication works
- [ ] Offline functionality works
- [ ] Weekend banner appears on weekends
- [ ] Themes save and persist
- [ ] Portfolio data syncs correctly
- [ ] Achievements unlock properly
- [ ] App handles network connectivity changes
- [ ] No debug prints or test code in release

### App Store Guidelines Compliance
- [ ] App is educational/simulation only (no real trading)
- [ ] Privacy policy is accessible in app
- [ ] Terms of service are accessible in app
- [ ] No inappropriate content
- [ ] App doesn't crash or freeze
- [ ] UI is polished and professional
- [ ] App metadata is accurate
- [ ] Screenshots represent actual app functionality

### Content Requirements
- [ ] App icons at all required sizes
- [ ] Screenshots for required device sizes
- [ ] App description written
- [ ] Keywords selected
- [ ] App categorized correctly
- [ ] Privacy policy URL provided
- [ ] Support URL provided (can be email)

---

## 🚀 Final Submission

### Submit for Review
```
In App Store Connect:
1. Complete all sections (App Information, Pricing, etc.)
2. Add your screenshots
3. Submit build for review
4. Add review notes if needed
5. Click "Submit for Review"
```

### Review Timeline
- **Typical Review Time**: 24-48 hours
- **Possible Outcomes**: Approved, Rejected (with feedback), or Developer Rejected
- **If Rejected**: Address feedback and resubmit

### After Approval
- Your app will be live on the App Store
- You can update via new builds and submissions
- Monitor reviews and ratings
- Plan future updates and features

---

## 🆘 Troubleshooting Common Issues

### "No Signing Certificate Found"
```
Solution:
1. Make sure you're enrolled in Apple Developer Program
2. In Xcode: Preferences → Accounts → Add Apple ID
3. Select your team in project settings
4. Enable "Automatically manage signing"
```

### "Bundle ID Already Exists"
```
Solution:
1. Choose a unique bundle ID (com.yourname.stox)
2. Make sure it matches in both Apple Developer Portal and Xcode
3. Don't use com.example.* for production apps
```

### "Archive Failed"
```
Solution:
1. Clean build folder: Product → Clean Build Folder
2. Make sure you selected "Any iOS Device" not simulator
3. Check for any build errors in logs
4. Ensure all dependencies are compatible
```

### "Upload to App Store Connect Failed"
```
Solution:
1. Check your internet connection
2. Make sure your Apple ID has access to App Store Connect
3. Try using Transporter app instead of Xcode
4. Check Apple Developer System Status
```

---

## 💡 Pro Tips

1. **Test Thoroughly**: Test on multiple device sizes and iOS versions
2. **Screenshots Matter**: High-quality screenshots increase downloads
3. **Keywords**: Choose relevant keywords for better discovery
4. **Update Regularly**: Plan updates to keep users engaged
5. **Monitor Feedback**: Respond to user reviews and feedback
6. **Analytics**: Use App Store Connect analytics to understand usage

---

## 📞 Next Steps

1. **Start with Apple Developer Account** - This is the foundation
2. **Set up your bundle ID** - Choose your unique identifier
3. **Test on physical device** - Make sure everything works
4. **Create screenshots** - Take high-quality app screenshots
5. **Submit to TestFlight** - Get feedback from testers
6. **Submit for App Store Review** - Go live!

Would you like me to help you with any specific step? I can guide you through the Xcode setup, help write the app description, or troubleshoot any issues you encounter!