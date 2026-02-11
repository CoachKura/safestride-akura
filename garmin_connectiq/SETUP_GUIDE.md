# 🎯 GARMIN CONNECT IQ - COMPLETE SETUP GUIDE
## Building AISRI Zone Monitor Data Field

**Date**: 2026-02-10  
**Platform**: Windows  
**Target**: AISRI Zone Monitor Data Field  
**Timeline**: 2-4 hours setup + 1-2 days development  

---

## 📋 PREREQUISITES

### What You Need:
- ✅ Windows PC (you have this)
- ✅ Internet connection
- ✅ Garmin watch (Forerunner/Fenix/Vivoactive series)
- ✅ Garmin Connect account (free)
- ✅ USB cable to connect watch to PC
- ⏳ Visual Studio Code (recommended, or any text editor)

### Skills Required:
- Basic programming knowledge (Java/C-style syntax)
- Familiarity with terminal/command line
- No prior Monkey C experience needed!

---

## 🚀 STEP 1: INSTALL CONNECT IQ SDK

### Option A: Automatic Installation (Recommended)

#### 1.1 Download Connect IQ SDK Manager

1. **Open browser** and go to:
   ```
   https://developer.garmin.com/connect-iq/sdk/
   ```

2. **Click "Download SDK Manager"** button

3. **Choose Windows version**:
   - Download: `connectiq-sdk-manager-windows.exe`
   - Save to: `C:\Users\[YourUsername]\Downloads\`

4. **Run the installer**:
   ```powershell
   # Navigate to Downloads folder
   cd $env:USERPROFILE\Downloads
   
   # Run installer
   .\connectiq-sdk-manager-windows.exe
   ```

5. **Follow installation wizard**:
   - Accept license agreement
   - Choose installation path: `C:\Garmin\ConnectIQ`
   - Click "Install"
   - Wait 5-10 minutes for download

#### 1.2 Verify Installation

```powershell
# Check if SDK is installed
Test-Path "C:\Garmin\ConnectIQ\bin\monkeyc.exe"
# Should return: True

# Add to PATH (if not already)
$env:PATH += ";C:\Garmin\ConnectIQ\bin"
```

### Option B: Manual Installation (Alternative)

If SDK Manager doesn't work, download ZIP directly:

1. Go to: https://developer.garmin.com/connect-iq/sdk/
2. Scroll to "Manual Download"
3. Download: `connectiq-sdk-win-[version].zip`
4. Extract to: `C:\Garmin\ConnectIQ`
5. Add `C:\Garmin\ConnectIQ\bin` to Windows PATH

---

## 🔧 STEP 2: INSTALL VS CODE EXTENSION

### 2.1 Install Visual Studio Code (if not installed)

```powershell
# Download VS Code
# Go to: https://code.visualstudio.com/
# Or use winget:
winget install Microsoft.VisualStudioCode
```

### 2.2 Install Monkey C Extension

1. **Open VS Code**
2. **Press**: `Ctrl+Shift+X` (Extensions)
3. **Search**: "Monkey C"
4. **Install**: "Monkey C" by Garmin
5. **Restart** VS Code

### 2.3 Configure Extension

1. **Open Settings**: `Ctrl+,`
2. **Search**: "Monkey C"
3. **Set SDK Path**: `C:\Garmin\ConnectIQ`
4. **Set Simulator Path**: `C:\Garmin\ConnectIQ\bin\simulator.exe`

---

## 📱 STEP 3: REGISTER GARMIN DEVELOPER ACCOUNT

### 3.1 Create Developer Account

1. **Go to**: https://developer.garmin.com/
2. **Click**: "Register" (top right)
3. **Fill in details**:
   - Email
   - Password
   - Name
   - Accept Terms
4. **Verify email** (check inbox)
5. **Wait 5-10 minutes** for account activation

### 3.2 Request Developer Key

1. **Log in** to developer portal
2. **Go to**: https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/
3. **Click**: "Generate Developer Key"
4. **Save the key file**: 
   - Download: `developer_key`
   - Save to: `C:\Garmin\ConnectIQ\developer_key`

**Important**: You MUST have this key to build apps!

---

## 🎨 STEP 4: CREATE AISRI ZONE MONITOR PROJECT

### 4.1 Create Project Structure

```powershell
# Create project directory
cd c:\safestride
mkdir garmin_connectiq\AISRIZoneMonitor
cd garmin_connectiq\AISRIZoneMonitor

