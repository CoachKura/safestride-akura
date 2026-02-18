$url = "https://xzxnnswggwqtctcgpocr.supabase.co"
$key = "sb_publishable_Zyucm83AmvswhLn5nIWLTw_wQQxpEVz"

$headers = @{
    "apikey" = $key
    "Authorization" = "Bearer $key"
}

$tables = @('profiles', 'athlete_goals', 'structured_workouts', 'strava_connections', 'strava_activities', 'garmin_connections', 'garmin_activities')

Write-Host ""
Write-Host " VERIFYING SAFESTRIDE DATABASE TABLES..." -ForegroundColor Cyan
Write-Host ("=" * 50)

$found = 0
foreach ($table in $tables) {
    try {
        $null = Invoke-RestMethod -Uri "$url/rest/v1/$table`?select=id&limit=0" -Headers $headers -ErrorAction Stop
        Write-Host " $table" -ForegroundColor Green
        $found++
    } catch {
        Write-Host " $table (NOT FOUND)" -ForegroundColor Red
    }
}

Write-Host ("=" * 50)
if ($found -eq 7) {
    Write-Host " SUCCESS: All $found of 7 tables exist!" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Only $found of 7 tables found" -ForegroundColor Yellow
}
Write-Host ""
