# Quick script to help copy Supabase API keys
# This will open the Supabase API settings page

Write-Host "`n📋 SUPABASE API KEYS NEEDED`n" -ForegroundColor Cyan

Write-Host "Opening Supabase API Settings page..." -ForegroundColor Yellow
Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/settings/api"

Write-Host "`nIn the Supabase dashboard, copy these two keys:`n" -ForegroundColor Green

Write-Host "1. Project API keys section:" -ForegroundColor White
Write-Host "   - Find 'anon' 'public' key (click the copy icon)" -ForegroundColor Gray
Write-Host "   - Find 'service_role' key (click the copy icon)" -ForegroundColor Gray
Write-Host ""

Write-Host "⚠️  IMPORTANT: The service_role key is SECRET - don't share it!" -ForegroundColor Red
Write-Host ""

# Wait for user
Read-Host "Press Enter once you've copied the anon key"

Write-Host "`nPaste the anon/public key here (starts with eyJ...):" -ForegroundColor Yellow
$anonKey = Read-Host

Write-Host "`nNow copy the service_role key from the dashboard" -ForegroundColor Yellow
Read-Host "Press Enter once you've copied the service_role key"

Write-Host "`nPaste the service_role key here (starts with eyJ...):" -ForegroundColor Yellow
$serviceKey = Read-Host

# Read current .env file
$envPath = "ai_agents\.env"
$envContent = Get-Content $envPath -Raw

# Replace the placeholder keys
$envContent = $envContent -replace 'SUPABASE_ANON_KEY=.*', "SUPABASE_ANON_KEY=$anonKey"
$envContent = $envContent -replace 'SUPABASE_SERVICE_ROLE_KEY=.*', "SUPABASE_SERVICE_ROLE_KEY=$serviceKey"

# Save back
$envContent | Set-Content $envPath -NoNewline

Write-Host "`n✅ Supabase keys updated in .env file!" -ForegroundColor Green
Write-Host ""

# Now ask for Strava
Write-Host "Do you also want to set up Strava credentials? (y/n): " -ForegroundColor Cyan -NoNewline
$setupStrava = Read-Host

if ($setupStrava -eq 'y') {
    Write-Host "`nOpening Strava API settings..." -ForegroundColor Yellow
    Start-Process "https://www.strava.com/settings/api"
    
    Write-Host "`nIn Strava settings:" -ForegroundColor Green
    Write-Host "   1. Find your application (Client ID: 162971)" -ForegroundColor Gray
    Write-Host "   2. Click 'show' next to Client Secret" -ForegroundColor Gray
    Write-Host "   3. Copy the Client Secret" -ForegroundColor Gray
    Write-Host ""
    
    Read-Host "Press Enter once you've copied the Client Secret"
    
    Write-Host "`nPaste the Strava Client Secret:" -ForegroundColor Yellow
    $stravaSecret = Read-Host
    
    # Read updated .env file
    $envContent = Get-Content $envPath -Raw
    $envContent = $envContent -replace 'STRAVA_CLIENT_SECRET=.*', "STRAVA_CLIENT_SECRET=$stravaSecret"
    $envContent | Set-Content $envPath -NoNewline
    
    Write-Host "`n✅ Strava credentials updated!" -ForegroundColor Green
}

Write-Host "`n🚀 All set! Now run:" -ForegroundColor Cyan
Write-Host "   python ai_agents/strava_signup_api.py" -ForegroundColor White
Write-Host ""
