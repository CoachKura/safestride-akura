# Garmin WiFi Connectivity Guide

## Overview
SafeStride now supports **WiFi connectivity** for Garmin devices in addition to traditional Bluetooth. WiFi offers several advantages including extended range, faster data transfer, and more stable connections indoors.

## Benefits of WiFi Connection

### ✅ **Advantages**
- 🏠 **Extended Range** - Connect from anywhere in your home (up to 50m vs Bluetooth's 10m)
- ⚡ **Faster Sync** - Transfer workout data 5-10x faster than Bluetooth
- 📶 **Stable Indoors** - Less interference from walls and obstacles
- 🔋 **Battery Efficient** - WiFi uses less battery for large data transfers
- 🔄 **Background Sync** - Continue syncing even when phone screen is off
- 💪 **Reliable Connection** - Less prone to dropouts during workouts

### 📊 **Connection Comparison**

| Feature | Bluetooth | WiFi | Both |
|---------|-----------|------|------|
| **Range** | ~10 meters | ~50 meters | Best of both |
| **Speed** | 1-2 Mbps | 10-50 Mbps | Fastest available |
| **Battery Impact** | Low | Very Low | Optimized |
| **Indoor Stability** | Moderate | Excellent | Excellent |
| **Setup Complexity** | Easy | Moderate | Moderate |
| **Best For** | Quick workouts | Long syncs | All scenarios |

## Supported Devices

### WiFi-Enabled Garmin Watches
- ✅ Forerunner 245 Music, 645 Music, 745, 945, 955, 965
- ✅ Fenix 5 Plus/6/7 series
- ✅ Vivoactive 3 Music, 4, 4S
- ✅ Venu, Venu 2, Venu 2 Plus, Venu 3
- ✅ Epix Gen 2
- ⚠️ **Note**: Base models (non-Music/non-Plus) may not support WiFi

## Setup Guide

### Prerequisites
1. ✅ Garmin watch with WiFi capability
2. ✅ Both phone and watch connected to **same WiFi network**
3. ✅ WiFi router with 2.4GHz or 5GHz band
4. ✅ SafeStride app updated to latest version

---

## Step-by-Step Setup

### Part 1: Configure WiFi on Garmin Watch

#### **Step 1: Access WiFi Settings**
1. On your Garmin watch, press and hold **MENU** button
2. Navigate to **Settings** → **Connectivity** → **Wi-Fi**
3. Select **My Networks**

#### **Step 2: Add WiFi Network**
1. Select **Add Network**
2. Choose your home WiFi network from the list
3. Enter WiFi password using watch interface
   - Use touchscreen or buttons to select characters
   - Most watches support on-screen keyboard
4. Select **Done** when password entered

#### **Step 3: Verify Connection**
1. Watch will display **"Connected"** when successful
2. WiFi icon (📶) appears on watch face
3. Check signal strength (should show 3-4 bars)

**Troubleshooting WiFi Setup:**
- If network not found: Move closer to router, ensure 2.4GHz band enabled
- If password fails: Re-check password, ensure correct case sensitivity
- If connection drops: Restart watch and router

---

### Part 2: Connect via SafeStride App

#### **Step 1: Open Garmin Device Screen**
1. Launch SafeStride app
2. Tap **More Menu (⋮)** → **Garmin Device**
3. You'll see the connection screen

#### **Step 2: Select Connection Type**
You have 3 options:
- **WiFi** - Connect only via WiFi (recommended for home use)
- **Bluetooth** - Traditional Bluetooth connection
- **Both** - Scan for devices on both WiFi and Bluetooth

**Choose based on your situation:**
- 🏠 **At Home** → Select **WiFi** for best range and speed
- 🏃 **Outdoor Activity** → Select **Bluetooth** for proximity
- 🤷 **Not Sure** → Select **Both** to find all available methods

#### **Step 3: Scan for Devices**
1. Tap **"Scan for Devices"** button
2. App will search for 10 seconds
3. Watch will appear in device list with:
   - Device name (e.g., "Fenix 7")
   - Connection type icon (📶 WiFi or Bluetooth)
   - IP address (if WiFi)
   - Signal strength

#### **Step 4: Connect to Watch**
1. Tap on your watch from the list
2. App connects using selected method
3. **Success!** Green "Connected" banner appears
4. Device info displayed: model, firmware, battery

---

### Part 3: Verify WiFi Connection

#### **Check Connection Status**
Once connected, you'll see:
```
✅ Connected
Device: Garmin Fenix 7
Connection: WiFi (192.168.1.25)
Battery: 85%
Signal: Strong
```

#### **Test Data Sync**
1. Tap **"Sync Data"** button
2. App retrieves last 7 days of workouts
3. Sync should complete in 15-30 seconds (faster than Bluetooth)
4. Check **Workout History** to see synced activities

---

## WiFi Network Requirements

### Recommended Router Settings
```
Network Type: 2.4GHz or 5GHz (2.4GHz preferred for range)
Security: WPA2-PSK (most compatible)
Channel: Auto or 1/6/11 (less interference)
Bandwidth: 20MHz or 40MHz
DHCP: Enabled (for automatic IP assignment)
Firewall: Allow local network device discovery
```

### Port Requirements
SafeStride communicates with Garmin watches on:
- **HTTP**: Port 80 (device discovery)
- **HTTPS**: Port 443 (secure data transfer)
- **Garmin Protocol**: Port 8080 (custom Garmin sync)

**Firewall Configuration:**
If using custom firewall, allow outbound connections to:
- `*.garmin.com`
- Local network subnet (e.g., `192.168.1.0/24`)

---

## Using WiFi Connection

### Automatic Reconnection
Once configured, watch automatically reconnects to WiFi when:
- ✅ You return home (in WiFi range)
- ✅ App is opened
- ✅ Scheduled sync time (if auto-sync enabled)

**No manual reconnection needed!**

### Auto-Sync Settings
Configure automatic workout synchronization:

1. **Garmin Device Screen** → Tap Settings icon ⚙️
2. Toggle **"Auto-Sync"** ON
3. Choose sync frequency:
   - After every workout (recommended)
   - Every 6 hours
   - Every 24 hours
   - Manual only

**WiFi Auto-Sync Benefits:**
- 🏠 Syncs when you arrive home
- 🔋 No battery drain (watch charges while syncing)
- 📊 Data always up-to-date
- 🤖 Completely automatic

### Manual Sync
To manually sync:
1. Open **Garmin Device Screen**
2. Ensure watch is connected (green banner)
3. Tap **"Sync Data"** button
4. Choose sync period (1-30 days)
5. Wait for completion

**WiFi Sync Speed:**
- 7 days of data: ~20 seconds
- 30 days of data: ~1 minute
- Full history sync: ~3-5 minutes

---

## Advanced Features

### Dual Connection Mode
Use **"Both"** connection type for maximum flexibility:

**How it works:**
1. App scans WiFi and Bluetooth simultaneously
2. Connects via WiFi if available (priority)
3. Falls back to Bluetooth if WiFi unavailable
4. Seamlessly switches between connections

**Use cases:**
- 🏠 → 🏃 **Home to Outdoor**: Start workout at home (WiFi), continue outdoors (Bluetooth)
- 🏃 → 🏠 **Outdoor to Home**: Track run (Bluetooth), auto-sync when home (WiFi)
- 📶 **Poor WiFi Signal**: Automatically switches to Bluetooth

### Connection Preferences
Set preferred connection in app settings:
```
Settings → Garmin Integration → Connection Preferences
  ├─ Prefer WiFi when available ✓
  ├─ Fallback to Bluetooth ✓
  ├─ Auto-switch on signal loss ✓
  └─ WiFi-only mode (disable Bluetooth fallback)
```

### Live Tracking via WiFi
During workouts, WiFi offers enhanced live tracking:

**Advantages:**
- 📍 Real-time location updates (1-second interval vs 5-second on Bluetooth)
- ❤️ Continuous heart rate streaming
- 📊 Live workout metrics (pace, distance, cadence)
- 🚨 Instant emergency alerts

**Setup:**
1. Start workout from app
2. Select **"Send to Garmin"**
3. Enable **"Live Tracking"**
4. Choose WiFi as tracking method
5. Start workout on watch

---

## Troubleshooting

### WiFi Connection Issues

#### **Problem: Watch not found during WiFi scan**

**Solutions:**
1. ✅ **Same Network Check**
   - Verify phone and watch on same WiFi
   - Check WiFi SSID name matches
   - Disable mobile data on phone temporarily

2. ✅ **Signal Strength**
   - Move closer to WiFi router
   - Check watch shows 3-4 WiFi bars
   - Test other devices can connect

3. ✅ **Network Discovery**
   - Enable "Allow device discovery" in router settings
   - Disable AP isolation if enabled
   - Check router firewall allows local device scanning

4. ✅ **Watch WiFi Reset**
   - On watch: Settings → Connectivity → Wi-Fi → Forget Network
   - Re-add network with password
   - Wait 30 seconds for connection

#### **Problem: Connection repeatedly drops**

**Solutions:**
1. ✅ **Router Optimization**
   - Switch to 2.4GHz band (better range than 5GHz)
   - Change WiFi channel (try channel 1, 6, or 11)
   - Update router firmware
   - Reduce number of connected devices

2. ✅ **Watch Settings**
   - Disable Bluetooth while using WiFi (reduces interference)
   - Update watch firmware (Settings → System → Software Update)
   - Reset network settings on watch

3. ✅ **App Settings**
   - Disable battery saver mode on phone
   - Allow SafeStride to run in background
   - Grant location permission (required for WiFi scanning)

#### **Problem: Slow sync speed via WiFi**

**Solutions:**
1. ✅ **Network Congestion**
   - Pause other downloads on network
   - Move watch closer to router
   - Check router not overloaded (too many devices)

2. ✅ **Watch Memory**
   - Clear old activities on watch (Settings → System → Storage)
   - Free up space (delete unused apps)
   - Sync smaller time periods (7 days instead of 30)

3. ✅ **App Cache**
   - Clear SafeStride app cache (Settings → Storage)
   - Restart app
   - Re-sync activities

#### **Problem: "Invalid IP address" error**

**Solutions:**
1. ✅ **DHCP Configuration**
   - Enable DHCP on router
   - Restart watch to get new IP
   - Check router DHCP pool not exhausted

2. ✅ **Static IP (Advanced)**
   - On watch: Settings → Connectivity → Wi-Fi → Advanced
   - Set static IP in router's subnet (e.g., 192.168.1.100)
   - Set gateway to router IP (e.g., 192.168.1.1)
   - Set DNS to 8.8.8.8 or router IP

---

## Security & Privacy

### WiFi Security
SafeStride uses encrypted connections:
- ✅ **TLS 1.3** encryption for data transfer
- ✅ **WPA2-PSK** WiFi security (minimum)
- ✅ **Certificate pinning** for Garmin API
- ✅ **No plain-text credentials** stored

### Network Isolation
For enhanced security:
1. Create **guest network** for IoT devices
2. Connect Garmin watch to guest network
3. Isolate from main network (optional)

### Data Privacy
- ✅ Workout data stays local until you sync
- ✅ No third-party sharing
- ✅ Your WiFi password **never** leaves the watch
- ✅ SafeStride doesn't access router settings

---

## Best Practices

### For Home Use
1. ✅ **Connect watch to WiFi** when you arrive home
2. ✅ **Enable auto-sync** (syncs workouts automatically)
3. ✅ **Place watch on charger** near router (syncs while charging)
4. ✅ **Use WiFi connection type** in app for faster speeds

### For Workouts
1. ✅ **Use Bluetooth** for outdoor activities (better proximity)
2. ✅ **Switch to WiFi** when returning home
3. ✅ **Let dual mode** handle switching automatically
4. ✅ **Sync before** long runs (get latest training plans)

### For Data Management
1. ✅ **Daily sync** (keeps data fresh)
2. ✅ **Weekly full sync** (includes older activities)
3. ✅ **Clear watch memory** monthly (prevents slowdowns)
4. ✅ **Backup workouts** regularly (export from app)

---

## FAQ

**Q: Does WiFi drain watch battery faster than Bluetooth?**  
A: No, WiFi actually uses **less battery** for large data transfers. Bluetooth is more efficient for small, frequent updates.

**Q: Can I use WiFi while outdoor running?**  
A: Only if you're within range of your WiFi network (up to 50m). For outdoor activities beyond WiFi range, Bluetooth is recommended.

**Q: Do I need to reconnect every time?**  
A: No! Once configured, watch automatically connects when in range. App remembers your device.

**Q: Can multiple devices connect to same watch?**  
A: Yes, but only one app can control workout at a time. Sync works with multiple devices.

**Q: What if my WiFi password changes?**  
A: Update password on watch: Settings → Connectivity → Wi-Fi → [Network] → Edit Password

**Q: Does this work with mobile hotspot?**  
A: Yes! Connect watch to phone's hotspot. However, this uses mobile data for syncing.

**Q: Can I sync without internet connection?**  
A: No. Workout data syncs to Supabase cloud. Local storage coming in future update.

**Q: Which is better: WiFi or Bluetooth?**  
A: **WiFi for home**, **Bluetooth for outdoor**, **Both for flexibility**. Choose based on location and range needs.

**Q: Does this work with 5GHz WiFi?**  
A: Most newer Garmin watches support 5GHz. Older models (pre-2020) may only support 2.4GHz. Check watch specs.

**Q: Can I disable Bluetooth and use WiFi only?**  
A: Yes! Select "WiFi" connection type in app. Useful to reduce interference or when Bluetooth unavailable.

---

## Technical Details

### Network Protocols Used
- **mDNS/Bonjour** - Device discovery on local network
- **HTTP/HTTPS** - Data transfer with Garmin watch
- **WebSocket** - Real-time workout data streaming
- **REST API** - Garmin Connect API integration

### WiFi Specifications
```
Supported Standards: 802.11 b/g/n/ac (device dependent)
Frequency Bands: 2.4GHz (all devices), 5GHz (2020+ models)
Security: WPA2-PSK, WPA3 (2022+ models)
Range: Up to 50 meters (clear line of sight)
Speed: 10-50 Mbps (actual speed varies)
```

### Connection Flow
```
1. App broadcasts mDNS discovery packet
2. Watch responds with device info + IP address
3. App establishes TCP connection to watch
4. TLS handshake (encrypted connection)
5. Authenticate with Garmin OAuth token
6. Sync workout data via HTTPS
7. Keep-alive packets maintain connection
```

---

## Support

### Get Help
- 📧 **Email**: support@safestride.com
- 💬 **Chat**: In-app support (Settings → Help)
- 📖 **Docs**: https://docs.safestride.com/garmin-wifi

### Report Issues
If WiFi connection isn't working:
1. Screenshot error message
2. Note watch model and firmware version
3. Check router model and settings
4. Submit via app: Settings → Help → Report Problem

---

**Happy syncing! 🏃‍♂️📶**
