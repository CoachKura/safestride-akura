# 🏃 GPS Workout Tracking Test Guide

## ✅ What You're Testing:
1. Start live GPS tracking
2. Record a workout with map route
3. Save the activity
4. See it appear in your calendar

---

## 📱 **TEST STEPS:**

### **Step 1: Open GPS Tracker**
1. Open SafeStride app
2. Tap **"Tracker"** tab at the bottom (🗺️ icon)
3. Grant location permissions if prompted
4. Wait for map to load and show your current location

### **Step 2: Select Workout Type** (Optional)
1. At top of screen, see "Today's Scheduled Workouts"
2. If you have a planned workout, tap to select it
3. Or proceed without selecting (will save as "Running")

### **Step 3: Start Tracking**
1. Tap the big **"Start"** button (green play icon)
2. Watch the timer start: `00:00:00`
3. See the map tracking your route (blue line)
4. Watch metrics update in real-time:
   - **Distance** (km)
   - **Duration** (time)
   - **Pace** (min/km)
   - **Avg Speed** (km/h)
   - **Calories** (kcal)

### **Step 4: During Tracking** (Walk/Run for 2-3 minutes)
- ✅ Blue line draws your path on the map
- ✅ Distance increases
- ✅ Timer counts up
- ✅ Pace/speed updates continuously

**TIP:** Walk in different directions to see the path clearly

### **Step 5: Pause (Optional)**
1. Tap **"Pause"** button (⏸️)
2. Timer stops
3. Metrics freeze
4. Tap **"Resume"** to continue

### **Step 6: Stop & Save**
1. Tap **"Stop"** button (⏹️ red square)
2. Dialog appears: **"Workout Complete!"**
3. Review your stats:
   - Total distance
   - Total time
   - Average pace
   - Calories burned
4. Tap **"Save Activity"**
5. See success message: ✅ **"Activity saved!"**

### **Step 7: Verify in Calendar**
1. Tap **"Calendar"** tab at bottom (📅 icon)
2. Find today's date on the calendar
3. **YOU SHOULD SEE:**
   - A green dot on today's date
   - A workout card showing your tracked activity
   - Activity name: 🏃 **Running - X.XX km (manual)**
4. Tap the workout card to see full details:
   - Distance
   - Duration
   - Pace
   - Calories
   - Heart rate (if available)
   - Cadence (if available)

---

## 🧪 **EXPECTED RESULTS:**

### ✅ **During Tracking:**
- Map shows your current location (blue marker)
- Route draws as blue line behind you
- Distance increases as you move
- Timer counts up continuously
- Pace updates (slower when stopped, faster when moving)

### ✅ **After Saving:**
- Success message appears
- Activity saved to database
- **Calendar tab shows the workout** on today's date
- Workout card displays all metrics

### ✅ **Calendar Display:**
```
📅 Calendar Tab
Today (Feb 9, 2026) has green indicator

Card shows:
┌─────────────────────────────┐
│ 🏃 Running - 2.43 km        │
│    (manual)                 │
│                             │
│ ⏱️ 15 min • 🔥 120 kcal    │
│ 📊 Pace: 6:10 min/km       │
│ ❤️ HR: 145 bpm (if tracked) │
└─────────────────────────────┘
```

---

## ⚠️ **IMPORTANT NOTES:**

### **TWO Different Calendars:**

1. **Calendar Tab** (Bottom Navigation)
   - Shows ALL workouts
   - ✅ GPS tracked activities (saved here)
   - ✅ Strava synced activities
   - ✅ Planned workouts from athlete_calendar

2. **Kura Coach Calendar** (More Menu → Kura Coach Calendar)
   - Shows ONLY AI-generated workout plans
   - ❌ Does NOT show GPS tracked workouts
   - This is for planned training, not completed activities

### **Where Data is Saved:**
```
GPS Tracker
    ↓ (saves to)
gps_activities table
    ↓ (appears in)
Calendar Tab (shows all activities)
```

---

## 🐛 **TROUBLESHOOTING:**

### **Issue: Location not updating**
**Fix:**
- Check Bluetooth/GPS is enabled on phone
- Grant location permissions (Settings → Apps → SafeStride)
- Go outside or near a window for better GPS signal

### **Issue: Map not loading**
**Fix:**
- Check internet connection (map tiles need data)
- Wait 10-15 seconds for initial load
- Restart the app

### **Issue: Workout doesn't appear in calendar**
**Fix:**
- Make sure you tapped "Save Activity" (not just Stop)
- Check you're looking at the **Calendar Tab**, not Kura Coach Calendar
- Tap today's date on calendar to refresh
- Look for green dot on today's date

### **Issue: Distance not tracking**
**Fix:**
- Actually move/walk (GPS tracks location changes)
- If testing indoors, GPS accuracy is poor - go outside
- Move at least 10-20 meters to see distance change

---

## 📊 **DATABASE CHECK (Optional):**

After saving, you can verify in Supabase:

1. Open Supabase dashboard
2. Go to **Table Editor** → **gps_activities**
3. Filter by today's date
4. You should see your activity row with:
   - `user_id`: Your user ID
   - `platform`: "manual"
   - `activity_type`: "Running"
   - `distance_meters`: Your distance × 1000
   - `duration_seconds`: Your time in seconds
   - `start_time`: When you started
   - `end_time`: When you stopped

---

## ✅ **SUCCESS CHECKLIST:**

- [ ] GPS Tracker screen loads with map
- [ ] Current location appears (blue marker)
- [ ] Start button works
- [ ] Timer starts counting
- [ ] Blue route line draws on map as you move
- [ ] Distance increases as you walk/run
- [ ] Pause button works
- [ ] Resume button works
- [ ] Stop button shows completion dialog
- [ ] "Save Activity" button saves successfully
- [ ] **Calendar tab shows the workout on today's date**
- [ ] Workout card shows correct distance/time/pace
- [ ] Can tap workout card to see full details

---

## 🎯 **AFTER SUCCESSFUL TEST:**

Reply with:
- ✅ **"GPS tracking works!"**
- Distance you tracked (e.g., "2.5 km")
- Whether it appeared in Calendar tab

---

## 📝 **WHAT THIS PROVES:**

1. ✅ GPS location tracking works
2. ✅ Route mapping works (blue line on map)
3. ✅ Metrics calculation works (distance, pace, calories)
4. ✅ Data saves to `gps_activities` table
5. ✅ Calendar service queries and displays GPS activities
6. ✅ Complete workout → calendar flow works end-to-end

---

**Ready to test? Go to Tracker tab and start tracking! 🚀**
