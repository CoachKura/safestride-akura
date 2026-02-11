# Test-StravaIntegration.ps1
# Verifies Strava OAuth configuration and connection flow

param(
    [switch]$CheckCode,
    [switch]$CheckSupabase,
    [switch]$CheckStrava,
    [switch]$All
)

$ErrorActionPreference = 'Continue'
$script:issues = @()
$script:warnings = @()
$script:success = @()

function Write-Section {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
    $script:success += $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
    $script:warnings += $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
    $script:issues += $Message
}

function Test-CodeStructure {
    Write-Section "1. Code Structure Check"
    
    $screenPath = "c:\safestride\lib\screens\strava_connect_screen.dart"
    
    if (-not (Test-Path $screenPath)) {
        Write-Error "File not found: $screenPath"
        return
    }
    
    $content = Get-Content $screenPath -Raw
    
    # Check if file has correct class order
    $widgetIndex = $content.IndexOf("class StravaConnectScreen extends StatefulWidget")
    $stateIndex = $content.IndexOf("class _StravaConnectScreenState extends State")
    
    if ($widgetIndex -lt 0) {
        Write-Error "Missing StatefulWidget class declaration"
    } elseif ($stateIndex -lt 0) {
        Write-Error "Missing State class declaration"
    } elseif ($widgetIndex -gt $stateIndex) {
        Write-Error "Class order WRONG: State class appears before Widget class"
        Write-Warning "Fix: Replace file with corrected version from STRAVA_INTEGRATION_FIX.md"
    } else {
        Write-Success "Class order correct: Widget → State"
    }
    
    # Check for hardcoded credentials
    if ($content -match 'stravaClientId\s*=\s*[''"]YOUR_CLIENT_ID[''"]') {
        Write-Warning "Found hardcoded CLIENT_ID placeholder (should be in Supabase)"
    }
    
    if ($content -match "stravaClientSecret") {
        Write-Warning "Client Secret referenced in code (should ONLY be in Supabase backend)"
    }
    
    # Check for OAuth flow
    if ($content -match "connectStrava|launchUrl") {
        Write-Success "OAuth flow implemented (custom implementation)"
    } else {
        Write-Error "Missing OAuth implementation"
    }
    
    # Check for proper redirect URI  
    if ($content -match "akura\.in") {
        Write-Success "Redirect URI configured: akura.in"
    } else {
        Write-Warning "Custom redirect URI not found"
    }
    
    # Check for required scopes
    if ($content -match "activity:read") {
        Write-Success "Strava scopes configured: activity:read"
    } else {
        Write-Warning "Strava scopes may not be configured"
    }
}

function Test-ServiceLogic {
    Write-Section "2. Service Logic Check"
    
    $servicePath = "c:\safestride\lib\services\strava_service.dart"
    
    if (-not (Test-Path $servicePath)) {
        Write-Error "File not found: $servicePath"
        return
    }
    
    $content = Get-Content $servicePath -Raw
    
    # Check for token storage
    if ($content -match "profiles.*strava_access_token") {
        Write-Success "Uses database table: profiles (strava_access_token)"
    } else {
        Write-Warning "Token storage method unclear"
    }
    
    # Check for token refresh logic
    if ($content -match "_refreshAccessToken") {
        if ($content -match "_refreshAccessToken.*?return null") {
            Write-Warning "Token refresh not implemented (returns null)"
            Write-Warning "Users will need to reconnect every 60 days"
        } else {
            Write-Success "Token refresh logic implemented"
        }
    }
    
    # Check for activity sync
    if ($content -match "syncActivities") {
        Write-Success "Activity sync method exists"
    } else {
        Write-Error "Missing syncActivities method"
    }
    
    # Check for multi-user support (uses auth.uid())
    if ($content -match "auth\.uid\(\)") {
        Write-Success "Multi-user support: Uses auth.uid() for current user"
    } else {
        Write-Warning "May not support multiple users properly"
    }
}

function Test-SupabaseConfig {
    Write-Section "3. Supabase Configuration Check"
    
    Write-Host "⚠️  Manual verification required:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Open: https://app.supabase.com" -ForegroundColor White
    Write-Host "2. Select your SafeStride project" -ForegroundColor White
    Write-Host "3. Go to: Authentication → Providers" -ForegroundColor White
    Write-Host "4. Find: Strava" -ForegroundColor White
    Write-Host ""
    Write-Host "Verify:" -ForegroundColor Cyan
    Write-Host "  ✓ Strava provider is ENABLED (toggle ON)" -ForegroundColor Gray
    Write-Host "  ✓ Client ID is filled in" -ForegroundColor Gray
    Write-Host "  ✓ Client Secret is filled in" -ForegroundColor Gray
    Write-Host "  ✓ Redirect URL is shown (https://xxx.supabase.co/auth/v1/callback)" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Is Strava provider enabled in Supabase? (y/n)"
    if ($response -eq 'y') {
        Write-Success "Supabase Strava provider enabled"
        
        $clientId = Read-Host "Client ID configured? (y/n)"
        if ($clientId -eq 'y') {
            Write-Success "Client ID configured"
        } else {
            Write-Error "Client ID missing - paste from Strava API settings"
        }
        
        $clientSecret = Read-Host "Client Secret configured? (y/n)"
        if ($clientSecret -eq 'y') {
            Write-Success "Client Secret configured"
        } else {
            Write-Error "Client Secret missing - paste from Strava API settings"
        }
    } else {
        Write-Error "Strava provider NOT enabled in Supabase"
        Write-Warning "Enable it: Authentication → Providers → Strava → Toggle ON"
    }
}

