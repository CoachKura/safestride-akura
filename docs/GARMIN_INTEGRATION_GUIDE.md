# 🔌 GARMIN API INTEGRATION GUIDE
## AKURA SafeStride × Garmin Connect

**Date**: 2026-02-10  
**Version**: 1.0  
**Status**: Implementation Ready  
**Priority**: High  

---

## 🎯 INTEGRATION OVERVIEW

### What We're Building
- **Garmin Connect OAuth**: Users connect their Garmin accounts
- **Activity Sync**: Import workouts from Garmin Connect
- **Push Workouts**: Send structured workouts to Garmin devices
- **Real-time Data**: Receive live metrics during workouts
- **Training Status**: Sync training load, recovery, VO2 Max

### Why Garmin?
- ✅ 80% Market Share: Most serious runners use Garmin watches
- ✅ Rich Data: Best-in-class metrics (HR, GPS, training effect)
- ✅ Structured Workouts: Native support for complex training plans
- ✅ Offline Sync: Works without phone during run
- ✅ Premium Features: VO2 Max, training status, recovery time

---

## 📋 GARMIN API OPTIONS

### Option 1: Garmin Connect API (OAuth)
**Best For**: Syncing historical activities and pushing workouts

**Features**:
- OAuth 2.0 authentication
- Activity import (FIT files)
- Workout push (structured workouts)
- Training plans sync
- User profile data

**Limitations**:
- No real-time data during workout
- API requires approval from Garmin
- Rate limits apply

### Option 2: Garmin Connect IQ (Watch Apps)
**Best For**: Real-time workout guidance on watch

**Features**:
- Custom watch apps
- Data fields during workout
- Real-time zone alerts
- Offline functionality
- Direct watch integration

**Limitations**:
- Requires separate app development
- Limited to Connect IQ compatible watches
- User must install watch app

## Setup Instructions

### Initial Pairing

#### Step 1: Prepare Your Garmin Device
1. Turn on your Garmin watch
2. Go to **Settings** → **Bluetooth**
3. Select **Pair New Device** or **Add Device**
4. Keep watch nearby (within 10 meters)

#### Step 2: Connect from SafeStride App
1. Open SafeStride app
2. Tap **More Menu (⋮)** → **Garmin Device**
3. Tap **"Scan for Devices"**
4. Wait 10 seconds for scan to complete
5. Select your watch from the list
6. Confirm pairing on both devices

#### Step 3: Verify Connection
- Green "Connected" banner appears
- Battery level displayed
- Device model and firmware shown

### First-Time Sync
After pairing:
1. Tap **"Sync Data"** button
2. App retrieves last 7 days of workouts
3. Historical activities appear in Workout History
4. Takes 30-60 seconds depending on data volume

## Using Garmin Integration

### Starting a Workout from App

#### Method 1: Quick Start
1. Dashboard → AI Workout Card → **"Suggest"**
2. Review AI-suggested workout
3. Tap **"Start Workout"**
4. Select **"Start on Garmin Watch"**
5. Watch begins tracking automatically

#### Method 2: Scheduled Workout
1. View today's workout on Dashboard
2. Tap workout card
3. Select **"Send to Garmin"**
4. Workout appears on watch
5. Start from watch menu

#### Method 3: Manual Start
1. Start workout on Garmin watch
2. App automatically detects activity
3. Real-time data streams to app
4. View live stats on phone

### During Workout

#### Live Data Display
App shows real-time:
```
❤️ Heart Rate: 145 bpm (Zone 3)
⏱️ Duration: 32:15
🏃 Distance: 5.2 km
📊 Pace: 6:12 /km
🔥 Calories: 312 kcal
⛰️ Elevation: +85m
```

#### Controls Available
- **Pause** - Temporarily stop tracking
- **Resume** - Continue workout
- **Lap** - Mark interval/split
- **Stop** - End and save workout

#### Alerts
- **HR Zone Alerts** - Notify when out of target zone
- **Pace Alerts** - Too fast/slow notifications
- **Distance Milestones** - Every 1km, 5km, etc.
- **Hydration Reminders** - Every 20 minutes

### Stopping a Workout

1. **From Watch**:
   - Press Stop button on watch
   - Confirm save
   - Data syncs automatically to app

2. **From App**:
   - Tap **"Stop Workout"** button
   - Watch stops tracking
   - Saves to both devices

### Post-Workout

#### Automatic Actions
- Workout saved to database
- GPS track points stored
- Statistics calculated
- AISRI score updated
- Training phase adjusted if needed

