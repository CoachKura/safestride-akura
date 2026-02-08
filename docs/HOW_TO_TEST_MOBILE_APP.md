# 📱 HOW TO TEST SAFESTRIDE - PRACTICAL GUIDE

**Date:** February 4, 2026  
**App Type:** Flutter Mobile Application (Android & iOS)  

---

## ⚠️ IMPORTANT: THIS IS A MOBILE APP

SafeStride is a **Flutter mobile application**, not a web app. This means:

❌ **Cannot** run in a web browser  
❌ **Cannot** run on desktop without emulator  
✅ **Requires** Android device or emulator  
✅ **Requires** Flutter SDK to build  
✅ **Requires** proper mobile testing environment  

---

## 🎯 TESTING OPTIONS

### **OPTION 1: Test on Your Computer** ⭐ **Recommended**

**Requirements:**
- ✅ Windows/Mac/Linux computer
- ✅ Flutter SDK installed (currently at `E:\Akura Safe Stride\safestride\akura_mobile`)
- ✅ Android device **OR** Android Studio with emulator
- ✅ VS Code or Android Studio IDE

**Steps:**

1. **Open Project**
   ```powershell
   cd "E:\Akura Safe Stride\safestride\akura_mobile"
   code .
   ```

2. **Install Dependencies**
   ```powershell
   flutter pub get
   ```

3. **Connect Device or Start Emulator**
   - **Physical Device:** Connect via USB, enable USB debugging
   - **Emulator:** Start from Android Studio (`Tools → Device Manager`)

4. **Verify Device Connected**
   ```powershell
   flutter devices
   ```
   Should show your device/emulator listed

5. **Run App**
   ```powershell
   flutter run
   ```
   App will launch on your device

6. **Follow Testing Guide**
   - Open `docs/READY_TO_TEST.md`
   - Use provided test data
   - Complete all test scenarios
   - Verify expected results

**Time Required:** 30 minutes for complete testing

---

### **OPTION 2: Build APK, Test on Physical Phone**

**Requirements:**
- ✅ Flutter SDK installed on any computer
- ✅ Android phone (no USB cable needed)
- ✅ Ability to transfer files to phone

**Steps:**

1. **Build Release APK**
   ```powershell
   cd "E:\Akura Safe Stride\safestride\akura_mobile"
   flutter build apk --release
   ```
   
2. **Locate APK File**
   ```
   Build output: E:\Akura Safe Stride\safestride\akura_mobile\build\app\outputs\flutter-apk\app-release.apk
   ```

3. **Transfer APK to Phone**
   - Email to yourself
   - Upload to Google Drive/Dropbox
   - Transfer via USB cable
   - Use file sharing app (Nearby Share, SHAREit)

4. **Install on Phone**
   - Download APK on phone
   - Tap to install (may need to enable "Install from unknown sources")
   - Accept permissions

5. **Test App**
   - Open SafeStride app
   - Follow `docs/READY_TO_TEST.md`
   - Complete test scenarios
   - Take screenshots of results

**Time Required:** 15 min build + 30 min testing = 45 minutes

---

### **OPTION 3: Test on iOS Device** (Mac Only)

**Requirements:**
- ✅ Mac computer with Xcode
- ✅ iPhone or iPad
- ✅ Apple Developer account (for physical device)

**Steps:**

1. **Open Project in Xcode**
   ```bash
   cd /path/to/safestride/akura_mobile
   open ios/Runner.xcworkspace
   ```

2. **Select Device**
   - Connect iPhone via USB
   - Select device in Xcode toolbar

3. **Run App**
   - Click "Run" button (▶️) in Xcode
   - App builds and installs on device

4. **Test App**
   - Follow `docs/READY_TO_TEST.md`
   - Complete all scenarios

**Time Required:** 30 minutes

---

## 🛠️ SETUP VERIFICATION

### **Check Flutter Installation**
```powershell
flutter doctor -v
```

**Expected Output:**
```
✅ Flutter (Channel stable, 3.x.x)
✅ Android toolchain - develop for Android devices
✅ VS Code (version x.x.x)
✅ Connected device (if device connected)
```

