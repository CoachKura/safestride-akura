# 🚀 QUICK START GUIDE - AISRI Zone Monitor

## ⚡ Super Fast Setup (30 Minutes)

### Step 1: Install SDK (10 min)
```powershell
# Download from: https://developer.garmin.com/connect-iq/sdk/
# Run: connectiq-sdk-manager-windows.exe
# Install to: C:\Garmin\ConnectIQ
```

### Step 2: Get Developer Key (5 min)
```powershell
# 1. Register at: https://developer.garmin.com/
# 2. Download developer_key
# 3. Save to: C:\Garmin\ConnectIQ\developer_key
```

### Step 3: Build App (5 min)
```powershell
cd c:\safestride\garmin_connectiq\AISRIZoneMonitor

# Build for your watch (example: Forerunner 955)
& "C:\Garmin\ConnectIQ\bin\monkeyc.exe" `
  -f monkey.jungle `
  -o AISRIZone.prg `
  -y C:\Garmin\ConnectIQ\developer_key `
  -d fr955

# For other watches, replace 'fr955' with supported device ID:

# Forerunner Series (Most Popular):
# fr965, fr265, fr255, fr955, fr945, fr745, fr645, fr245, fr165

# Fenix Series (Premium Multi-Sport):
# fenix7, fenix7s, fenix7x, fenix6, fenix6s, fenix6x, fenix5, fenix5s, fenix5x

# Epix Series (AMOLED Display):
# epix2, epix2pro42, epix2pro47, epix2pro51

# Venu Series (Lifestyle + Fitness):
# venu2, venu2s, venu2plus, venu, venusq, venusqm

# Vivoactive Series (All-Day Fitness):
# vivoactive4, vivoactive4s, vivoactive3

# Other Models:
# enduro, enduro2, marq-athlete, marq-adventurer
```

### Step 4: Copy to Watch (5 min)
```powershell
# Connect watch via USB
# Wait for drive to appear (e.g., E:\GARMIN)

# Copy app to watch
Copy-Item "AISRIZone.prg" -Destination "E:\GARMIN\APPS\"

# Safely eject watch
```

### Step 5: Test on Watch (5 min)
1. Disconnect USB
2. On watch: Start a Run activity
3. Press UP (Menu) → Activity Settings → Data Screens
4. Edit a screen → Add Field → Select "AISRI Zone"
5. Start run and watch zone update! 🎉

---

## 📱 Using AISRI Zone Monitor

### What You'll See:
```
┌──────────────┐
│  THRESHOLD   │ ← Zone name (color-coded)
│              │
│     162      │ ← Current heart rate
│     bpm      │
│              │
│   02:34      │ ← Time in this zone
└──────────────┘
```

### Zone Colors:
- 🟢 **GREEN** = Recovery (50-60% max HR)
- 🔵 **DARK BLUE** = Foundation (60-70%)
- 🔷 **BLUE** = Endurance (70-80%)
- 🟡 **YELLOW** = Threshold (80-87%)
- 🟠 **ORANGE** = Peak (87-95%)
- 🔴 **RED** = Sprint (95-100%)

### Training Tips:
- **Recovery runs**: Stay in GREEN zone
- **Easy runs**: DARK BLUE or BLUE zone
- **Tempo runs**: YELLOW (Threshold) zone
- **Intervals**: ORANGE (Peak) or RED (Sprint) zone

---

## 🐛 Troubleshooting

### Build fails?
```powershell
# Check SDK installed
Test-Path "C:\Garmin\ConnectIQ\bin\monkeyc.exe"

# Check developer key exists
Test-Path "C:\Garmin\ConnectIQ\developer_key"
```

