# AI Workout Integration Test Script
# Tests the Python backend and displays workout generation

Write-Host "🧪 Testing AI Workout Integration" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if Python server is running
Write-Host "1️⃣ Checking Python FastAPI server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8001/" -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ Server is running (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Server is not running. Please start it with:" -ForegroundColor Red
    Write-Host "      cd ai_agents; python -m uvicorn main:app --reload --port 8001" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Test 2: Test generate-workout endpoint with sample athlete
Write-Host "2️⃣ Testing workout generation endpoint..." -ForegroundColor Yellow
try {
    $body = @{
        athlete_id = "33308fc1-3545-431d-a5e7-648b52e1866c"
    } | ConvertTo-Json

    $result = Invoke-RestMethod -Uri "http://localhost:8001/agent/generate-workout" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -ErrorAction Stop

    if ($result.status -eq "success") {
        Write-Host "   ✅ Workout generated successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "   📊 Results:" -ForegroundColor Cyan
        Write-Host "   ========================================" -ForegroundColor Gray
        Write-Host "   Athlete ID:   $($result.athlete_id)" -ForegroundColor White
        Write-Host "   AISRI Score:  $($result.aisri_score)" -ForegroundColor White
        Write-Host "   Training Zone: $($result.zone)" -ForegroundColor White
        Write-Host ""
        Write-Host "   Workout Name: $($result.workout.name)" -ForegroundColor Yellow
        Write-Host "   Duration:     $($result.workout.duration) minutes" -ForegroundColor White
        Write-Host "   Intensity:    $($result.workout.intensity)" -ForegroundColor White
        Write-Host "   Description:  $($result.workout.description)" -ForegroundColor Gray
        Write-Host "   ========================================" -ForegroundColor Gray
    }
    else {
        Write-Host "   ❌ Failed: $($result.message)" -ForegroundColor Red
    }
}
catch {
    Write-Host "   ❌ Error calling endpoint: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Check Flutter service file
Write-Host "3️⃣ Checking Flutter service..." -ForegroundColor Yellow
if (Test-Path "lib\services\workout_ai_service.dart") {
    Write-Host "   ✅ workout_ai_service.dart exists" -ForegroundColor Green
}
else {
    Write-Host "   ❌ workout_ai_service.dart not found" -ForegroundColor Red
}

Write-Host ""

# Test 4: Check dashboard integration
Write-Host "4️⃣ Checking dashboard integration..." -ForegroundColor Yellow
$dashboardContent = Get-Content "lib\screens\dashboard_screen.dart" -Raw
if ($dashboardContent -match "_generateAIWorkout" -and 
    $dashboardContent -match "WorkoutAIService" -and
    $dashboardContent -match "floatingActionButton") {
    Write-Host "   ✅ Dashboard has AI workout buttons (FAB + Quick Actions)" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Dashboard integration incomplete" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Integration Test Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 To test in the app:" -ForegroundColor Yellow
Write-Host "   1. Run: flutter run -d chrome" -ForegroundColor Gray
Write-Host "   2. Log in to the app" -ForegroundColor Gray
Write-Host "   3. Go to Dashboard" -ForegroundColor Gray
Write-Host "   4. Click the purple 'Generate AI Workout' button" -ForegroundColor Gray
Write-Host "   5. Or click the green FAB (bottom-right)" -ForegroundColor Gray
Write-Host "   6. You will see a success notification with workout details" -ForegroundColor Gray
Write-Host ""
