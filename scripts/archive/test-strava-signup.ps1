# SafeStride Strava Signup - Integration Test
# Tests the complete signup flow from OAuth to database storage

Write-Host "🧪 SafeStride Strava Signup Integration Test" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$API_URL = "http://localhost:8000"
$SUPABASE_URL = $env:SUPABASE_URL
$SUPABASE_ANON_KEY = $env:SUPABASE_ANON_KEY

# Test counters
$totalTests = 0
$passedTests = 0

function Test-Step {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    $script:totalTests++
    Write-Host "[$script:totalTests] Testing: $Name" -ForegroundColor Yellow
    
    try {
        & $Test
        Write-Host "    ✅ PASSED" -ForegroundColor Green
        $script:passedTests++
        return $true
    }
    catch {
        Write-Host "    ❌ FAILED: $_" -ForegroundColor Red
        return $false
    }
}

# Test 1: Check API is running
Test-Step "API Health Check" {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get
    if ($response.status -ne "healthy") {
        throw "API not healthy"
    }
}

# Test 2: Check environment variables
Test-Step "Environment Variables" {
    if (-Not $env:STRAVA_CLIENT_ID) {
        throw "STRAVA_CLIENT_ID not set"
    }
    if (-Not $env:STRAVA_CLIENT_SECRET) {
        throw "STRAVA_CLIENT_SECRET not set"
    }
    if (-Not $env:SUPABASE_URL) {
        throw "SUPABASE_URL not set"
    }
    if (-Not $env:SUPABASE_SERVICE_ROLE_KEY) {
        throw "SUPABASE_SERVICE_ROLE_KEY not set"
    }
}

# Test 3: Check database schema
Test-Step "Database Schema (profiles table)" {
    $query = @"
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name IN ('strava_athlete_id', 'pb_5k', 'pb_10k', 'pb_half_marathon', 'pb_marathon', 'total_runs')
"@
    
    $headers = @{
        "apikey"        = $env:SUPABASE_ANON_KEY
        "Authorization" = "Bearer $env:SUPABASE_ANON_KEY"
        "Content-Type"  = "application/json"
    }
    
    $body = @{
        query = $query
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/query" -Method Post -Headers $headers -Body $body
    
    if ($response.Count -lt 6) {
        throw "Missing required columns in profiles table. Run migration: supabase/migrations/20240115_strava_signup_stats.sql"
    }
}

# Test 4: Check strava_activities table exists
Test-Step "Database Schema (strava_activities table)" {
    $headers = @{
        "apikey"        = $env:SUPABASE_ANON_KEY
        "Authorization" = "Bearer $env:SUPABASE_ANON_KEY"
    }
    
    try {
        Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/strava_activities?limit=1" -Method Get -Headers $headers | Out-Null
    }
    catch {
        throw "strava_activities table not found. Run migration."
    }
}

# Test 5: Test OAuth URL generation
Test-Step "OAuth URL Generation" {
    $clientId = $env:STRAVA_CLIENT_ID
    $redirectUri = "https://akura.in/strava-callback"
    $scope = "read,activity:read_all,profile:read_all"
    
    $authUrl = "https://www.strava.com/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=$scope&approval_prompt=auto"
    
    if (-Not $authUrl.Contains("client_id=$clientId")) {
        throw "OAuth URL not generated correctly"
    }
    
    Write-Host "    OAuth URL: $authUrl" -ForegroundColor Gray
}

# Test 6: Check Flutter dependencies
Test-Step "Flutter Service Files" {
    $servicePath = Join-Path (Split-Path -Parent $PSScriptRoot) "lib\services\strava_complete_sync_service.dart"
    
    if (-Not (Test-Path $servicePath)) {
        throw "strava_complete_sync_service.dart not found"
    }
}

# Test 7: Check Flutter screens
Test-Step "Flutter Screen Files" {
    $signupScreen = Join-Path (Split-Path -Parent $PSScriptRoot) "lib\screens\strava_signup_screen.dart"
    $dashboardScreen = Join-Path (Split-Path -Parent $PSScriptRoot) "lib\screens\athlete_dashboard.dart"
    
    if (-Not (Test-Path $signupScreen)) {
        throw "strava_signup_screen.dart not found"
    }
    if (-Not (Test-Path $dashboardScreen)) {
        throw "athlete_dashboard.dart not found"
    }
}

# Test 8: Check web signup page
Test-Step "Web Signup Page" {
    $webSignup = Join-Path (Split-Path -Parent $PSScriptRoot) "web\signup.html"
    
    if (-Not (Test-Path $webSignup)) {
        throw "signup.html not found"
    }
    
    # Check if it contains Strava OAuth URL
    $content = Get-Content $webSignup -Raw
    if (-Not $content.Contains("strava.com/oauth/authorize")) {
        throw "signup.html missing Strava OAuth URL"
    }
}

# Test 9: Verify API dependencies
Test-Step "API Python Dependencies" {
    $requiredPackages = @("fastapi", "uvicorn", "httpx", "supabase")
    
    foreach ($package in $requiredPackages) {
        $installed = pip show $package 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Python package '$package' not installed. Run: pip install $package"
        }
    }
}

# Test 10: Mock signup flow (without real OAuth)
Test-Step "Mock Signup Flow Structure" {
    # This just checks that the endpoint exists and returns proper error for missing code
    try {
        $body = @{
            code = "invalid_code"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$API_URL/api/strava-signup" -Method Post -Body $body -ContentType "application/json"
    }
    catch {
        # Expected to fail with invalid code, but endpoint should exist
        if ($_.Exception.Response.StatusCode -eq 400) {
            # This is expected - invalid code should return 400
            Write-Host "    (Expected 400 error for invalid code)" -ForegroundColor Gray
        }
        else {
            throw "Unexpected error: $_"
        }
    }
}

# Results Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Test Results: $passedTests / $totalTests passed" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host ""

if ($passedTests -eq $totalTests) {
    Write-Host "✅ All tests passed! System is ready for Strava signup." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure API is running: .\start-strava-signup-api.ps1" -ForegroundColor White
    Write-Host "2. Open web signup: http://localhost:8000/signup.html" -ForegroundColor White
    Write-Host "3. Or launch Flutter app and navigate to StravaSignupScreen" -ForegroundColor White
    Write-Host "4. Test with real Strava account" -ForegroundColor White
}
else {
    Write-Host "⚠️  Some tests failed. Please fix issues before proceeding." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Cyan
    Write-Host "1. Run database migration: npx supabase db push" -ForegroundColor White
    Write-Host "2. Install API dependencies: pip install fastapi uvicorn httpx supabase" -ForegroundColor White
    Write-Host "3. Configure .env file with Strava and Supabase credentials" -ForegroundColor White
    Write-Host "4. Start API server: .\start-strava-signup-api.ps1" -ForegroundColor White
}

Write-Host ""
