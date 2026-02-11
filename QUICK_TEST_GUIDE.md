# 🧪 Quick Test Guide - All 3 Features

## Prerequisites
✅ Database migration deployed successfully  
✅ App compiled with no errors (`flutter analyze` passed)  
✅ Android device connected

---

## 🎯 Test Scenario 1: Body Measurements

### Steps:
1. **Launch app** → Login
2. **Dashboard** → Scroll to "Quick Access"
3. **Tap "Body Tracking"** (purple card with weight icon)
4. **Verify**: Empty state shows "No measurements yet"
5. **Tap "+ Add First Measurement"** button
6. **Enter**:
   - Weight: `75.5` kg
   - Height: `175` cm
   - Date: Today
7. **Tap "Add"**
8. **Verify**: 
   - ✅ Measurement appears in list
   - ✅ BMI calculated automatically (~24.7)
   - ✅ BMI category badge shows "Normal" (green)
   - ✅ Progress summary card NOT shown (need 2+ measurements)

### Test 2nd Measurement:
9. **Tap "+"** FAB (bottom right)
10. **Enter**: Weight `74.0` kg, Height `175` cm, Date: 1 week ago
11. **Tap "Add"**
12. **Verify**:
    - ✅ Progress summary appears at top
    - ✅ Shows "Weight Change: -1.5 kg"
    - ✅ Timeline sorted by date (newest first)

---

## 🎯 Test Scenario 2: Injury Tracking

### Steps:
1. **Dashboard** → **Tap "Injuries Log"** (red card)
2. **Verify**: Empty state shows "No active injuries"
3. **Tap "+"** FAB
4. **Fill form**:
   - Injury Name: `Plantar Fasciitis`
   - Affected Area: `Left Foot`
   - Injury Type: `Chronic`
   - Status: `Active`
   - Severity: Slide to `7/10`
   - Current Pain: Slide to `5/10`
   - Recovery: Slide to `30%`
   - Injury Date: `2 weeks ago`
   - Expected Recovery: `6 weeks from now`
   - Caused By: `Increased mileage too quickly`
   - Treatment: `Rest, ice, stretching exercises`
5. **Tap "SAVE"**
6. **Verify**:
   - ✅ Injury appears in list
   - ✅ Red status dot (active)
   - ✅ Severity badge shows "Moderate" (orange)
   - ✅ Progress bar at 30%
   - ✅ "Injured 14 days ago" counter
   - ✅ Summary card at top shows "1 Active Injury"

### Test Edit:
7. **Tap injury card** → Opens detail screen
8. **Update Recovery** to `50%`
9. **Tap "SAVE"**
10. **Verify**: Progress bar updated to 50%

### Test Filter:
11. **Tap history icon** (top right)
12. **Verify**: Shows "Show All" toggle
13. Add another injury with Status: `Healed`
14. Toggle filter to see active vs all

---

## 🎯 Test Scenario 3: Goals

### Steps:
1. **Dashboard** → **Tap "Goals Dashboard"** (amber card)
2. **Verify**: Empty state shows "No active goals"
3. **Tap "+"** FAB
4. **Create Goal**:
   - Title: `Run First 5K`
   - Type: `Complete Distance`
   - Target: `5.0` km
   - Target Date: `30 days from now`
   - Description: `Train for local charity run`
5. **Tap "Create"**
6. **Verify**:
   - ✅ Goal card appears
   - ✅ Shows "30 Days Remaining"
   - ✅ Target: "5.0 km"
   - ✅ Progress: 0%
   - ✅ Status badge: "Active" (blue)
   - ✅ Running icon displayed

### Test Multiple Goals:
7. **Create 2nd goal**: "Consistency" → 4 workouts/week
8. **Create 3rd goal**: "Weight Loss" → 70 kg target
9. **Verify**: All 3 goals listed

### Test Filter:
10. **Tap menu** (top right) → Select "Completed Goals"
11. **Verify**: Empty (no completed goals yet)
12. **Switch to "All Goals"** → Shows all 3

---

## ✅ Final Dashboard Check

### Verify Quick Access Section:
Navigate back to Dashboard → Scroll to "Quick Access"

**Should see 2 rows:**

**Row 1** (existing):
- 🔵 AISRI Assessment
- 🟢 AISRI Calculator  
- 🟠 Call AISRI

**Row 2** (NEW):
- 🟣 **Body Tracking** → Opens Body Measurements
- 🔴 **Injuries Log** → Opens Injuries Screen
- 🟡 **Goals Dashboard** → Opens Goals Screen

---

## 🎨 Visual Verification Checklist

### Body Measurements:
- [ ] Purple/gradient theme
- [ ] BMI color badges (green/orange/red)
- [ ] Weight/height/BMI icons
- [ ] Date formatting correct
- [ ] Progress summary card when 2+ measurements

### Injuries:
- [ ] Red/warning theme
- [ ] Status dots (red/orange/green)
- [ ] Severity badges
- [ ] Progress bars animate smoothly
- [ ] "Days since injury" updates
- [ ] Recovery percentage displays

### Goals:
- [ ] Blue/amber theme
- [ ] Trophy/target icons
- [ ] Progress bars
- [ ] Days countdown
- [ ] Priority colors
- [ ] Goal type icons match

---

## 🐛 Common Issues

**If screens are blank:**
- Check internet connection (Supabase requires online)
- Verify user is logged in
- Check console for error messages

**If "No data" persists:**
- Verify RLS policies are enabled in Supabase
- Check user_id matches authenticated user
- Try manual refresh (pull-to-refresh if implemented)

**Database errors:**
- Ensure migration deployed successfully
- Check Supabase project is active
- Verify table names match exactly

---

## 📊 Test Results Summary

| Feature | Test Status | Notes |
|---------|------------|-------|
| Body Measurements | ⬜ Not Tested / ✅ Pass / ❌ Fail | |
| Injury Tracking | ⬜ Not Tested / ✅ Pass / ❌ Fail | |
| Goals Dashboard | ⬜ Not Tested / ✅ Pass / ❌ Fail | |
| Dashboard Integration | ⬜ Not Tested / ✅ Pass / ❌ Fail | |

---

**🚀 Ready to test!** Connect your Android device and run: `flutter run -d "SM A707F"`
