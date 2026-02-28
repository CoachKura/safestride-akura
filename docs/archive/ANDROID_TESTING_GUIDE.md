# 📱 ANDROID MOBILE APP TESTING GUIDE

## ✅ Current Status

Your Flutter app is **ready to test** with:

- ✅ Assessment images configured in `pubspec.yaml`
- ✅ Evaluation form screen: `lib/screens/evaluation_form_screen.dart`
- ✅ All 18 images in: `assets/images/assessments/`
- ✅ Supabase integration working
- ✅ Strava OAuth ready

---

## 🚀 Quick Test on Android (5 Minutes)

### **Method 1: Test on Physical Device**

```powershell
# 1. Connect your Android phone via USB
# 2. Enable USB debugging on your phone:
#    Settings → About Phone → Tap "Build Number" 7 times
#    Settings → Developer Options → Enable USB Debugging

# 3. Verify device is connected
flutter devices

# Expected output:
# SM-G998B (mobile) • 1234567890ABCDEF • android-arm64 • Android 13 (API 33)

# 4. Run the app
flutter run -d <device-id>

# Or simply (if only one device):
flutter run
```

### **Method 2: Test on Android Emulator**

```powershell
# 1. Launch Android Studio emulator first
# Or create one if you don't have:
flutter emulators --launch <emulator-id>

# 2. Check emulator is running
flutter devices

# Expected output:
# sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33)

# 3. Run the app
flutter run
```

---

## 🧪 What to Test: Evaluation Form Flow

### **Test Sequence:**

#### **1. Launch App → Sign Up**

```
1. Open app
2. Click "Don't have an account? Sign up"
3. Fill:
   - Name: Test Athlete
   - Email: test@example.com
   - Password: test123456
   - Role: Athlete
4. Click "Create Account"
```

**✅ Expected:** Redirected to Evaluation Form

---

#### **2. Step 1: Personal Information**

```
Fill basic details:
- Age: 30
- Gender: Male
- Weight: 70 kg
- Height: 175 cm
```

**✅ Check:** Text fields accepting input, no crashes

---

#### **3. Step 2-5: Background Questions**

```
Answer training, injury, recovery, and performance questions
```

**✅ Check:** Sliders, dropdowns, and date pickers working

---

#### **4. Step 6: Physical Assessments (15 Tests) ⭐**

**THIS IS THE KEY TEST - Assessment Images!**

Check each test displays its image:

**Lower Body Tests (6):**

1. ✅ Ankle Dorsiflexion → Shows `Proper Ankle Dorsiflexion Test.png`
2. ✅ Knee Flexion → Shows `Knee Flexion (Heel-to-Buttock) Test.png`
3. ✅ Hip Flexion → Shows `Hip Flexion ROM Test.png`
4. ✅ Hip Abduction → Shows `Hip Abduction Strength Test.png`
5. ✅ Hamstring Flexibility → Shows `Hamstring Flexibility (Sit-and-Reach).png`
6. ✅ Single-Leg Squat → Shows `Single-Leg Squat Depth.png`

**Balance & Core Tests (2):** 7. ✅ Balance Test → Shows `balance test instructional diagram.png` 8. ✅ Plank Hold → Shows `Plank Hold Test.png`

**Upper Body Tests (4):** 9. ✅ Shoulder Flexion → Shows `Shoulder Flexion ROM.png` 10. ✅ Shoulder Abduction → Shows `Shoulder Abduction ROM Test.png` 11. ✅ Shoulder Rotation → Shows `Shoulder Internal Rotation (Scratch Test).png` 12. ✅ Neck Rotation → Shows `Neck Rotation ROM.png`

**Recovery Tests (2):** 13. ✅ Fatigue Level → Shows `Fatigue Scale Visual.png` 14. ✅ Heart Rate → Shows `Heart Rate Check.png`

**📸 What to Look For:**

