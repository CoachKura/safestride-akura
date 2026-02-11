# 📦 SafeStride APK Build & Distribution Guide

## 🎯 Current Status
✅ GPS Workout Tracking - TESTED & WORKING
✅ Calendar Integration - Shows tracked workouts
✅ Kura Coach AI Plans - Ready
⏳ Ready to build APK for athlete distribution

---

## 🚀 QUICK BUILD COMMAND

```powershell
# Navigate to project
cd C:\safestride

# Clean build
flutter clean

# Build release APK
flutter build apk --release

# APK location:
# C:\safestride\build\app\outputs\flutter-apk\app-release.apk
```

---

## 📱 BUILDING THE APK

### Step 1: Update App Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Change to 1.0.1+2, 1.0.2+3, etc.
```

### Step 2: Update App Name & Icon (Optional)
**App Name:**
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="SafeStride"  <!-- Change this -->
```

**App Icon:**
Place icon files in: `android/app/src/main/res/mipmap-*/ic_launcher.png`

### Step 3: Build Release APK
```powershell
# Full clean build
flutter clean
flutter pub get
flutter build apk --release
```

**Build time:** 2-3 minutes

**Output:** `C:\safestride\build\app\outputs\flutter-apk\app-release.apk`

**File size:** ~50-60 MB

### Step 4: Verify APK
```powershell
# Check APK details
flutter build apk --release --verbose

# Install on connected device to test
flutter install
```

---

## 📤 DISTRIBUTING TO ATHLETES

### Method 1: Direct File Transfer (Recommended for Testing)

**via WhatsApp/Telegram:**
1. Locate: `C:\safestride\build\app\outputs\flutter-apk\app-release.apk`
2. Send file to athletes
3. Athletes:
   - Download APK
   - Settings → Security → "Install from Unknown Sources" (enable)
   - Open APK file
   - Tap "Install"

**via Google Drive/Dropbox:**
1. Upload `app-release.apk` to cloud storage
2. Share link with athletes
3. Athletes download and install as above

**via Email:**
- Some email providers block APK files
- Rename to `app-release.zip` before sending
- Athletes rename back to `.apk` before installing

### Method 2: Internal Testing (Recommended for Production)

**Google Play Internal Testing:**
1. Create Google Play Developer account ($25 one-time fee)
2. Create new app in Play Console
3. Upload APK to Internal Testing
4. Add athlete emails to tester list
5. Athletes get email with install link (no "Unknown Sources" needed)

**Benefits:**
- ✅ No security warnings
- ✅ Auto-updates
- ✅ Install from Play Store app
- ✅ Professional distribution

**Steps:**
```powershell
# 1. Build app bundle (better than APK for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# 2. Upload .aab to Play Console
# 3. Set up Internal Testing track
# 4. Add testers by email
# 5. Share test link
```

### Method 3: Firebase App Distribution (Free, Easy)

**Setup:**
1. Create Firebase project (free): https://console.firebase.google.com
2. Add Android app
3. Download `google-services.json` → `android/app/`
4. Install Firebase CLI: `npm install -g firebase-tools`
5. Deploy:
```powershell
firebase login
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "athletes"
```

**Benefits:**
- ✅ Free
- ✅ Athletes get email with install link
- ✅ Track who installed
- ✅ Push new versions easily

---

## 🔐 APP SIGNING (Important for Updates)

### First Time Setup:
```powershell
# Navigate to Android folder
cd android

# Generate keystore (do this ONCE, save the file!)
keytool -genkey -v -keystore C:\safestride\keystore\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Follow prompts, remember passwords!
```