function Test-StravaApp {
    Write-Section "4. Strava App Configuration Check"
    
    Write-Host "⚠️  Manual verification required:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Open: https://www.strava.com/settings/api" -ForegroundColor White
    Write-Host "2. Find your SafeStride app (or click 'Create App')" -ForegroundColor White
    Write-Host ""
    Write-Host "Verify:" -ForegroundColor Cyan
    Write-Host "  ✓ Application Name: SafeStride" -ForegroundColor Gray
    Write-Host "  ✓ Category: Training" -ForegroundColor Gray
    Write-Host "  ✓ Authorization Callback Domain matches Supabase redirect" -ForegroundColor Gray
    Write-Host "    Example: abcdefgh12345.supabase.co" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Is Strava app configured? (y/n)"
    if ($response -eq 'y') {
        Write-Success "Strava app exists"
        
        $callback = Read-Host "Authorization Callback Domain matches Supabase? (y/n)"
        if ($callback -eq 'y') {
            Write-Success "Callback domain configured correctly"
        } else {
            Write-Error "Callback domain mismatch"
            Write-Warning "Copy redirect URL from Supabase and paste in Strava app settings"
        }
    } else {
        Write-Error "Strava app NOT configured"
        Write-Warning "Create it: strava.com/settings/api → Create App"
    }
}

function Test-Database {
    Write-Section "5. Database Schema Check"
    
    Write-Host "⚠️  Verify these tables exist in Supabase:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Required tables:" -ForegroundColor Cyan
    Write-Host "  - strava_connections (stores access tokens)" -ForegroundColor Gray
    Write-Host "  - strava_activities (stores synced workouts)" -ForegroundColor Gray
    Write-Host "  - strava_weekly_stats (aggregated stats)" -ForegroundColor Gray
    Write-Host "  - strava_personal_bests (PRs)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Run in Supabase SQL Editor:" -ForegroundColor Cyan
    Write-Host @"
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'strava%';

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE 'strava%';
"@ -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Do all Strava tables exist? (y/n)"
    if ($response -eq 'y') {
        Write-Success "Database schema exists"
    } else {
        Write-Error "Missing database tables"
        Write-Warning "Apply migration: Run SQL files in database/migrations/"
    }
    
    $rls = Read-Host "Is Row Level Security enabled? (y/n)"
    if ($rls -eq 'y') {
        Write-Success "RLS enabled (data isolated per user)"
    } else {
        Write-Error "RLS not enabled - security risk!"
        Write-Warning "Enable RLS for all strava_* tables"
    }
}

function Show-Summary {
    Write-Section "SUMMARY"
    
    if ($script:success.Count -gt 0) {
        Write-Host "✅ PASSED ($($script:success.Count)):" -ForegroundColor Green
        $script:success | ForEach-Object { Write-Host "  • $_" -ForegroundColor Green }
        Write-Host ""
    }
    
    if ($script:warnings.Count -gt 0) {
        Write-Host "⚠️  WARNINGS ($($script:warnings.Count)):" -ForegroundColor Yellow
        $script:warnings | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
        Write-Host ""
    }
    
    if ($script:issues.Count -gt 0) {
        Write-Host "❌ ISSUES ($($script:issues.Count)):" -ForegroundColor Red
        $script:issues | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "  1. Review STRAVA_FIX_STEP_BY_STEP.md" -ForegroundColor White
        Write-Host "  2. Fix issues above" -ForegroundColor White
        Write-Host "  3. Run this script again" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "🎉 ALL CHECKS PASSED!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ready to test:" -ForegroundColor Cyan
        Write-Host "  1. Hot reload app (press 'r' in terminal)" -ForegroundColor White
        Write-Host "  2. Navigate to Strava Connect" -ForegroundColor White
        Write-Host "  3. Tap 'Connect to Strava'" -ForegroundColor White
        Write-Host "  4. Log into YOUR Strava" -ForegroundColor White
        Write-Host "  5. Authorize SafeStride" -ForegroundColor White
        Write-Host "  6. Tap 'Sync Activities'" -ForegroundColor White
        Write-Host "  7. Verify today's workout appears!" -ForegroundColor White
        Write-Host ""
    }
}

# Main execution
Write-Host @"
╔════════════════════════════════════════════════════════╗
║  STRAVA INTEGRATION VERIFICATION                       ║
║  SafeStride Mobile v6.0                                ║
╚════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

if ($All -or (-not $CheckCode -and -not $CheckSupabase -and -not $CheckStrava)) {
    Test-CodeStructure
    Test-ServiceLogic
    Test-SupabaseConfig
    Test-StravaApp
    Test-Database
} else {
    if ($CheckCode) { 
        Test-CodeStructure 
        Test-ServiceLogic
    }
    if ($CheckSupabase) { Test-SupabaseConfig }
    if ($CheckStrava) { Test-StravaApp }
}

Show-Summary

Write-Host "Script completed!" -ForegroundColor Cyan
Write-Host ""