# Create directory structure
mkdir source
mkdir resources
mkdir resources\drawables
mkdir resources\strings
```

### 4.2 Create manifest.xml

```powershell
# Create manifest file
New-Item -Path "manifest.xml" -ItemType File
```

Copy this content into `manifest.xml`:

```xml
<?xml version="1.0"?>
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application 
        entry="AISRIZoneApp" 
        id="YOUR_APP_ID_HERE"
        launcherIcon="@Drawables.LauncherIcon" 
        minApiLevel="3.2.0" 
        name="@Strings.AppName" 
        type="datafield" 
        version="1.0.0">
        
        <!-- Supported Devices -->
        <iq:products>
            <!-- Forerunner Series -->
            <iq:product id="fenix7"/>
            <iq:product id="fenix7s"/>
            <iq:product id="fenix7x"/>
            <iq:product id="fenix6"/>
            <iq:product id="fenix6pro"/>
            <iq:product id="fenix6s"/>
            <iq:product id="fenix6xpro"/>
            <iq:product id="fr955"/>
            <iq:product id="fr965"/>
            <iq:product id="fr265"/>
            <iq:product id="fr265s"/>
            <iq:product id="fr255"/>
            <iq:product id="fr255s"/>
            <iq:product id="fr255m"/>
            <iq:product id="fr945"/>
            <iq:product id="fr745"/>
            <iq:product id="fr645"/>
            <iq:product id="fr645m"/>
            <iq:product id="fr245"/>
            <iq:product id="fr245m"/>
            <iq:product id="vivoactive4"/>
            <iq:product id="vivoactive4s"/>
            <iq:product id="venu"/>
            <iq:product id="venu2"/>
            <iq:product id="venu2plus"/>
            <iq:product id="venu2s"/>
            <iq:product id="epix2"/>
        </iq:products>
        
        <!-- Permissions -->
        <iq:permissions>
            <iq:uses-permission id="Sensor"/>
            <iq:uses-permission id="SensorHistory"/>
        </iq:permissions>
        
        <!-- Languages -->
        <iq:languages>
            <iq:language>eng</iq:language>
        </iq:languages>
    </iq:application>
</iq:manifest>
```

**Note**: Replace `YOUR_APP_ID_HERE` with a unique ID (we'll generate this later when submitting to store).

### 4.3 Create monkey.jungle (Build Configuration)

```powershell
New-Item -Path "monkey.jungle" -ItemType File
```

Copy this content:

```
project.manifest = manifest.xml

base.sourcePath = source
base.resourcePath = resources
```

### 4.4 Create strings.xml (App Name)

```powershell
New-Item -Path "resources\strings\strings.xml" -ItemType File
```

Copy this content:

```xml
<strings>
    <string id="AppName">AISRI Zone</string>
</strings>
```

---

## 💻 STEP 5: IMPLEMENT AISRI ZONE MONITOR CODE

### 5.1 Create Main View File

```powershell
New-Item -Path "source\AISRIZoneView.mc" -ItemType File
```

Now I'll create the complete implementation code in the next file...

---

## 🧪 STEP 6: BUILD AND TEST

### 6.1 Build in VS Code

1. **Open project**: `code .` (in AISRIZoneMonitor folder)
2. **Open**: `source\AISRIZoneView.mc`
3. **Press**: `Ctrl+Shift+B` (Build)
4. **Select**: "Build for Device"
5. **Choose Device**: (e.g., fenix7, fr955)
6. **Wait for build**: Should see "Build Successful"

### 6.2 Run in Simulator

```powershell
# Launch simulator
& "C:\Garmin\ConnectIQ\bin\simulator.exe"