- Images load correctly (not broken/missing)
- Images are clear and readable
- Instructions text visible below each image
- Input fields work for measurements

---

#### **5. Step 7: Goals**

```
Set:
- Target Race: Half Marathon
- Date: 90 days from today
- Goal: PR time
```

---

#### **6. Submit & View Results**

```
Click "Complete Assessment"
```

**✅ Expected:**

1. Loading spinner appears
2. Success message: "Assessment completed successfully! 🎉"
3. Redirected to Results Screen showing:
   - AISRI Score (0-100)
   - 6 Pillar Breakdown
   - Risk Category
   - Training Recommendations

---

## 🐛 Common Issues & Fixes

### **Issue 1: Images Not Loading**

```
Error: Unable to load asset: assets/images/assessments/...
```

**Fix:**

```powershell
# 1. Verify images exist
ls assets\images\assessments\

# 2. Clean and rebuild
flutter clean
flutter pub get
flutter build apk

# 3. Hot restart (not hot reload)
# In running app: Press R (capital R)
```

---

### **Issue 2: Supabase Connection Error**

```
Error: Invalid API Key or URL
```

**Fix:**

```powershell
# 1. Check .env file exists
cat .env

# Expected content:
# SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
# SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 2. If missing, create .env file
notepad .env

# 3. Rebuild
flutter clean
flutter run
```

---

### **Issue 3: Build Fails**

```
Error: Gradle build failed
```

**Fix:**

```powershell
# 1. Clean project
flutter clean

# 2. Update dependencies
flutter pub get

# 3. Upgrade Flutter
flutter upgrade

# 4. Check Android SDK
flutter doctor -v

# 5. If all fails, invalidate Android Studio cache:
# Android Studio → File → Invalidate Caches → Invalidate and Restart
```

---

## 📊 Test Checklist

Copy and check off as you test:

### **Pre-Flight**

- [ ] Flutter version: `flutter --version` (should be ≥3.5.0)
- [ ] Android device connected or emulator running
- [ ] USB debugging enabled (for physical device)
- [ ] App builds without errors: `flutter build apk`

### **Registration Flow**

- [ ] Sign up form submits successfully
- [ ] Email validation works
- [ ] Password requirements met
- [ ] Redirects to evaluation form after signup

### **Evaluation Form - Step 1-5**

- [ ] All text fields accept input
- [ ] Sliders move smoothly
- [ ] Dropdowns show options
- [ ] Date picker works
- [ ] "Next" button advances to next step

### **Evaluation Form - Step 6 (Images) ⭐**

- [ ] All 15 test images load correctly
- [ ] Images are clear and visible
- [ ] Instructions text readable
- [ ] Measurement input fields work
- [ ] Scrolling works smoothly
- [ ] No crashes or freezes

### **Results Screen**

- [ ] AISRI score displays (0-100)
- [ ] 6 pillar scores show
- [ ] Risk category visible
- [ ] Chart/graph renders
- [ ] Can navigate to other screens

### **Strava Integration (Optional)**

- [ ] "Connect Strava" button visible
- [ ] OAuth flow works
- [ ] Activities sync
- [ ] Profile updates with Strava data

---

## 📱 Expected App Screenshots

When testing, you should see screens like this:

### **Screen 1: Evaluation Form - Personal Info**

```
┌─────────────────────────────────────┐
│  Athlete Assessment            [1/7] │
├─────────────────────────────────────┤
│                                     │
│  Age: [___30____] years             │
│                                     │
│  Gender: ⚪ Male ⚫ Female          │
│                                     │
│  Weight: [___70____] kg             │
│                                     │
│  Height: [___175___] cm             │
│                                     │
│         [Next: Training →]          │
└─────────────────────────────────────┘
```

### **Screen 6: Physical Assessment with Image**

