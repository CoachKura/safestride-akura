# 📱 SafeStride AI - Flutter Mobile Deployment Guide

## 🎯 Overview

Complete guide for building and deploying the SafeStride Flutter mobile app to iOS (App Store) and Android (Google Play).

---

## 📋 Prerequisites

### Development Environment

- [ ] Flutter SDK 3.16+ installed
- [ ] Xcode 15+ (for iOS, macOS only)
- [ ] Android Studio with Android SDK 33+
- [ ] CocoaPods installed (for iOS)
- [ ] Valid developer accounts:
  - Apple Developer Program ($99/year)
  - Google Play Developer ($25 one-time)

### Verify Installation

```bash
# Check Flutter
flutter doctor -v

# Expected output:
# ✓ Flutter (Channel stable, 3.16.x)
# ✓ Android toolchain
# ✓ Xcode (for iOS)
# ✓ VS Code / Android Studio
# ✓ Connected devices
```

---

## 🔧 Part 1: Configure Flutter Project

### Step 1: Update API Configuration

Create `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Backend API URLs (update with your Render URLs)
  static const String baseUrl = 'https://safestride-api.onrender.com';
  static const String webhooksUrl = 'https://safestride-webhooks.onrender.com';
  static const String oauthUrl = 'https://safestride-oauth.onrender.com';
  
  // API Endpoints
  static const String signupEndpoint = '/athletes/signup';
  static const String profileEndpoint = '/athletes';
  static const String raceAnalysisEndpoint = '/races/analyze';
  static const String fitnessEndpoint = '/fitness';
  static const String workoutsEndpoint = '/workouts';
  static const String stravaConnectEndpoint = '/strava/connect';
  static const String stravaStatusEndpoint = '/strava/status';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
}
```

### Step 2: Update App Configuration

Edit `pubspec.yaml`:

```yaml
name: safestride
description: AI-powered running coach with holistic training approach
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
publish_to: 'none'

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  http: ^1.1.0
  dio: ^5.4.0
  
  # State Management
  provider: ^6.1.1
  
  # Local Storage
  shared_preferences: ^2.2.2
  
  # OAuth & Deep Links
  url_launcher: ^6.2.2
  uni_links: ^0.5.1
  
  # UI Components
  cupertino_icons: ^1.0.6
  flutter_svg: ^2.0.9
  
  # Charts & Analytics
  fl_chart: ^0.65.0
  
  # Date & Time
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

### Step 3: Set App Metadata

#### iOS: `ios/Runner/Info.plist`

```xml
<key>CFBundleDisplayName</key>
<string>SafeStride AI</string>

<key>CFBundleIdentifier</key>
<string>com.safestride.app</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>1</string>

<!-- Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>SafeStride needs your location to track outdoor runs</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>SafeStride needs access to save workout screenshots</string>

<!-- URL Scheme for OAuth -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>safestride</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.safestride.app</string>
    </dict>
</array>
```

#### Android: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="SafeStride AI"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            
            <!-- Deep Links for OAuth -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="safestride"
                    android:host="callback" />
            </intent-filter>
        </activity>
    </application>
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</manifest>
```

---

## 🍎 Part 2: iOS Deployment

### Step 1: Configure Xcode Project

```bash
# Open Xcode workspace
cd ios
open Runner.xcworkspace
```

In Xcode:

1. **Select Runner target** (top left)
2. **General tab**:
   - Display Name: `SafeStride AI`
   - Bundle Identifier: `com.safestride.app`
   - Version: `1.0.0`
   - Build: `1`
   - Minimum Deployments: `iOS 13.0`

3. **Signing & Capabilities**:
   - Team: Select your Apple Developer team
   - ✅ Automatically manage signing
   - Provisioning Profile: Xcode Managed Profile

### Step 2: Create App Icons

