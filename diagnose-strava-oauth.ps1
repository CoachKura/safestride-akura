# Strava OAuth Diagnostics
# Checks Supabase Edge Function configuration and tests the OAuth flow

Write-Host "🔍 Strava OAuth Diagnostic Tool" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$SUPABASE_URL = "https://bdisppaxbvygsspcuymb.supabase.co"
$SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNDY4NDQsImV4cCI6MjA4NjgyMjg0NH0.bjgoVhVboDQTmIPe_A5_4yiWvTBvckVtw88lQ7GWFrc"

Write-Host "1️⃣ Checking Supabase Edge Function status..." -ForegroundColor Yellow
try {
    $headers = @{
        "apikey"        = $SUPABASE_ANON_KEY
        "Authorization" = "Bearer $SUPABASE_ANON_KEY"
    }
    
    # Test if edge function exists (OPTIONS request)
    $optionsResponse = Invoke-WebRequest `
        -Uri "$SUPABASE_URL/functions/v1/strava-oauth" `
        -Method OPTIONS `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    Write-Host "   ✅ Edge function 'strava-oauth' is deployed" -ForegroundColor Green
    Write-Host "   Status: $($optionsResponse.StatusCode)" -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ Edge function not found or not deployed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   📝 To deploy:" -ForegroundColor Yellow
    Write-Host "      cd supabase/functions/strava-oauth" -ForegroundColor Gray
    Write-Host "      supabase functions deploy strava-oauth" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "2️⃣ Checking required environment secrets..." -ForegroundColor Yellow
Write-Host "   ⚠️  Cannot check secrets remotely - verify in Supabase Dashboard" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Required secrets:" -ForegroundColor Cyan
Write-Host "   • STRAVA_CLIENT_ID" -ForegroundColor White
Write-Host "   • STRAVA_CLIENT_SECRET" -ForegroundColor White
Write-Host "   • SUPABASE_URL" -ForegroundColor White
Write-Host "   • SUPABASE_ANON_KEY" -ForegroundColor White
Write-Host ""
Write-Host "   📝 To set secrets:" -ForegroundColor Yellow
Write-Host "      supabase secrets set STRAVA_CLIENT_ID=162971" -ForegroundColor Gray
Write-Host "      supabase secrets set STRAVA_CLIENT_SECRET=your_secret_here" -ForegroundColor Gray

Write-Host ""
Write-Host "3️⃣ Checking database table 'strava_connections'..." -ForegroundColor Yellow
try {
    $headers = @{
        "apikey"        = $SUPABASE_ANON_KEY
        "Authorization" = "Bearer $SUPABASE_ANON_KEY"
        "Content-Type"  = "application/json"
    }
    
    # Try to query the table (limit 0 to avoid data, just check existence)
    $tableResponse = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/strava_connections?limit=0" `
        -Method GET `
        -Headers $headers `
        -ErrorAction Stop
    
    Write-Host "   ✅ Table 'strava_connections' exists and is accessible" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Table 'strava_connections' not found or not accessible" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   📝 To create table, run this SQL in Supabase SQL Editor:" -ForegroundColor Yellow
    Write-Host "   CREATE TABLE strava_connections (" -ForegroundColor Gray
    Write-Host "       id UUID PRIMARY KEY DEFAULT gen_random_uuid()," -ForegroundColor Gray
    Write-Host "       athlete_id TEXT UNIQUE NOT NULL," -ForegroundColor Gray
    Write-Host "       strava_athlete_id BIGINT," -ForegroundColor Gray
    Write-Host "       access_token TEXT NOT NULL," -ForegroundColor Gray
    Write-Host "       refresh_token TEXT NOT NULL," -ForegroundColor Gray
    Write-Host "       expires_at TIMESTAMPTZ NOT NULL," -ForegroundColor Gray
    Write-Host "       athlete_data JSONB," -ForegroundColor Gray
    Write-Host "       created_at TIMESTAMPTZ DEFAULT NOW()," -ForegroundColor Gray
    Write-Host "       updated_at TIMESTAMPTZ DEFAULT NOW()" -ForegroundColor Gray
    Write-Host "   );" -ForegroundColor Gray
}

Write-Host ""
Write-Host "4️⃣ Testing edge function with mock request..." -ForegroundColor Yellow
try {
    $testBody = @{
        code      = "test_code_12345"
        athleteId = "test_athlete_diagnostic"
    } | ConvertTo-Json
    
    $headers = @{
        "apikey"        = $SUPABASE_ANON_KEY
        "Authorization" = "Bearer $SUPABASE_ANON_KEY"
        "Content-Type"  = "application/json"
    }
    
    # This will fail with invalid code, but we can see the error message
    $testResponse = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/functions/v1/strava-oauth" `
        -Method POST `
        -Headers $headers `
        -Body $testBody `
        -ErrorAction Stop
    
    Write-Host "   ⚠️  Unexpected success with test code" -ForegroundColor Yellow
}
catch {
    $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
    
    if ($errorDetails.error -match "Strava token exchange failed") {
        Write-Host "   ✅ Edge function is working correctly" -ForegroundColor Green
        Write-Host "   Response: $($errorDetails.error)" -ForegroundColor Gray
        Write-Host "   (This error is expected - it means the function can contact Strava)" -ForegroundColor Gray
    }
    elseif ($errorDetails.error -match "client_id") {
        Write-Host "   ❌ STRAVA_CLIENT_ID secret is missing or invalid" -ForegroundColor Red
        Write-Host "   Error: $($errorDetails.error)" -ForegroundColor Gray
    }
    elseif ($errorDetails.error -match "client_secret") {
        Write-Host "   ❌ STRAVA_CLIENT_SECRET secret is missing or invalid" -ForegroundColor Red
        Write-Host "   Error: $($errorDetails.error)" -ForegroundColor Gray
    }
    else {
        Write-Host "   ⚠️  Unexpected error" -ForegroundColor Yellow
        Write-Host "   Error: $($errorDetails.error)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "If you see errors above:" -ForegroundColor Cyan
Write-Host "1. Deploy edge function: supabase functions deploy strava-oauth" -ForegroundColor White
Write-Host "2. Set required secrets in Supabase Dashboard or CLI" -ForegroundColor White
Write-Host "3. Ensure strava_connections table exists" -ForegroundColor White
Write-Host "4. Check Supabase Edge Function logs for detailed errors" -ForegroundColor White
Write-Host ""
Write-Host "To view edge function logs:" -ForegroundColor Cyan
Write-Host "  supabase functions logs strava-oauth --tail" -ForegroundColor White
Write-Host ""
Write-Host "To test Strava OAuth in browser:" -ForegroundColor Cyan
Write-Host "  http://localhost:64109/training-plan-builder.html" -ForegroundColor White
Write-Host ""
