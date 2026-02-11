# ⌚ Manual Garmin Workout Creation Workflow

## 📖 Overview

SafeStride's **Kura Coach** generates personalized training plans based on AISRI methodology. For now, athletes will **manually create workouts** in the Garmin Connect app. Future updates will enable automatic workout push.

---

## 🔄 Complete Workflow

```
Step 1: Complete AISRI Assessment
   ↓
Step 2: Set Goals in SafeStride
   ↓
Step 3: SafeStride Generates 4-Week Plan
   • 28 workouts (7 days × 4 weeks)
   • Zone-based intervals
   • HR targets calculated
   ↓
Step 4: View Daily Workout in SafeStride
   ↓
Step 5: Manually Create in Garmin Connect
   ↓
Step 6: Sync to Garmin Watch
   ↓
Step 7: Complete Workout
   ↓
Step 8: Auto-Upload to Strava
   ↓
Step 9: SafeStride Syncs from Strava
   ↓
Step 10: After 4 Weeks → Auto Adaptation
```

---

## 📱 Step-by-Step Instructions

### **STEP 1: View Today's Workout in SafeStride**

1. Open SafeStride mobile app
2. Navigate to **Training Calendar**
3. Tap on today's date
4. Review workout details:
   - **Zone Name** (e.g., "TH - Threshold")
   - **Total Duration** (e.g., "35 minutes")
   - **Workout Structure**:
     - Warmup: 10 min (AR Zone)
     - Intervals: 8 min work / 3 min rest × 3 repeats (TH Zone)
     - Cooldown: 5 min (AR Zone)
   - **Heart Rate Zones**:
     - AR: 108-120 bpm
     - TH: 144-157 bpm
   - **Pace Targets** (if applicable)

---

### **STEP 2: Create Workout in Garmin Connect App**

#### **A. Open Garmin Connect**
1. Open the **Garmin Connect** app on your phone
2. Tap **More** (bottom right)
3. Select **Training**
4. Tap **Workouts**
5. Tap **Create a Workout** button

#### **B. Set Workout Type**
1. Choose **Run** (or appropriate activity type)
2. Name the workout: Copy from SafeStride (e.g., "Day 8: TH Intervals")

#### **C. Add Warmup**
1. Tap **Add Step**
2. Select **Warmup**
3. Duration: **Distance** (e.g., 1.5 km) or **Time** (e.g., 10 min)
4. Target: **Heart Rate** → Select **Zone 1** (AR: 108-120 bpm)
   - Or manually enter: Min 108, Max 120
5. Tap **Save**

#### **D. Add Interval Set**
1. Tap **Add Step** → Select **Repeat**
2. Set Repeat: **3 times** (or as specified)

##### **Work Interval:**
3. Tap **Add** (inside repeat block)
4. Type: **Active**
5. Duration: **Time** → **8:00** (8 minutes)
6. Target: **Heart Rate** → Select **Zone 4** (TH: 144-157 bpm)
   - Or manually enter: Min 144, Max 157
7. Tap **Save**

##### **Rest Interval:**
8. Tap **Add** (inside repeat block)
9. Type: **Rest**
10. Duration: **Time** → **3:00** (3 minutes)
11. Target: **Heart Rate** → Select **Zone 2** (F: 120-132 bpm)
12. Tap **Save**

13. Tap **Done** to close repeat block

#### **E. Add Cooldown**
1. Tap **Add Step**
2. Select **Cooldown**
3. Duration: **Distance** (e.g., 1 km) or **Time** (e.g., 5 min)
4. Target: **Heart Rate** → Select **Zone 1** (AR: 108-120 bpm)
5. Tap **Save**

#### **F. Save Workout**
1. Review the complete structure
2. Tap **Save** (top right)
3. Workout is now in your library!

---

### **STEP 3: Sync Workout to Watch**

1. Open **Garmin Connect** app
2. Ensure Bluetooth is ON
3. Pull down to **Sync** (syncs workouts to watch)
4. Wait for sync to complete ✅

---

### **STEP 4: Start Workout on Garmin Watch**

#### **On Your Garmin Watch:**
1. Press **Start** button (top right)
2. Select **Run** (or activity type)
3. Scroll down and select **Workouts**
4. Choose today's workout (e.g., "Day 8: TH Intervals")
5. Press **Start** to begin
6. Follow watch prompts:
   - **Warmup**: Watch shows target HR zone, beeps when complete
   - **Work Intervals**: Watch alerts you to go hard, beeps at end
   - **Rest Intervals**: Watch tells you to recover
   - **Cooldown**: Final easy section
7. Press **Stop** when complete
8. **Save** activity