# From VS Code:
# Press F5 (Run and Debug)
# Choose device from dropdown
```

### 6.3 Test in Simulator

1. **Choose activity**: Running
2. **Start activity**: Click play button
3. **Add data field**: 
   - Click "Activity Settings"
   - Click "Data Screens"
   - Click "+ Add Field"
   - Select "AISRI Zone"
4. **Watch it work**: HR changes → zone updates

---

## 📱 STEP 7: TEST ON REAL GARMIN WATCH

### 7.1 Connect Watch to PC

1. **Plug in USB cable**: Watch → PC
2. **Watch shows**: "USB Mode" or "Mass Storage"
3. **Windows shows**: New drive (e.g., `E:\GARMIN`)

### 7.2 Build for Your Watch

```powershell
# In project folder
cd c:\safestride\garmin_connectiq\AISRIZoneMonitor

# Build for specific device (example: Forerunner 955)
& "C:\Garmin\ConnectIQ\bin\monkeyc.exe" `
  -f monkey.jungle `
  -o AISRIZone.prg `
  -y C:\Garmin\ConnectIQ\developer_key `
  -d fr955

# Check output
dir *.prg
# Should see: AISRIZone.prg
```

### 7.3 Copy to Watch

```powershell
# Find watch drive letter (example: E:)
$watchDrive = "E:"

# Create app folder if not exists
mkdir "$watchDrive\GARMIN\APPS" -ErrorAction SilentlyContinue

# Copy app to watch
Copy-Item "AISRIZone.prg" -Destination "$watchDrive\GARMIN\APPS\"

# Safely eject watch
# Windows: Right-click drive → Eject
```

### 7.4 Test on Watch

1. **Disconnect USB**
2. **On watch**: Go to activity (e.g., Run)
3. **Press**: Up button (Menu)
4. **Select**: "Activity Settings"
5. **Select**: "Data Screens"
6. **Edit screen**: Press Select
7. **Add field**: Scroll to find "AISRI Zone"
8. **Start run**: Press Start
9. **Watch zone update**: As HR changes, zone name/color changes

---

## 📤 STEP 8: SUBMIT TO CONNECT IQ STORE

### 8.1 Prepare Assets

Create the following files in `resources\drawables\`:

**App Icon (launcher_icon.png)**:
- Size: 60x60 pixels
- Format: PNG with transparency
- Design: AISRI logo or "AZ" text with zone colors

**Screenshots** (take from simulator or real watch):
- Screenshot 1: Shows "RECOVERY" zone (green)
- Screenshot 2: Shows "THRESHOLD" zone (orange)
- Screenshot 3: Shows "PEAK" zone (red)
- Size: Device native resolution
- Format: PNG

### 8.2 Create Store Listing

**Prepare this information**:

```
App Name: AISRI Zone Monitor

Short Description (80 chars):
Real-time heart rate zone guidance for injury-free training

Long Description (4000 chars):
AISRI Zone Monitor displays your current training zone in real-time based on the AISRI (Athletic Injury and Safety Risk Index) training methodology.

✅ 6 Training Zones:
• RECOVERY (50-60% max HR) - Green
• FOUNDATION (60-70%) - Dark Blue  
• ENDURANCE (70-80%) - Blue
• THRESHOLD (80-87%) - Yellow/Orange
• PEAK (87-95%) - Orange/Red
• SPRINT (95-100%) - Red

🎯 Features:
• Real-time zone calculation from heart rate
• Color-coded display for quick recognition
• Time-in-zone counter
• Automatic max HR calculation based on age
• Works offline (no phone needed)
• Battery efficient

📱 Compatible Devices:
Forerunner 955/965, 255/265, 745/945, 245/645
Fenix 7/6 series
Vivoactive 4
Venu 2/3
Epix Gen 2

🏃 How to Use:
1. Add AISRI Zone to your data screen
2. Start your run
3. Watch your current zone in real-time
4. Stay in your target zone for optimal training

💡 Based on science-backed AISRI methodology for injury prevention and optimal performance.

Keywords: heart rate, training zones, AISRI, running, injury prevention, zone training, HR zones
```

### 8.3 Submit to Store

1. **Go to**: https://apps.garmin.com/en-US/developer/
2. **Log in** with developer account
3. **Click**: "Add New App"
4. **Fill in form**:
   - **App Type**: Data Field
   - **App Name**: AISRI Zone Monitor
   - **Short Description**: (copy from above)
   - **Long Description**: (copy from above)
   - **Category**: Health & Fitness
   - **Price**: Free (or $0.99-$2.99)
   - **App Icon**: Upload launcher_icon.png
   - **Screenshots**: Upload 3 screenshots
5. **Upload APK**:
   - Build production version: `AISRIZone.prg`
   - Upload this file
6. **Submit for Review**:
   - Click "Submit for Approval"
   - Wait 1-2 weeks for Garmin review
7. **Publication**:
   - Garmin emails when approved
   - App goes live in Connect IQ Store

---

## 🐛 TROUBLESHOOTING

### Issue: SDK Won't Install
**Solution**:
```powershell
# Check Windows version (need Win 10/11)
winver