### Watch doesn't show app?
1. Verify file copied to `GARMIN\APPS\` folder
2. Check file name: `AISRIZone.prg`
3. Disconnect USB properly (don't just unplug!)
4. Restart watch if needed

### App crashes?
1. Test in simulator first
2. Check watch model matches build (`-d fr955` etc.)
3. Update watch firmware
4. Rebuild for your specific watch model

---

## 📤 Submit to Connect IQ Store

Once tested and working:

1. **Prepare assets**:
   - App icon (60x60 PNG)
   - Screenshots (3+)
   - Description text

2. **Submit**:
   - Go to: https://apps.garmin.com/en-US/developer/
   - Click "Add New App"
   - Upload `AISRIZone.prg`
   - Fill in description
   - Submit for review

3. **Wait for approval**: 1-2 weeks

---

## ✅ Pre-Release Testing Checklist

Before submitting to Connect IQ Store, verify:

### Functionality Tests:
- [ ] Zone calculation matches AISRI percentages
- [ ] Heart rate updates smoothly (1-2 second refresh)
- [ ] Zone changes reflected immediately
- [ ] Timer resets correctly on zone change
- [ ] All 6 zones display with correct colors
- [ ] Works across different activities (Run, Bike, Swim)

### Device Tests:
- [ ] Tested on primary target device (e.g., FR955)
- [ ] Tested on at least 2 other device families
- [ ] Text readable in daylight
- [ ] Colors visible on AMOLED and MIP displays
- [ ] Memory usage under 15KB
- [ ] Battery impact < 2% per hour

### Edge Cases:
- [ ] Handles missing HR sensor gracefully
- [ ] Works with chest strap HR monitors
- [ ] Works with optical HR sensor
- [ ] Handles max HR = 0 (shows default zones)
- [ ] Handles HR = 0 (shows "---")
- [ ] Activity pause/resume maintains state

### Performance Metrics:
```
Target Specifications:
- Memory Usage: < 15KB
- CPU Usage: < 5% average
- Update Frequency: Every 1-2 seconds
- Battery Impact: < 2% per hour of activity
- Load Time: < 0.5 seconds
```

---

## 📦 Connect IQ Store Release Process

### Phase 1: Preparation (2-3 days)
1. **Final code review**:
   - Remove debug logs
   - Optimize memory usage
   - Test on 3+ devices
   
2. **Create store assets**:
   - App icon: 60x60 PNG (transparent background)
   - Screenshots: 3-5 images showing different zones
   - Feature graphic: 1024x500 PNG
   - Description: 500-4000 characters

3. **Version information**:
   - Version number: `1.0.0`
   - Min SDK version: `4.0.0`
   - Supported devices: List all tested models

### Phase 2: Submission (1 day)
1. **Login to developer portal**: https://apps.garmin.com/developer/
2. **Create new app**:
   - Select "Data Field" type
   - Enter "AISRI Zone Monitor" as name
   - Upload compiled `.prg` file
   
3. **Fill in details**:
   - Category: Health & Fitness
   - Description: Mention AISRI methodology
   - Keywords: "heart rate, training zones, AISRI, running"
   - Support email: Your contact

4. **Upload assets**:
   - App icon (required)
   - Screenshots (3 minimum)
   - Feature graphic (optional but recommended)

5. **Set pricing**: Free (recommended for v1.0)

6. **Submit for review**

### Phase 3: Review & Approval (1-2 weeks)
- Garmin reviews app functionality
- Tests on their device fleet
- Checks for policy violations
- May request changes

### Phase 4: Launch (1 day)
- App appears in Connect IQ Store
- Share on social media
- Announce in SafeStride app
- Monitor reviews and ratings

---

## 🎯 Next Steps

After your data field works:

1. **Share with SafeStride users** in app
2. **Collect feedback** from beta testers
3. **Iterate and improve** based on feedback
4. **Market on**:
   - r/running
   - r/Garmin
   - Strava groups
   - Running clubs

---

## 📞 Need Help?

- **Full guide**: See `SETUP_GUIDE.md`
- **Source code**: `source/AISRIZoneView.mc`
- **Garmin forums**: https://forums.garmin.com/developer/

**Let's ship this! 🚀⌚**
