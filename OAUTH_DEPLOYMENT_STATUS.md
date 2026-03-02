# ================================================================
# STRAVA OAUTH DEPLOYMENT - COMMAND EXECUTION REPORT
# Generated: March 1, 2026
# Deployment Target: api.akura.in (Render)
# ================================================================

## ✅ COMPLETED ACTIONS

### 1. Code Deployment to GitHub
- **Commit:** c452740
- **Repository:** CoachKura/safestride-akura
- **Branch:** main (pushed successfully)
- **Files Deployed:**
  ✓ ai_agents/strava_oauth_service.py (OAuth 2.0 handler)
  ✓ ai_agents/orchestrator.py (Strava connection methods)
  ✓ ai_agents/main.py (OAuth endpoints)
  ✓ ai_agents/aisri_safety_gate.py (Structural gating)
  ✓ ai_agents/workout_templates.py (Template engine)
  ✓ render.yaml (Added STRAVA_REDIRECT_URI env var)

### 2. OAuth Configuration Verified
- **STRAVA_CLIENT_ID:** 162971 ✓
- **STRAVA_CLIENT_SECRET:** ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626 ✓
- **STRAVA_REDIRECT_URI:** https://api.akura.in/strava/callback ✓

### 3. API Endpoints Confirmed in Code
- **GET /strava/connect** - Generate OAuth authorization URL
- **GET /strava/callback** - Handle OAuth callback & exchange code for tokens
- **GET /strava/status/{athlete_id}** - Check connection status

### 4. Supabase Edge Functions Located
- **strava-oauth:** /supabase/functions/strava-oauth/index.js ✓
- **strava-sync-activities:** /supabase/functions/strava-sync-activities/index.js ✓

### 5. Current API Status
- **Base URL:** https://api.akura.in - RESPONDING ✓
- **Service:** AISRi AI Engine v1.0 - ONLINE ✓
- **Server:** uvicorn (Render) - RUNNING ✓

## ⚠️ REQUIRED MANUAL ACTIONS (Dashboard Access Needed)

### ACTION 1: Verify Render Deployment Completed
**Dashboard:** https://dashboard.render.com
**Service:** aisri-ai-engine
**Expected:** Deployment triggered by commit c452740 should be LIVE

**Commands to verify deployment:**
```bash
# Check if new endpoints are live (should return auth URL, not 404)
curl "https://api.akura.in/strava/connect?athlete_id=test_001"
```

**Current Status:** API responding but OAuth endpoints returning 404
**Likely Cause:** Render deployment in progress OR environment variables not set

---

### ACTION 2: Set Render Environment Variables
**Dashboard:** https://dashboard.render.com → aisri-ai-engine → Environment

**REQUIRED Variables (add if missing):**
```
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626
STRAVA_REDIRECT_URI=https://api.akura.in/strava/callback
```

**After adding:** Render will auto-redeploy (takes ~2-3 minutes)

---

### ACTION 3: Deploy Supabase Edge Functions
**Dashboard:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb

**Method 1: Via Supabase Dashboard**
1. Navigate to Edge Functions
2. Create new function: "strava-oauth"
3. Copy code from: /supabase/functions/strava-oauth/index.js
4. Deploy

5. Create new function: "strava-sync-activities"
6. Copy code from: /supabase/functions/strava-sync-activities/index.js
7. Deploy

**Method 2: Via Supabase CLI (if you have access token)**
```bash
# Set access token
$env:SUPABASE_ACCESS_TOKEN="your_access_token_here"

# Deploy both functions
npx supabase functions deploy strava-oauth --project-ref bdisppaxbvygsspcuymb
npx supabase functions deploy strava-sync-activities --project-ref bdisppaxbvygsspcuymb
```

**Set Edge Function Environment Variables:**
```
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=[your_service_key]
```

---

### ACTION 4: Verify Strava App Settings
**Dashboard:** https://www.strava.com/settings/api
**Application:** SafeStride (Client ID: 162971)

**Check Authorization Callback Domain:**
- Must include: **api.akura.in**
- Must include: **bdisppaxbvygsspcuymb.supabase.co** (if using Edge Functions)

**If not present:**
1. Click "Edit" on your Strava application
2. Add domain: api.akura.in
3. Add domain: bdisppaxbvygsspcuymb.supabase.co
4. Save changes

