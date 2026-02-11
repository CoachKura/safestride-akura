# How to Get Developer Key (UPDATED Feb 2026)

## 🚨 CURRENT REALITY
The "Account Settings → Developer Key" option **does not exist** on the Garmin portal anymore.

## ✅ METHOD 1: Use SDK Manager (EASIEST)

The developer key is now generated **by the SDK itself**!

### Steps:
1. **Install Connect IQ SDK** (if not done):
   - Download: https://developer.garmin.com/connect-iq/sdk/
   - Run installer → Install to `C:\Garmin\ConnectIQ`

2. **Run SDK Manager**:
   ```powershell
   & "C:\Garmin\ConnectIQ\bin\connectiq.bat"
   ```
   OR find "Connect IQ SDK Manager" in Start Menu

3. **Generate Key in SDK Manager**:
   - In SDK Manager: **Tools → Generate Developer Key**
   - Sign in with your Garmin account
   - Key automatically saved to: `C:\Garmin\ConnectIQ\developer_key`
   - ✅ Done!

4. **Verify Key Exists**:
   ```powershell
   Test-Path "C:\Garmin\ConnectIQ\developer_key"
   # Should return: True
   ```

## ✅ METHOD 2: Generate via Command Line

Even simpler - use the built-in key generator:

```powershell
cd "C:\Garmin\ConnectIQ\bin"
.\monkeyc.bat --apikey
```

This will:
- Open browser for Garmin login
- Generate developer key automatically
- Save to `C:\Garmin\ConnectIQ\developer_key`

## ✅ METHOD 3: Extract from SDK (No Login Required!)

The SDK might include a default development key:

```powershell
# Check if SDK has a default key
Get-ChildItem "C:\Garmin\ConnectIQ" -Recurse -Filter "developer_key*"
```

## 🎮 BEST OPTION: Test in Simulator First (NO KEY NEEDED)

**You don't need a developer key to test in simulator!**

### Quick Test (15 minutes):

1. **Install SDK** (if not done):
   - https://developer.garmin.com/connect-iq/sdk/
   - Install to `C:\Garmin\ConnectIQ`

2. **Build for Simulator**:
   ```powershell
   cd c:\safestride\garmin_connectiq\AISRIZoneMonitor
   .\Build-Simulator.ps1
   ```

3. **Test It**:
   - Script will offer to launch simulator
   - Select FR 265 device
   - Load AISRIZone.prg
   - Test with simulated heart rate!

4. **See It Work**:
   - ✅ Zones change colors (green → red)
   - ✅ Heart rate displays
   - ✅ Time-in-zone counts
   - ✅ All AISRI zones working!

5. **After Testing, Get Key**:
   - Once you confirm it works in simulator
   - Use Method 1 or 2 above to get key for real watch

## 📝 Why This Approach?

**Simulator First:**
- ✅ No key needed
- ✅ See it working in 15 minutes
- ✅ Validate code before watch deployment
- ✅ Zero risk to your FR 265

**Real Watch Later:**
- Get key using SDK Manager (Method 1)
- Build with `.\Build-And-Deploy.ps1 -DeviceId fr265`
- Deploy to real FR 265
- Use during actual runs!

## 🔧 Troubleshooting

**"Can't find SDK Manager"**:
- Look in: `C:\Garmin\ConnectIQ\bin\connectiq.bat`
- Or reinstall SDK from: https://developer.garmin.com/connect-iq/sdk/

**"monkeyc.bat not found"**:
- SDK not installed correctly
- Reinstall to `C:\Garmin\ConnectIQ`

**"Still can't generate key"**:
- Just use simulator! Test everything there first
- Real watch deployment can wait until you're happy with the app

## 🚀 RECOMMENDED PATH

1. **TODAY**: Test in simulator (no key needed) ← START HERE
2. **After validating**: Get key via SDK Manager (Method 1)
3. **Then**: Deploy to real FR 265 watch
4. **Finally**: Use during real runs and enjoy AISRI zones!

---

**Bottom Line**: Don't let the developer key block you. Test in simulator NOW, get key later!
