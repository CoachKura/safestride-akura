# 🚀 SafeStride Backend Deployment Guide

**Date**: 2026-02-19  
**Project**: SafeStride Athlete Management Portal  
**Estimated Time**: 50 minutes

---

## ✅ Prerequisites Check

Before starting, verify you have:

- [x] Supabase project created (bdisppaxbvygsspcuymb)
- [x] Supabase CLI installed (version 2.76.10)
- [x] Git repository with all code committed
- [x] Database password: `Akura@2026$`
- [x] Strava credentials: Client ID `162971`

---

## 📋 Step-by-Step Deployment

### Step 1: Authenticate to Supabase (5 minutes)

**1.1 - Open PowerShell in your project directory**
```powershell
cd c:\safestride
```

**1.2 - Login to Supabase**
```powershell
supabase login
```

**What happens**:
- A browser window will open
- You'll be redirected to Supabase
- Click "Authorize" to grant CLI access
- The browser will show "You can close this window"
- Return to PowerShell

**Expected output**:
```
✓ Logged in successfully
```

**Troubleshooting**:
- If browser doesn't open: Check your default browser settings
- If authorization fails: Try `supabase logout` first, then login again
- If stuck: Press Ctrl+C and retry

---

### Step 2: Link Your Project (3 minutes)

**2.1 - Link to your Supabase project**
```powershell
supabase link --project-ref bdisppaxbvygsspcuymb
```

**When prompted for database password, enter**:
```
Akura@2026$
```

**Expected output**:
```
✓ Linked to project bdisppaxbvygsspcuymb
```

**What this does**:
- Creates a `supabase/.temp/project-ref` file
- Establishes connection to your remote database
- Enables CLI commands to work with your project

**Troubleshooting**:
- **"Invalid password"**: Double-check password is `Akura@2026$` (case-sensitive)
- **"Project not found"**: Verify project ref is `bdisppaxbvygsspcuymb`
- **"Connection refused"**: Check your internet connection

---

### Step 3: Set Environment Secrets (5 minutes)

**3.1 - Set Strava Client ID**
```powershell
supabase secrets set STRAVA_CLIENT_ID=162971
```

**Expected output**:
```
✓ Set secret STRAVA_CLIENT_ID
```

**3.2 - Set Strava Client Secret**
```powershell
supabase secrets set STRAVA_CLIENT_SECRET=6554eb9bb83f222a585e312c17420221313f85c1
```

**Expected output**:
```
✓ Set secret STRAVA_CLIENT_SECRET
```

**3.3 - Verify secrets were set**
```powershell
supabase secrets list
```

**Expected output**:
```
NAME                     │ VALUE
─────────────────────────┼───────────────
STRAVA_CLIENT_ID         │ 162971
STRAVA_CLIENT_SECRET     │ 6554...85c1
```

**What this does**:
- Stores credentials securely in Supabase
- Makes them available to Edge Functions via `Deno.env.get()`
- Prevents credentials from being exposed in code

**Troubleshooting**:
- **"Not logged in"**: Run `supabase login` again
- **"Project not linked"**: Run Step 2 again
- **Secrets not showing**: Wait 30 seconds and try `supabase secrets list` again

---

### Step 4: Apply Database Migrations (10 minutes)

**4.1 - Check what migrations exist**
```powershell
Get-ChildItem supabase\migrations
```

**Expected output**:
```
001_strava_integration.sql
002_authentication_system.sql
```

**4.2 - Push migrations to database**
```powershell
supabase db push
```

**What happens**:
- Reads all SQL files in `supabase/migrations/`
- Applies them to your remote database in order
- Creates tables: profiles, strava_connections, strava_activities, aisri_scores, training_zones, training_sessions, safety_gates

**Expected output**:
```
Checking remote database...
✓ Remote database is up to date
Applying migration 001_strava_integration.sql...
✓ Applied migration 001_strava_integration.sql
Applying migration 002_authentication_system.sql...
✓ Applied migration 002_authentication_system.sql
```

**4.3 - Verify tables were created**

Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/editor

Click "Tables" in left sidebar. You should see:
- ✅ profiles
- ✅ strava_connections
- ✅ strava_activities
- ✅ aisri_scores
- ✅ training_zones
- ✅ training_sessions
- ✅ safety_gates

**Troubleshooting**:
- **"Migration already applied"**: That's OK! It means tables already exist
- **"Syntax error"**: Check SQL files for errors, fix, and retry
- **"Permission denied"**: Your database password may be incorrect
- **"Connection timeout"**: Check internet connection, retry

---

### Step 5: Deploy Edge Functions (20 minutes)

**5.1 - Deploy strava-oauth function**
```powershell
supabase functions deploy strava-oauth
```

**What happens**:
- Bundles `supabase/functions/strava-oauth/index.js`
- Uploads to Supabase Edge Functions
- Makes it available at: `https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth`

**Expected output**:
```
Deploying function strava-oauth...
✓ Function strava-oauth deployed successfully
URL: https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth
Version: 1
```

