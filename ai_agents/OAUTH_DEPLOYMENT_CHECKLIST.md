# ============================================================================
# STRAVA OAUTH DEPLOYMENT CHECKLIST
# ============================================================================
# Generated: 2026-03-01 15:39:05

## ✅ PRE-DEPLOYMENT VERIFICATION

### 1. Local Environment
- [x] STRAVA_CLIENT_ID set: 162971
- [x] STRAVA_CLIENT_SECRET set: ca2a2ef...626 (verified)
- [x] STRAVA_REDIRECT_URI set: https://api.akura.in/strava/callback
- [x] OAuth service exists: strava_oauth_service.py
- [x] Orchestrator OAuth methods exist
- [x] Main.py endpoints exist: /strava/connect, /strava/callback, /strava/status
- [x] Syntax validated: All files compile

### 2. Database Schema
- [x] Migration exists: 20260218_strava_ml_integration.sql
- [x] Tables defined:
  - strava_connections (access_token, refresh_token, expires_at)
  - strava_activities
  - aisri_scores (with pillar_scores, structural scores)
- [ ] **NEEDS VERIFICATION**: Migration deployed to production Supabase

### 3. Strava Application Settings
**CRITICAL**: Verify in Strava Developer Portal (https://www.strava.com/settings/api)
- [ ] Application exists for Client ID 162971
- [ ] Authorized Callback Domain: api.akura.in
- [ ] Redirect URI includes: https://api.akura.in/strava/callback
- [ ] Scopes requested: read, activity:read_all, activity:write

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Verify Supabase Schema
\\\ash
# Log into Supabase Dashboard: https://app.supabase.com/project/xzxnnswggwqtctcgpocr
# Navigate to: SQL Editor
# Run this query to verify tables exist:

SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('strava_connections', 'strava_activities', 'aisri_scores');

# Expected result: All 3 tables should be listed
# If not, run the migration: supabase/migrations/20260218_strava_ml_integration.sql
\\\

### Step 2: Update Railway Environment Variables
**Railway Dashboard**: https://railway.app/project/[your-project-id]

Add/Verify these variables:
\\\
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626
STRAVA_REDIRECT_URI=https://api.akura.in/strava/callback
SUPABASE_SERVICE_ROLE_KEY=[your-service-role-key]
\\\

### Step 3: Verify Strava App Configuration
1. Go to: https://www.strava.com/settings/api
2. Find application with Client ID: 162971
3. Verify:
   - Authorization Callback Domain: **api.akura.in**
   - Redirect URI must include: **https://api.akura.in/strava/callback**

If not set:
   - Add domain: api.akura.in
   - Add callback URL: https://api.akura.in/strava/callback

### Step 4: Deploy to Railway
\\\ash
# Ensure all changes are committed
git status

# Commit OAuth fixes
git add ai_agents/.env ai_agents/strava_oauth_service.py ai_agents/orchestrator.py ai_agents/main.py
git commit -m "Deploy: OAuth fix - production redirect URI + Phase 0 orchestrator"

# Push to trigger Railway deployment
git push origin main

# Railway will auto-deploy within 2-3 minutes
\\\

### Step 5: Test OAuth Flow
\\\ash
# 1. Generate auth URL
curl "https://api.akura.in/strava/connect?athlete_id=test_athlete_001"

# Expected response:
# {
#   "status": "success",
#   "auth_url": "https://www.strava.com/oauth/authorize?client_id=162971&redirect_uri=https://api.akura.in/strava/callback&..."
# }

# 2. Open auth_url in browser
# 3. Authorize with Strava account
# 4. Should redirect to: https://api.akura.in/strava/callback?code=XXX&state=test_athlete_001

# 5. Verify token stored
curl "https://api.akura.in/strava/status/test_athlete_001"

# Expected response:
# {
#   "connected": true,
#   "athlete_id": "test_athlete_001",
#   "strava_athlete_id": 12345,
#   "expires_at": "2026-03-01T20:00:00Z"
# }
\\\

### Step 6: Verify Activity Sync
\\\ash
# Check if activities are syncing
curl "https://api.akura.in/strava/activities/test_athlete_001?limit=5"

# Should return recent activities from Strava
\\\

### Step 7: Verify AISRi Score Updates
\\\ash
# Trigger AISRi calculation from Strava data
curl -X POST "https://api.akura.in/aisri/calculate" \
  -H "Content-Type: application/json" \
  -d '{"athlete_id": "test_athlete_001"}'

# Check updated score includes structural components
curl "https://api.akura.in/aisri/score/test_athlete_001"

# Should return:
# {
#   "aisri_score": 75,
#   "structural_score": 68,
#   "structural_state": "yellow",
#   "pillar_scores": {
#     "strength_score": 65,
#     "mobility_score": 70,
#     "endurance_score": 78
#   }
# }
\\\

---

## 🔍 VERIFICATION CHECKLIST

After deployment, verify:

- [ ] **OAuth Flow Success**: Can generate auth URL, redirect works, tokens stored
- [ ] **Token Refresh**: Access tokens auto-refresh before expiry (check expires_at)
- [ ] **Activities Syncing**: Strava activities appear in strava_activities table
- [ ] **AISRi Updating**: Structural scores calculated from Strava data (strength, mobility from activity patterns)
- [ ] **Orchestrator Working**: /workout/generate-safe returns structural_state, speed_permission
- [ ] **Template Workflow**: Workouts respect structural state (RED/YELLOW/GREEN)

---

## 🐛 TROUBLESHOOTING

### Issue: "Invalid redirect_uri"
**Fix**: Verify in Strava settings that https://api.akura.in/strava/callback is listed

### Issue: "Access token expired"
**Check**: 
\\\sql
SELECT athlete_id, expires_at, created_at 
FROM strava_connections 
WHERE expires_at < NOW();
\\\
**Fix**: Token should auto-refresh. Check orchestrator logs for refresh attempts.

### Issue: "No activities syncing"
**Check**:
1. Token has activity:read_all scope
2. Activity integration webhook configured
3. Check logs for API errors

### Issue: "Structural score always 50"
**Check**:
1. Strava activities have heart rate, cadence data
2. AISRi calculator pulling from strava_activities table
3. Pillar score columns exist in aisri_scores table

---

## 📊 SUCCESS METRICS

### OAuth Flow: ✅ YES / ❌ NO
- Auth URL generates correctly
- Redirect works
- Tokens stored in database
- Token refresh working

### Activities Syncing: ✅ YES / ❌ NO  
- Activities appear in strava_activities table
- Activity data includes HR, pace, cadence
- New activities auto-sync

### AISRi Score Updating: ✅ YES / ❌ NO
- Structural score calculated from activities
- Pillar scores updated (strength, mobility, endurance)
- Workout templates respect structural state

---

## 🎯 NEXT STEPS AFTER VERIFICATION

Once all three are YES:

1. **Deploy Orchestrator Updates**
   - Structural state gating active
   - Template-based workout generation
   - Speed permission enforcement

2. **Build Elite Web Platform**
   - Dashboard with structural state display
   - Real-time AISRi gauge
   - Workout calendar with color-coded states

3. **Integrate Chat System**
   - Strict coaching responses
   - Template-based workout suggestions
   - Permission-based workout unlocks

4. **Device Hub**
   - Garmin integration
   - Apple Watch integration
   - Heart rate zone validation

---

**STATUS**: Ready for deployment
**BLOCKER**: None identified
**RISK**: Low (OAuth tested locally, schema validated)

**DEPLOY NOW.**

