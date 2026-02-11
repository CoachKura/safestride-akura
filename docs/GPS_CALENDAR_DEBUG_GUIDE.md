# 🧪 GPS Tracking → Calendar Save - Debug Testing Guide

## 🚨 ISSUE: Workout tracked but not appearing in Calendar

---

## ✅ FIXES APPLIED

1. **Calendar Auto-Refresh**: Set `wantKeepAlive = false` so calendar doesn't cache old data
2. **Manual Refresh Button**: Blue 🔄 icon in app bar (top-right)
3. **Pull-to-Refresh**: Swipe down on calendar to reload
4. **Enhanced Logging**: Detailed console output for debugging
5. **Better Save Confirmation**: Green snackbar + dialog changes

---

## 🧪 STEP-BY-STEP TEST WITH LOGGING

### **Step 1: Hot Reload the App**
```powershell
# In Flutter terminal, press: r
```

### **Step 2: Open VS Code Debug Console**
- View → Debug Console (or Ctrl+Shift+Y)
- This shows all `developer.log()` messages

### **Step 3: Start GPS Tracking**
1. Open app
2. Tap **Tracker** tab (bottom)
3. Tap **Start** button

**Watch Console for:**
```
🗺️ Starting GPS tracking...
📍 Location updates starting...
```

### **Step 4: Walk/Run for 1-2 Minutes**
- Move at least 50-100 meters
- Watch distance increase on screen

### **Step 5: Stop Tracking**
1. Tap **Stop** button (red square)

**Watch Console for:**
```
💾 Saving activity: X.XX km, XXX seconds
✅ Activity saved with ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
✅ Activity xxxxxxx saved with X track points
```

**On Screen:**
- Green snackbar: "Workout saved! (X.XX km)"
- Dialog: "Workout Saved!" with ✅ checkmark

### **Step 6: Close Dialog**
1. Tap **Got It** button
2. See snackbar: "Tap Calendar tab to see workout"

### **Step 7: Go to Calendar Tab**
1. Tap **Calendar** tab (bottom)

**Watch Console for:**
```
📅 Loading calendar workouts for 2026-02-09
🔍 Querying gps_activities for user: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
📅 Date range: 2026-02-01T00:00:00.000Z to 2026-02-28T23:59:59.999Z
✅ GPS activities found: X
  📍 Activity: Running - 1160m on 2026-02-09T...
📊 Loaded X workouts from database
📋 Today: 🏃 Running - 1.16 km (manual)
📅 Organized into X dates
  2026-02-09: 1 workout(s)
```

### **Step 8: Check Calendar Screen**
**Look for:**
- ✅ Today's date has a **green dot**
- ✅ "Quick Access" section shows "TODAY" card
- ✅ Card displays: "🏃 Running - X.XX km (manual)"
- ✅ Shows duration, pace, calories

### **Step 9: Tap Refresh (If Not Visible)**
1. Tap **🔄 Refresh** button (top-right, blue icon)
2. Or **pull down** to refresh

**Watch Console for:**
```
🔄 Manual refresh triggered
📅 Loading calendar workouts...
✅ GPS activities found: X
```

**On Screen:**
- Green snackbar: "✅ Calendar refreshed!"

---

## 🐛 DEBUGGING SCENARIOS

### **Scenario A: "Activity saved with ID" but "GPS activities found: 0"**

**Problem:** Date/time mismatch between save and query

**Check in Console:**
```
💾 Saving activity: ... start_time: 2026-02-09T06:30:00.000Z
📅 Date range: 2026-02-01T00:00:00.000Z to 2026-02-28T23:59:59.999Z
```

**If start_time is OUTSIDE date range:**
- Timezone issue
- Clock mismatch

**Fix:** Check device time settings

---

### **Scenario B: "Error saving activity: ..."**

**Problem:** Database insert failed

**Common Errors:**

**1. "User not logged in"**
```
❌ Cannot save: User not logged in
```
**Solution:** 
- Sign out and sign in again
- Check authentication status

**2. "duplicate key value violates unique constraint"**
```
❌ Error saving activity: duplicate key...
```
**Solution:**
- Platform activity ID collision (rare)
- Try tracking again

**3. "permission denied for table gps_activities"**
```
❌ Error saving activity: permission denied...
```
**Solution:**
- RLS (Row Level Security) policy issue
- Check Supabase RLS policies

---

### **Scenario C: Console shows "GPS activities found: X" but still not visible**

**Problem:** UI not updating after data load

**Check:**
1. Is `_isLoading` stuck on `true`?
2. Is data organized by correct date?

**Console Output:**
```
📅 Organized into X dates
  2026-02-09: 1 workout(s)
```