---

### ACTION 5: Verify Strava Webhook Subscription
**Check webhook status:**
```bash
curl "https://www.strava.com/api/v3/push_subscriptions" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Create webhook if not exists:**
```bash
curl -X POST "https://www.strava.com/api/v3/push_subscriptions" \
  -F client_id=162971 \
  -F client_secret=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626 \
  -F callback_url=https://api.akura.in/strava/webhook \
  -F verify_token=SAFESTRIDE_WEBHOOK_2026
```

---

## 🧪 OAUTH FLOW TESTING SEQUENCE

### Test 1: Generate Authorization URL
```bash
curl "https://api.akura.in/strava/connect?athlete_id=test_deployment_001"
```

**Expected Response:**
```json
{
  "status": "success",
  "auth_url": "https://www.strava.com/oauth/authorize?client_id=162971&response_type=code&redirect_uri=https://api.akura.in/strava/callback&scope=read,activity:read_all,activity:write&state=test_deployment_001"
}
```

**If 404:** Render deployment not complete or environment variables missing

---

### Test 2: Manual OAuth Authorization
1. Copy the `auth_url` from Test 1
2. Open in browser
3. Click "Authorize" on Strava
4. Browser redirects to: `https://api.akura.in/strava/callback?code=XXX&state=test_deployment_001`

**Expected:** Success page or JSON response confirming token exchange

---

### Test 3: Verify Token Storage
```bash
curl "https://api.akura.in/strava/status/test_deployment_001"
```

**Expected Response:**
```json
{
  "connected": true,
  "athlete_id": "test_deployment_001",
  "strava_athlete_id": 12345678,
  "expires_at": "2026-03-01T18:30:00Z"
}
```

**Verify in Supabase:**
```sql
SELECT athlete_id, strava_athlete_id, expires_at, created_at 
FROM strava_connections 
WHERE athlete_id = '\''test_deployment_001'\'';
```

---

### Test 4: Verify Token Refresh
**Wait 5-10 minutes, then:**
```bash
curl "https://api.akura.in/strava/status/test_deployment_001"
```

**Expected:** Token should auto-refresh if near expiry (5-min buffer)

---

### Test 5: Verify Activity Sync
**Trigger activity sync (if endpoint exists):**
```bash
curl -X POST "https://api.akura.in/strava/sync-activities?athlete_id=test_deployment_001"
```

**Check Supabase for synced activities:**
```sql
SELECT strava_activity_id, activity_data->>'\''name'\'' as name, 
       activity_data->>'\''type'\'' as type,
       activity_data->>'\''start_date'\'' as date
FROM strava_activities 
WHERE athlete_id = '\''test_deployment_001'\''
ORDER BY created_at DESC 
LIMIT 10;
```

**Expected:** Recent Strava activities from authorized account

---

### Test 6: Verify AISRi Score Updates
**Check if structural scores calculated from Strava data:**
```bash
curl "https://api.akura.in/aisri/score/test_deployment_001"
```

**Expected Response:**
```json
{
  "aisri_score": 75,
  "structural_score": 68,
  "structural_state": "yellow",
  "pillar_scores": {
    "strength_score": 65,
    "mobility_score": 70,
    "rom_score": 69
  },
  "speed_permission": false
}
```

**Verify in Supabase:**
```sql
SELECT athlete_id, total_score, 
       pillar_scores->>'\''strength_score'\'' as strength,
       pillar_scores->>'\''mobility_score'\'' as mobility,
       pillar_scores->>'\''rom_score'\'' as rom
FROM aisri_scores 
WHERE athlete_id = '\''test_deployment_001'\'';
```

---

## 📊 SUCCESS CRITERIA (3 Confirmations Required)

### ✅ Confirmation 1: OAuth Flow Success
- [ ] Authorization URL generates correctly
- [ ] Strava authorization page loads
- [ ] Redirect to callback URL succeeds
- [ ] Access token saved to strava_connections table
- [ ] Refresh token saved to strava_connections table
- [ ] Token expiry timestamp set correctly

**Status:** PENDING - Awaiting Render deployment completion

---

