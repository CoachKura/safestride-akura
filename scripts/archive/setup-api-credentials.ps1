# Get Supabase and Strava credentials for .env file
# Run this script and follow the instructions

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   SafeStride - API Credentials Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "You need to get the following credentials:`n" -ForegroundColor Yellow

Write-Host "1. SUPABASE CREDENTIALS" -ForegroundColor Green
Write-Host "   Go to: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/settings/api" -ForegroundColor Gray
Write-Host "   Copy these values:" -ForegroundColor White
Write-Host "   - Project URL (already set: https://bdisppaxbvygsspcuymb.supabase.co)" -ForegroundColor Gray
Write-Host "   - anon/public key (starts with 'eyJ...')" -ForegroundColor White
Write-Host "   - service_role key (starts with 'eyJ...') ⚠️ This is secret!" -ForegroundColor White
Write-Host ""

Write-Host "2. STRAVA API CREDENTIALS" -ForegroundColor Green
Write-Host "   Go to: https://www.strava.com/settings/api" -ForegroundColor Gray
Write-Host "   Your app should already exist:" -ForegroundColor White
Write-Host "   - Application Name: SafeStride" -ForegroundColor Gray
Write-Host "   - Client ID: 162971 (already in .env)" -ForegroundColor Gray
Write-Host "   Copy:" -ForegroundColor White
Write-Host "   - Client Secret (will show when you reveal it)" -ForegroundColor White
Write-Host "   Update Authorization Callback Domain to: localhost" -ForegroundColor White
Write-Host ""

Write-Host "3. UPDATE .env FILE" -ForegroundColor Green
Write-Host "   File location: ai_agents\.env" -ForegroundColor Gray
Write-Host "   Update these lines:" -ForegroundColor White
Write-Host "   SUPABASE_ANON_KEY=<paste anon key>" -ForegroundColor Yellow
Write-Host "   SUPABASE_SERVICE_ROLE_KEY=<paste service_role key>" -ForegroundColor Yellow
Write-Host "   STRAVA_CLIENT_SECRET=<paste client secret>" -ForegroundColor Yellow
Write-Host ""

# Offer to open URLs
$openSupabase = Read-Host "Open Supabase API settings? (y/n)"
if ($openSupabase -eq 'y') {
    Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/settings/api"
}

$openStrava = Read-Host "Open Strava API settings? (y/n)"
if ($openStrava -eq 'y') {
    Start-Process "https://www.strava.com/settings/api"
}

$openEnvFile = Read-Host "Open .env file for editing? (y/n)"
if ($openEnvFile -eq 'y') {
    code ai_agents\.env
}

Write-Host "`n✅ Once you've updated the .env file, run:" -ForegroundColor Green
Write-Host "   python ai_agents/strava_signup_api.py" -ForegroundColor Cyan
Write-Host ""
