# Test All AI Agent Endpoints
# Run this after deploying DEPLOY_ALL_TABLES.sql

$baseUrl = "http://127.0.0.1:8001"
$athleteId = "33308fc1-3545-431d-a5e7-648b52e1866c"  # Muthulakshmi

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTING AI AGENT ENDPOINTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: List Athletes
Write-Host "TEST 1: List Athletes..." -ForegroundColor Yellow
try {
    $body = @{goal = "list_athletes" } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$baseUrl/agent/commander" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ SUCCESS: Found $($result.result.Count) athletes" -ForegroundColor Green
    Write-Host "Athletes: $($result.result.full_name -join ', ')" -ForegroundColor Gray
}
catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Predict Injury Risk
Write-Host "`nTEST 2: Predict Injury Risk..." -ForegroundColor Yellow
try {
    $body = @{athlete_id = $athleteId } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$baseUrl/agent/predict-injury-risk" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  Risk Level: $($result.risk_level)" -ForegroundColor Gray
    Write-Host "  Risk Score: $($result.risk_score)" -ForegroundColor Gray
    Write-Host "  AISRI Score: $($result.latest_aisri_score)" -ForegroundColor Gray
    Write-Host "  Recommendation: $($result.recommendation)" -ForegroundColor Gray
}
catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Autonomous Decision
Write-Host "`nTEST 3: Autonomous Decision..." -ForegroundColor Yellow
try {
    $body = @{athlete_id = $athleteId } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$baseUrl/agent/autonomous-decision" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  Decision: $($result.decision)" -ForegroundColor Gray
    Write-Host "  Reason: $($result.reason)" -ForegroundColor Gray
    Write-Host "  AISRI: $($result.aisri_score)" -ForegroundColor Gray
    Write-Host "  Injury Risk: $($result.injury_risk)" -ForegroundColor Gray
    Write-Host "  Training Load: $($result.training_load)" -ForegroundColor Gray
}
catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Predict Performance
Write-Host "`nTEST 4: Predict Performance..." -ForegroundColor Yellow
try {
    $body = @{athlete_id = $athleteId } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$baseUrl/agent/predict-performance" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  VO2max: $($result.vo2max)" -ForegroundColor Gray
    Write-Host "  5K: $($result.predictions.predicted_5k)" -ForegroundColor Gray
    Write-Host "  10K: $($result.predictions.predicted_10k)" -ForegroundColor Gray
    Write-Host "  Half Marathon: $($result.predictions.predicted_half_marathon)" -ForegroundColor Gray
    Write-Host "  Marathon: $($result.predictions.predicted_marathon)" -ForegroundColor Gray
}
catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Generate Workout
Write-Host "`nTEST 5: Generate Workout..." -ForegroundColor Yellow
try {
    $body = @{
        athlete_id = $athleteId
        goal       = "endurance"
        duration   = "45"
    } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$baseUrl/agent/generate-workout" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  Type: $($result.workout_type)" -ForegroundColor Gray
    Write-Host "  Duration: $($result.duration_minutes) minutes" -ForegroundColor Gray
    Write-Host "  Description: $($result.description.Substring(0, [Math]::Min(80, $result.description.Length)))..." -ForegroundColor Gray
}
catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Generate Training Plan
Write-Host "`nTEST 6: Generate Training Plan..." -ForegroundColor Yellow
try {
    $body = @{
        athlete_id = $athleteId
        goal       = "marathon"
        weeks      = 1
    } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$baseUrl/agent/generate-training-plan" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  Plan ID: $($result.plan_id)" -ForegroundColor Gray
    Write-Host "  Workouts: $($result.workouts.Count) days" -ForegroundColor Gray
    Write-Host "  Status: $($result.message)" -ForegroundColor Gray
}
catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTING COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
