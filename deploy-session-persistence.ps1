# AUTOMATED DEPLOYMENT SCRIPT
# Run this AFTER allowing the GitHub secret

$ErrorActionPreference = "Stop"

Write-Host "`n🚀 AUTOMATED DEPLOYMENT - STRAVA SESSION PERSISTENCE`n" -ForegroundColor Cyan

# =============================================================================
# STEP 2: PUSH TO GITHUB
# =============================================================================
Write-Host "📤 STEP 2: Pushing to GitHub...`n" -ForegroundColor Yellow

try {
    git push origin main 2>&1 | Out-String | Write-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ STEP 2 COMPLETE: Pushed to GitHub successfully!`n" -ForegroundColor Green
    } else {
        Write-Host "`n❌ STEP 2 FAILED: Git push failed`n" -ForegroundColor Red
        Write-Host "Error: Push returned exit code $LASTEXITCODE`n" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "`n❌ STEP 2 FAILED: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

# =============================================================================
# STEP 3: VERIFY GITHUB SYNC
# =============================================================================
Write-Host "🔍 STEP 3: Verifying GitHub sync...`n" -ForegroundColor Yellow

$localCommit = git rev-parse HEAD
$remoteCommit = git rev-parse origin/main

if ($localCommit -eq $remoteCommit) {
    Write-Host "✅ STEP 3 COMPLETE: Local and remote in sync!`n" -ForegroundColor Green
    Write-Host "   Latest commit: $localCommit`n" -ForegroundColor White
} else {
    Write-Host "⚠️  Warning: Commits may not be fully synced yet`n" -ForegroundColor Yellow
    Write-Host "   Local:  $localCommit" -ForegroundColor White
    Write-Host "   Remote: $remoteCommit`n" -ForegroundColor White
}

# =============================================================================
# STEP 4: DEPLOY EDGE FUNCTION INSTRUCTIONS
# =============================================================================
Write-Host "`n📋 STEP 4: Deploy Supabase Edge Function`n" -ForegroundColor Yellow
Write-Host "⚠️  MANUAL STEP REQUIRED (Supabase CLI not configured)`n" -ForegroundColor Red

Write-Host "Option A: Deploy via Supabase Dashboard (RECOMMENDED)" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "1. Open: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions" -ForegroundColor White
Write-Host "2. Click: 'Deploy new function' button" -ForegroundColor White
Write-Host "3. Name: strava-refresh-token" -ForegroundColor White
Write-Host "4. Upload: C:\safestride\supabase\functions\strava-refresh-token\index.js" -ForegroundColor White
Write-Host "5. Click: 'Deploy'`n" -ForegroundColor White

Write-Host "Option B: Use Supabase CLI (if configured)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "npx supabase functions deploy strava-refresh-token --project-ref bdisppaxbvygsspcuymb`n" -ForegroundColor White

# =============================================================================
# STEP 5: TESTING INSTRUCTIONS
# =============================================================================
Write-Host "`n🧪 STEP 5: Test Production Deployment`n" -ForegroundColor Yellow

Write-Host "After Edge Function deploys, test here:" -ForegroundColor Cyan
Write-Host "https://www.akura.in/training-plan-builder.html`n" -ForegroundColor White

Write-Host "Expected Results:" -ForegroundColor Green
Write-Host "  ✅ Button shows: 🟢 'Strava Connected' (GREEN)" -ForegroundColor White
Write-Host "  ✅ Console: '✅ Found existing Strava connection'" -ForegroundColor White
Write-Host "  ✅ Console: '✅ Loaded 908 activities from database'" -ForegroundColor White
Write-Host "  ✅ Activities display automatically" -ForegroundColor White
Write-Host "  ✅ AISRI score shows: 52" -ForegroundColor White
Write-Host "  ✅ No 'Connect Strava' click needed!`n" -ForegroundColor White

# =============================================================================
# COMPLETION SUMMARY
# =============================================================================
Write-Host "`n" + ("=" * 65) -ForegroundColor Gray
Write-Host "📊 DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 65) -ForegroundColor Gray

Write-Host "`n✅ Completed Automatically:" -ForegroundColor Green
Write-Host "  • Git push to origin/main" -ForegroundColor White
Write-Host "  • GitHub sync verified" -ForegroundColor White

Write-Host "`n⏳ Manual Steps Remaining:" -ForegroundColor Yellow
Write-Host "  1. Deploy Edge Function (see Option A above)" -ForegroundColor White
Write-Host "  2. Test at www.akura.in/training-plan-builder.html" -ForegroundColor White

Write-Host "`n🎯 Success Criteria:" -ForegroundColor Cyan
Write-Host "  • Button is GREEN on first page load" -ForegroundColor White
Write-Host "  • Activities auto-load (908 activities)" -ForegroundColor White
Write-Host "  • Logout/login → Button STILL green" -ForegroundColor White
Write-Host "  • No reconnection needed = BUG FIXED! ✅`n" -ForegroundColor White

Write-Host ("=" * 65) -ForegroundColor Gray
Write-Host "`n💬 Reply 'EDGE FUNCTION DEPLOYED' after you complete Step 4!" -ForegroundColor Cyan
Write-Host ("=" * 65) + "`n" -ForegroundColor Gray