### ✅ Confirmation 2: Activities Syncing
- [ ] Activities appear in strava_activities table
- [ ] Activity data includes: heart_rate_max, average_cadence, moving_time
- [ ] Activity sync triggered automatically after OAuth
- [ ] Webhook receives activity updates from Strava

**Status:** PENDING - Awaiting OAuth flow success

---

### ✅ Confirmation 3: AISRi Score Updating
- [ ] Structural scores calculated from activity data
- [ ] Pillar scores include: strength_score, mobility_score, rom_score
- [ ] Structural state determined (RED/YELLOW/GREEN)
- [ ] Speed permission boolean set correctly
- [ ] Scores update automatically when new activities sync

**Status:** PENDING - Awaiting activity sync verification

---

## 🚨 TROUBLESHOOTING

### Issue: OAuth endpoints return 404
**Cause:** Render deployment not complete or wrong service running
**Fix:** 
1. Check Render dashboard deployment logs
2. Verify "aisri-ai-engine" service deployed commit c452740
3. Verify environment variables set (STRAVA_CLIENT_ID, SECRET, REDIRECT_URI)
4. Manual redeploy if needed

---

### Issue: Authorization URL generates but redirect fails
**Cause:** Strava app settings don'\''t include callback domain
**Fix:**
1. Go to https://www.strava.com/settings/api
2. Edit application 162971
3. Add domain: api.akura.in
4. Ensure redirect URI matches exactly: https://api.akura.in/strava/callback

---

### Issue: Tokens not saving to database
**Cause:** Supabase credentials missing or incorrect
**Fix:**
1. Verify SUPABASE_SERVICE_ROLE_KEY in Render env vars
2. Check database_integration.py connection
3. Verify strava_connections table exists (migration deployed)
4. Check Render deployment logs for database errors

---

### Issue: Activities not syncing
**Cause:** Webhook not configured or Edge Functions not deployed
**Fix:**
1. Deploy Supabase Edge Functions (strava-sync-activities)
2. Create Strava webhook subscription (see ACTION 5)
3. Verify webhook callback URL accessible
4. Check Edge Function logs in Supabase dashboard

---

### Issue: Structural scores always 50 (default)
**Cause:** AISRi calculation not triggered or missing Strava data
**Fix:**
1. Verify activities synced with HR/cadence data
2. Trigger manual AISRi calculation
3. Check aisri_scores table for recent updates
4. Verify calculation logic in aisri_auto_calculator.py

---

## 📋 DEPLOYMENT CHECKLIST

**Before Testing:**
- [ ] Render deployment completed (check dashboard)
- [ ] Environment variables set in Render (STRAVA_CLIENT_ID, SECRET, REDIRECT_URI)
- [ ] Supabase Edge Functions deployed (strava-oauth, strava-sync-activities)
- [ ] Strava app settings include api.akura.in callback domain
- [ ] Webhook subscription created (if not already active)

**After Testing:**
- [ ] OAuth flow generates valid authorization URL
- [ ] OAuth callback successfully exchanges code for tokens
- [ ] Tokens saved to strava_connections table
- [ ] Refresh token mechanism working
- [ ] Activities syncing to strava_activities table
- [ ] AISRi scores calculated from Strava data
- [ ] Structural state (RED/YELLOW/GREEN) determined correctly
- [ ] Speed permission boolean set correctly

---

## 🎯 NEXT STEPS AFTER VERIFICATION

Once all 3 confirmations are YES:
1. Deploy Elite Web Platform (Dashboard, Calendar, Device Hub)
2. Integrate Structural State Display (RED/YELLOW/GREEN badge)
3. Real-time AISRi Gauge Visualization
4. Speed Permission UI Controls (hide/show high-intensity options)
5. Workout Calendar Color-Coded by State

---

## 📝 LOGS TO CAPTURE

**Render Deployment Log:** (copy from dashboard after deployment)
**Supabase Edge Function Log:** (strava-oauth deployment)
**Supabase Edge Function Log:** (strava-sync-activities deployment)
**OAuth Test 1 Response:** (authorization URL generation)
**OAuth Test 3 Response:** (token storage verification)
**Activity Sync Query Result:** (10 recent activities)
**AISRi Score Query Result:** (structural score verification)

================================================================
END OF DEPLOYMENT REPORT
================================================================
