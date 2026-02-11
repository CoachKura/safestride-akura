# Deploy Structured Workouts Migration
# Provides instructions for deploying the migration to Supabase

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Structured Workouts Migration Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$migrationFile = Join-Path $PSScriptRoot "migration_structured_workouts.sql"

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
Write-Host "This migration must be run through the Supabase Dashboard:"
Write-Host ""
Write-Host "1. Open Supabase Dashboard: https://app.supabase.com" -ForegroundColor Cyan
Write-Host "2. Select your project" -ForegroundColor Cyan
Write-Host "3. Go to SQL Editor (left sidebar)" -ForegroundColor Cyan
Write-Host "4. Click 'New Query'" -ForegroundColor Cyan
Write-Host "5. Copy and paste the contents of:" -ForegroundColor Cyan
Write-Host "   $migrationFile" -ForegroundColor Green
Write-Host "6. Click 'Run' (or press Ctrl+Enter)" -ForegroundColor Cyan
Write-Host "7. Verify success message" -ForegroundColor Cyan
Write-Host ""
Write-Host "After deployment, run:" -ForegroundColor Yellow
Write-Host "  .\verify-structured-workouts.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What this migration creates:" -ForegroundColor Cyan
Write-Host "  ✓ structured_workouts table (with JSONB steps column)" -ForegroundColor Green
Write-Host "  ✓ workout_assignments table (links workouts to athletes)" -ForegroundColor Green
Write-Host "  ✓ Indexes for performance" -ForegroundColor Green
Write-Host "  ✓ RLS policies for security" -ForegroundColor Green
Write-Host "  ✓ Triggers for updated_at timestamps" -ForegroundColor Green
Write-Host ""

# Try to copy SQL to clipboard
if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    Set-Clipboard -Value $sql -ErrorAction SilentlyContinue
    Write-Host "✓ Migration SQL copied to clipboard!" -ForegroundColor Green
    Write-Host "  Just paste it into the Supabase SQL Editor" -ForegroundColor Gray
} else {
    Write-Host "ℹ️  Copy commands the SQL from $migrationFile" -ForegroundColor Gray
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
