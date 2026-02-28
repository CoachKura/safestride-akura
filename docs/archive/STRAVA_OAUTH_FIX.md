# Strava OAuth Issue - ROOT CAUSE FOUND ✅

## 🔍 Diagnostic Results

**Issue Found**: Strava API is rejecting the OAuth request with:
```json
{
  "message": "Bad Request",
  "errors": [{
    "resource": "Application",
    "field": "client_id",
    "code": "invalid"
  }]
}
```

---

## ⚠️ **ROOT CAUSE**: Missing or Invalid Supabase Secrets

The Supabase Edge Function `strava-oauth` is **deployed and working**, but it doesn't have the correct Strava credentials.

---

## ✅ **SOLUTION**: Set Supabase Secrets

You need to set the following secrets in your Supabase project:

### Method 1: Using Supabase CLI (Recommended)

```powershell
# Install Supabase CLI if not already installed
# npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref bdisppaxbvygsspcuymb

# Set the secrets
supabase secrets set STRAVA_CLIENT_ID=162971
supabase secrets set STRAVA_CLIENT_SECRET=your_secret_here
supabase secrets set SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
supabase secrets set SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNDY4NDQsImV4cCI6MjA4NjgyMjg0NH0.bjgoVhVboDQTmIPe_A5_4yiWvTBvckVtw88lQ7GWFrc

# Verify secrets are set
supabase secrets list
```

### Method 2: Using Supabase Dashboard

1. Go to: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/functions
2. Click on **Edge Functions** in the left sidebar
3. Click **Manage secrets**
4. Add the following secrets:
   - `STRAVA_CLIENT_ID` = `162971`
   - `STRAVA_CLIENT_SECRET` = (get from Strava API settings)
   - `SUPABASE_URL` = `https://bdisppaxbvygsspcuymb.supabase.co`
   - `SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (your anon key)

---

## 🔑 Getting Your Strava Client Secret

If you don't have the Strava Client Secret:

1. Go to: https://www.strava.com/settings/api
2. Find your application "Akura" (or create one)
3. Client ID should match: **162971**
4. Copy the **Client Secret** (never share this publicly!)
5. Set it in Supabase secrets

---

## ✅ Verification

After setting the secrets, test again:

```powershell
# Test the edge function
$testBody = '{"code":"test_12345","athleteId":"test_athlete"}'
$headers = @{
    "apikey" = "your_anon_key"
    "Authorization" = "Bearer your_anon_key"
    "Content-Type" = "application/json"
}
Invoke-WebRequest -Uri "https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth" `
    -Method POST -Headers $headers -Body $testBody -UseBasicParsing
```

**Expected result after fix**:
- Status: 400 (still fails, but with different error)
- Error should now say: `"Strava token exchange failed"` with a message about invalid authorization code
- This confirms the client_id/secret are working!

---

## 🌐 Testing in Browser

After secrets are set:

1. Open: http://localhost:64109/training-plan-builder.html
2. Click "Connect with Strava"
3. Authorize on Strava's page
4. You should be redirected back with a valid code
5. The edge function will now work correctly! ✅

---

## 📝 Summary

**Status**:
- ✅ Edge function deployed
- ✅ Edge function code is correct
- ✅ Database table exists (strava_connections)
- ❌ Supabase secrets not set (CLIENT_ID, CLIENT_SECRET)

**Action Required**:
1. Set Strava secrets in Supabase (see above)
2. Test in browser
3. OAuth should work! 🎉

---

## 🔧 Troubleshooting

**If it still doesn't work after setting secrets:**

1. **Check secrets are set**:
   ```bash
   supabase secrets list
   ```

2. **Redeploy edge function** (to pick up new secrets):
   ```bash
   cd supabase/functions/strava-oauth
   supabase functions deploy strava-oauth
   ```

3. **Check edge function logs**:
   ```bash
   supabase functions logs strava-oauth --tail
   ```

4. **Verify Strava API settings**:
   - Go to https://www.strava.com/settings/api
   - Ensure Authorization Callback Domain includes your domain
   - For local testing: `http://localhost:64109/training-plan-builder.html`

---

**Created**: February 21, 2026  
**Status**: Root cause identified - awaiting secret configuration
