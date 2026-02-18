# Deploy AISRI Terminology Correction Migration
# Provides instructions for deploying the AISRI correction to Supabase

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AISRI Terminology Correction Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$migrationFile = Join-Path $PSScriptRoot "migration_fix_aisri_terminology.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "✗ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "📖 Reading migration file..." -ForegroundColor Yellow
$sql = Get-Content $migrationFile -Raw
Write-Host "✓ Migration file loaded ($($sql.Length) characters)" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  MANUAL DEPLOYMENT REQUIRED" -ForegroundColor Yellow
Write-Host ""
Write-Host "This migration corrects AISRI → AISRI terminology throughout the database"
Write-Host ""
Write-Host "What will be changed:" -ForegroundColor Cyan
Write-Host "  • Tables: AISRI_assessments → aisri_assessments" -ForegroundColor White
Write-Host "  • Columns: AISRI_score → aisri_score" -ForegroundColor White
Write-Host "  • Columns: AISRI_zone → aisri_zone" -ForegroundColor White
Write-Host "  • JSONB: AISRIZone → aisriZone (in structured_workouts)" -ForegroundColor White
Write-Host "  • Indexes: All AISRI indexes recreated as AISRI" -ForegroundColor White
Write-Host "  • Policies: RLS policies updated" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  BREAKING CHANGE WARNING!" -ForegroundColor Red
Write-Host "This migration renames database tables and columns." -ForegroundColor Yellow
Write-Host "Ensure your app code has been updated first!" -ForegroundColor Yellow
Write-Host ""

Write-Host "Deployment Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open Supabase Dashboard: https://app.supabase.com" -ForegroundColor White
Write-Host "2. Select your project" -ForegroundColor White
Write-Host "3. Go to SQL Editor (left sidebar)" -ForegroundColor White
Write-Host "4. Click 'New Query'" -ForegroundColor White
Write-Host "5. Copy and paste the contents of:" -ForegroundColor White
Write-Host "   $migrationFile" -ForegroundColor Green
Write-Host "6. Click 'Run' (or press Ctrl+Enter)" -ForegroundColor White
Write-Host "7. Verify success messages in output" -ForegroundColor White
Write-Host "8. Check verification section at bottom" -ForegroundColor White
Write-Host ""

Write-Host "After deployment:" -ForegroundColor Yellow
Write-Host "  ✓ Test app on device" -ForegroundColor White
Write-Host "  ✓ Verify assessment screen works" -ForegroundColor White
Write-Host "  ✓ Check workout zones display correctly" -ForegroundColor White
Write-Host "  ✓ Confirm no AISRI references remain" -ForegroundColor White
Write-Host ""

# Try to copy SQL to clipboard
if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    Set-Clipboard -Value $sql -ErrorAction SilentlyContinue
    Write-Host "✓ Migration SQL copied to clipboard!" -ForegroundColor Green
    Write-Host "  Just paste it into the Supabase SQL Editor" -ForegroundColor Gray
} else {
    Write-Host "ℹ️  Copy the SQL from: $migrationFile" -ForegroundColor Gray
}

Write-Host ""

# Try to open the SQL file in VS Code
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "📝 Opening migration file in VS Code..." -ForegroundColor Yellow
    & code $migrationFile
}

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host
