# AUTOMATIC FILE MERGE SCRIPT
# This will integrate the session persistence code into production file

$ErrorActionPreference = "Stop"

Write-Host "🔧 MERGING SESSION PERSISTENCE INTO PRODUCTION FILE`n" -ForegroundColor Cyan

# Backup original
Write-Host "1. Creating backup..." -ForegroundColor Yellow
Copy-Item "web\training-plan-builder.html" "web\training-plan-builder.html.backup" -Force
Write-Host "   ✅ Backed up to: web\training-plan-builder.html.backup`n" -ForegroundColor Green

# Read files
Write-Host "2. Reading files..." -ForegroundColor Yellow
$production = Get-Content "web\training-plan-builder.html" -Raw
$newCode = Get-Content "ai_agents\web\training-plan-builder.html" -Raw
Write-Host "   ✅ Production: $($production.Length) chars" -ForegroundColor Green
Write-Host "   ✅ New code: $($newCode.Length) chars`n" -ForegroundColor Green

# Find the old function
Write-Host "3. Locating old checkStravaConnection function..." -ForegroundColor Yellow
$pattern = '(?s)(.*?)(      async function checkStravaConnection\(\) \{.*?\n      \})\s*(.*)'
if ($production -match $pattern) {
    $before = $Matches[1]
    $oldFunction = $Matches[2]
    $after = $Matches[3]
    
    Write-Host "   ✅ Found function: $($oldFunction.Length) chars" -ForegroundColor Green
    Write-Host "   ✅ Content before: $($before.Length) chars" -ForegroundColor Green
    Write-Host "   ✅ Content after: $($after.Length) chars`n" -ForegroundColor Green
} else {
    Write-Host "   ❌ Could not find old function!" -ForegroundColor Red
    exit 1
}

# Extract just the functions from new code (remove script tags)
Write-Host "4. Extracting new functions..." -ForegroundColor Yellow
$newFunctionsOnly = $newCode -replace '(?s)^.*?(<script>)(.*)(</script>).*$', '$2'
$newFunctionsOnly = $newFunctionsOnly.Trim()
Write-Host "   ✅ Extracted: $($newFunctionsOnly.Length) chars`n" -ForegroundColor Green

# Merge
Write-Host "5. Merging files..." -ForegroundColor Yellow
$merged = $before + "`n" + $newFunctionsOnly + "`n" + $after
Write-Host "   ✅ Merged file: $($merged.Length) chars`n" -ForegroundColor Green

# Save
Write-Host "6. Saving new file..." -ForegroundColor Yellow
$merged | Out-File "web\training-plan-builder.html" -Encoding UTF8 -NoNewline
Write-Host "   ✅ Saved to: web\training-plan-builder.html`n" -ForegroundColor Green

# Verify
Write-Host "7. Verifying..." -ForegroundColor Yellow
$verify = Get-Content "web\training-plan-builder.html" -Raw
if ($verify -match 'checkExistingStravaConnection') {
    Write-Host "   ✅ SUCCESS! New function found in production file`n" -ForegroundColor Green
} else {
    Write-Host "   ❌ ERROR: Function not found after merge!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ MERGE COMPLETE!`n" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open web\training-plan-builder.html and verify it looks correct" -ForegroundColor White
Write-Host "  2. Run: git diff web/training-plan-builder.html" -ForegroundColor White
Write-Host "  3. Run: git add web/training-plan-builder.html" -ForegroundColor White
Write-Host '  4. Run: git commit -m "✅ Apply Strava Session Persistence"' -ForegroundColor White
Write-Host "  5. Run: git push origin main`n" -ForegroundColor White

Write-Host "Backup available at: web\training-plan-builder.html.backup" -ForegroundColor Gray