```
┌─────────────────────────────────────┐
│  Physical Tests                [6/7] │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ [IMAGE: Ankle Dorsiflexion]   │ │
│  │ Person lunging toward wall    │ │
│  │ with foot measurements        │ │
│  └───────────────────────────────┘ │
│                                     │
│  Ankle Dorsiflexion Test            │
│  ───────────────────────────────    │
│  Instructions:                      │
│  1. Face wall, foot perpendicular   │
│  2. Lunge forward, knee touches     │
│  3. Heel stays flat on ground       │
│  4. Measure toe-to-wall distance    │
│                                     │
│  Distance: [___12____] cm           │
│  Normal: 10+ cm per foot            │
│                                     │
│         [← Back]  [Next →]          │
└─────────────────────────────────────┘
```

### **Screen 7: Results with AISRI Score**

```
┌─────────────────────────────────────┐
│  Your AISRI Report                  │
├─────────────────────────────────────┤
│                                     │
│       ┌─────────────────┐           │
│       │    AISRI SCORE  │           │
│       │       76        │           │
│       │     /100        │           │
│       └─────────────────┘           │
│                                     │
│  Risk Category: Moderate Risk       │
│                                     │
│  6 Pillar Breakdown:                │
│  🏃 Running:     75/100 ▓▓▓▓▓▓▓░░░  │
│  💪 Strength:    80/100 ▓▓▓▓▓▓▓▓░░  │
│  🤸 ROM:         70/100 ▓▓▓▓▓▓▓░░░  │
│  ⚖️ Balance:     65/100 ▓▓▓▓▓▓░░░░  │
│  📐 Alignment:   78/100 ▓▓▓▓▓▓▓▓░░  │
│  🔄 Mobility:    82/100 ▓▓▓▓▓▓▓▓░░  │
│                                     │
│  [View Full Report]                 │
│  [Generate Training Plan]           │
└─────────────────────────────────────┘
```

---

## 🔥 Advanced Testing

### **Test 1: Strava Integration**

```powershell
# After completing evaluation:
1. Click "Connect Strava" on dashboard
2. Login to Strava account
3. Grant permissions
4. Return to app
5. Check activities imported

Expected: Running pillar score should update from 50 → 75+ if you have active Strava data
```

### **Test 2: Re-Assessment**

```powershell
# Test that users can retake assessment:
1. Complete evaluation once
2. Navigate to Settings/Profile
3. Click "Retake Assessment"
4. Fill form again with different values
5. Submit

Expected: New record created, latest score shown in profile
```

### **Test 3: Offline Mode**

```powershell
# Test app works without internet:
1. Complete evaluation with WiFi/Data ON
2. View results (should work)
3. Turn OFF WiFi/Data
4. Try to view cached results
5. Turn ON WiFi/Data
6. App should sync changes

Expected: Graceful handling of offline state
```

---

## 🚀 Quick Test Script (PowerShell)

Run this for automated testing helper:

```powershell
# Save as: test-android-app.ps1

Write-Host "🏃 SafeStride Android App Test Helper" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# 1. Check Flutter
Write-Host "1️⃣  Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter not found. Install from: https://flutter.dev" -ForegroundColor Red
    exit 1
}

# 2. Check devices
Write-Host "`n2️⃣  Checking connected devices..." -ForegroundColor Yellow
$devices = flutter devices
Write-Host $devices

if ($devices -match "No devices detected") {
    Write-Host "❌ No Android device/emulator found" -ForegroundColor Red
    Write-Host "   Connect device or start emulator" -ForegroundColor Gray
    exit 1
}

# 3. Check assets
Write-Host "`n3️⃣  Verifying assessment images..." -ForegroundColor Yellow
$imageCount = (Get-ChildItem "assets\images\assessments\*.png").Count
Write-Host "   Found $imageCount images" -ForegroundColor Green

if ($imageCount -lt 18) {
    Write-Host "⚠️  Expected 18 images, found $imageCount" -ForegroundColor Yellow
}

# 4. Check .env
Write-Host "`n4️⃣  Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "   ✅ .env file exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ .env file missing!" -ForegroundColor Red
    exit 1
}