**If Issues:**
- ❌ Flutter not installed → Install from https://flutter.dev
- ❌ Android toolchain missing → Install Android Studio
- ❌ No devices → Connect device or start emulator

---

## 📋 TESTING CHECKLIST

### **Pre-Testing Setup**
- [ ] Flutter SDK installed and working (`flutter doctor`)
- [ ] Device/emulator connected (`flutter devices`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Supabase credentials configured (`.env` file)
- [ ] Internet connection available (for Supabase)

### **Core Features to Test**
- [ ] **Login/Register** - Create account, sign in
- [ ] **Dashboard** - Displays correctly, all widgets visible
- [ ] **Evaluation Form** - 7 steps, all fields work
- [ ] **Submit Assessment** - Data saves to Supabase
- [ ] **View Results** - AISRI score, gait analysis, roadmap display
- [ ] **Strava Connect** - OAuth flow (if configured)
- [ ] **Profile** - View/edit user info
- [ ] **History** - View past assessments

### **Success Criteria**
- [ ] App launches without crashes
- [ ] Can create account and login
- [ ] Can complete full assessment
- [ ] Results screen displays correctly
- [ ] Data visible in Supabase dashboard
- [ ] No console errors

---

## 🚨 COMMON ISSUES & SOLUTIONS

### **Issue: "No devices found"**
**Solution:**
```powershell
# Check connected devices
flutter devices

# If physical device:
# - Enable USB debugging on phone
# - Install USB drivers (Windows)
# - Allow USB debugging prompt on phone

# If emulator:
# - Open Android Studio → Device Manager
# - Start an AVD (Android Virtual Device)
# - Wait for boot complete
```

### **Issue: "Build failed"**
**Solution:**
```powershell
# Clean build cache
flutter clean

# Reinstall dependencies
flutter pub get

# Try building again
flutter run
```

### **Issue: "Supabase connection failed"**
**Solution:**
- Check `.env` file exists with correct credentials
- Verify internet connection
- Check Supabase project is not paused
- Verify RLS policies allow access

### **Issue: "App crashes on launch"**
**Solution:**
```powershell
# Check console logs
flutter run --verbose

# Common fixes:
# 1. Check all dependencies installed
# 2. Verify Supabase URL/key correct
# 3. Check for null safety issues
# 4. Rebuild app completely
```

---

## 📱 DEVICE REQUIREMENTS

### **Android**
- **Minimum:** Android 5.0 (API 21)
- **Recommended:** Android 10+ (API 29+)
- **RAM:** 2GB minimum, 4GB recommended
- **Storage:** 100MB for app + data

### **iOS**
- **Minimum:** iOS 11.0
- **Recommended:** iOS 14+
- **Device:** iPhone 6S or newer
- **Storage:** 100MB for app + data

---

## 🎯 QUICK START COMMANDS

### **Windows (PowerShell)**
```powershell
# Navigate to project
cd "E:\Akura Safe Stride\safestride\akura_mobile"

# Check everything ready
flutter doctor

# Get dependencies
flutter pub get

# List devices
flutter devices

# Run app (debug mode)
flutter run

# Build APK (release mode)
flutter build apk --release
```

### **Mac/Linux (Terminal)**
```bash
# Navigate to project
cd /path/to/akura_mobile

# Check setup
flutter doctor

# Get dependencies
flutter pub get

# Run app
flutter run

# Build iOS (Mac only)
flutter build ios --release
```

---

## 📊 TESTING WORKFLOW

```
1. SETUP ENVIRONMENT (5-10 min)
   ↓
   Install Flutter SDK
   Install Android Studio/Xcode
   Connect device or start emulator
   ↓

2. PREPARE PROJECT (2-3 min)
   ↓
   cd to project folder
   flutter pub get
   Verify .env file configured
   ↓

3. RUN APP (1-2 min)
   ↓
   flutter run
   Wait for build and launch
   ↓

4. TEST FEATURES (20-30 min)
   ↓
   Register account
   Complete evaluation form
   Submit assessment
   View results
   Test Strava (if configured)
   ↓

5. VERIFY RESULTS (5 min)
   ↓
   Check Supabase data
   Compare with expected output
   Take screenshots
   ↓

6. REPORT FINDINGS
   ↓
   Document any issues
   Note success/failures
   Suggest improvements
```

**Total Time:** 35-50 minutes

---

## 🎓 TESTING GUIDE REFERENCES

### **Complete Testing Instructions**
📄 **READY_TO_TEST.md** - Full testing guide with sample data

### **Quick References**
📄 **QUICK_START_CHECKLIST.md** - Quick start steps  
📄 **TROUBLESHOOTING_FAQ.md** - Common issues & fixes  

### **Setup Guides**
📄 **WINDOWS_SETUP_GUIDE.md** - Flutter setup on Windows  
📄 **SUPABASE_CONNECTION_GUIDE.md** - Backend configuration  

### **Strava Testing** (If Configured)
📄 **STRAVA_SETUP_GUIDE.md** - OAuth configuration  
📄 **STRAVA_QUICK_REFERENCE.md** - Testing checklist  

---

## ✅ YOUR TESTING SITUATION

**Answer these questions to get started:**

1. **Do you have Flutter SDK installed?**
   - ✅ Yes → Proceed to Option 1
   - ❌ No → Install from https://flutter.dev

2. **Do you have an Android phone?**
   - ✅ Yes → Consider Option 2 (APK)
   - ❌ No → Use emulator (Option 1)

3. **Do you have Android Studio or Xcode?**
   - ✅ Yes → Use emulator (Option 1)
   - ❌ No → Use physical device (Option 2)

4. **Do you prefer testing on device or emulator?**
   - Device → Use Option 2 (APK)
   - Emulator → Use Option 1 (flutter run)

---

## 🚀 RECOMMENDED PATH

**For Windows Users (Your Setup):**

Since you already have:
- ✅ Flutter SDK at `E:\Akura Safe Stride\safestride\akura_mobile`
- ✅ Project dependencies installed (`flutter pub get` ran successfully)

**You should:**

1. **Connect Android Device or Start Emulator** (5 min)
   - Physical: Enable USB debugging, connect via USB
   - Emulator: Open Android Studio → Device Manager → Start AVD

2. **Run App** (2 min)
   ```powershell
   cd "E:\Akura Safe Stride\safestride\akura_mobile"
   flutter run
   ```

3. **Follow Testing Guide** (30 min)
   - Open `docs/READY_TO_TEST.md`
   - Complete all test scenarios
   - Verify results

**Alternative: Build APK for Phone Testing**
```powershell
flutter build apk --release
# APK location: build\app\outputs\flutter-apk\app-release.apk
```

---

## 📞 SUPPORT

**If you encounter issues:**

1. Check `docs/TROUBLESHOOTING_FAQ.md`
2. Run `flutter doctor` to diagnose setup
3. Check console logs for specific errors
4. Verify Supabase credentials configured
5. Ensure internet connection active

**Key Files:**
- `READY_TO_TEST.md` - Main testing guide
- `TROUBLESHOOTING_FAQ.md` - Solutions to common issues
- `WINDOWS_SETUP_GUIDE.md` - Flutter setup help
- `PROJECT_FINAL_STATUS.md` - What's included in project

---

## 🎉 READY TO TEST!

**Your Current Setup:**
- 📁 Project: `E:\Akura Safe Stride\safestride\akura_mobile`
- ✅ Dependencies: Installed
- 🎯 Status: Ready for device connection
- 📱 Next Step: Connect device or start emulator, then run `flutter run`

**Time to Production:**
- Setup: Already complete ✅
- Testing: 30 minutes
- Deployment: Ready after successful tests

**Start Testing Now:** Follow Option 1 above for fastest results! 🚀

---

**Last Updated:** February 4, 2026  
**For:** SafeStride AISRI + Strava Integration v1.0.0
