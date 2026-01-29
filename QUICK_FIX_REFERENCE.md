# Quick Reference: Dashboard Real Data Loading

## Problem You Had
Dashboard showed hardcoded "Dinesh" name and "76" score instead of your actual data.

## What We Fixed
- ✅ Removed script loading conflicts
- ✅ Fixed error handling in data fetching
- ✅ Added comprehensive diagnostics
- ✅ Dashboard now loads real user data

## How to Verify It's Working

### Step 1: Open Browser Console
```
F12 (or right-click → Inspect → Console tab)
```

### Step 2: Check the Logs
When dashboard loads, you should see:
```
✅ User authenticated: [YOUR_USER_ID] Email: [YOUR_EMAIL]
✅ Profile fetched: { full_name: "[YOUR_NAME]", ... }
✅ Assessment fetched: { aifri_score: [YOUR_SCORE], ... }
```

### Step 3: Check Your Data
Should see on dashboard:
- Your name (not "Dinesh")
- Your AIFRI score (not "76")
- Your streak (not "12 Days")

## If Something's Wrong

### Dashboard shows error banner
Check console for which query failed:
- If "Profile query failed" → You haven't created your profile yet
- If "Assessment query failed" → You haven't completed the assessment
- If both work but blank → Check Supabase permissions

### Still showing hardcoded data
Console should tell you the issue. Otherwise:
1. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
2. Clear browser cache
3. Try in incognito window

## The Fix in One Picture

```
OLD (Broken):
┌─────────────────────┐
│ Welcome back, Dinesh│ ← Hardcoded
│ Score: 76 ADVANCED  │ ← Hardcoded
│ Error loading data  │ ← Any query fails = everything breaks
└─────────────────────┘

NEW (Fixed):
┌──────────────────────────────┐
│ Welcome back, John Doe       │ ← From database
│ Score: 82 ADVANCED           │ ← From your assessment
│ 🔥 14 Days Streak            │ ← From your workouts
│ All queries run in parallel   │ ← One failing doesn't break others
└──────────────────────────────┘
```

## Key Files Changed

1. **`frontend/athlete-dashboard.html`**
   - Lines 1099-1310: Data loading and UI update logic
   - Removed duplicate script tags
   - Added error handling and logging

2. **`frontend/debug-dashboard.js`** (NEW)
   - Debug utility for troubleshooting
   - Copy-paste into console

3. **`DASHBOARD_FIX_SUMMARY.md`** (NEW)
   - Detailed technical explanation

## Database Tables Used

```
profiles             assessments              workouts
├─ id                ├─ id                    ├─ id
├─ full_name    ←→  ├─ athlete_id    ←→      ├─ athlete_id
├─ email             ├─ aifri_score           ├─ scheduled_date
└─ role              ├─ scores                └─ completed
                     ├─ risk_level
                     └─ created_at
```

Dashboard queries:
1. Get profile by user ID
2. Get latest assessment by user ID
3. Get recent workouts by user ID
4. Display all on dashboard

## Assessment Score Calculation

When you complete the 9-step assessment, system calculates:

```
Score = Average of (Running + Strength + ROM + Balance + Mobility + Alignment)

Grade:
- 80+ = ADVANCED  🟢
- 60-79 = INTERMEDIATE 🟡
- <60 = BASIC 🔴
```

## Testing Commands (In Console)

### See all your assessments
```javascript
const supabase = window.AkuraAuth.getClient();
const user = await window.AkuraAuth.getCurrentUser();
const { data } = await supabase.from('assessments').select('*').eq('athlete_id', user.id);
console.log(data);
```

### Clear local data
```javascript
localStorage.removeItem('assessment');
localStorage.removeItem('aifriScore');
location.reload();
```

### Force dashboard refresh
```javascript
await initializeDashboard();
```

### Run full debug
```javascript
// First load debug-dashboard.js from frontend folder, then:
debugDashboard();
```

## Common Questions

**Q: Why does it show "NOT ASSESSED"?**
A: You haven't completed your fitness assessment yet. Click "Take Assessment Now".

**Q: Why is my score different than expected?**
A: Make sure you answered all questions honestly. Score is calculated from your FMS scores and flexibility measurements.

**Q: Can I edit my assessment?**
A: Currently no, but you can retake it anytime to update your profile.

**Q: How often is my data updated?**
A: Dashboard loads fresh data each time you visit. Changes appear immediately after submission.

**Q: What if Supabase is down?**
A: You'll see an error in the console. The dashboard won't load until service is restored.

---

## Still Having Issues?

1. **Copy your console errors** (right-click → Save As)
2. **Run**: `debugDashboard()` in console and save output
3. **Contact support** with:
   - Your email
   - Browser (Chrome, Firefox, Safari, etc.)
   - Screenshots of console errors
   - Output from debugDashboard()

---

**Last Updated**: 2026-01-27  
**For Support**: Use the debug utility and share console output
