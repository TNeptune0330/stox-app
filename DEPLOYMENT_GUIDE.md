# 🚀 Stox App Deployment Guide

Complete guide for signing, testing, and publishing your Stox trading simulator app to both App Store and Google Play Store.

## 📋 Prerequisites

### Required Accounts
- **Apple Developer Account** ($99/year) - https://developer.apple.com
- **Google Play Console Account** ($25 one-time) - https://play.google.com/console
- **Xcode** (latest version from Mac App Store)
- **Android Studio** (latest version)

### Required Setup
- Mac computer for iOS builds
- Valid Apple ID with Developer Program enrollment
- Google account with Play Console access

---

## 🍎 iOS Setup & Signing

### Step 1: Apple Developer Account Setup

1. **Enroll in Apple Developer Program**
   ```bash
   # Visit: https://developer.apple.com/programs/
   # Sign up with your Apple ID
   # Pay $99 annual fee
   # Complete verification process
   ```

2. **Create App Identifier**
   - Go to Apple Developer Portal → Certificates, Identifiers & Profiles
   - Create new App ID: `com.yourcompany.stox`
   - Enable capabilities:
     - App Groups
     - Sign In with Apple (if needed)
     - Push Notifications (future feature)

### Step 2: Certificates & Provisioning Profiles

1. **Development Certificate**
   ```bash
   # In Xcode:
   # 1. Open ios/Runner.xcworkspace
   # 2. Select Runner target
   # 3. Go to Signing & Capabilities
   # 4. Enable "Automatically manage signing"
   # 5. Select your team
   ```

2. **Distribution Certificate**
   - Xcode will create this automatically when you archive for distribution
   - Or manually create in Apple Developer Portal

### Step 3: Configure Xcode Project

1. **Update Bundle Identifier**
   ```bash
   # In Xcode, update these settings:
   PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.stox
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   CODE_SIGN_IDENTITY = Apple Development (for debug)
   CODE_SIGN_IDENTITY = Apple Distribution (for release)
   ```

2. **Update Info.plist** (already configured)
   - App name: "Stox"
   - Bundle identifier: matches your App ID
   - Version: 1.0.0
   - Build: 1

### Step 4: Build for Testing

1. **Build Debug Version for Physical Device**
   ```bash
   flutter build ios --debug
   # Then in Xcode:
   # 1. Connect your iPhone/iPad
   # 2. Select your device as target
   # 3. Click Run (▶️) button
   ```

2. **Build Release Version**
   ```bash
   flutter build ios --release
   # In Xcode:
   # 1. Product → Archive
   # 2. Wait for archive to complete
   # 3. Distribute App → Development (for testing)
   ```

### Step 5: TestFlight Distribution

1. **Create App in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Create new app with same bundle ID
   - Fill basic information

2. **Upload to TestFlight**
   ```bash
   # After archiving in Xcode:
   # 1. Select "Distribute App"
   # 2. Choose "App Store Connect"
   # 3. Upload build
   # 4. Add internal/external testers in App Store Connect
   ```

---

## 🤖 Android Setup & Signing

### Step 1: Create Keystore

```bash
# Navigate to your app directory
cd /Users/takshpradhan/stox-app/stox

# Create keystore (DO THIS ONCE - KEEP SAFE!)
keytool -genkey -v -keystore ~/stox-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias stox-key

# You'll be prompted for:
# - Keystore password (REMEMBER THIS!)
# - Key password (can be same as keystore)
# - Your name/organization details
```

### Step 2: Configure Gradle Signing

1. **Create key.properties file**
   ```bash
   # Create android/key.properties (DON'T COMMIT TO GIT!)
   echo "storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=stox-key
   storeFile=$HOME/stox-release-key.keystore" > android/key.properties
   ```

2. **Update android/app/build.gradle**
   ```gradle
   # Add before android block:
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

### Step 3: Build Signed APK/AAB

```bash
# Build signed APK for testing
flutter build apk --release

