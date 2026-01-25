Write-Host "SafeStride Frontend Testing" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test 1: Open homepage
Write-Host "`nTEST 1: Opening homepage..." -ForegroundColor Yellow
Start-Process "http://localhost:5173/"
Start-Sleep -Seconds 2

# Test 2: Test login page
Write-Host "TEST 2: Testing /login..." -ForegroundColor Yellow
Start-Process "http://localhost:5173/login"
Start-Sleep -Seconds 1

# Test 3: Test signup page
Write-Host "TEST 3: Testing /signup..." -ForegroundColor Yellow
Start-Process "http://localhost:5173/signup"
Start-Sleep -Seconds 1

# Test 4: Test protected routes
Write-Host "TEST 4: Testing /coach/dashboard..." -ForegroundColor Yellow
Start-Process "http://localhost:5173/coach/dashboard"
Start-Sleep -Seconds 1

Write-Host "TEST 5: Testing /athlete/dashboard..." -ForegroundColor Yellow
Start-Process "http://localhost:5173/athlete/dashboard"
Start-Sleep -Seconds 1

Write-Host "TEST 6: Testing /athlete/devices..." -ForegroundColor Yellow
Start-Process "http://localhost:5173/athlete/devices"
Start-Sleep -Seconds 1

# Test backend API
Write-Host "`nBACKEND API TESTS" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

Write-Host "TEST 7: Health check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/api/health"
    Write-Host "Health check:" -ForegroundColor Green
    $health | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Health check failed: $_" -ForegroundColor Red
}

Write-Host "TEST 8: Athlete endpoint (protected)..." -ForegroundColor Yellow
try {
    $athlete = Invoke-RestMethod -Uri "http://localhost:3000/api/athlete"
    Write-Host "Athlete endpoint:" -ForegroundColor Green
    $athlete | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Athlete endpoint failed (expected without token): $_" -ForegroundColor Red
}

Write-Host "" -ForegroundColor Green
Write-Host "Testing script finished. Check opened browser tabs for UI results." -ForegroundColor Green
