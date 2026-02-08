# 🎯 DATABASE FIX - STEP BY STEP

## ❌ THE PROBLEM

Your app has mixed schema references:
- **OLD CODE** → Uses `profiles` table (needs `name` column)
- **NEW CODE** → Uses `athlete_profiles` table
- **RESULT** → Schema mismatch errors

## ✅ THE SOLUTION

Run **ONE master migration** that creates BOTH tables with ALL needed columns.

---

## 🚀 STEP-BY-STEP FIX (5 MINUTES)

### **Step 1: Open Supabase (1 minute)**

1. Go to https://supabase.com/dashboard
2. Select your **SafeStride** project
3. Click **SQL Editor** in left sidebar

### **Step 2: Run Quick Fix Migration (2 minutes)**

1. In SQL Editor, click **"New query"**
2. Copy **ALL** content from: `database/QUICK_FIX_SCHEMA_MISMATCH.sql`
3. Paste into SQL Editor
4. Click **"Run"** button (or press Ctrl+Enter)
5. Wait ~10 seconds for completion

**Expected Output:**
```
status                    | profiles | athlete_profiles | exercises | coaches
--------------------------|----------|------------------|-----------|--------
Migration Complete!       | 1+       | 1+               | 15        | 1+
```

✅ If you see these numbers → **SUCCESS!**
❌ If you see errors → Copy the error message and share with me

### **Step 3: Hot Reload the App (1 minute)**

The app is already running in Chrome. Just hot reload:

**Option A: Press 'r' in the terminal**
```
Terminal shows: "Flutter run key commands"
Press: r
```

**Option B: Refresh Chrome**
```
Press F5 in Chrome browser
```

### **Step 4: Test the Button (1 minute)**

1. ✅ App reloads (errors should be gone!)
2. ✅ Navigate to **Profile** screen
3. ✅ Scroll down to green **"Generate Protocol"** card
4. ✅ Tap button
5. ✅ Wait 3-5 seconds
6. ✅ Success dialog appears!

---

## 🎉 EXPECTED SUCCESS

### **Success Dialog:**
```
✅ Success!

6 workouts scheduled!

📊 Analysis:
Cadence: 167 spm (Below optimal)
Weekly Distance: 23.0 km/week
AISRI Score: 60/100

🏋️ Protocol:
Cadence Optimization Protocol
2 weeks • 3 workouts/week
Focus: cadence, mobility, strength
Injury Risk: moderate

📅 Workouts added to your calendar

[Close] [View Calendar]
```

### **Then Check Calendar:**
1. Tap **"View Calendar"** button
2. See **6 workout dots** on calendar
3. Tap any date with workout
4. See workout details
5. Test **Complete** button

---

## 🆘 TROUBLESHOOTING

### **Error: "User not found" in Supabase**

Your user ID might be different. Check the app logs for your actual UUID and update line 227 in the migration file:

```sql
-- Replace with your actual user ID from app logs
v_user_id UUID := 'YOUR-ACTUAL-USER-ID-HERE';
```

### **Error: "Permission denied"**

Your Supabase project might have strict RLS. Disable RLS temporarily:
1. Go to Supabase → **Authentication** → **Policies**
2. Disable RLS on all tables
3. Run migration again
4. Re-enable RLS after

### **Error: "Syntax error at line X"**

The file might have been copied incorrectly. Try:
1. Open `MASTER_UNIFIED_MIGRATION.sql` in VS Code
2. Select ALL (Ctrl+A)
3. Copy (Ctrl+C)
4. Paste into Supabase SQL Editor
5. Run again

---

## 📊 VERIFICATION QUERIES

After migration, run these to verify:

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check your profiles
SELECT * FROM profiles 
WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3';

SELECT * FROM athlete_profiles 
WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3';

-- Check exercises
SELECT category, COUNT(*) as count
FROM exercises
GROUP BY category
ORDER BY category;

-- Expected:
-- Balance: 2
-- Flexibility: 3
-- Mobility: 2
-- Strength: 8
```

---

## 🎯 TIMELINE

```
NOW:           Read this guide (2 min)
↓
+3 min:        Run migration in Supabase
↓
+4 min:        Hot reload app (press 'r')
↓
+5 min:        Test button → SUCCESS! 🎉
```

---

## ✅ CHECKLIST

Before testing:
- [ ] Migration ran successfully in Supabase
- [ ] Verification queries returned expected counts
- [ ] App hot reloaded (no schema errors in console)

Ready to test:
- [ ] Navigate to Profile screen
- [ ] Find green "Generate Protocol" card
- [ ] Button is enabled (not greyed out)

Testing:
- [ ] Tap button
- [ ] Loading indicator appears
- [ ] Success dialog shows after 3-5 seconds
- [ ] Dialog shows analysis data
- [ ] "View Calendar" button works
- [ ] Calendar shows 6 workouts

---

## 🚀 READY?

**Current Status:**
- ✅ Code: 100% Complete
- ⏳ Database: Need to run migration
- ⏳ Testing: Waiting for database

**Next Action:**
1. Open Supabase SQL Editor
2. Copy/paste `MASTER_UNIFIED_MIGRATION.sql`
3. Click Run
4. Reply: **"MIGRATION DONE"** or **"ERROR: [message]"**

You're 3 minutes from success! 🎯
