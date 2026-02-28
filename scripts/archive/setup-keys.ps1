Write-Host ""
Write-Host "SUPABASE API KEYS SETUP" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening Supabase API Settings page..." -ForegroundColor Yellow
Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/settings/api"

Write-Host ""
Write-Host "In the Supabase dashboard, copy these two keys:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Project API keys section:" -ForegroundColor White
Write-Host "   - Find 'anon' 'public' key (click the copy icon)" -ForegroundColor Gray
Write-Host "   - Find 'service_role' key (click the copy icon)" -ForegroundColor Gray
Write-Host ""
Write-Host "WARNING: The service_role key is SECRET - do not share it!" -ForegroundColor Red
Write-Host ""

Read-Host "Press Enter once you have copied the anon key"

Write-Host ""
Write-Host "Paste the anon/public key here (starts with eyJ...):" -ForegroundColor Yellow
$anonKey = Read-Host

Write-Host ""
Write-Host "Now copy the service_role key from the dashboard" -ForegroundColor Yellow
Read-Host "Press Enter once you have copied the service_role key"

Write-Host ""
Write-Host "Paste the service_role key here (starts with eyJ...):" -ForegroundColor Yellow
$serviceKey = Read-Host

$envPath = "ai_agents\.env"
$envContent = Get-Content $envPath -Raw

$envContent = $envContent -replace 'SUPABASE_ANON_KEY=.*', "SUPABASE_ANON_KEY=$anonKey"
$envContent = $envContent -replace 'SUPABASE_SERVICE_ROLE_KEY=.*', "SUPABASE_SERVICE_ROLE_KEY=$serviceKey"

$envContent | Set-Content $envPath -NoNewline

Write-Host ""
Write-Host "SUCCESS: Supabase keys updated in .env file!" -ForegroundColor Green
Write-Host ""

Write-Host "Do you also want to set up Strava credentials? (y/n): " -ForegroundColor Cyan -NoNewline
$setupStrava = Read-Host

if ($setupStrava -eq 'y') {
    Write-Host ""
    Write-Host "Opening Strava API settings..." -ForegroundColor Yellow
    Start-Process "https://www.strava.com/settings/api"
    
    Write-Host ""
    Write-Host "In Strava settings:" -ForegroundColor Green
    Write-Host "   1. Find your application (Client ID: 162971)" -ForegroundColor Gray
    Write-Host "   2. Click 'show' next to Client Secret" -ForegroundColor Gray
    Write-Host "   3. Copy the Client Secret" -ForegroundColor Gray
    Write-Host ""
    
    Read-Host "Press Enter once you have copied the Client Secret"
    
    Write-Host ""
    Write-Host "Paste the Strava Client Secret:" -ForegroundColor Yellow
    $stravaSecret = Read-Host
    
    $envContent = Get-Content $envPath -Raw
    $envContent = $envContent -replace 'STRAVA_CLIENT_SECRET=.*', "STRAVA_CLIENT_SECRET=$stravaSecret"
    $envContent | Set-Content $envPath -NoNewline
    
    Write-Host ""
    Write-Host "SUCCESS: Strava credentials updated!" -ForegroundColor Green
}

Write-Host ""
Write-Host "All set! Now run:" -ForegroundColor Cyan
Write-Host "python ai_agents/strava_signup_api.py" -ForegroundColor White
Write-Host ""
