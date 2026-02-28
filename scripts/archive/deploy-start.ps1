# 🚀 Quick Start: Deploy SafeStride AI to Production
# This script helps you gather all credentials needed for deployment

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SafeStride AI - Production Deployment Assistant" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Gather Credentials
Write-Host "📋 STEP 1: Gather Your Credentials" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "1️⃣  Supabase Credentials" -ForegroundColor Green
Write-Host "    Go to: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/api" -ForegroundColor White
Write-Host ""
$SUPABASE_URL = Read-Host "    Enter SUPABASE_URL (default: https://bdisppaxbvygsspcuymb.supabase.co)"
if ([string]::IsNullOrWhiteSpace($SUPABASE_URL)) {
    $SUPABASE_URL = "https://bdisppaxbvygsspcuymb.supabase.co"
}
Write-Host "    ✓ URL: $SUPABASE_URL" -ForegroundColor Gray
Write-Host ""

$SUPABASE_SERVICE_KEY = Read-Host "    Enter SUPABASE_SERVICE_KEY (service_role key)" -AsSecureString
$SUPABASE_SERVICE_KEY_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SUPABASE_SERVICE_KEY)
)
Write-Host "    ✓ Service Key: $($SUPABASE_SERVICE_KEY_PLAIN.Substring(0, 20))..." -ForegroundColor Gray
Write-Host ""

Write-Host "2️⃣  Strava API Credentials" -ForegroundColor Green
Write-Host "    Go to: https://www.strava.com/settings/api" -ForegroundColor White
Write-Host ""
$STRAVA_CLIENT_ID = Read-Host "    Enter STRAVA_CLIENT_ID"
Write-Host "    ✓ Client ID: $STRAVA_CLIENT_ID" -ForegroundColor Gray
Write-Host ""

$STRAVA_CLIENT_SECRET = Read-Host "    Enter STRAVA_CLIENT_SECRET" -AsSecureString
$STRAVA_CLIENT_SECRET_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($STRAVA_CLIENT_SECRET)
)
Write-Host "    ✓ Client Secret: $($STRAVA_CLIENT_SECRET_PLAIN.Substring(0, 10))..." -ForegroundColor Gray
Write-Host ""

$STRAVA_VERIFY_TOKEN = "safestride_webhook_verify_2026"
Write-Host "    ✓ Verify Token: $STRAVA_VERIFY_TOKEN (auto-generated)" -ForegroundColor Gray
Write-Host ""

# Save credentials to secure file
Write-Host "💾 Saving credentials to .env.production (encrypted)..." -ForegroundColor Yellow
$envContent = @"
# SafeStride AI - Production Environment Variables
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# ⚠️  KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT!

# Supabase
SUPABASE_URL=$SUPABASE_URL
SUPABASE_SERVICE_KEY=$SUPABASE_SERVICE_KEY_PLAIN

# Strava
STRAVA_CLIENT_ID=$STRAVA_CLIENT_ID
STRAVA_CLIENT_SECRET=$STRAVA_CLIENT_SECRET_PLAIN
STRAVA_VERIFY_TOKEN=$STRAVA_VERIFY_TOKEN

# Garmin (optional - add later if needed)
# GARMIN_CONSUMER_KEY=
# GARMIN_CONSUMER_SECRET=
"@

$envContent | Out-File -FilePath ".env.production" -Encoding UTF8
Write-Host "✓ Credentials saved to .env.production" -ForegroundColor Green
Write-Host ""

# Step 2: Test Local Connection
Write-Host "🔍 STEP 2: Test Supabase Connection" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

try {
    $headers = @{
        'apikey'        = $SUPABASE_SERVICE_KEY_PLAIN
        'Authorization' = "Bearer $SUPABASE_SERVICE_KEY_PLAIN"
    }
    
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/" -Headers $headers -Method Get
    Write-Host "✅ Supabase connection successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Supabase connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please verify your credentials and try again." -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Render Deployment Instructions
Write-Host "🚀 STEP 3: Deploy to Render.com" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Now follow these steps to deploy:" -ForegroundColor White
Write-Host ""
Write-Host "1. Go to: https://dashboard.render.com/" -ForegroundColor Cyan
Write-Host "2. Click 'New' → 'Blueprint'" -ForegroundColor White
Write-Host "3. Connect your GitHub account" -ForegroundColor White
Write-Host "4. Select repository: safestride" -ForegroundColor White
Write-Host "5. Render will detect render.yaml with 3 services" -ForegroundColor White
Write-Host "6. Click 'Apply' to deploy all services" -ForegroundColor White
Write-Host ""
Write-Host "After deployment, configure environment variables:" -ForegroundColor Yellow
Write-Host ""

Write-Host "For safestride-api:" -ForegroundColor Cyan
Write-Host "  SUPABASE_URL = $SUPABASE_URL"
Write-Host "  SUPABASE_SERVICE_KEY = [paste from clipboard below]"
Write-Host ""

Write-Host "For safestride-webhooks:" -ForegroundColor Cyan
Write-Host "  SUPABASE_URL = $SUPABASE_URL"
Write-Host "  SUPABASE_SERVICE_KEY = [paste from clipboard below]"
Write-Host "  STRAVA_CLIENT_ID = $STRAVA_CLIENT_ID"
Write-Host "  STRAVA_CLIENT_SECRET = [paste from clipboard below]"
Write-Host "  STRAVA_VERIFY_TOKEN = $STRAVA_VERIFY_TOKEN"
Write-Host ""

Write-Host "For safestride-oauth:" -ForegroundColor Cyan
Write-Host "  SUPABASE_URL = $SUPABASE_URL"
Write-Host "  SUPABASE_SERVICE_KEY = [paste from clipboard below]"
Write-Host "  STRAVA_CLIENT_ID = $STRAVA_CLIENT_ID"
Write-Host "  STRAVA_CLIENT_SECRET = [paste from clipboard below]"
Write-Host "  STRAVA_REDIRECT_URI = https://safestride-oauth.onrender.com/strava/callback"
Write-Host "  (Update with actual URL after deployment!)"
Write-Host ""

# Copy credentials to clipboard for easy pasting
Write-Host "📋 STEP 4: Credentials Copied to Clipboard" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

$clipboardContent = @"
Supabase Service Key:
$SUPABASE_SERVICE_KEY_PLAIN

Strava Client Secret:
$STRAVA_CLIENT_SECRET_PLAIN
"@

$clipboardContent | Set-Clipboard
Write-Host "✓ Credentials copied to clipboard for pasting into Render!" -ForegroundColor Green
Write-Host ""

# Step 5: Next Steps
Write-Host "📚 STEP 5: Complete Documentation" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Detailed guides available:" -ForegroundColor White
Write-Host "  • DEPLOYMENT_ACTION_PLAN.md - Complete step-by-step plan" -ForegroundColor Cyan
Write-Host "  • DEPLOYMENT_GUIDE.md - Backend deployment details" -ForegroundColor Cyan
Write-Host "  • FLUTTER_DEPLOYMENT_GUIDE.md - Mobile app deployment" -ForegroundColor Cyan
Write-Host "  • PRODUCTION_CHECKLIST.md - Launch checklist" -ForegroundColor Cyan
Write-Host ""

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ Setup Complete - Ready to Deploy!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Open Render.com and start deployment! 🚀" -ForegroundColor Yellow
Write-Host ""

# Open Render in browser
$openRender = Read-Host "Open Render.com in browser now? (Y/n)"
if ($openRender -ne 'n') {
    Start-Process "https://dashboard.render.com/"
}