# Run as Administrator
Right-click installer → "Run as Administrator"

# Try manual ZIP download instead
```

### Issue: "Developer Key Not Found"
**Solution**:
```powershell
# Download developer key from:
# https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/

# Save to correct path
Copy-Item "developer_key" -Destination "C:\Garmin\ConnectIQ\developer_key"
```

### Issue: Build Fails with Errors
**Solution**:
```powershell
# Clean build
Remove-Item "bin" -Recurse -Force -ErrorAction SilentlyContinue

# Rebuild
& "C:\Garmin\ConnectIQ\bin\monkeyc.exe" -f monkey.jungle -o bin\app.prg -y C:\Garmin\ConnectIQ\developer_key
```

### Issue: Watch Doesn't Show App
**Solution**:
1. Check USB connection is solid
2. Verify watch is in Mass Storage mode
3. Check file copied to `GARMIN\APPS\` folder
4. Disconnect USB properly (don't just unplug)
5. Restart watch: Hold Power 10 seconds → Restart

### Issue: App Crashes on Watch
**Solution**:
1. Check simulator first - if it works there, issue is device-specific
2. View crash logs: Connect watch → Check `GARMIN\DEBUG\` folder
3. Common issues:
   - Memory limit exceeded (data fields have 32KB limit)
   - Unsupported API on older devices
   - Null pointer exceptions

---

## 📚 ADDITIONAL RESOURCES

### Official Documentation:
- **SDK Guide**: https://developer.garmin.com/connect-iq/connect-iq-basics/
- **API Reference**: https://developer.garmin.com/connect-iq/api-docs/
- **Sample Apps**: https://github.com/garmin/connectiq-samples

### Community Support:
- **Forums**: https://forums.garmin.com/developer/
- **Stack Overflow**: Tag `garmin-connect-iq`
- **Reddit**: r/Garmin

### Learning Resources:
- **Monkey C Tutorial**: https://developer.garmin.com/connect-iq/monkey-c/
- **YouTube**: Search "Garmin Connect IQ tutorial"
- **Sample Projects**: Explore Connect IQ store for open-source examples

---

## ✅ CHECKLIST

### Setup Phase:
- [ ] Downloaded Connect IQ SDK
- [ ] Installed VS Code + Monkey C extension
- [ ] Created Garmin Developer account
- [ ] Downloaded developer key
- [ ] Verified SDK installation

### Development Phase:
- [ ] Created project structure
- [ ] Implemented manifest.xml
- [ ] Wrote AISRIZoneView.mc code
- [ ] Built successfully in VS Code
- [ ] Tested in simulator

### Testing Phase:
- [ ] Connected Garmin watch to PC
- [ ] Built .prg file for specific device
- [ ] Copied to watch
- [ ] Tested during actual run
- [ ] Verified zone changes with HR

### Publishing Phase:
- [ ] Created app icon (60x60 PNG)
- [ ] Captured 3 screenshots
- [ ] Prepared store description
- [ ] Submitted to Connect IQ Store
- [ ] Waited for approval (1-2 weeks)

---

## 🎯 NEXT STEPS

After completing this guide:

1. **Complete code implementation** (see next file)
2. **Test thoroughly** on your Garmin watch
3. **Gather beta feedback** from other runners
4. **Submit to store** and wait for approval
5. **Market your data field**:
   - Post on r/running, r/Garmin
   - Share on Strava
   - Add to SafeStride app documentation

---

**Estimated Time**: 4-6 hours for complete setup and first build  
**Difficulty**: Intermediate (but this guide makes it easy!)  
**Support**: If stuck, ask in Garmin Developer Forums  

**Let's build your first Connect IQ app! 🚀⌚**
