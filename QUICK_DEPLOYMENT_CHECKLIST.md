# ⚡ QUICK DEPLOYMENT CHECKLIST

**Deployment Time:** 30 minutes  
**Date:** 2026-02-19  

---

## 📋 PRE-DEPLOYMENT CHECKLIST

Before starting, ensure you have:

- [ ] Access to Supabase dashboard: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb
- [ ] Access to Strava API settings: https://www.strava.com/settings/api
- [ ] Access to Windows PowerShell on machine with `C:\safestride-web\` folder
- [ ] GitHub account with push access to CoachKura/safestride-akura
- [ ] 30 minutes of uninterrupted time

---

## ⏱️ PHASE 1: PUSH CODE TO GITHUB (5 minutes)

**Location:** Windows PowerShell in `C:\safestride-web\`

```powershell
# Step 1: Navigate to project
cd C:\safestride-web\

# Step 2: Checkout production branch
git checkout production

# Step 3: Pull latest changes from sandbox
git pull origin production

# Step 4: Push to GitHub
git push origin production

# Step 5: Update GitHub Pages
git checkout gh-pages
git merge production
git push origin gh-pages
```

**Wait 2 minutes for GitHub Pages to build**

### ✅ Verify:
- [ ] Visit https://www.akura.in/login.html
- [ ] Visit https://www.akura.in/coach-dashboard.html
- [ ] Both pages load without errors

---

## ⏱️ PHASE 2: DEPLOY DATABASE SCHEMAS (10 minutes)

**Location:** Supabase SQL Editor  
**URL:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/sql/new

### **Schema 1: Authentication System (5 min)**

1. Open file: `C:\safestride-web\supabase\migrations\002_authentication_system.sql`
2. Copy entire contents (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click "Run" button
5. Wait for "Success" message (~30 seconds)

### ✅ Verify:
Run this query in SQL Editor:
```sql
SELECT 'Users' AS type, COUNT(*) AS count FROM public.users
UNION ALL
SELECT 'Roles' AS type, COUNT(*) AS count FROM public.user_roles
UNION ALL
SELECT 'Profiles' AS type, COUNT(*) AS count FROM public.profiles;
```

**Expected Result:**
```
Users:    2  (admin@akura.in, coach@akura.in)
Roles:    3  (admin, coach, athlete)
Profiles: 0  (will populate when athletes are created)
```

- [ ] Users count = 2
- [ ] Roles count = 3
- [ ] No errors displayed

### **Schema 2: Strava Integration (3 min)**

1. Open file: `C:\safestride-web\supabase\migrations\001_strava_integration.sql`
2. Copy entire contents
3. Paste into NEW SQL query (click "New query" button)
4. Click "Run"
5. Wait for "Success"

### ✅ Verify:
```sql
SELECT 'Strava Connections' AS type, COUNT(*) AS count FROM strava_connections
UNION ALL
SELECT 'Strava Activities' AS type, COUNT(*) AS count FROM strava_activities
UNION ALL
SELECT 'AISRI Scores' AS type, COUNT(*) AS count FROM aisri_scores;
```

**Expected Result:** All counts = 0 (empty tables, ready for data)

- [ ] All 3 tables exist
- [ ] All counts = 0
- [ ] No errors

### **Schema 3: AISRI Complete System (2 min)**

1. Open file: `C:\safestride-web\public\sql\02_aisri_complete_schema.sql`
2. Copy entire contents
3. Paste into NEW SQL query
4. Click "Run"
5. Wait for "Success"

### ✅ Verify:
```sql
SELECT zone_code, zone_name, min_aisri_score 
FROM public.training_zones 
ORDER BY sort_order;
```

**Expected Result:** 6 rows
```
AR  | Active Recovery  | 0
F   | Foundation       | 0
EN  | Endurance        | 40
TH  | Threshold        | 55
P   | Power            | 70
SP  | Speed            | 85
```

- [ ] 6 training zones displayed
- [ ] Scores match above
- [ ] No errors

---

## ⏱️ PHASE 3: DEPLOY EDGE FUNCTIONS (10 minutes)

**Location:** Supabase Functions  
**URL:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

### **Function 1: strava-oauth (5 min)**

1. Click "+ Create a new function"
2. Function name: `strava-oauth`
3. Runtime: Deno
4. Open file: `C:\safestride-web\supabase\functions\strava-oauth\index.ts`
5. Copy entire contents
6. Paste into function editor
7. Click "Deploy" button
8. Wait for deployment success (~60 seconds)

### ✅ Verify:
- [ ] Function shows "Deployed" status
- [ ] Green checkmark visible
- [ ] Function URL displayed

### **Function 2: strava-sync-activities (5 min)**

1. Click "+ Create a new function"
2. Function name: `strava-sync-activities`
3. Runtime: Deno
4. Open file: `C:\safestride-web\supabase\functions\strava-sync-activities\index.ts`
5. Copy entire contents
6. Paste into function editor
7. Click "Deploy"
8. Wait for success

### ✅ Verify:
- [ ] Function shows "Deployed" status
- [ ] Green checkmark visible
- [ ] Function URL displayed

### **Add Strava Secrets**

**Location:** Settings → Edge Functions → Secrets

1. Click "+ New secret"
2. Name: `STRAVA_CLIENT_ID`
3. Value: `162971`
4. Click "Save"

5. Click "+ New secret"
6. Name: `STRAVA_CLIENT_SECRET`
7. Value: `6554eb9bb83f222a585e312c17420221313f85c1`
8. Click "Save"

### ✅ Verify:
- [ ] 2 secrets visible in list
- [ ] STRAVA_CLIENT_ID = 162971
- [ ] STRAVA_CLIENT_SECRET = (hidden, shows dots)

---

## ⏱️ PHASE 4: UPDATE STRAVA CALLBACK (2 minutes)

**Location:** Strava API Settings  
**URL:** https://www.strava.com/settings/api

1. Find "Authorization Callback Domain" field
2. Change from: `localhost:3000` or any other value
3. Change to: `www.akura.in`
4. Click "Update" button
5. Wait for "Successfully updated" message

### ✅ Verify:
- [ ] Authorization Callback Domain shows: `www.akura.in`
- [ ] Success message displayed
- [ ] No error messages

---

## ⏱️ PHASE 5: TEST COMPLETE SYSTEM (5 minutes)

### **Test 1: Coach Login (1 min)**

1. Open: https://www.akura.in/login.html
2. Enter email: `coach@akura.in`
3. Enter password: `Coach@123`
4. Click "Sign In"

### ✅ Verify:
- [ ] Redirects to `/coach-dashboard.html`
- [ ] Shows "Kura B Sathyamoorthy" in top right
- [ ] Shows "Total Athletes: 0"
- [ ] No console errors (F12 → Console)

### **Test 2: Create Test Athlete (2 min)**

1. Click "Create New Athlete" button
2. Fill form:
   - Full Name: `Test Athlete`
   - Email: `test@example.com`
   - Phone: `+91 9876543210`
   - Date of Birth: `1990-01-01`
   - Gender: `Male`
   - Click "Generate" for password (note it down!)
3. Click "Create Athlete"

### ✅ Verify:
- [ ] Success message appears
- [ ] Athlete appears in table
- [ ] Stats update: "Total Athletes: 1"
- [ ] Athlete UID generated (e.g., ATH0123)

### **Test 3: Athlete First Login (2 min)**

1. Logout from coach account
2. Go to: https://www.akura.in/login.html
3. Enter email: `test@example.com`
4. Enter password: (the generated password)
5. Click "Sign In"

### ✅ Verify:
- [ ] Redirects to `/change-password.html` (or prompts password change)
- [ ] Can set new password successfully
- [ ] After password change, redirects to athlete dashboard

---

## 🎉 POST-DEPLOYMENT CHECKLIST

### **Immediate Actions:**

1. **Change Default Passwords:**
   - [ ] Login as admin@akura.in
   - [ ] Change password from Admin@123 to strong password
   - [ ] Logout
   - [ ] Login as coach@akura.in
   - [ ] Change password from Coach@123 to strong password

2. **Test Strava Connection:**
   - [ ] Login as test athlete
   - [ ] Click "Connect Strava"
   - [ ] Authorize on Strava
   - [ ] Verify activities sync
   - [ ] Verify AISRI score calculated
   - [ ] Verify personal bests displayed
   - [ ] Verify training plan generated

3. **Delete Test Data:**
   - [ ] Delete test athlete from coach dashboard
   - [ ] Clear test data from database (optional)

### **Documentation:**

- [ ] Save admin password securely
- [ ] Save coach password securely
- [ ] Bookmark important URLs:
  - Login: https://www.akura.in/login.html
  - Coach Dashboard: https://www.akura.in/coach-dashboard.html
  - Supabase: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb
  - Strava API: https://www.strava.com/settings/api

### **Communication:**

- [ ] Inform athletes that system is live
- [ ] Provide login URL: https://www.akura.in/login.html
- [ ] Provide coach contact for account creation

---

## ❌ TROUBLESHOOTING

### **Issue: Login page not loading**
**Solution:**
1. Wait 2-5 minutes for DNS propagation
2. Try hard refresh (Ctrl+Shift+R)
3. Check GitHub Pages deployment status
4. Verify gh-pages branch is updated

### **Issue: "Invalid email or password"**
**Solution:**
1. Verify database migration ran successfully
2. Check users table has default accounts:
   ```sql
   SELECT email, full_name FROM public.users;
   ```
3. If empty, re-run authentication schema

### **Issue: "Function not found: authenticate_user"**
**Solution:**
1. Verify authentication schema was deployed
2. Check function exists:
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'authenticate_user';
   ```
