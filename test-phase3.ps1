# 🧪 SafeStride AI - Phase 3 Testing Script
# Complete API testing suite

param(
    [Parameter(Mandatory = $false)]
    [string]$ApiUrl = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OAuthUrl = ""
)

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SafeStride AI - Phase 3 Testing Suite" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get URLs if not provided
if ([string]::IsNullOrWhiteSpace($ApiUrl)) {
    Write-Host "Enter your Render service URLs:" -ForegroundColor Yellow
    Write-Host "(Find these in Render Dashboard → Services → Copy URL)" -ForegroundColor Gray
    Write-Host ""
    $ApiUrl = Read-Host "Main API URL (e.g., https://safestride-api-xxxx.onrender.com)"
    $OAuthUrl = Read-Host "OAuth URL (e.g., https://safestride-oauth-xxxx.onrender.com)"
}

# Remove trailing slashes
$ApiUrl = $ApiUrl.TrimEnd('/')
$OAuthUrl = $OAuthUrl.TrimEnd('/')

Write-Host ""
Write-Host "Testing against:" -ForegroundColor Yellow
Write-Host "  API: $ApiUrl" -ForegroundColor Cyan
Write-Host "  OAuth: $OAuthUrl" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2

$testResults = @()

# Test 1: Health Check
Write-Host "═══ Test 1: Health Check ═══" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$ApiUrl/health" -TimeoutSec 10
    Write-Host "✅ PASSED: Health check successful" -ForegroundColor Green
    Write-Host "   Status: $($health.status)" -ForegroundColor Gray
    Write-Host "   Timestamp: $($health.timestamp)" -ForegroundColor Gray
    $testResults += @{Test = "Health Check"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Health check failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Health Check"; Status = "FAILED" }
}
Write-Host ""

# Test 2: Create Athlete
Write-Host "═══ Test 2: Create Athlete ═══" -ForegroundColor Yellow
$testName = "Tester-$(Get-Date -Format 'HHmmss')"
$athleteData = @{
    name      = $testName
    age       = 32
    gender    = "M"
    weight_kg = 72
    height_cm = 178
    email     = "test-$testName@safestride.example"
} | ConvertTo-Json