#### View Workout Details
1. Go to **Workout History**
2. Find your workout (marked with 🟢 Garmin badge)
3. Tap to view:
   - Complete GPS route map
   - Heart rate graph
   - Pace/speed chart
   - Elevation profile
   - Split times
   - Zone distribution

## HR Zone Sync

### Push Zones to Watch
Your personalized HR zones (from AISRI system) can be sent to your Garmin:

1. Dashboard → View AISRI widget
2. Tap **"Sync HR Zones to Garmin"**
3. Zones transferred to watch:
   ```
   Zone 1 (AR): 104-125 bpm (50-60%)
   Zone 2 (F): 125-146 bpm (60-70%)
   Zone 3 (EN): 146-167 bpm (70-80%)
   Zone 4 (TH): 167-181 bpm (80-87%)
   Zone 5 (P): 181-198 bpm (87-95%)
   Zone 6 (SP): 198-208 bpm (95-100%)
   ```

### Zone-Based Workouts
When starting AI workouts with target HR:
- Zones automatically set on watch
- Watch beeps if out of zone
- App shows real-time zone compliance

## Sending Workouts to Device

### AI-Generated Plans
1. Create training plan with AI generator
2. Review workouts in calendar
3. Tap any workout
4. Select **"Send to Garmin"**
5. Workout structure transferred:
   - Warm-up phase
   - Work intervals
   - Rest periods
   - Cool-down phase

### Workout Format on Watch
```
Workout: Tempo Run
- Warm-up: 10min easy
- Tempo: 20min @ Zone 4 (167-181 bpm)
- Cool-down: 5min easy
Total: 35 minutes, 8.0 km
```

## Data Sync & History

### Auto-Sync Settings
Configure automatic synchronization:

1. Garmin Device Screen → Settings icon
2. Toggle **"Auto-Sync"**
3. Set sync interval:
   - After every workout
   - Every 6 hours
   - Every 24 hours
   - Manual only

### Manual Sync
1. Open Garmin Device Screen
2. Tap **"Sync Data"** button
3. Choose sync period:
   - Last 24 hours
   - Last 3 days
   - Last 7 days
   - Last 30 days

### Sync Status
Monitor synchronization:
- 🟢 **Synced** - Up to date
- 🟡 **Syncing** - In progress
- 🔴 **Sync Error** - Connection issue
- ⚪ **Not Synced** - Manual sync needed

## Battery Management

### Watch Battery
- App displays real-time battery %
- Low battery alert at 20%
- Estimated time remaining shown
- Sync disabled below 10%

### App Battery Optimization
- Background sync uses minimal power
- GPS only active during workouts
- Bluetooth Low Energy (BLE) protocol
- Smart sync scheduling

## Troubleshooting

### Device Won't Connect
**Problem**: Can't find Garmin watch during scan

**Solutions**:
1. ✅ Check watch is powered on
2. ✅ Enable Bluetooth on phone
3. ✅ Restart both devices
4. ✅ Ensure watch is in pairing mode
5. ✅ Move closer (within 10m)
6. ✅ Remove old pairing and re-pair

### Connection Drops During Workout
**Problem**: Device disconnects mid-workout

**Solutions**:
1. ✅ Keep phone nearby (< 10m)
2. ✅ Avoid interference (metal, crowds)
3. ✅ Check watch battery level
4. ✅ Disable other Bluetooth devices
5. ✅ App continues logging locally

### Sync Fails
**Problem**: Data not syncing to app

**Solutions**:
1. ✅ Check internet connection
2. ✅ Verify Bluetooth connected
3. ✅ Force quit and restart app
4. ✅ Try manual sync
5. ✅ Check storage space on phone
6. ✅ Update app to latest version

### Inaccurate Heart Rate
**Problem**: HR readings seem wrong

**Solutions**:
1. ✅ Tighten watch band (1-2 fingers snug)
2. ✅ Wear watch 1-2cm above wrist bone
3. ✅ Clean watch sensors
4. ✅ Warm up before workout
5. ✅ Update watch firmware
6. ✅ Calibrate HR in settings

### GPS Not Tracking
**Problem**: No GPS data from watch

**Solutions**:
1. ✅ Start outdoors with clear sky view
2. ✅ Wait 30-60 sec for satellite lock
3. ✅ Enable GPS on watch settings
4. ✅ Update GPS ephemeris data (sync)
5. ✅ Check location permissions

## Advanced Features