3. If missing, re-run schema migration

### **Issue: Create athlete fails**
**Solution:**
1. Verify all 3 schemas deployed successfully
2. Check browser console for errors (F12)
3. Verify Supabase connection is working
4. Check that coach_id matches logged-in user

### **Issue: Strava connect fails**
**Solution:**
1. Verify callback URL is set to `www.akura.in`
2. Verify Edge Functions are deployed
3. Verify Strava secrets are added
4. Check browser console for errors
5. Check Supabase function logs

---

## 📊 SUCCESS METRICS

After deployment, you should have:

- ✅ 2 default accounts (admin, coach)
- ✅ All database tables created
- ✅ All functions deployed
- ✅ Strava integration working
- ✅ Coach can create athletes
- ✅ Athletes can login and connect Strava
- ✅ AISRI scores calculating automatically
- ✅ Training plans generating
- ✅ Zero errors in browser console
- ✅ Zero errors in Supabase logs

---

## 🎯 DEPLOYMENT COMPLETE!

If all checkboxes above are checked, your AKURA SafeStride system is **LIVE AND OPERATIONAL!**

**Total Deployment Time:** ~30 minutes  
**System Status:** Production Ready  
**Next Step:** Start onboarding real athletes  

---

## 📞 SUPPORT

If you need help:
1. Check browser console (F12 → Console)
2. Check Supabase logs (Dashboard → Logs)
3. Review deployment guide: `COMPLETE_DEPLOYMENT_GUIDE.md`
4. Review implementation summary: `IMPLEMENTATION_COMPLETE_SUMMARY.md`

**Questions?** Ask for help with any specific step!
