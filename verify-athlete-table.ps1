# Quick verification script for athlete_profiles table

Write-Host "`n🔍 VERIFICATION CHECKLIST" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

Write-Host "`n1️⃣  Open Supabase Dashboard:" -ForegroundColor Yellow
Write-Host "   https://app.supabase.com/project/bdisppaxbvygsspcuymb/editor" -ForegroundColor White

Write-Host "`n2️⃣  Go to SQL Editor and run this query:" -ForegroundColor Yellow
Write-Host @"
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'athlete_profiles'
   ORDER BY ordinal_position;
"@ -ForegroundColor Gray

Write-Host "`n3️⃣  Expected columns (should see all 15):" -ForegroundColor Yellow
$expectedColumns = @(
    "id (uuid)",
    "athlete_id (text)",
    "name (text)",
    "email (text)",
    "age (integer)",
    "resting_hr (integer)",
    "weekly_distance (numeric)",
    "pillars (jsonb)",
    "rom_tests (jsonb) 👈 NEW",
    "aisri_score (integer) 👈 NEW",
    "risk_category (text) 👈 NEW",
    "predicted_stride_length (numeric) 👈 NEW",
    "predicted_cadence (integer) 👈 NEW",
    "predicted_vertical_oscillation (numeric) 👈 NEW",
    "has_strava (boolean)",
    "strava_athlete_id (text) 👈 NEW",
    "created_at (timestamp)",
    "updated_at (timestamp)"
)

foreach ($col in $expectedColumns) {
    Write-Host "   ✓ $col" -ForegroundColor Gray
}

Write-Host "`n4️⃣  Test the signup form:" -ForegroundColor Yellow
Write-Host "   http://localhost:64109/athlete-signup.html" -ForegroundColor White

Write-Host "`n5️⃣  After submitting test data, verify in Table Editor:" -ForegroundColor Yellow
Write-Host "   Check if new row appears in athlete_profiles table" -ForegroundColor Gray

Write-Host "`n✨ If all checks pass, you're ready to go!" -ForegroundColor Green
Write-Host ""