**If date is different from today:**
- Timezone issue
- Workout saved with wrong date

**Solution:**
- Check `_workoutsByDate` keys
- Verify `DateTime` normalization

---

### **Scenario D: "No GPS activities found" in Console**

**Problem:** Query returns empty result

**Possible Causes:**

**1. Wrong User ID**
```
🔍 Querying gps_activities for user: xxxx (different from saved user)
```
**Solution:** Re-authenticate

**2. Date Range Mismatch**
```
📅 Date range: 2026-02-01... to 2026-02-28...
💾 Saving activity: start_time: 2026-03-01... (WRONG MONTH!)
```
**Solution:** Device clock is wrong

**3. Database Empty**
- Check Supabase Table Editor
- Verify `gps_activities` table has the row

---

## 🔍 MANUAL DATABASE CHECK

### **Check Supabase Directly:**

1. Open Supabase Dashboard: https://supabase.com
2. Select your project
3. Go to **Table Editor** → **gps_activities**
4. Look for row with today's date

**Expected Row:**
| Column | Value |
|--------|-------|
| id | UUID |
| user_id | Your user UUID |
| platform | manual |
| activity_type | Running |
| distance_meters | 1160 (for 1.16 km) |
| duration_seconds | ~800 (for ~14 min) |
| start_time | 2026-02-09T06:XX:XX+00:00 |
| end_time | 2026-02-09T06:XX:XX+00:00 |

**If row EXISTS but not showing in app:**
- RLS policy blocks query
- Date filtering issue
- UI rendering problem

**If row DOES NOT EXIST:**
- Save failed silently
- Check error logs
- Check network connection

---

## 📱 QUICK FIX CHECKLIST

Try these in order:

- [ ] **1. Hot reload app** (`r` in terminal)
- [ ] **2. Tap refresh button** (🔄 in calendar)
- [ ] **3. Pull down to refresh** (swipe down on calendar)
- [ ] **4. Check console logs** (any errors?)
- [ ] **5. Navigate away and back** (Home → Calendar)
- [ ] **6. Check date is correct** (device clock)
- [ ] **7. Sign out and sign in** (re-authenticate)
- [ ] **8. Check Supabase table** (row exists?)
- [ ] **9. Full app restart** (press `q`, then `flutter run`)
- [ ] **10. Check internet connection** (Wi-Fi/mobile data)

---

## 🎯 EXPECTED CONSOLE OUTPUT (SUCCESS)

```
💾 Saving activity: 1.16 km, 843 seconds
✅ Activity saved with ID: abc12345-6789-...
✅ Activity abc12345 saved with 127 track points
📅 Loading calendar workouts for 2026-02-09
🔍 Querying gps_activities for user: def67890-1234-...
📅 Date range: 2026-02-01T00:00:00.000Z to 2026-02-28T23:59:59.999Z
✅ GPS activities found: 1
  📍 Activity: Running - 1160m on 2026-02-09T06:30:15.123Z
📊 Loaded 1 workouts from database
📋 Today: 🏃 Running - 1.16 km (manual)
📋 Tomorrow: None
📋 Yesterday: None
📅 Organized into 1 dates
  2026-02-09: 1 workout(s)
```

---

## ✅ SUCCESS CRITERIA

After completing the test, you should see:

1. ✅ **Console:** "Activity saved with ID: ..."
2. ✅ **Snackbar:** "Workout saved! (X.XX km)"
3. ✅ **Dialog:** "Workout Saved!" with checkmark
4. ✅ **Console:** "GPS activities found: 1"
5. ✅ **Console:** "Today: 🏃 Running - X.XX km (manual)"
6. ✅ **Calendar UI:** Green dot on today's date
7. ✅ **Calendar UI:** "TODAY" card in Quick Access
8. ✅ **Calendar UI:** Workout card shows distance/time/pace

---

## 🚨 IF STILL NOT WORKING

**Copy entire console output and send it to me. Include:**

1. Complete log from "💾 Saving activity" to end
2. Screenshot of Calendar screen
3. Screenshot of Supabase `gps_activities` table (with today's row visible)

**I'll diagnose the exact issue from the logs.**

---

## 📞 QUICK COMMANDS

**Hot Reload:**
```powershell
# Press in Flutter terminal: r
```

**Full Restart:**
```powershell
# Press: q
flutter run
```

**View Console:**
```
VS Code: View → Debug Console (Ctrl+Shift+Y)
```

**Filter Console (search):**
```
Type in Debug Console search: "GPS activities"
Type in Debug Console search: "Saving activity"
Type in Debug Console search: "❌" (find errors)
```

---

**Test NOW with logging enabled! Share the console output with me.** 🔍