**5.2 - Deploy strava-sync-activities function**
```powershell
supabase functions deploy strava-sync-activities
```

**Expected output**:
```
Deploying function strava-sync-activities...
✓ Function strava-sync-activities deployed successfully
URL: https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-sync-activities
Version: 1
```

**5.3 - Verify both functions are deployed**
```powershell
supabase functions list
```

**Expected output**:
```
NAME                        │ VERSION │ STATUS  │ URL
────────────────────────────┼─────────┼─────────┼───────────────────────────────────────────
strava-oauth                │ 1       │ deployed│ https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth
strava-sync-activities      │ 1       │ deployed│ https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-sync-activities
```

**Troubleshooting**:
- **"Bundle error"**: Check JavaScript syntax in function files
- **"Import error"**: Verify Deno imports are correct
- **"Function not found"**: Check folder structure is correct
- **"Deployment failed"**: View logs with `supabase functions logs function-name`

---

### Step 6: Test Edge Functions (5 minutes)

**6.1 - Test strava-oauth function**
```powershell
curl -X POST `
  'https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth' `
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY4MjM4OTEsImV4cCI6MjA1MjM5OTg5MX0.4vYk5u3AijkkNMB0JxFy0t2dNUPPGS8BnpWCym_hl_w' `
  -H 'Content-Type: application/json' `
  -d '{"code":"test","athleteId":"test"}'
```

**Expected output** (should return error about invalid code, which is fine):
```json
{"error": "Invalid authorization code"}
```

**This confirms**:
- ✅ Function is deployed and running
- ✅ CORS is configured correctly
- ✅ Function can receive requests
- ✅ Environment variables are loaded

**6.2 - Check function logs**
```powershell
supabase functions logs strava-oauth --tail
```

**What to look for**:
- ✅ No "undefined" errors for STRAVA_CLIENT_ID
- ✅ No "undefined" errors for STRAVA_CLIENT_SECRET
- ✅ Error message about invalid code (expected)

**Press Ctrl+C to stop tailing logs**

**Troubleshooting**:
- **"STRAVA_CLIENT_ID is undefined"**: Secrets weren't set correctly. Go back to Step 3
- **"CORS error"**: Check CORS headers in function code
- **"500 Internal Server Error"**: Check function logs for details

---

### Step 7: Configure Strava Application (5 minutes)

**7.1 - Go to Strava API Settings**

Open: https://www.strava.com/settings/api

**7.2 - Find your application**

You should see an application with:
- **Client ID**: 162971
- **Name**: SafeStride (or similar)

**7.3 - Update callback URLs**

Set **Authorization Callback Domain** to:
```
www.akura.in
```

Set **Authorization Callback URLs** to:
```
https://www.akura.in/strava-profile.html
https://www.akura.in/strava-callback.html
```

**7.4 - Save changes**

Click "Update" at the bottom of the form.

**What this does**:
- Allows Strava to redirect back to your site after OAuth
- Prevents "Invalid redirect_uri" errors

**Troubleshooting**:
- **Can't find application**: You may need to create a new one
- **To create new application**:
  - Application Name: SafeStride
  - Website: https://www.akura.in
  - Authorization Callback Domain: www.akura.in
  - Check "Read" and "Read All Activities"

---

### Step 8: End-to-End Testing (10 minutes)

**8.1 - Test Login Page**

1. Open: https://www.akura.in/login.html
2. Enter test credentials (if you have any)
3. Should redirect to appropriate dashboard

**Expected behavior**:
- ✅ Page loads without errors
- ✅ Form accepts input
- ✅ Can submit login

**8.2 - Test Strava Profile Page**

1. Open: https://www.akura.in/strava-profile.html
2. Open browser console (F12)
3. Check for JavaScript errors

**Expected behavior**:
- ✅ Page loads without errors
- ✅ No "undefined" errors in console
- ✅ Config loaded successfully

**8.3 - Test Strava OAuth Flow**

1. On profile page, click **"Connect with Strava"**
2. You should be redirected to Strava
3. Click **"Authorize"** on Strava
4. You should be redirected back to profile page
5. Should see success message

**Expected behavior**:
- ✅ Redirects to Strava correctly
- ✅ Returns to your site after authorization
- ✅ Token is saved to database
- ✅ Connection status shows "Connected"

**8.4 - Test Activity Sync**

1. After connecting, click **"Sync Activities"**
2. Wait 5-10 seconds
3. Activities list should populate

**Expected behavior**:
- ✅ Sync button shows loading state
- ✅ Activities appear in list
- ✅ AISRI scores are calculated
- ✅ Stats update (total distance, activities, etc.)

**8.5 - Test Auto-Fill**

1. Refresh the profile page
2. All fields should auto-fill:
   - Name, UID, email
   - Avatar
   - Strava stats
   - AISRI scores (6 pillars with bars)
   - Recent activities

**Expected behavior**:
- ✅ Page loads with real data (no placeholders)
- ✅ Avatar displays correctly
- ✅ AISRI bars show percentages
- ✅ Activities list is populated

**8.6 - Check Database**

Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/editor