# Build signed App Bundle for Play Store
flutter build appbundle --release

# Files will be in:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

### Step 4: Google Play Console Setup

1. **Create App in Play Console**
   - Go to https://play.google.com/console
   - Create new app
   - Choose app details

2. **Upload for Internal Testing**
   - Go to Release → Testing → Internal testing
   - Create new release
   - Upload app-release.aab
   - Add release notes
   - Review and publish

---

## 📱 Testing on Multiple Devices

### iOS Testing Options

1. **Direct Installation (Development)**
   ```bash
   # Connect device via USB
   flutter run --release -d [device-id]
   
   # Or build and install via Xcode
   flutter build ios --release
   # Then use Xcode to install on connected device
   ```

2. **TestFlight (Recommended)**
   - Upload build to App Store Connect
   - Add devices/users in TestFlight
   - Testers download TestFlight app
   - Install your app through TestFlight

3. **Ad Hoc Distribution**
   - Register device UDIDs in Apple Developer Portal
   - Create Ad Hoc provisioning profile
   - Archive and distribute

### Android Testing Options

1. **Direct APK Installation**
   ```bash
   # Build and install
   flutter build apk --release
   flutter install --release
   
   # Or manually install APK
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Google Play Internal Testing**
   - Upload AAB to Play Console
   - Add testers via email
   - Share testing link
   - Testers install via Play Store

3. **Firebase App Distribution** (Optional)
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Setup and distribute
   firebase login
   firebase apps:distribute:android build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🏪 App Store Submission

### iOS App Store

1. **Prepare App Store Connect**
   - Complete app information
   - Add screenshots (required sizes)
   - Write app description
   - Set pricing
   - Add privacy policy URL
   - Complete app review questionnaire

2. **Submit for Review**
   - Upload final build via Xcode or Transporter
   - Submit for review
   - Response time: 24-48 hours typically

### Google Play Store

1. **Complete Store Listing**
   - App details and description
   - Screenshots and graphics
   - Content rating questionnaire
   - Pricing and distribution

2. **Release to Production**
   - Upload signed AAB
   - Complete all required sections
   - Submit for review
   - Response time: Usually within 3 days

---

## 📊 Required Assets

### Screenshots (Generate these from your app)

**iOS Requirements:**
- iPhone 6.7" (1290 x 2796)
- iPhone 6.5" (1242 x 2688)
- iPhone 5.5" (1242 x 2208)
- iPad Pro 12.9" (2048 x 2732)

**Android Requirements:**
- Phone: 1080 x 1920 minimum
- 7" Tablet: 1024 x 1600 minimum
- 10" Tablet: 1200 x 1920 minimum

### App Icons (Already configured)
- iOS: Various sizes in Assets.xcassets
- Android: Various sizes in android/app/src/main/res/

### Marketing Graphics
- iOS: No additional graphics required
- Android: Feature graphic (1024 x 500)

---

## 🛡️ Security Checklist

- [ ] Remove all debug prints for production
- [ ] Verify API keys are secure
- [ ] Test on multiple devices
- [ ] Verify Google Sign-In works
- [ ] Test offline functionality
- [ ] Verify weekend banner appears
- [ ] Test theme persistence
- [ ] Verify achievements work
- [ ] Test portfolio sync
- [ ] Check app performance

---

## 📞 Need Help?

If you encounter issues during any step:

1. **iOS Issues**: Check Apple Developer Forums
2. **Android Issues**: Check Android Developer Documentation
3. **Flutter Issues**: Check Flutter Documentation
4. **General**: I can help debug specific error messages

**Important Files to Keep Safe:**
- `~/stox-release-key.keystore` (Android)
- `android/key.properties` (Android)
- Apple Developer account credentials
- App Store Connect access

**Never commit to Git:**
- `android/key.properties`
- Keystore files
- API keys (use environment variables)

Ready to start? Let me know which platform you'd like to tackle first!