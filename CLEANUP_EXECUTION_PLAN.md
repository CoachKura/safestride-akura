# CLEANUP EXECUTION PLAN - DEPLOY TODAY

## PHASE 1: CREATE ARCHIVE DIRECTORY

```powershell
cd C:\safestride\ai_agents
New-Item -ItemType Directory -Path "..\archive\non_production" -Force
New-Item -ItemType Directory -Path "..\archive\agent_modules" -Force
New-Item -ItemType Directory -Path "..\archive\dev_scripts" -Force
```

## PHASE 2: MOVE NON-PRODUCTION FILES

### A) Standalone FastAPI Apps (Not Used in Production)

```powershell
Move-Item api_endpoints.py ..\archive\non_production\
Move-Item activity_integration.py ..\archive\non_production\
Move-Item communication_agent_v2.py ..\archive\non_production\
Move-Item main_integration.py ..\archive\non_production\
```

### B) Non-Production Agent Directories

```powershell
Move-Item mobile_agent ..\archive\agent_modules\
Move-Item test_agent ..\archive\agent_modules\
Move-Item devops_agent ..\archive\agent_modules\
Move-Item backend_agent ..\archive\agent_modules\
Move-Item ai_agents ..\archive\agent_modules\  # nested directory
```

### C) Development/Test/Migration Scripts

```powershell
Move-Item test_table.py ..\archive\dev_scripts\
Move-Item test_decision_agent.py ..\archive\dev_scripts\
Move-Item test_performance_agent.py ..\archive\dev_scripts\
Move-Item check_status.py ..\archive\dev_scripts\
Move-Item simple_test.py ..\archive\dev_scripts\
Move-Item simple_daily_cycle.py ..\archive\dev_scripts\
Move-Item daily_runner.py ..\archive\dev_scripts\
Move-Item verify_integration.py ..\archive\dev_scripts\
Move-Item verify_strava_webhook.py ..\archive\dev_scripts\
Move-Item final_verification.py ..\archive\dev_scripts\
Move-Item add_structural_enum.py ..\archive\dev_scripts\
Move-Item add_structural_methods.py ..\archive\dev_scripts\
Move-Item add_structural_to_orchestrator.py ..\archive\dev_scripts\
Move-Item add_template_loader.py ..\archive\dev_scripts\
Move-Item fix_orphaned_except.py ..\archive\dev_scripts\
Move-Item fix_syntax.py ..\archive\dev_scripts\
Move-Item create_templates.py ..\archive\dev_scripts\
Move-Item update_orchestrator_workflow.py ..\archive\dev_scripts\
Move-Item update_workout_endpoint.py ..\archive\dev_scripts\
Move-Item unified_api_router.py ..\archive\dev_scripts\
```

### D) Keep Commander and Database Agent (May Be Used)

⚠️ AUDIT FIRST - Check if these are imported by main.py or orchestrator

```powershell
# Only move if confirmed unused:
# Move-Item commander ..\archive\agent_modules\
# Move-Item database_agent ..\archive\agent_modules\
```

## PHASE 3: CREATE RUNTIME.TXT

```powershell
cd C:\safestride\ai_agents
Copy-Item runtime.txt.local runtime.txt
```

## PHASE 4: UPDATE RENDER CONFIGURATION

**File:** `c:\safestride\render.yaml`

**Change line 14:** (aisri-ai-engine service)

```yaml
# BEFORE
startCommand: python api_endpoints.py

# AFTER
startCommand: uvicorn main:app --host 0.0.0.0 --port ${PORT:-10000}
```

## PHASE 5: ADD NEW ENVIRONMENT VARIABLES TO RENDER

**In Render Dashboard:** https://dashboard.render.com/web/srv-xxx/env

Add these new variables:

```
ALLOW_DEBUG_ENDPOINTS=false
ALLOW_NONPROD_MODULES=false
```

Update these values:

```
STRAVA_REDIRECT_URI=https://api.akura.in/strava/callback
OPENAI_API_KEY=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
```

