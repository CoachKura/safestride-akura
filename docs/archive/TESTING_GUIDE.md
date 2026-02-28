# SafeStride Testing Checklist
# Quick reference for manual testing

## 🎯 TASK 2: STRUCTURED WORKOUTS DEPLOYMENT

### Step 1: Deploy Migration
```powershell
cd c:\safestride\database
.\deploy-structured-workouts.ps1
```

**Manual Steps:**
1. ✅ Open Supabase Dashboard: https://app.supabase.com
2. ✅ Navigate to SQL Editor
3. ✅ Copy SQL from `migration_structured_workouts.sql`
4. ✅ Paste into SQL Editor
5. ✅ Click "Run"
6. ✅ Verify success message

### Step 2: Verify Deployment
```powershell
.\verify-structured-workouts.ps1
```

**Expected Results:**
- ✅ 2 tables created: `structured_workouts`, `workout_assignments`
- ✅ `steps` column is JSONB type
- ✅ At least 3 indexes exist
- ✅ At least 4 RLS policies exist

### Step 3: Test in App
- ✅ Open SafeStride app
- ✅ Navigate to More → Structured Workouts
- ✅ Tap "+" to create workout
- ✅ Add steps with AISRI zones
- ✅ Save successfully
- ✅ Workout appears in list
- ✅ Can view workout details

---

## 🎯 TASK 3: END-TO-END TESTING

### Critical Flows (Must Pass)

#### ✅ Flow 1: User Registration
**Steps:**
1. Launch app (logged out)
2. Tap "Register"
3. Enter credentials
4. Register successfully
5. See Dashboard

**Pass Criteria:**
- User account created
- Logged in automatically
- Dashboard loads with bottom nav

---

#### ✅ Flow 2: AISRI Evaluation → Protocol
**Steps:**
1. More → Evaluation Form
2. Complete all questions
3. Submit evaluation
4. See AISRI score
5. Tap "Start Your Training Journey"
6. Wait for generation
7. See success dialog
8. Navigate to Athlete Goals
9. Fill in goals
10. Save goals
11. Check Kura Coach Calendar

**Pass Criteria:**
- Evaluation saves correctly
- AISRI score calculated (0-100)
- Protocol generation completes
- 4 weeks of workouts scheduled
- Workouts use AISRI zones (AR, F, EN, TH, P)
- Calendar shows all workouts

---

#### ✅ Flow 3: Create Structured Workout
**Steps:**
1. More → Structured Workouts
2. Tap "+" button
3. Enter name: "Threshold Intervals"
4. Add warmup (10 min, Zone F)
5. Add interval (5 min, Zone TH, x5)
6. Add recovery (2 min, Zone AR)
7. Add cooldown (10 min, Zone F)
8. Save workout
9. View in list
10. Open details

**Pass Criteria:**
- All step types available
- Can set AISRI zones
- Can set duration/distance
- Saves successfully
- Appears in list immediately
- Details show all steps correctly

---

### Important Flows (Should Pass)

#### ✅ Flow 4: Manual Training Template
**Steps:**
1. More → Manual Training
2. See 6 templates with zones
3. Tap "Easy Run"
4. Modify to 8 km
5. Create workout
6. Check calendar

**Pass Criteria:**
- Templates show AISRI zones
- Can modify distance
- Creates successfully
- Shows in calendar for today

---

#### ✅ Flow 5: Calendar Integration
**Steps:**
1. Calendar tab
2. View current week
3. See protocol workouts
4. See manual workouts
5. Tap a workout
6. View details
7. Navigate weeks

**Pass Criteria:**
- All workouts visible
- Correct dates
- Color-coded by type
- Can view details
- Can navigate months

---

#### ✅ Flow 6: GPS Tracking
**Steps:**
1. Dashboard
2. Tap "Start Run"
3. Grant location permission
4. Start workout
5. Run 1+ minute
6. Stop workout
7. View summary

**Pass Criteria:**
- GPS activates
- Map shows location
- Stats update real-time
- Summary shows correct data
- Saves to history

---

## 📊 SUCCESS CRITERIA

### Deployment Complete When:
- ✅ Migration deployed to Supabase
- ✅ Tables verified with SQL
- ✅ App can create/load workouts
- ✅ No database errors in console

### Testing Complete When:
- ✅ At least 5/6 flows pass
- ✅ Critical flows (1-3) all pass
- ✅ Blocking bugs documented
- ✅ App ready for beta users

---

## 🐛 KNOWN ISSUES TO WATCH FOR

1. **Missing Database Columns**
   - Check console for "column does not exist" errors
   - Run relevant migrations if needed

2. **Null Safety Errors**
   - Check for "null value" crashes
   - Verify data exists before display

3. **RLS Policy Blocks**
   - If operations fail silently, check RLS
   - Verify user has correct permissions

4. **AISRI Zone Calculation**
   - Verify max HR calculated correctly: 208 - (0.7 × age)
   - Check zone percentages match requirements

---

## 📝 TEST REPORT TEMPLATE

```
Date: ___________
Tester: ___________
Device: ___________
OS Version: ___________

DEPLOYMENT:
[ ] Migration deployed
[ ] Tables verified
[ ] App connects successfully

FLOW TESTING:
[ ] Flow 1 - Registration: PASS / FAIL
    Issue: ___________

[ ] Flow 2 - Protocol Gen: PASS / FAIL
    Issue: ___________

[ ] Flow 3 - Structured Workout: PASS / FAIL
    Issue: ___________

[ ] Flow 4 - Manual Training: PASS / FAIL
    Issue: ___________

[ ] Flow 5 - Calendar: PASS / FAIL
    Issue: ___________

[ ] Flow 6 - GPS Tracking: PASS / FAIL
    Issue: ___________

OVERALL: PASS / FAIL
```

---

## 🚀 QUICK START

Run all deployment and testing:

```powershell
# 1. Deploy evaluation tracking
cd c:\safestride\database
.\deploy-evaluation-tracking.ps1

# 2. Deploy structured workouts (MANUAL - see above)
.\deploy-structured-workouts.ps1

# 3. Verify deployment
.\verify-structured-workouts.ps1

# 4. Run E2E tests
.\run-e2e-tests.ps1
```

---

## 📞 SUPPORT

If you encounter issues:
1. Check Supabase logs for errors
2. Review Flutter console output
3. Verify migrations applied correctly
4. Check RLS policies allow operations

---

Generated: February 10, 2026
Version: 6.1 - Data Object Edition
