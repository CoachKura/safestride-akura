# ============================================================================
# SUPABASE EDGE FUNCTIONS - AUTOMATED DEPLOYMENT SCRIPT
# ============================================================================
# This script deploys all three Strava Edge Functions and sets secrets
# Usage: .\deploy-supabase-functions.ps1
# ============================================================================

Write-Host ""
Write-Host "🚀 SUPABASE EDGE FUNCTIONS DEPLOYMENT" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is installed
Write-Host "🔍 Checking Supabase CLI installation..." -ForegroundColor Yellow
$supabaseVersion = & supabase --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Supabase CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📦 Installing Supabase CLI via npm..." -ForegroundColor Yellow
    npm install -g supabase
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install Supabase CLI" -ForegroundColor Red
        Write-Host "Please install manually: npm install -g supabase" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Supabase CLI installed successfully" -ForegroundColor Green
} else {
    Write-Host "✅ Supabase CLI found: $supabaseVersion" -ForegroundColor Green
}

Write-Host ""

# Navigate to project directory
$projectPath = "C:\safestride"
if (Test-Path $projectPath) {
    Set-Location $projectPath
    Write-Host "✅ Project directory: $projectPath" -ForegroundColor Green
} else {
    Write-Host "❌ Project directory not found: $projectPath" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if project is linked
Write-Host "🔗 Checking project link..." -ForegroundColor Yellow
$linkStatus = & supabase projects list 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not logged in to Supabase" -ForegroundColor Yellow
    Write-Host "📝 Please run: supabase login" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening browser for authentication..." -ForegroundColor Cyan
    & supabase login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Login failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Authenticated with Supabase" -ForegroundColor Green
Write-Host ""

# Link project (if not already linked)
Write-Host "🔗 Linking to project bdisppaxbvygsspcuymb..." -ForegroundColor Yellow
& supabase link --project-ref bdisppaxbvygsspcuymb 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project linked successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Project already linked or needs database password" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "📦 DEPLOYING EDGE FUNCTIONS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Deploy strava-oauth
Write-Host "🚀 [1/3] Deploying strava-oauth..." -ForegroundColor Yellow
& supabase functions deploy strava-oauth --project-ref bdisppaxbvygsspcuymb
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ strava-oauth deployed" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to deploy strava-oauth" -ForegroundColor Red
}

Write-Host ""

# Deploy strava-sync-activities
Write-Host "🚀 [2/3] Deploying strava-sync-activities..." -ForegroundColor Yellow
& supabase functions deploy strava-sync-activities --project-ref bdisppaxbvygsspcuymb
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ strava-sync-activities deployed" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to deploy strava-sync-activities" -ForegroundColor Red
}

Write-Host ""

# Deploy strava-refresh-token
Write-Host "🚀 [3/3] Deploying strava-refresh-token..." -ForegroundColor Yellow
& supabase functions deploy strava-refresh-token --project-ref bdisppaxbvygsspcuymb
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ strava-refresh-token deployed" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to deploy strava-refresh-token" -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "🔐 SETTING ENVIRONMENT SECRETS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Set STRAVA_CLIENT_ID
Write-Host "🔑 [1/2] Setting STRAVA_CLIENT_ID..." -ForegroundColor Yellow
& supabase secrets set STRAVA_CLIENT_ID=162971 --project-ref bdisppaxbvygsspcuymb
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ STRAVA_CLIENT_ID set" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set STRAVA_CLIENT_ID" -ForegroundColor Red
}

Write-Host ""

# Set STRAVA_CLIENT_SECRET
Write-Host "🔑 [2/2] Setting STRAVA_CLIENT_SECRET..." -ForegroundColor Yellow
& supabase secrets set STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626 --project-ref bdisppaxbvygsspcuymb
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ STRAVA_CLIENT_SECRET set" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set STRAVA_CLIENT_SECRET" -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✅ VERIFYING DEPLOYMENT" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# List deployed functions
Write-Host "📋 Deployed Functions:" -ForegroundColor Yellow
& supabase functions list --project-ref bdisppaxbvygsspcuymb

Write-Host ""

# List secrets
Write-Host "🔐 Environment Secrets:" -ForegroundColor Yellow
& supabase secrets list --project-ref bdisppaxbvygsspcuymb

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "🧪 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Test at: https://www.akura.in/training-plan-builder.html" -ForegroundColor White
Write-Host "2. Click 'Connect Strava' button" -ForegroundColor White
Write-Host "3. Open DevTools Console (F12)" -ForegroundColor White
Write-Host "4. Check for:" -ForegroundColor White
Write-Host "   ✅ 'OAuth exchange successful'" -ForegroundColor Green
Write-Host "   ✅ 'Found existing Strava connection'" -ForegroundColor Green
Write-Host "   ✅ 'Loaded 908 activities from database'" -ForegroundColor Green
Write-Host "   ❌ NO 401 errors" -ForegroundColor Yellow
Write-Host ""
Write-Host "📊 Dashboard: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions" -ForegroundColor Cyan
Write-Host ""