Generate icons using [App Icon Generator](https://www.appicon.co/):

1. Upload your logo (1024×1024 px)
2. Download iOS icon set
3. Replace `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Step 3: Update Launch Screen

Edit `ios/Runner/Assets.xcassets/LaunchImage.imageset/`:
- Add your splash screen images (1x, 2x, 3x)
- Or use `flutter pub add flutter_native_splash`

### Step 4: Build for Testing

```bash
cd ..  # Back to project root

# Clean build
flutter clean
flutter pub get

# Build iOS app (simulator)
flutter build ios --debug

# Run on connected iPhone
flutter run --release
```

### Step 5: Build for App Store

```bash
# Build Release IPA
flutter build ipa --release

# Output location:
# build/ios/ipa/safestride.ipa
```

### Step 6: Upload to App Store Connect

#### Option A: Via Xcode

1. Archive the app:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. In Xcode:
   - Product → Archive
   - Wait for archive to complete
   - Click "Distribute App"
   - Select "App Store Connect"
   - Upload

#### Option B: Via Transporter

1. Download **Transporter** from Mac App Store
2. Open Transporter
3. Sign in with Apple ID
4. Drag `build/ios/ipa/safestride.ipa` into Transporter
5. Click "Deliver"

### Step 7: Submit for Review

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)

2. **Create new app**:
   - Name: SafeStride AI
   - Primary Language: English
   - Bundle ID: com.safestride.app
   - SKU: safestride-001

3. **Fill App Information**:
   - Subtitle: "Your AI Running Coach"
   - Description:
     ```
     SafeStride AI is your personalized running coach powered by artificial intelligence.
     
     🏃 HOLISTIC TRAINING APPROACH
     - Mileage progression with injury prevention
     - Strength & mobility exercises
     - Balance & coordination drills
     - Mental toughness training
     - Recovery optimization
     
     🤖 AI-POWERED COACHING
     - Analyzes your race history
     - Assesses current fitness level
     - Generates adaptive workout plans
     - Tracks performance metrics
     - Provides real-time feedback
     
     📊 STRAVA INTEGRATION
     - Automatic activity sync
     - Detailed performance analysis
     - Progress tracking
     - Ability progression monitoring
     
     🎯 FEATURES
     - Personalized training plans (180-365 days)
     - Foundation phase for injury prevention
     - ACWR monitoring
     - Progressive overload optimization
     - Recovery week detection
     - Race prediction & goal setting
     
     Perfect for runners of all levels from beginners to advanced athletes preparing for marathons, half marathons, and beyond!
     ```

   - Keywords: `running, coach, AI, training, marathon, fitness, workout, strava`
   - Support URL: `https://safestride.ai/support`
   - Privacy Policy URL: `https://safestride.ai/privacy`

4. **Add Screenshots** (required sizes):
   - 6.7" Display (iPhone 15 Pro Max): 1290 × 2796 px
   - 5.5" Display (iPhone 8 Plus): 1242 × 2208 px
   - 12.9" Display (iPad Pro): 2048 × 2732 px

   Minimum 3 screenshots per size. Use [screenshot.rocks](https://screenshot.rocks/) for mockups.

5. **App Preview** (optional but recommended):
   - 15-30 second video showing key features
   - Upload .m4v or .mov file

6. **Pricing & Availability**:
   - Price: Free (or your pricing tier)
   - Availability: All countries

7. **App Review Information**:
   - Demo account credentials (if login required)
   - Notes for reviewer explaining Strava integration

8. **Submit for Review**:
   - Click "Submit for Review"
   - Review time: 7-14 days typically

---

## 🤖 Part 3: Android Deployment

### Step 1: Generate Signing Key

```bash
# Generate release keystore
keytool -genkey -v -keystore C:\Users\<YOU>\safestride-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias safestride

# Enter details:
# - Password: [SECURE_PASSWORD] (save this!)
# - Name: SafeStride AI
# - Organization: SafeStride
# - City, State, Country: Your details
```

### Step 2: Configure Signing

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=safestride
storeFile=C:/Users/YOU/safestride-release-key.jks
```

**⚠️ IMPORTANT**: Add `android/key.properties` to `.gitignore`!

### Step 3: Update Build Configuration

Edit `android/app/build.gradle`:

```gradle
// Add before 'android' block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.safestride.app"
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.safestride.app"
        minSdkVersion 23  // Android 6.0+
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
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
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 4: Create App Icons

Generate Android icon set:

1. Go to [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)
2. Upload logo (512×512 px)
3. Download icon set
4. Replace `android/app/src/main/res/mipmap-*/ic_launcher.png`

Or use:
```bash
flutter pub add flutter_launcher_icons
```

### Step 5: Build for Testing

```bash
# Build debug APK
flutter build apk --debug

# Install on connected device
flutter install

# Test app thoroughly
flutter run --release
```

### Step 6: Build for Production

```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output:
# build/app/outputs/bundle/release/app-release.aab

# Or build APK (for direct distribution)
flutter build apk --release --split-per-abi

# Outputs:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Step 7: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console/)

2. **Create new app**:
   - App name: SafeStride AI
   - Default language: English
   - App or game: App
   - Free or paid: Free

3. **Dashboard tasks** (complete all):

#### A. App Content
- Privacy Policy: `https://safestride.ai/privacy`
- App category: Health & Fitness
- Tags: Running, Fitness, Training, Coach
- Contact email: support@safestride.ai

#### B. Store Listing
- Short description (80 chars):
  ```
  AI-powered running coach with holistic training and Strava integration
  ```

- Full description (4000 chars):
  ```
  🏃 YOUR PERSONAL AI RUNNING COACH
  
  SafeStride AI brings professional-level coaching to every runner. Our advanced AI engine analyzes your fitness, creates personalized training plans, and adapts to your progress in real-time.
  
  🎯 HOLISTIC TRAINING APPROACH
  
  Unlike other running apps that focus only on mileage, SafeStride takes a complete approach:
  
  ✓ Mileage Progression - Safe weekly increases with injury prevention
  ✓ Strength Training - 3x weekly sessions integrated into your plan
  ✓ Mobility & Flexibility - ROM exercises for injury prevention
  ✓ Balance & Coordination - Stability drills for efficiency
  ✓ Mental Training - Mindfulness and focus techniques
  ✓ Recovery Optimization - Smart rest days and deload weeks
  
  🤖 AI-POWERED FEATURES
  
  • Race Analysis - Upload past races for fitness assessment
  • Fitness Scoring - 6-dimension evaluation (0-100 scale)
  • Adaptive Plans - 180-365 day personalized roadmaps
  • Performance Tracking - GIVEN vs EXPECTED vs RESULT analysis
  • Workout Generation - Daily intelligent workout creation
  • ACWR Monitoring - Injury risk prevention (0.8-1.3 safe zone)
  • Progressive Overload - Optimal 5-10% weekly increases
  
  📊 STRAVA INTEGRATION
  
  Seamlessly connect your Strava account:
  • Automatic activity sync
  • Real-time performance analysis
  • Workout vs actual comparison
  • Ability progression tracking
  • Training load monitoring
  
  🏅 PERFECT FOR
  
  • Beginner runners building foundation (12+ weeks)
  • Intermediate runners chasing PRs
  • Advanced athletes training for marathons
  • Anyone wanting injury-free progression
  • Runners seeking holistic improvement
  
  📈 TRAINING PHASES
  
  1. Foundation Phase - Build base fitness & strength
  2. Base Building - Increase aerobic capacity
  3. Speed Development - Add tempo & intervals
  4. Race Preparation - Sharpen for goal race
  5. Taper & Peak - Arrive fresh and ready
  
  🔧 KEY FEATURES
  
  • Personalized onboarding with race history
  • Daily workout assignments with details
  • Real-time performance feedback
  • Ability tracking across dimensions
  • Training load visualization
  • Recovery recommendations
  • Injury risk alerts
  • Goal race predictions
  
  💪 INJURY PREVENTION
  
  SafeStride prioritizes long-term health:
  • ACWR monitoring prevents overtraining
  • Foundation phase required for weak areas
  • Auto recovery weeks every 4 weeks
  • Progressive overload limits (max 10%)
  • Holistic strength & mobility work
  
  🎓 BASED ON SCIENCE
  
  Our AI engine incorporates:
  • Exercise physiology principles
  • Sports science research
  • Biomechanics optimization
  • Recovery science
  • Periodization theory
  
  🚀 GET STARTED TODAY
  
  1. Sign up & complete profile
  2. Upload past race results
  3. Complete fitness assessment
  4. Connect Strava (optional)
  5. Receive your personalized plan
  6. Start training smarter!
  
  📞 SUPPORT
  
  Questions? Email support@safestride.ai
  Website: https://safestride.ai
  Privacy: https://safestride.ai/privacy
  
  Download SafeStride AI and start your journey to becoming a stronger, faster, healthier runner! 🏃‍♂️💨
  ```

- **Screenshots** (at least 2, max 8):
  - Phone: 1080 × 1920 px or larger
  - 7-inch tablet: 1920 × 1080 px
  - 10-inch tablet: 1920 × 1200 px
  
  Recommended: 5-8 screenshots showing:
  1. Onboarding flow
  2. Fitness assessment results
  3. Training plan overview
  4. Daily workout details
  5. Strava connection
  6. Performance charts
  7. Ability progression
  8. Settings/profile

- **Feature Graphic** (required):
  - Size: 1024 × 500 px
  - Use Canva or Figma to create branded banner

#### C. Production Release

1. **Create new release**:
   - Release name: `1.0.0 (1)`
   - Release notes:
     ```
     🎉 Welcome to SafeStride AI v1.0!
     
     ✓ Personalized AI coaching
     ✓ Holistic 6-dimension training
     ✓ Strava integration
     ✓ Adaptive workout generation
     ✓ Performance tracking
     ✓ Injury prevention monitoring
     
     Start your journey to becoming a better runner today!
     ```

2. **Upload AAB**:
   - Drag `build/app/outputs/bundle/release/app-release.aab`
   - Wait for processing (2-5 minutes)

3. **Review & rollout**:
   - Countries: All (or select specific)
   - Rollout percentage: 100% (or staged rollout)
   - Click "Review Release"
   - Click "Start Rollout to Production"

### Step 8: Submit for Review

- Review time: 1-7 days (usually faster than iOS)
- Check status in Play Console dashboard
- Address any policy issues if flagged

---

## 🧪 Part 4: Beta Testing (Recommended)

### iOS TestFlight

1. **In App Store Connect**:
   - Go to TestFlight tab
   - Create Internal Testing group
   - Add testers by email (up to 100)

2. **Distribute build**:
   - Select build
   - Add to testing group
   - Testers receive email invite

3. **Collect feedback**:
   - TestFlight app has built-in feedback option
   - Monitor crash reports
   - Iterate for 2-4 weeks

### Android Internal Testing

1. **In Google Play Console**:
   - Release → Testing → Internal testing
   - Create release
   - Upload AAB

2. **Add testers**:
   - Create email list (up to 100)
   - Or use Google Group

3. **Distribute**:
   - Testers get Play Store link
   - Install via Play Store
   - Provide feedback via form

---

## 📊 Part 5: Post-Launch Monitoring

### App Store Connect Analytics

- Impressions & downloads
- Crash reports
- Reviews & ratings
- Retention metrics

### Google Play Console Analytics

- Install statistics
- Crashes & ANRs
- User reviews
- Performance metrics

### Firebase Analytics (Recommended)

```bash
# Add Firebase
flutter pub add firebase_core
flutter pub add firebase_analytics

# Track events:
- app_open
- sign_up
- strava_connect
- workout_complete
- race_analyzed
```

---

## 🔄 Part 6: Updates & Maintenance

### Version Numbering

Follow semantic versioning:
- **1.0.1**: Bug fixes
- **1.1.0**: New features
- **2.0.0**: Major changes

### Release Process

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.1.0+2  # 1.1.0 is version name, +2 is build number
   ```

2. **Build new release**:
   ```bash
   flutter build ipa --release     # iOS
   flutter build appbundle --release  # Android
   ```

3. **Upload to stores**:
   - TestFlight → Production (iOS)
   - Internal Testing → Production (Android)

4. **Monitor rollout**:
   - Check crash rates
   - Monitor reviews
   - Fix critical issues ASAP

---

## 🚨 Troubleshooting

### Build Errors

```bash
# Clean and rebuild
flutter clean
rm -rf ios/Pods ios/.symlinks
cd ios && pod install --repo-update
cd .. && flutter pub get
flutter build ios
```

### Signing Issues (iOS)

- Verify Apple Developer membership active
- Check provisioning profiles in Xcode
- Try manual signing instead of automatic

### Upload Fails

- Check App Store Connect/Play Console for error details
- Verify version number incremented
- Ensure all required fields completed

### Crash on Launch

- Check native logs: `flutter logs`
- Verify API URLs are correct
- Test on physical device, not simulator

---

## ✅ Deployment Checklist

### Pre-Submission
- [ ] API configuration updated with production URLs
- [ ] App icons generated (all sizes)
- [ ] Launch screens created
- [ ] Privacy policy & support URLs active
- [ ] Tested on multiple devices & OS versions
- [ ] No console errors or warnings
- [ ] Performance optimized (60 FPS)
- [ ] Deep links working (Strava OAuth)

### iOS Specific
- [ ] Xcode project configured correctly
- [ ] Bundle ID matches Apple Developer
- [ ] Signing certificates valid
- [ ] TestFlight build uploaded
- [ ] App Store screenshots (all sizes)
- [ ] Privacy descriptions in Info.plist

### Android Specific
- [ ] Signing key generated & stored securely
- [ ] key.properties created (not in Git)
- [ ] Build.gradle configured correctly
- [ ] Play Console account active
- [ ] Screenshots uploaded (phone & tablet)
- [ ] Privacy policy URL set

### Post-Submission
- [ ] Monitor review status daily
- [ ] Respond to reviewer questions within 24h
- [ ] Fix any rejection issues immediately
- [ ] Prepare marketing materials for launch
- [ ] Plan user onboarding for first 72 hours

---

## 🎉 Launch Day Checklist

- [ ] App approved in both stores
- [ ] Website updated with download links
- [ ] Social media announcement ready
- [ ] Support email monitoring active
- [ ] Analytics dashboard set up
- [ ] Crash reporting configured
- [ ] Beta testers thanked & notified
- [ ] Press release sent (optional)
- [ ] Monitor reviews & ratings
- [ ] Celebrate! 🎊

---

**🏃 Ready to ship? You've got this!** 🚀

For support: support@safestride.ai