try {
    $athlete = Invoke-RestMethod -Uri "$ApiUrl/athletes/signup" `
        -Method Post -ContentType "application/json" -Body $athleteData -TimeoutSec 30
    $athleteId = $athlete.athlete_id
    Write-Host "✅ PASSED: Athlete created successfully" -ForegroundColor Green
    Write-Host "   Athlete ID: $athleteId" -ForegroundColor Gray
    Write-Host "   Name: $testName" -ForegroundColor Gray
    $testResults += @{Test = "Create Athlete"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Athlete creation failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Create Athlete"; Status = "FAILED" }
    Write-Host ""
    Write-Host "⚠️  Cannot continue without athlete ID. Exiting." -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 3: Race Analysis
Write-Host "═══ Test 3: Race Analysis ═══" -ForegroundColor Yellow
$raceData = @{
    athlete_id          = $athleteId
    race_type           = "HALF_MARATHON"
    finish_time_seconds = 7800
    race_date           = "2026-01-15"
    heart_rate_avg      = 165
    splits              = @(
        @{distance_km = 5; time_seconds = 1850; pace_min_per_km = 6.17 }
        @{distance_km = 10; time_seconds = 1850; pace_min_per_km = 6.17 }
        @{distance_km = 15; time_seconds = 1900; pace_min_per_km = 6.33 }
        @{distance_km = 21.0975; time_seconds = 2300; pace_min_per_km = 6.28 }
    )
} | ConvertTo-Json -Depth 10

try {
    $race = Invoke-RestMethod -Uri "$ApiUrl/races/analyze" `
        -Method Post -ContentType "application/json" -Body $raceData -TimeoutSec 30
    Write-Host "✅ PASSED: Race analyzed successfully" -ForegroundColor Green
    Write-Host "   Classification: $($race.classification)" -ForegroundColor Gray
    Write-Host "   Pacing Score: $($race.pacing_consistency_score)/100" -ForegroundColor Gray
    Write-Host "   HR Efficiency: $($race.heart_rate_efficiency_score)/100" -ForegroundColor Gray
    Write-Host "   Recommended Timeline: $($race.recommended_weeks_to_goal) weeks" -ForegroundColor Gray
    $testResults += @{Test = "Race Analysis"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Race analysis failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Race Analysis"; Status = "FAILED" }
}
Write-Host ""

# Test 4: Fitness Assessment
Write-Host "═══ Test 4: Fitness Assessment ═══" -ForegroundColor Yellow
try {
    $fitness = Invoke-RestMethod -Uri "$ApiUrl/fitness/$athleteId" -TimeoutSec 30
    Write-Host "✅ PASSED: Fitness assessment completed" -ForegroundColor Green
    Write-Host "   Overall Score: $($fitness.overall_fitness_score)/100" -ForegroundColor Gray
    Write-Host "   Injury Risk: $($fitness.injury_risk_level)" -ForegroundColor Gray
    Write-Host "   Training Timeline: $($fitness.recommended_training_weeks) weeks" -ForegroundColor Gray
    Write-Host "   Foundation Needed: $($fitness.foundation_phase_needed)" -ForegroundColor Gray
    $testResults += @{Test = "Fitness Assessment"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Fitness assessment failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Fitness Assessment"; Status = "FAILED" }
}
Write-Host ""

# Test 5: Get Workouts
Write-Host "═══ Test 5: Get Workouts ═══" -ForegroundColor Yellow
try {
    $workouts = Invoke-RestMethod -Uri "$ApiUrl/workouts/$athleteId" -TimeoutSec 30
    Write-Host "✅ PASSED: Workouts retrieved successfully" -ForegroundColor Green
    Write-Host "   Total Workouts: $($workouts.Count)" -ForegroundColor Gray
    if ($workouts.Count -gt 0) {
        Write-Host "   First Workout:" -ForegroundColor Gray
        Write-Host "     - Type: $($workouts[0].workout_type)" -ForegroundColor Gray
        Write-Host "     - Distance: $($workouts[0].distance_km) km" -ForegroundColor Gray
        Write-Host "     - Date: $($workouts[0].scheduled_date)" -ForegroundColor Gray
    }
    $testResults += @{Test = "Get Workouts"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Workout retrieval failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Get Workouts"; Status = "FAILED" }
}
Write-Host ""

# Test 6: Get Ability Progression
Write-Host "═══ Test 6: Get Ability Progression ═══" -ForegroundColor Yellow
try {
    $ability = Invoke-RestMethod -Uri "$ApiUrl/ability/$athleteId" -TimeoutSec 30
    Write-Host "✅ PASSED: Ability progression retrieved" -ForegroundColor Green
    Write-Host "   Records Found: $($ability.Count)" -ForegroundColor Gray
    $testResults += @{Test = "Ability Progression"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Ability progression retrieval failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Ability Progression"; Status = "FAILED" }
}
Write-Host ""

# Test 7: Strava OAuth
Write-Host "═══ Test 7: Strava OAuth ═══" -ForegroundColor Yellow
try {
    $strava = Invoke-RestMethod -Uri "$OAuthUrl/strava/connect?athlete_id=$athleteId" -TimeoutSec 10
    Write-Host "✅ PASSED: OAuth URL generated" -ForegroundColor Green
    Write-Host "   Authorize URL: $($strava.authorize_url.Substring(0, 60))..." -ForegroundColor Gray
    $testResults += @{Test = "Strava OAuth"; Status = "PASSED" }
}
catch {
    Write-Host "❌ FAILED: Strava OAuth failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Strava OAuth"; Status = "FAILED" }
}
Write-Host ""

# Test Summary
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Test Results Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$passed = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count
$total = $testResults.Count

foreach ($result in $testResults) {
    if ($result.Status -eq "PASSED") {
        Write-Host "  ✅ $($result.Test)" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $($result.Test)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 All tests passed! Your backend is working correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Test mobile apps with beta testers" -ForegroundColor White
    Write-Host "  2. Monitor Render logs daily" -ForegroundColor White
    Write-Host "  3. Check Supabase metrics" -ForegroundColor White
    Write-Host "  4. Collect user feedback" -ForegroundColor White
    Write-Host ""
    Write-Host "Test Athlete Created:" -ForegroundColor Cyan
    Write-Host "  Athlete ID: $athleteId" -ForegroundColor White
    Write-Host "  Name: $testName" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host "⚠️  Some tests failed. Please review errors above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check Render service logs" -ForegroundColor White
    Write-Host "  2. Verify environment variables are set" -ForegroundColor White
    Write-Host "  3. Ensure Supabase connection is working" -ForegroundColor White
    Write-Host "  4. Review DEPLOYMENT_GUIDE.md troubleshooting section" -ForegroundColor White
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Save test results
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$resultsFile = "test-results-$timestamp.json"
$testResults | ConvertTo-Json | Out-File -FilePath $resultsFile
Write-Host "📄 Test results saved to: $resultsFile" -ForegroundColor Cyan
Write-Host ""

# Return exit code based on test results
if ($failed -eq 0) {
    exit 0
}
else {
    exit 1
}