**Create `android/key.properties`:**
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=C:/safestride/keystore/upload-keystore.jks
```

**Update `android/app/build.gradle`:**
```gradle
// Add before 'android {'
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

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
            signingConfig signingConfigs.release  // Add this
        }
    }
}
```

**⚠️ CRITICAL: Backup keystore file!** If you lose it, you can't update the app.

---

## 📋 PRE-RELEASE CHECKLIST

Before sending to athletes:

### Technical Checks:
- [ ] App builds without errors: `flutter build apk --release`
- [ ] No critical warnings: `flutter analyze`
- [ ] Test on real device (not emulator)
- [ ] GPS tracking works
- [ ] Workout saves to calendar
- [ ] Login/signup works
- [ ] Supabase connection configured correctly

### Content Checks:
- [ ] Updated version number in `pubspec.yaml`
- [ ] App name correct (not "akura_mobile")
- [ ] Splash screen loads
- [ ] No placeholder text visible
- [ ] All screens accessible

### User Experience:
- [ ] Clear onboarding flow
- [ ] Error messages are user-friendly
- [ ] Loading states show properly
- [ ] No crashes during normal use

### Security:
- [ ] Supabase RLS policies enabled
- [ ] API keys not exposed in code
- [ ] User data properly isolated

---

## 🐛 TROUBLESHOOTING

### "Installation blocked" on athlete devices
**Solution:** Athletes must enable "Install from Unknown Sources"
- Settings → Security → Unknown Sources (enable)
- Or: Settings → Apps → Special Access → Install Unknown Apps → (Your File Manager) → Allow

### "App not installed" error
**Causes:**
1. Old version already installed → Uninstall first
2. APK corrupted during transfer → Re-send file
3. Insufficient storage → Free up space
4. Android version too old → Check minimum SDK

### APK too large (>100 MB)
**Solutions:**
```powershell
# Split APK by architecture (recommended)
flutter build apk --release --split-per-abi

# Outputs 3 files:
# - app-armeabi-v7a-release.apk (32-bit, ~25 MB)
# - app-arm64-v8a-release.apk (64-bit, ~25 MB) ← Most common
# - app-x86_64-release.apk (emulators, ~30 MB)

# Send arm64-v8a to most athletes, armeabi-v7a for older phones
```

### Build fails with "Gradle sync failed"
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📊 TRACKING INSTALLS & USAGE

### Google Analytics (Free)
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_analytics: ^10.8.0
```

Track events:
```dart
FirebaseAnalytics.instance.logEvent(name: 'workout_completed', parameters: {'distance': 1.16});
```

### Crashlytics (Free, Recommended)
Auto-reports crashes:
```yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

---

## 🔄 UPDATING THE APP

### For Athletes with APK:
1. Build new version with incremented version number
2. Send new APK
3. Athletes install over old version (data preserved)

### For Google Play Internal Testing:
1. Build new version
2. Upload to Play Console
3. Athletes get automatic update notification

### For Firebase App Distribution:
1. Build new APK
2. Run: `firebase appdistribution:distribute ...`
3. Athletes get email notification

---

## 📱 MINIMUM DEVICE REQUIREMENTS

Current settings:
- **Android:** 6.0 (API 23) or higher
- **RAM:** 2 GB minimum, 4 GB recommended
- **Storage:** 100 MB free space
- **GPS:** Required for workout tracking
- **Internet:** Required for cloud sync

To change minimum Android version, edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Change this (23 = Android 6.0)
    }
}
```

---

## ✅ RECOMMENDED WORKFLOW

**For 10 Test Athletes (Current):**
```
1. flutter build apk --release
2. Upload to Google Drive
3. Share link via WhatsApp group
4. Athletes install & test
5. Collect feedback
6. Fix issues
7. Repeat
```

**For Production Launch (Future):**
```
1. Set up Google Play Internal Testing
2. flutter build appbundle --release
3. Upload to Play Console
4. Add all athletes as testers
5. Send install link
6. Monitor crashes via Crashlytics
7. Push updates seamlessly
```

---

## 🎯 NEXT STEPS FOR TODAY

1. **Hot reload the fix:**
   ```powershell
   # In Flutter terminal, press: r
   ```

2. **Test GPS tracking again:**
   - Start → Walk → Stop → Verify save → Check Calendar

3. **If working:**
   ```powershell
   flutter build apk --release
   ```

4. **APK ready at:**
   ```
   C:\safestride\build\app\outputs\flutter-apk\app-release.apk
   ```

5. **Send to athletes via:**
   - WhatsApp / Telegram (direct file)
   - Google Drive (share link)
   - Firebase App Distribution (email notification)

---

## 📞 ATHLETE INSTALLATION INSTRUCTIONS

**Send this to athletes:**

```
🏃 SafeStride App - Installation Guide

1️⃣ Download the APK file I sent you

2️⃣ Open the file on your phone

3️⃣ If you see "Install blocked":
   → Tap "Settings"
   → Enable "Install from unknown sources"
   → Go back and try again

4️⃣ Tap "Install"

5️⃣ Open the app and sign up with your email

6️⃣ Grant location permissions when asked

✅ You're ready! Go to "Tracker" tab to start tracking workouts.

Questions? Reply to this message!
```

---

**Ready to build? First test the fix with: `r` (hot reload) in Flutter terminal!** 🚀