# 5. Clean build
Write-Host "`n5️⃣  Cleaning previous build..." -ForegroundColor Yellow
flutter clean | Out-Null
flutter pub get | Out-Null
Write-Host "   ✅ Build cleaned" -ForegroundColor Green

# 6. Run app
Write-Host "`n6️⃣  Launching app on Android..." -ForegroundColor Yellow
Write-Host "   Starting Flutter in debug mode...`n" -ForegroundColor Gray
flutter run

# Test checklist reminder
Write-Host "`n🧪 TESTING CHECKLIST:" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "1. Sign up as new athlete" -ForegroundColor White
Write-Host "2. Complete evaluation form (7 steps)" -ForegroundColor White
Write-Host "3. ⭐ CHECK: All 15 test images load!" -ForegroundColor Yellow
Write-Host "4. Submit assessment" -ForegroundColor White
Write-Host "5. View AISRI score and results" -ForegroundColor White
Write-Host "6. (Optional) Connect Strava" -ForegroundColor White
```

---

## 🎯 Testing Priority Order

### **Phase 1: Basic Functionality (5 minutes)**

1. ✅ App launches without crashing
2. ✅ Sign up flow works
3. ✅ Evaluation form navigates through steps
4. ✅ Can submit assessment

### **Phase 2: Image Verification (10 minutes)** ⭐

5. ✅ ALL 15 test images load correctly
6. ✅ Images are clear and helpful
7. ✅ No broken image icons
8. ✅ Instructions match images

### **Phase 3: Data Integration (5 minutes)**

9. ✅ Assessment saves to Supabase
10. ✅ AISRI score calculates correctly
11. ✅ Results screen displays properly
12. ✅ Can navigate to dashboard

### **Phase 4: Advanced Features (Optional)**

13. ✅ Strava OAuth works
14. ✅ Activities sync and update pillars
15. ✅ Training plan generates
16. ✅ Can retake assessment

---

## 📞 Need Help?

### **If images don't load:**

```powershell
# Verify images are in correct location:
ls assets\images\assessments\

# Should show 18 .png files

# If images are missing, check they're named correctly:
# - "Proper Ankle Dorsiflexion Test.png" (with spaces)
# - Not "proper-ankle-dorsiflexion-test.png" (lowercase with dashes)
```

### **If app crashes on evaluation form:**

```dart
// Check evaluation_form_screen.dart line ~1260-1280
// Make sure Image.asset paths match actual file names exactly (case-sensitive!)

// Example:
Image.asset(
  'assets/images/assessments/Proper Ankle Dorsiflexion Test.png',
  errorBuilder: (context, error, stackTrace) {
    print('Failed to load image: $error'); // Check debug console
    return Icon(Icons.image_not_supported);
  },
)
```

### **If Supabase errors:**

```powershell
# Test connection:
curl https://bdisppaxbvygsspcuymb.supabase.co/rest/v1/

# Should return: {"message":"Not Found"}
# (This is normal - means Supabase is reachable)
```

---

## ✅ Success Criteria

Your Android app test is successful when:

1. ✅ **App installs and launches** on Android device/emulator
2. ✅ **Sign up flow completes** without errors
3. ✅ **All 15 assessment images display** correctly in evaluation form
4. ✅ **Assessment submits** and saves to Supabase
5. ✅ **AISRI score displays** on results screen
6. ✅ **6-pillar breakdown** shows correct values
7. ✅ **No crashes** throughout entire flow

**Bonus:**

- ✅ Strava OAuth connects and imports activities
- ✅ Training plan generates based on AISRI score
- ✅ Dashboard shows athlete profile with all data

---

## 🚀 Ready to Test?

Run this single command to start:

```powershell
flutter run
```

Then follow the testing checklist above!

**Good luck! Your SafeStride mobile app with visual assessment guides is ready to test! 🏃‍♂️📱**