Run this SQL:
```sql
-- Check Strava connections
SELECT * FROM strava_connections ORDER BY created_at DESC LIMIT 1;

-- Check activities
SELECT COUNT(*) as activity_count FROM strava_activities;

-- Check AISRI scores
SELECT * FROM aisri_scores ORDER BY created_at DESC LIMIT 1;
```

**Expected results**:
- ✅ strava_connections has 1 row with access_token
- ✅ strava_activities has multiple rows (your activities)
- ✅ aisri_scores has 1 row with calculated scores

**Troubleshooting**:
- **OAuth fails**: Check Strava callback URLs are correct
- **No activities synced**: Check Edge Function logs
- **AISRI scores all 0**: Check activity data completeness
- **Auto-fill not working**: Check browser console for errors

---

### Step 9: Run Automated Tests (5 minutes)

**9.1 - Open test suite**

Go to: https://www.akura.in/strava-autofill-test.html

**9.2 - Run all tests**

Click **"Run All Tests"** button

**Expected results**:
- ✅ 13 tests pass (green)
- ⚠️ 3 tests pending (yellow) - These are manual tests

**Test categories**:
1. Generator Tests (3/3) - Should pass
2. Data Fetch Tests (3/3) - Should pass
3. Role-Based Access Tests (3/3) - Should pass
4. Auto-Fill Tests (4/4) - Should pass
5. Integration Tests (0/3) - Manual only

**If tests fail**:
- Check browser console for errors
- Verify Supabase config is correct
- Check Edge Functions are deployed
- Review test failure messages

---

## ✅ Deployment Complete!

Congratulations! Your SafeStride backend is now deployed and functional.

### What's Working Now:

- ✅ **Frontend**: All pages live at www.akura.in
- ✅ **Backend**: Edge Functions deployed and running
- ✅ **Database**: All tables created with proper schema
- ✅ **OAuth**: Strava integration fully functional
- ✅ **Auto-Fill**: Profile pages generate automatically
- ✅ **AISRI**: ML/AI scoring calculating correctly

### Quick Reference:

**Your Supabase Project**:
- URL: https://bdisppaxbvygsspcuymb.supabase.co
- Dashboard: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb

**Your Live Site**:
- Main: https://www.akura.in
- Login: https://www.akura.in/login.html
- Profile: https://www.akura.in/strava-profile.html
- Tests: https://www.akura.in/strava-autofill-test.html

**Edge Functions**:
- OAuth: https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth
- Sync: https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-sync-activities

**Useful Commands**:
```powershell
# View function logs
supabase functions logs strava-oauth --tail
supabase functions logs strava-sync-activities --tail

# Check secrets
supabase secrets list

# Redeploy function
supabase functions deploy strava-oauth

# Check project status
supabase projects list
```

---

## 🐛 Common Issues & Solutions

### Issue: "Function returned undefined"
**Solution**: Check that environment variables are set:
```powershell
supabase secrets list
```

### Issue: "Invalid redirect_uri" from Strava
**Solution**: Update Strava app callback URLs:
- Go to: https://www.strava.com/settings/api
- Set callback domain: `www.akura.in`
- Set callback URL: `https://www.akura.in/strava-profile.html`

### Issue: No activities syncing
**Solution**: Check Edge Function logs:
```powershell
supabase functions logs strava-sync-activities --tail
```

### Issue: AISRI scores showing 0
**Solution**: Verify activity data exists:
```sql
SELECT * FROM strava_activities LIMIT 5;
```

### Issue: Auto-fill showing placeholders
**Solution**: 
1. Check browser console (F12) for errors
2. Verify Supabase config in `safestride-config.js`
3. Check that athlete data exists in database

---

## 📞 Support Resources

**Documentation**:
- README: https://www.akura.in/README.md
- Deployment Checklist: https://www.akura.in/DEPLOYMENT_CHECKLIST.md
- Status Report: https://www.akura.in/STATUS_REPORT.md

**External Resources**:
- Supabase Docs: https://supabase.com/docs
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- Strava API Docs: https://developers.strava.com/docs/

**Monitoring**:
```powershell
# Monitor OAuth function
supabase functions logs strava-oauth --tail

# Monitor sync function
supabase functions logs strava-sync-activities --tail

# Check database activity
# Go to: Supabase Dashboard → Database → Logs
```

---

## 🎉 Next Steps

### Immediate (This Week):
1. ✅ Test with real athlete accounts
2. ✅ Monitor Edge Function logs for errors
3. ✅ Verify AISRI calculations are accurate
4. ✅ Create 2-3 test athletes via Coach Dashboard

### Short-term (This Month):
1. Add Google Analytics tracking
2. Implement email notifications
3. Create user documentation
4. Plan training program features

### Long-term (This Quarter):
1. AI-powered training recommendations
2. Coach-athlete messaging
3. Achievement badges
4. Mobile app development

---

**Deployment Date**: 2026-02-19  
**Total Time**: ~50 minutes  
**Status**: ✅ Complete and Production Ready  
**Next Action**: Test with real users! 🚀

---

*Good luck with your deployment!*