## PHASE 6: VERIFY GUARDIAN PASSES

```powershell
cd C:\safestride\ai_agents
python system_guardian.py --audit --strict
```

Expected Result:

- ✅ All checks pass
- ✅ No Flutter artifacts
- ✅ No nested .git
- ✅ No non-prod modules (or ALLOW_NONPROD_MODULES=false if they don't exist)
- ✅ requirements.txt valid

## PHASE 7: LOCAL TEST BEFORE DEPLOY

```powershell
# Syntax check
python -m compileall main.py orchestrator.py system_guardian.py

# Start server locally
python main.py
```

Expected output:

```
======================================================================
AISRI ENGINE STARTUP
======================================================================
✅ Guardian: All integrity checks passed
Orchestrator initialized
...
```

Test endpoints:

```powershell
# Health check
Invoke-RestMethod http://localhost:8000/system/health

# OAuth connect (should work)
Invoke-RestMethod "http://localhost:8000/strava/connect?athlete_id=test_001"

# Debug endpoint (should return 404 if ALLOW_DEBUG_ENDPOINTS=false)
Invoke-RestMethod http://localhost:8000/test-supabase
```

## PHASE 8: GIT COMMIT AND PUSH

```powershell
cd C:\safestride

# Review changes
git status
git diff render.yaml
git diff ai_agents/main.py

# Stage production cleanup
git add render.yaml
git add ai_agents/runtime.txt
git add ai_agents/main.py
git add ai_agents/system_guardian.py
git add archive/

# Commit
git commit -m "Production cleanup: Fix entrypoint, archive non-prod files, enforce Guardian

- Fix render.yaml: Use main.py as entrypoint (was api_endpoints.py)
- Create runtime.txt for Python version specification
- Move non-production files to archive/
- Remove directory contamination (mobile_agent, test_agent, devops_agent, etc)
- Guardian now enforces clean deploy root
- OAuth bypass routes fixed
- Single FastAPI app enforced"

# Push
git push origin main
```

## PHASE 9: MONITOR RENDER DEPLOYMENT

1. Go to: https://dashboard.render.com/web/srv-xxx/events
2. Wait for "Deploy live" status (2-3 minutes)
3. Check logs for startup confirmation:
   - ✅ Guardian checks passed
   - ✅ Orchestrator initialized
   - ✅ No errors

## PHASE 10: PRODUCTION VERIFICATION

```powershell
# 1. Health check
$health = Invoke-RestMethod "https://api.akura.in/system/health"
$health | ConvertTo-Json

# Expected:
# {
#   "status": "healthy",
#   "services": {
#     "database": "connected",
#     "strava_oauth": "configured"
#   }
# }

# 2. OAuth flow test
$auth = Invoke-RestMethod "https://api.akura.in/strava/connect?athlete_id=test_deploy_001"
Start-Process $auth.auth_url  # Opens browser

# 3. Verify redirect_uri correct
if ($auth.auth_url -match 'redirect_uri=([^&]+)') {
    $redirect = [System.Web.HttpUtility]::UrlDecode($matches[1])
    Write-Host "Redirect URI: $redirect"
    # Should be: https://api.akura.in/strava/callback
}

# 4. Complete OAuth and test
# Click "Authorize" in browser
# Verify success page
Invoke-RestMethod "https://api.akura.in/strava/status/test_deploy_001"
```

---

## ROLLBACK PLAN (If Production Breaks)

```powershell
# If deployment fails, revert render.yaml
cd C:\safestride
git checkout HEAD~1 render.yaml
git add render.yaml
git commit -m "ROLLBACK: Revert to api_endpoints.py entrypoint"
git push origin main --force
```

Then restore files from archive for investigation.

---

## SUCCESS CRITERIA

✅ Guardian passes all checks
✅ Orchestrator initializes successfully
✅ OAuth flow works end-to-end
✅ Health endpoint returns "healthy"
✅ No directory contamination
✅ Single FastAPI app serving all routes
✅ Render uses main.py as entrypoint