### Workout Templates
Create custom workout structures:
```dart
{
  "name": "Interval Training",
  "steps": [
    {
      "type": "warmup",
      "duration_minutes": 10,
      "target_zone": "Zone 2"
    },
    {
      "type": "repeat",
      "count": 6,
      "steps": [
        {
          "type": "work",
          "duration_minutes": 2,
          "target_zone": "Zone 5"
        },
        {
          "type": "rest",
          "duration_minutes": 2,
          "target_zone": "Zone 2"
        }
      ]
    },
    {
      "type": "cooldown",
      "duration_minutes": 5,
      "target_zone": "Zone 1"
    }
  ]
}
```

### Live Tracking Share
Enable live location sharing:
1. Settings → Live Tracking
2. Add emergency contacts
3. Start workout
4. Contacts receive tracking link
5. View real-time location on map

### Performance Metrics
Advanced data from Garmin:
- **VO2 Max** - Aerobic capacity estimate
- **Training Load** - 7-day load accumulation
- **Recovery Time** - Hours until full recovery
- **Training Effect** - Aerobic/Anaerobic impact
- **Performance Condition** - Real-time fitness vs baseline

## Technical Implementation

### Architecture
```
SafeStride App ←→ Garmin SDK ←→ Garmin Device
     ↓                              ↓
  Supabase                      Garmin Cloud
```

### Data Flow
1. **Watch Records** → Garmin device sensors
2. **BLE Transfer** → Data streamed via Bluetooth
3. **App Processes** → SafeStride receives & parses
4. **Database Save** → Stored in Supabase
5. **Cloud Sync** → Optional Garmin Connect sync

### SDK Integration
The app uses:
- **Android**: Garmin Connect Mobile SDK
- **iOS**: Garmin Health SDK
- **Protocol**: Bluetooth Low Energy (BLE)
- **Data Format**: FIT (Flexible and Interoperable Data Transfer)

### Database Schema
```sql
garmin_devices:
  - device_id (unique)
  - device_name
  - device_info (model, firmware)
  - last_connected_at
  - sync_settings

gps_activities:
  - device_source: 'garmin'
  - device_id
  - track_points (GPS data)
  - heart_rate_data
  - cadence_data
```

## Privacy & Security

### Data Protection
- ✅ All data encrypted in transit (TLS)
- ✅ Local storage encrypted
- ✅ RLS policies on database
- ✅ User-owned data only

### Permissions Required
- **Bluetooth** - Device connection
- **Location** - GPS tracking
- **Storage** - Workout data caching
- **Internet** - Cloud sync

### What's Shared
- ✅ Workout metrics with your account
- ✅ GPS routes (optional)
- ❌ NOT shared with third parties
- ❌ NOT sold or monetized

## Supported Workout Types

### Running Activities
- Outdoor run
- Treadmill run
- Trail run
- Track run (intervals)

### Cycling Activities
- Road cycling
- Indoor cycling
- Mountain biking

### Other Activities
- Walking
- Hiking
- Swimming (select models)
- Strength training
- Yoga/Stretching

## FAQ

**Q: Can I use multiple Garmin devices?**  
A: Yes, pair multiple watches. Active device shown in app.

**Q: Does this work offline?**  
A: Workouts track offline, sync when connection restored.

**Q: Battery impact on phone?**  
A: Minimal. BLE uses <5% battery per hour during workout.

**Q: Max distance from phone?**  
A: Bluetooth range ~10m. Stays connected up to 30m outdoors.

**Q: Can I export data?**  
A: Yes, export GPX, TCX, or FIT files from Workout History.

**Q: Works with Garmin Connect?**  
A: Yes, workouts sync to both SafeStride and Garmin Connect.

**Q: Real-time data updates?**  
A: Updates every 1-2 seconds during active workout.

## Benefits vs Garmin Connect App

| Feature | SafeStride + Garmin | Garmin Connect |
|---------|---------------------|----------------|
| AISRI Injury Prevention | ✅ | ❌ |
| AI Training Plans | ✅ | Limited |
| Safety Gates | ✅ | ❌ |
| 6-Pillar Analysis | ✅ | ❌ |
| HR Zone Optimization | ✅ | Basic |
| Phase Tracking | ✅ | ❌ |
| Goal-Based Plans | ✅ | Basic |
| Real-time Coaching | ✅ | Limited |

## Get Started

1. **Dashboard** → **More Menu (⋮)** → **Garmin Device**
2. Follow setup wizard
3. Start your first synced workout!

---

**Support**: Need help? Contact support@safestride.com or visit the Help Center in the app.