---

### **STEP 5: Auto-Sync to Strava** ✅ (Already Set Up)

1. Your completed workout **automatically uploads** to Strava
2. No action needed (Garmin → Strava sync is automatic)

---

### **STEP 6: SafeStride Retrieves Data from Strava** ✅ (Automatic)

1. SafeStride syncs with Strava every 15 minutes
2. Your workout appears as **Completed** in SafeStride calendar
3. SafeStride records:
   - Actual duration
   - Time in each HR zone
   - Distance covered
   - Average pace
4. You'll be prompted to log **RPE (Rate of Perceived Exertion)**

---

### **STEP 7: Log RPE in SafeStride** (Optional but Recommended)

1. Open SafeStride app
2. Navigate to **Training Calendar**
3. Tap on completed workout (marked ✅)
4. Tap **Log Performance**
5. Enter:
   - **RPE**: 1-10 scale (how hard it felt)
   - **Notes**: How you felt, any issues, etc.
6. Tap **Save**

---

### **STEP 8: Repeat Daily!** 🔄

- Each day, repeat Steps 1-7
- SafeStride tracks your progress
- After 4 weeks, Kura Coach analyzes and adapts your plan

---

## 🎯 Training Zones Reference

### **Heart Rate Zones** (Example for 30-year-old, Max HR = 190 bpm)

| Zone | Name | % Max HR | HR Range (bpm) | Purpose |
|------|------|----------|----------------|---------|
| **AR** | Active Recovery | 50-60% | 95-114 | Easy recovery runs |
| **F** | Foundation | 60-70% | 114-133 | Build aerobic base |
| **EN** | Endurance | 70-80% | 133-152 | Long steady runs |
| **TH** | Threshold | 80-87% | 152-165 | Lactate threshold training |
| **P** | Performance | 87-95% | 165-180 | VO2 max intervals |
| **SP** | Speed | 95-100% | 180-190 | Sprint training |

> **Note**: Your zones are calculated based on your age and displayed in SafeStride.

---

## 🚀 Quick Tips

### **✅ DO:**
- Copy workout names exactly from SafeStride
- Double-check HR zone numbers before saving
- Sync your watch **before** heading out
- Log RPE after every workout
- Review your plan for the week on Sunday

### **❌ DON'T:**
- Skip warmup or cooldown
- Ignore HR zone targets (watch will beep if too high/low)
- Forget to sync watch after workout
- Skip logging RPE (helps adaptation)

---

## 🛠️ Troubleshooting

### **"I can't find my workout on my watch"**
- **Solution**: Pull down in Garmin Connect app to sync. Wait 30 seconds, try again.

### **"My watch isn't detecting HR zones correctly"**
- **Solution**: Ensure watch has your correct Max HR. Go to Settings → User Profile → Heart Rate → Max HR.

### **"Workout didn't upload to Strava"**
- **Solution**: 
  1. Check Garmin → Strava connection in Strava settings
  2. Manually sync: Garmin Connect → Activity → Share → Strava

### **"SafeStride doesn't show my completed workout"**
- **Solution**:
  1. Wait 15 minutes for auto-sync
  2. Or manually: SafeStride → Profile → Sync Strava Now

---

## 📊 Example Workout

### **SafeStride Plan: Day 8 - Threshold Intervals**

```
Duration: 35 minutes
Zone: TH (Threshold)

Structure:
├─ Warmup: 10 min (AR Zone: 108-120 bpm)
├─ Repeat 3×
│  ├─ Work: 8 min (TH Zone: 144-157 bpm)
│  └─ Rest: 3 min (F Zone: 120-132 bpm)
└─ Cooldown: 5 min (AR Zone: 108-120 bpm)

Total: 10 + (8+3)×3 + 5 = 48 minutes
```

### **Garmin Connect Equivalent:**

```
Workout Name: Day 8: TH Intervals

Steps:
1. Warmup - 10:00 min - HR Zone 1 (108-120 bpm)
2. Repeat 3×
   a. Active - 8:00 min - HR Zone 4 (144-157 bpm)
   b. Rest - 3:00 min - HR Zone 2 (120-132 bpm)
3. Cooldown - 5:00 min - HR Zone 1 (108-120 bpm)
```

---

## 🔮 Future: Automated Workout Push

**Coming Soon!**
- SafeStride → Garmin Connect IQ App
- Automatic workout push to watch
- No manual entry needed
- One-click start workouts

**Until then**: Manual creation ensures you understand your training! 💪

---

## ❓ Questions?

Contact your coach or check the SafeStride Help Center.

**Happy Training! 🏃‍♂️💨**
